// MMEM --- M MEMORY
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog.
//	???: Nets added.
//	???: Nets removed.
//   (1978-02-03 04:39:58 TK) Initial.

`timescale 1ns/1ps
`default_nettype none

module MMEM(/*AUTOARG*/
   // Outputs
   mmem,
   // Inputs
   clk, reset, l, madr, mrp, mwp
   );

   input clk;
   input reset;

   input [31:0] l;
   input [4:0] madr;
   input mrp;
   input mwp;
   output [31:0] mmem;

   ////////////////////////////////////////////////////////////////////////////////

   localparam ADDR_WIDTH = 5;
   localparam DATA_WIDTH = 32;
   localparam MEM_DEPTH = 32;

   ////////////////////////////////////////////////////////////////////////////////

`ifdef ISE
   wire ena_a = mrp | 1'b0;
   wire ena_b = 1'b0 | mwp;

   ise_MMEM inst
     (
      .clka(clk),
      .ena(ena_a),
      .wea(1'b0),
      .addra(madr),
      .dina(32'b0),
      .douta(mmem),
      .clkb(clk),
      .enb(ena_b),
      .web(mwp),
      .addrb(madr),
      .dinb(l),
      .doutb()
      /*AUTOINST*/);
		
`elsif SIMULATION
	reg [31:0] ram [0:31];
   reg [31:0] out_a;
   reg [31:0] out_b;

   assign mmem = out_a;


   always @(posedge clk)
     if (1'b0) begin
	ram[madr] <= 32'b0;
     end else if (mwp) begin
	ram[madr] <= l;
     end

   always @(posedge clk)
     if (reset)
       out_a <= 0;
     else if (mrp) begin
	out_a <= ram[madr];
     end

   always @(posedge clk)
     if (reset)
       out_b <= 0;
     else if (1'b0) begin
	out_b <= ram[madr];
     end
`else // ALTERA

	reg [31:0] ram [0:31];
   reg [31:0] out_a;
   
   assign mmem = out_a;
	initial out_a = 0;

   always @(posedge clk) begin
		if (mwp) begin
			ram[madr] <= l;
		end
	end
	
	always @(posedge clk) begin
		if (mrp) begin
			out_a <= ram[madr];
		end
	end

`endif

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: (".." "../cores/xilinx")
// End:
