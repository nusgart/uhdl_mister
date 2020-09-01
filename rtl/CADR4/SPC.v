// SPC --- SPC MEMORY AND POINTER
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog.
//	???: Nets added.
//	???: Nets removed.
//   (1979-03-31 04:51:21 TK) Initial.

`timescale 1ns/1ps
`default_nettype none

module SPC(/*AUTOARG*/
   // Outputs
   spco, spcptr,
   // Inputs
   clk, reset, state_fetch, spcw, spcnt, spush, srp, swp
   );

   input clk;
   input reset;

   input state_fetch;

   input [18:0] spcw;
   input spcnt;
   input spush;
   input srp;
   input swp;
   output [18:0] spco;
   output [4:0] spcptr;

   ////////////////////////////////////////////////////////////////////////////////

   localparam ADDR_WIDTH = 5;
   localparam DATA_WIDTH = 19;
   localparam MEM_DEPTH = 32;

   reg [4:0] spcptr;

   wire [4:0] spcadr;

   ////////////////////////////////////////////////////////////////////////////////

   wire [4:0] spcptr_p1;
   assign spcptr_p1 = spcptr + 5'b00001;
   assign spcadr = (spcnt && spush) ? spcptr_p1 : spcptr;

`ifndef ISE
   reg [18:0] ram [0:31];
   reg [18:0] out_a;
   reg [18:0] out_b;
	
	reg swp_cond;
	
	always @(posedge clk) begin
		swp_cond <= (swp && spcadr == spcptr);
		out_b <= spcw;
	end

   assign spco = (swp_cond) ? out_a : out_b;

	always @(posedge clk) begin
		if (swp) begin
			ram[spcadr] <= spcw;
		end
	end

	always @(posedge clk) begin
		if (srp) begin
			out_a <= ram[spcptr];
		end
	end
	
	/*
   always @(posedge clk)
     if (1'b0) begin
	ram[spcptr] <= 19'b0;
     end else if (swp) begin
	ram[spcadr] <= spcw;
     end

   always @(posedge clk)
     if (reset)
       out_a <= 0;
     else if (srp && ~swp) begin
	/ * WE NEED 'READ NEW DATA' ON SIMULTANEOUS WRITE/READ TO SAME ADDR * /
	if (swp && spcadr == spcptr) begin
	   out_a <= spcw;
	end else begin
	   out_a <= ram[spcptr];
	end
     end
	*/
	  
`else
   wire ena_a = srp && ~swp | 1'b0;
   wire ena_b = 1'b0 | swp;

   ise_SPC inst
     (
      .clka(clk),
      .ena(ena_a),
      .wea(1'b0),
      .addra(spcptr),
      .dina(19'b0),
      .douta(spco),
      .clkb(clk),
      .enb(ena_b),
      .web(swp),
      .addrb(spcadr),
      .dinb(spcw),
      .doutb()
      /*AUTOINST*/);
`endif

   always @(posedge clk)
     if (reset)
       spcptr <= 0;
     else if (state_fetch) begin
	if (spcnt) begin
	   if (spush)
	     spcptr <= spcptr + 5'd1;
	   else
	     spcptr <= spcptr - 5'd1;
	end
     end

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: (".." "../cores/xilinx")
// End:
