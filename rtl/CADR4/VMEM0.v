// VMEM0 --- VIRTUAL MEMORY MAP STAGE 0
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog.
//	???: Nets added.
//	???: Nets removed.
//   (1978-08-22 11:29:05 TK) Initial.

`timescale 1ns/1ps
`default_nettype none

module VMEM0(/*AUTOARG*/
   // Outputs
   vmap,
   // Inputs
   clk, reset, mapi, vma, memstart, srcmap, vm0rp, vm0wp
   );

   input clk;
   input reset;

   input [23:8] mapi;
   input [31:0] vma;
   input memstart;
   input srcmap;
   input vm0rp;
   input vm0wp;
   output [4:0] vmap;

   ////////////////////////////////////////////////////////////////////////////////

   localparam ADDR_WIDTH = 11;
   localparam DATA_WIDTH = 5;
   localparam MEM_DEPTH = 2048;

   wire [10:0] vmem0_adr;
   wire use_map;

   ////////////////////////////////////////////////////////////////////////////////

   assign vmem0_adr = mapi[23:13];

`ifdef ISE
   wire ena_a = vm0rp && ~vm0wp | 1'b0;
   wire ena_b = 1'b0 | vm0wp;

   ise_VMEM0 inst
     (
      .clka(clk),
      .ena(ena_a),
      .wea(1'b0),
      .addra(vmem0_adr),
      .dina(5'b0),
      .douta(vmap),
      .clkb(clk),
      .enb(ena_b),
      .web(vm0wp),
      .addrb(vmem0_adr),
      .dinb(vma[31:27]),
      .doutb()
      /*AUTOINST*/);
		
`else 

	reg [4:0] ram [0:2047];
   reg [4:0] out_a;
	initial out_a = 0;
   
	assign vmap = out_a;

	wire [4:0] vma_in = vma[31:27];
	wire vma_en = vm0rp | vm0wp;
	
	always @(posedge clk) begin
		if (vma_en) begin
			if (vm0wp) begin
				ram[vmem0_adr] <= vma_in;
			end
			out_a <= ram[vmem0_adr];
		end
	end

`endif

   assign use_map = srcmap | memstart;

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: (".." "../cores/xilinx")
// End:
