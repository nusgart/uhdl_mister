/******************************************************************************* 
 * Engineer: Nicholas Nusgart
 * Design Name: LM-3 CADR implementation
 * Module Name: ram_controller_mister
 * Project Name: LM-3
 * Description: This module is acts as the memory controller for the LM-3.  It
                acts as the interface from the LM-3 sdram bus to the MiSTer's
					 DDR3 and from the LM-3 vram bus to the VRAM (implemented as
					 block ram).  
 * Dependencies:  alt_vram
 * Revision:
 * Revision 0.01 - File Created
 * Additional Comments: 
******************************************************************************/

`timescale 1ns/1ps
`default_nettype none

module ram_controller_mister (
	// system interface
	input clk,
   input cpu_clk,
   input vga_clk,
   input reset,
	// DDR interface
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	
   //// CADR sdram interface
	input wire [21:0] sdram_addr,
   input wire [31:0] sdram_data_in,
	output [31:0] sdram_data_out,
	input wire sdram_req,
   input wire sdram_write,
	output reg sdram_done,
   output reg sdram_ready,
	
	
	// CADR microcode interface
   input wire [13:0] mcr_addr,
	input wire [48:0] mcr_data_in,
	output [48:0] mcr_data_out,
	input mcr_write,
	output mcr_done,
   output mcr_ready,
	
	// CADR & VGA VRAM interface
   input [14:0] vram_cpu_addr,
	input [31:0] vram_cpu_data_in,
	output [31:0] vram_cpu_data_out,
	input vram_cpu_req,
   input vram_cpu_write,
	output vram_cpu_done,
   output vram_cpu_ready,
	
	input [14:0] vram_vga_addr,
   output [31:0] vram_vga_data_out,
   input vram_vga_req,
   output vram_vga_ready
   );

	
	////// SDRAM support -- this probably needs work.  Probably doesn't meet xbus requirements
	////// -- specifically, it might not take enough clock cycles.
	// TODO since there is a large amount of free block ram, implement a 64 KW cache (256 KB).
	// I think using a direct mapped cache would be fine here since the cachable portion of the
	// address space is only 3.75 MW, so that's only 60 addresses mapping to 1 cache line.
	assign DDRAM_CLK = clk;
	assign DDRAM_BURSTCNT = 1;
	assign DDRAM_ADDR = {7'b0, sdram_addr};
	assign DDRAM_RD = sdram_req && ~DDRAM_BUSY;
	assign DDRAM_WE = sdram_write && ~DDRAM_BUSY;
	assign sdram_data_out = DDRAM_DOUT[31:0];
	assign DDRAM_DIN = sdram_data_in[31:0];
	assign sdram_ready = DDRAM_DOUT_READY && ~DDRAM_BUSY;
	assign sdram_done = ~DDRAM_BUSY;
	assign DDRAM_BE = 0;

   ////////////////////////////////////////////////////////////////////////////////
   reg [31:0] vram_vga_data;
   reg [3:0] vram_cpu_ready_dly;
   reg [3:0] vram_vga_ready_dly;
   wire [31:0] vram_vga_ram_out;

	

   //wire ena_a = vram_cpu_req | vram_cpu_write;
   //wire ena_b = vram_vga_req | 1'b0;
	alt_vram inst (
		.address_a(vram_cpu_addr),
		.address_b(vram_vga_addr),
		.clock_a(cpu_clk),
		.clock_b(vga_clk),
		.data_a(vram_cpu_data_in),
		.data_b(32'b0),
		.wren_a(vram_cpu_write),
		.wren_b(1'b0),
		.q_a(vram_cpu_data_out),
		.q_b(vram_vga_ram_out));


   assign vram_vga_data_out = vram_vga_ready ? vram_vga_ram_out : vram_vga_data;

   always @(posedge vga_clk)
     if (reset) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	vram_vga_data <= 32'h0;
	// End of automatics
     end else
       if (vram_vga_ready)
	 vram_vga_data <= vram_vga_ram_out;

   always @(posedge vga_clk)
     if (reset) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	vram_vga_ready_dly <= 4'h0;
	// End of automatics
     end else
       vram_vga_ready_dly <= { vram_vga_ready_dly[2:0], vram_vga_req };

   assign vram_vga_ready = vram_vga_ready_dly[0];
   assign vram_cpu_done = 1'b1;

   always @(posedge cpu_clk)
     if (reset) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	vram_cpu_ready_dly <= 4'h0;
	// End of automatics
     end else
       vram_cpu_ready_dly <= { vram_cpu_ready_dly[2:0], vram_cpu_req };

   assign vram_cpu_ready = vram_cpu_ready_dly[3];
	`ifndef EXTERNAL_MCR
   assign mcr_data_out = 0;
   assign mcr_ready = 0;
   assign mcr_done = 0;
	`else
	//TODO
	`endif

endmodule
`default_nettype wire