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
    output logic  [18:0] addr,
    output logic  [23:0] data_out,
    output logic  write_en
  );

    logic [15:0] data_reg;
    logic [18:0] address;
    logic [1:0] line;
    logic [6:0] href_last;
    logic write_en_reg;
    logic href_hold;
    logic latched_vsync;
    logic latched_href;
    logic [7:0] latched_d;

    assign addr     = address;
    assign write_en = write_en_reg;
    assign data_out = {data_reg[15:12], data_reg[15:12], data_reg[10:7], data_reg[10:7], data_reg[4:1], data_reg[4:1]};

    always_ff @(posedge pclk) begin
        href_hold <= latched_href;
        write_en_reg <= 1'b0;

        if (write_en_reg == 1'b1)
            address <= address + 1'b1;

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
            data_reg <= {data_reg[7:0], latched_d};
        end

        // Is a new screen about to start (i.e. we have to restart capturing
        if (latched_vsync == 1'b1) begin
            address      <= 19'd0;
            href_last    <= 7'd0;
            line         <= 2'd0;
        end
        else begin
            // If not, set the write enable whenever we need to capture a pixel
            if (href_last[0] == 1'b1) begin
                write_en_reg <= 1'b1;
                href_last <= 7'd0;
            end
            else begin
                href_last <= {href_last[5:0], latched_href};
            end
        end
    end

    always_ff @(negedge pclk) begin
        latched_d     <= data;
        latched_href  <= href;
        latched_vsync <= vsync;
    end
endmodule