`default_nettype none

module MagComp
  #(parameter WIDTH = 6)
  (input logic [WIDTH-1:0] A, B,
   output logic AltB , AeqB, AgtB);

  always_comb begin
    AltB = (A < B);
    AeqB = (A == B);
    AgtB = (A > B);
  end

endmodule: MagComp

module Adder
  #(parameter WIDTH = 6)
  (input logic [WIDTH-1:0] A, B,
   input logic Cin,
   output logic [WIDTH-1:0] S,
   output logic Cout);

  always_comb begin
    S = A + B + Cin;
    Cout = ((A + B + Cin) >= (2 ** WIDTH));
  end

endmodule: Adder

module Multiplexer
  #(parameter WIDTH = 6)
  (input logic [WIDTH-1:0] I,
   input logic [$clog2(WIDTH)-1:0] S,
   output logic Y);

  always_comb begin
    Y = I[S];
  end

endmodule: Multiplexer

module Mux2to1
  #(parameter WIDTH = 6)
  (input logic [WIDTH-1:0] I0, I1,
   input logic S,
   output logic [WIDTH-1:0] Y);

  always_comb begin
    Y = (S) ? I1:I0;
  end

endmodule: Mux2to1

module Decoder
  #(parameter WIDTH = 6)
  (input logic [$clog2(WIDTH)-1:0] I,
   input logic en,
   output logic [WIDTH-1:0] D);

  always_comb begin
    D[I] = en;
  end

endmodule: Decoder

module Register
  #(parameter WIDTH = 6)
  (input logic [WIDTH-1:0] D,
   input logic en, clear, clock,
   output logic [WIDTH-1:0] Q);

  always_ff @(posedge clock)
    if (en)
      Q <= D;
    else if (clear)
      Q <= 0;
    else
      Q <= Q;

endmodule: Register

//a generic counter module, counts up on enable and resets on clear
module Counter #(parameter WIDTH = 10)
 (input logic clock, en, clear,
  output logic [WIDTH-1:0] count);

  logic [WIDTH-1:0] regIn;

  Adder #(WIDTH) add (.A('h1), .B(count), .Cin(1'b0), .Cout(), .S(regIn));

  Register #(WIDTH) val (.D(regIn), .Q(count), .clear(clear), .en(en),
                      .clock(clock));
endmodule: Counter
