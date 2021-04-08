`default_nettype none
module BCDtoSevenSegment
  (input logic [3:0] bcd,
   output logic [6:0] segment);

  always_comb begin
     case (bcd)
       4'd0: segment = 7'b1000000;
       4'd1: segment = 7'b1111001;
       4'd2: segment = 7'b0100100;
       4'd3: segment = 7'b0110000;
       4'd4: segment = 7'b0011001;
       4'd5: segment = 7'b0010010;
       4'd6: segment = 7'b0000010;
       4'd7: segment = 7'b1111000;
       4'd8: segment = 7'b0000000;
       4'd9: segment = 7'b0011000;
       4'd10: segment = 7'b0001000;
       4'd11: segment = 7'b0000011;
       4'd12: segment = 7'b1000110;
       4'd13: segment = 7'b0100001;
       4'd14: segment = 7'b0000110;
       4'd15: segment = 7'b0001110;
       default: segment = 7'b1111111;
     endcase
  end
endmodule: BCDtoSevenSegment

