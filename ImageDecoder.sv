/*
----------------------------------------
Stereoscopic Vision System
Senior Design Project - Team 11
California State University, Sacramento
Spring 2015 / Fall 2015
----------------------------------------
Omnivision 7670 Data Capture
Authors:  Greg M. Crist, Jr. (gmcrist@gmail.com)
Description:
    Abstracts the data capture of the OV 7670 Camera
*/

`default_nettype none

module ov_7670_capture
  (
    input logic pclk,
    input logic vsync,
    input logic href,
    input logic [7:0] data,
    output logic  [15:0] addr,
    output logic  [15:0] data_out,
    output logic  write_en
  );

    logic [31:0] data_reg;
    logic [15:0] CounterX, CounterY, xPos;
    logic [1:0] line;
    logic [6:0] href_last;
    logic write_en_reg;
    logic href_hold;
    logic latched_vsync;
    logic latched_href;
    logic [7:0] latched_d;

    assign addr     = (16'd235 * CounterY) + CounterX;
    assign write_en = write_en_reg;
    logic [4:0] R_p, B_p;
    logic [5:0] G_p;
    logic isValidxPos;

    assign data_out = {R_p, G_p, B_p}; //functional RGB565!
    assign CounterX = (isValidxPos) ? (xPos - 16'd40) : 16'd0;


    
    assign isValidxPos = (xPos <= 16'd275 && xPos >= 16'd40);



    

    // rgb 565 (this is reading off by one cycle at the moment, not quite sure how to fix)
    assign R_p = {data_reg[7:3]}; //red channel
    assign G_p = {data_reg[2:0], data_reg[15:13]}; //green channel 
    assign B_p = {data_reg[12:8]}; //blue channel

    always_ff @(negedge pclk) begin
        href_hold <= latched_href;
        write_en_reg <= 1'b0;

        if (href_hold == 1'b0)
            xPos <= 16'd0;
        else if (href_last[0] == 1'b1) begin
            CounterY <= (xPos == 16'd0) ? (CounterY + 16'd1) : CounterY;
            xPos <= xPos + 1'b1;
        end

        //if ((href_last[0] + href_last[1] + href_last[2]) == 1'b1) 
        //    address <= address + 1'b1;

        // detect the rising edge on href - the start of the scan line
        if (href_hold == 1'b0 && latched_href == 1'b1) begin
            case (line)
                2'b00:   line <= 2'b01;
                2'b01:   line <= 2'b10;
                2'b10:   line <= 2'b11;
                default: line <= 2'b00;
            endcase
        end

        // capturing the data from the camera, 12-bit RGB
        if (latched_href == 1'b1) begin
            data_reg <= {data_reg[23:0], latched_d};
        end

        // Is a new screen about to start (i.e. we have to restart capturing
        if (latched_vsync == 1'b1) begin
            xPos      <= 16'd0;
            href_last    <= 7'd0;
            line         <= 2'd0;
            CounterY <= 16'd0;
        end
        else begin
            // If not, set the write enable whenever we need to capture a pixel
            if (href_last[0] == 1'b1) begin
                write_en_reg <= (isValidxPos);
                href_last <= 7'd0;
            end
            else begin
                href_last <= {href_last[5:0], latched_href};

            end
        end
    end

    always_ff @(posedge pclk) begin
        latched_d     <= data;
        latched_href  <= href;
        latched_vsync <= vsync;
    end
endmodule