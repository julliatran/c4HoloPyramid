`default_nettype none

module hvsync_generator(
    input logic clk,
    output logic vga_h_sync,
    output logic vga_v_sync,
    output logic inDisplayArea,
    output logic [15:0] CounterX,
    output logic [15:0] CounterY
  );
    reg vga_HS, vga_VS;

    wire CounterXmaxed = (CounterX == 1664); // 1280 + sync
    wire CounterYmaxed = (CounterY == 748); // 720 + sync

    always @(posedge clk)
    if (CounterXmaxed)
      CounterX <= 0;
    else
      CounterX <= CounterX + 1;

    always @(posedge clk)
    begin
      if (CounterXmaxed)
      begin
        if(CounterYmaxed)
          CounterY <= 0;
        else
          CounterY <= CounterY + 1;
      end
    end

    always @(posedge clk)
    begin
      vga_HS <= (CounterX > (1280 + 64) && (CounterX < (1280 + 64 + 128)));   
      vga_VS <= (CounterY > (720 + 3) && (CounterY < (720 + 3 + 5)));   
    end

    always @(posedge clk)
    begin
        inDisplayArea <= (CounterX < 1280) && (CounterY < 720);
    end

    assign vga_h_sync = ~vga_HS;
    assign vga_v_sync = ~vga_VS;


endmodule

module VGADemo(
    input logic clk_25,
    input logic [15:0] data_in,
    output logic [23:0] pixel,
    output logic hsync_out,
    output logic vsync_out,
    output logic [15:0] CounterX, CounterY
);
    wire inDisplayArea;

    hvsync_generator hvsync(
      .clk(clk_25),
      .vga_h_sync(hsync_out),
      .vga_v_sync(vsync_out),
      .CounterX(CounterX),
      .CounterY(CounterY),
      .inDisplayArea(inDisplayArea),
    );
    
    //rgb 565 conversion
    logic [7:0] R, G, B;
    assign R = {data_in[15:11], 3'b0};
    assign G = {data_in[10:5], 2'b0};
    assign B = {data_in[4:0], 3'b0};

    //assign R = {8'd255};
    //assign G = {8'd255};
    //assign B = {8'd255};

    always @(posedge clk_25)
    begin
      if (inDisplayArea)
        pixel <= {R, G, B};
      else // if it's not to display, go dark
        pixel <= 23'b0;
    end

endmodule

module ChipInterface
  (input logic CLOCK_50,
   input logic [1:0] KEY,
   output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4,
   output logic [1:0] LEDR,
   output logic [7:0] VGA_R, VGA_G, VGA_B,
   output logic VGA_CLK, VGA_SYNC_N, VGA_BLANK_N, VGA_VS, VGA_HS,
   inout GPIO[25:10]);

  logic [7:0] CAM_DATA;
  logic [15:0] camera_decode_out;

  logic [25:10] GPIO_out;
  logic [25:10] GPIO_in;

  assign GPIO[24] = GPIO_out[24];
  assign GPIO[23] = 1'bz;
  //assign GPIO[22] = 1'bz;
  assign GPIO_in[23] = GPIO[23];
  assign GPIO_in[22] = GPIO[22];
  assign GPIO[21] = GPIO_out[21];
  assign GPIO[20] = 1'bz;
  assign GPIO[19] = 1'bz;
  assign GPIO[18] = 1'bz;
  assign GPIO[17] = 1'bz;
  assign GPIO[16] = 1'bz;
  assign GPIO[15] = 1'bz;
  assign GPIO[14] = 1'bz;
  assign GPIO[13] = 1'bz;
  assign GPIO[12] = 1'bz;
  assign GPIO_in[20] = GPIO[20];
  assign GPIO_in[19] = GPIO[19];
  assign GPIO_in[18] = GPIO[18];
  assign GPIO_in[17] = GPIO[17];
  assign GPIO_in[16] = GPIO[16];
  assign GPIO_in[15] = GPIO[15];
  assign GPIO_in[14] = GPIO[14];
  assign GPIO_in[13] = GPIO[13];
  assign GPIO_in[12] = GPIO[12];
  assign GPIO[11] = GPIO_out[11];
  assign GPIO[10] = GPIO_out[10];


  assign CAM_DATA = {GPIO_in[18], GPIO_in[19], GPIO_in[16], GPIO_in[17], GPIO_in[14], GPIO_in[15], GPIO_in[12], GPIO_in[13]};

  logic SCCB_CLK, CLOCK_24;

  //BCDtoSevenSegment(.bcd(camera_decode_out[23:20]), .segment(HEX2));
  //BCDtoSevenSegment(.bcd(camera_decode_out[15:12]), .segment(HEX1));
  //BCDtoSevenSegment(.bcd(camera_decode_out[7:4]), .segment(HEX0));

  logic vsync;
  assign vsync = GPIO_in[22];
  assign LEDR[0] = vsync;
  assign LEDR[1] = 1'b1;

  logic start, reset, cam_en;
  assign start = ~KEY[1];
  assign reset = ~KEY[0];

  logic [15:0] cam_addr;

  assign GPIO_out[21] = CLOCK_24; //mclock

  top (.CLOCK_24(CLOCK_24), .SDA(GPIO[25]), .SCL(GPIO_out[24]), .pwdn(GPIO_out[11]), .start(start), .reset(reset), 
       .SCCB_CLK(SCCB_CLK), .DATA_IN(CAM_DATA), .HREF(GPIO_in[23]), .VSYNC(vsync), .PCLK(GPIO_in[20]), .data_out(camera_decode_out),
       .write_en(cam_en), .addr(cam_addr));

  assign GPIO_out[10] = ~reset;



  SCCB_pll	SCCB_pll_inst (
	.inclk0 (CLOCK_50),
	.c0 (SCCB_CLK)
	);

  CLOCK_24	CLOCK_24_inst (
	.inclk0 (CLOCK_50),
	.c0 (CLOCK_24)
	);


  PLL720p	PLL720p_inst (
	.inclk0 (CLOCK_50),
	.c0 (VGA_CLK)
	);


  logic [23:0] pixel;

  logic [7:0] red, green, blue;

  logic [15:0] vga_addr;
  logic incam1, incam2, incam3, incam4;

  logic [15:0] CounterX, CounterY, posX, posY;

  assign posX = (CounterX >= 16'd48) ? CounterX + 16'd48 : 16'd0;
  assign posY = CounterY;

  logic [15:0] stored_cam1, stored_cam2, stored_cam3, stored_cam4;
  logic [15:0] cam_mem_out;


  always_comb begin
    vga_addr = 16'd0;
    incam1 = 1'b0;
    incam2 = 1'b0;
    incam3 = 1'b0;
    incam4 = 1'b0; 
    cam_mem_out = 16'd0;
    if (posY >= 16'd0 && posY <= 16'd235 && posX >= 16'd520 && posX <= 16'd755) begin //top cam
      vga_addr = (16'd235 * (posY - 16'd0)) + (16'd755 - posX);
      incam1 = 1'b1;
      cam_mem_out = stored_cam1;
    end
    else if (posY >= 16'd240 && posY <= 16'd475 && posX >= 16'd760 && posX <= 16'd995) begin //right cam
      vga_addr = (16'd235 * (16'd995 - posX)) + (16'd475 - posY);
      incam2 = 1'b1;
      cam_mem_out = stored_cam2;
    end
    else if (posY >= 16'd240 && posY <= 16'd475 && posX >= 16'd280 && posX <= 16'd515) begin //left cam
      vga_addr = (16'd235 * (posX - 16'd280)) + (posY - 16'd240);
      incam3 = 1'b1;
      cam_mem_out = stored_cam3;
    end
    else if (posY >= 16'd480 && posY <= 16'd715 && posX >= 16'd520 && posX <= 16'd755) begin //bottom cam
      vga_addr = (16'd235 * (16'd715 - posY)) + (posX - 16'd520);
      incam4 = 1'b1;
      cam_mem_out = stored_cam4;
    end
  end


  //BCDtoSevenSegment(.bcd({1'b0,addr[18:16]}), .segment(HEX4));
  //BCDtoSevenSegment(.bcd(addr[15:12]), .segment(HEX3));
  //BCDtoSevenSegment(.bcd(addr[11:8]), .segment(HEX2));
  //BCDtoSevenSegment(.bcd(addr[7:4]), .segment(HEX1));
  //BCDtoSevenSegment(.bcd(addr[3:0]), .segment(HEX0));




  qvga16bit235p4096bd	qvga16bit_inst1 (
	.data (camera_decode_out),
	.rdaddress (vga_addr),
	.rdclock (VGA_CLK),
	.wraddress (cam_addr),
	.wrclock (GPIO_in[20]),
	.wren (cam_en),
	.q (stored_cam1)
	);

  qvga16bit235p4096bd	qvga16bit_inst2 (
	.data (camera_decode_out),
	.rdaddress (vga_addr),
	.rdclock (VGA_CLK),
	.wraddress (cam_addr),
	.wrclock (GPIO_in[20]),
	.wren (cam_en),
	.q (stored_cam2)
	);

  qvga16bit235p4096bd	qvga16bit_inst3 (
	.data (camera_decode_out),
	.rdaddress (vga_addr),
	.rdclock (VGA_CLK),
	.wraddress (cam_addr),
	.wrclock (GPIO_in[20]),
	.wren (cam_en),
	.q (stored_cam3)
	);

  qvga16bit235p4096bd	qvga16bit_inst4 (
	.data (camera_decode_out),
	.rdaddress (vga_addr),
	.rdclock (VGA_CLK),
	.wraddress (cam_addr),
	.wrclock (GPIO_in[20]),
	.wren (cam_en),
	.q (stored_cam4)
	);







  
  
  logic [23:0] vga_to_display;

  assign vga_to_display = (incam1 || incam2 || incam3 || incam4) ? pixel : 23'd0;
  
  assign VGA_R = vga_to_display[23:16];
  assign VGA_G = vga_to_display[15:8];
  assign VGA_B = vga_to_display[7:0];

  assign VGA_BLANK_N = 1'b1;
  assign VGA_SYNC_N = 1'b0;

  VGADemo VGA_OUT(.clk_25(VGA_CLK), .pixel(pixel), .hsync_out(VGA_HS), .vsync_out(VGA_VS), 
                  .data_in(cam_mem_out), .CounterX(CounterX), .CounterY(CounterY));

endmodule: ChipInterface
  