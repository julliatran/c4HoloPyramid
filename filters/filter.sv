module chroma_key
  (input logic [15:0] pixel,
   input logic [15:0] target,
   input logic [1:0] threshold,
   output logic [15:0] out);

   logic signed [5:0] red_diff, blue_diff;
   logic signed [6:0] green_diff;
   logic signed [17:0] red_prod, blue_prod, green_prod, total_diff;

   assign red_diff = target[15:11] - pixel[15:11];
   assign green_diff = target[10:5] - pixel[10:5];
   assign blue_diff = target[4:0] - pixel[4:0];

   //assign red_prod = red_diff * red_diff;
   //assign green_prod = green_diff * green_diff;
   //assign blue_prod = blue_diff * blue_diff;


   mult9bit m1(.dataa({red_diff[0], red_diff[0], red_diff[0], red_diff[0], red_diff}),
            .datab({red_diff[0], red_diff[0], red_diff[0], red_diff[0], red_diff}),
            .result(red_prod));
   mult9bit m2(.dataa({blue_diff[0], blue_diff[0], blue_diff[0], blue_diff[0], blue_diff}),
            .datab({blue_diff[0], blue_diff[0], blue_diff[0], blue_diff[0], blue_diff}),
            .result(blue_prod));
   mult9bit m3(.dataa({green_diff[0], green_diff[0], green_diff[0], green_diff}),
            .datab({green_diff[0], green_diff[0], green_diff[0], green_diff}),
            .result(green_prod));

   // red_diff and blue_diff need a 5-bit times 5-bit multiplier
   // green_diff needs a 6_bit times 6_bit multiplier
   assign total_diff = (red_prod << 2) + (blue_prod << 2) + green_prod;
   assign out = (total_diff < (14'd64 << threshold)) ? 16'b0 : pixel;
endmodule: chroma_key

module brighten
  (input logic [15:0] pixel,
   input logic [2:0] beta, // brightness coefficient
   output logic [15:0] out);

   logic [4:0] red, blue;
   logic [5:0] green;
   logic [3:0] brightness;

   assign red = pixel[15:11];
   assign green = pixel[10:5];
   assign blue = pixel[4:0];
   assign brightness = beta << 1;

   assign out[15:11] = (red > (5'b11111 - beta)) ? 5'b11111 : (red + beta);
   assign out[10:5] = (green > (6'b111111 - brightness)) ? 6'b111111 : (green + brightness);
   assign out[4:0] = (blue > (5'b11111 - brightness)) ? 5'b11111 : (blue + beta);
endmodule: brighten

module contrast
  (input logic [15:0] pixel,
   input logic [4:0] alpha,
   output logic [15:0] out);

  logic [4:0] red_tmp, blue_tmp;
  logic [5:0] green_tmp;

  assign out[15:11] = alpha * (pixel[15:11] - 5'b10000) + 5'b10000;
  assign out[10:5] = alpha * (pixel[10:5] - 6'b100000) + 6'b100000;
  assign out[4:0] = alpha * (pixel[4:0] - 5'b10000) + 5'b10000;

endmodule: contrast
