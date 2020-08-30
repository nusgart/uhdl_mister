// block_dev_dpi.v --- ---!!!

`timescale 1ns/1ps
`default_nettype none

module block_dev_dpi(/*AUTOARG*/
   // Outputs
   bd_bsy, bd_rdy, bd_err, bd_data_out, bd_iordy,
   // Inputs
   clk, reset, bd_cmd, bd_start, bd_addr, bd_data_in, bd_rd, bd_wr
   );

   input clk;
   input reset;

   input [1:0] bd_cmd;
   input bd_start;
   output bd_bsy;
   output bd_rdy;
   output bd_err;
   input [23:0] bd_addr;
   input [15:0] bd_data_in;
   output [15:0] bd_data_out;
   input bd_rd;
   input bd_wr;
   output bd_iordy;

   ////////////////////////////////////////////////////////////////////////////////
   
   import "DPI-C" function void block_dev_dpi(input integer cmd, 
					  input integer start, 
					  output integer bdy, 
					  output integer rdy, 
					  output integer err, 
					  input integer addr, 
					  input integer data_in, 
					  output integer data_out, 
					  input integer rd, 
					  input integer wr, 
					  output integer iordy);

   integer bsy, rdy, err, iordy, data_out;

   assign bd_bsy = bsy[0];
   assign bd_rdy = rdy[0];
   assign bd_err = err[0];
   assign bd_iordy = iordy[0];
   assign bd_data_out = data_out[15:0];
   
   always @(posedge clk)
     block_dev_dpi({30'b0, bd_cmd}, {31'b0, bd_start}, bsy, rdy, err, {8'b0, bd_addr}, 
		   {16'b0, bd_data_in}, data_out, {31'b0, bd_rd}, {31'b0, bd_wr}, iordy);

endmodule 

`default_nettype wire

// Local Variables:
// verilog-library-directories: (".")
// End:
