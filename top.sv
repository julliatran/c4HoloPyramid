`default_nettype none

module top
  (input logic CLOCK_24,   // TODO: system clock for state transitions
   inout SDA,              // TODO: for i2c SCCB data (tri-state) ties to sio_d ?
   output logic SCL,       // TODO: i2c clock? ties to sio_c = SCCB clock ?
   output logic pwdn,      // TODO: power down for cams, not sure which port
   input  logic start, reset, // for reset signal, start?
   input logic SCCB_CLK,    // TODO: clock for sccb protocol (100kHz to 400kHz)
   input logic [7:0] DATA_IN,
   input logic HREF, VSYNC, PCLK,
   output logic [23:0] data_out,
   output logic write_en,
   output logic [18:0] addr);  // TODO:

  logic done;
  ov_7670_init i(.clk(CLOCK_24),      // TODO: System clock for state transitions
                 .clk_sccb(SCCB_CLK), // TODO  Clock for SCCB protocol (100kHz to 400kHz)
                 .reset(reset),      // TODO: RESET KEY Async reset signal
                 .sio_d(SDA),         // TODO: 
                 .start(start),       // TODO: KEY for start i2c?
                 .sio_c(SCL),        // output TODO
                 .pwdn(pwdn),         // output TODO
                 .done(done));        // output TODO

  //write_en data_out needs to be captured
  ov_7670_capture c(.pclk(PCLK),          // TODO
                    .vsync(VSYNC),        // TODO
                    .href(HREF),          // TODO
                    .data(DATA_IN[7:0]),     // TODO 
                    .addr(addr),          // address of pixel_data
                    .data_out(data_out),  //
                    .write_en(write_en)); //
endmodule