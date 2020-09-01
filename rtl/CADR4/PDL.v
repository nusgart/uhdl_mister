// PDL --- PDL BUFFER
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog; merge of PDL0, and PDL1.
//	???: Nets added.
//	???: Nets removed.
//   (1978-02-02 20:56:26 TK) PDL0: Initial.
//   (1978-02-02 20:53:20 TK) PDL1: Initial.

`timescale 1ns/1ps
`default_nettype none

module PDL(/*AUTOARG*/
   // Outputs
   pdlo,
   // Inputs
   clk, reset, l, pdla, prp, pwp
   );

   input clk;
   input reset;

   input [31:0] l;
   input [9:0] pdla;
   input prp;
   input pwp;
   output [31:0] pdlo;

   ////////////////////////////////////////////////////////////////////////////////

   localparam ADDR_WIDTH = 10;
   localparam DATA_WIDTH = 32;
   localparam MEM_DEPTH = 1024;

   ////////////////////////////////////////////////////////////////////////////////

`ifdef ISE
   wire ena_a = prp | 1'b0;
   wire ena_b = 1'b0 | pwp;

   ise_PDL inst
     (
      .clka(clk),
      .ena(ena_a),
      .wea(1'b0),
      .addra(pdla),
      .dina(32'b0),
      .douta(pdlo),
      .clkb(clk),
      .enb(ena_b),
      .web(pwp),
      .addrb(pdla),
      .dinb(l),
      .doutb()
      /*AUTOINST*/);
`else
	reg [31:0] ram [0:1023];
   reg [31:0] out_a;
   reg [31:0] out_b;

	initial out_a = 0;
   assign pdlo = out_a;

	wire p_en = pwp | prp;
	
	always @(posedge clk) begin
		if (p_en) begin
			if (pwp) begin
				ram[pdla] <= l;
			end
			out_a <= ram[pdla];
		end
	end
	
	/*
	reg [31:0] ram [0:1023];
   reg [31:0] out_a;
   reg [31:0] out_b;

   assign pdlo = out_a;
	
   always @(posedge clk)
     if (1'b0) begin
	ram[pdla] <= 32'b0;
     end else if (pwp) begin
	ram[pdla] <= l;
     end

   always @(posedge clk)
     if (reset)
       out_a <= 0;
     else if (prp) begin
	out_a <= ram[pdla];
     end

   always @(posedge clk)
     if (reset)
       out_b <= 0;
     else if (1'b0) begin
	out_b <= ram[pdla];
     end
	*/
`endif

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: (".." "../cores/xilinx")
// End:
