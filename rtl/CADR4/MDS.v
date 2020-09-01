// MDS --- MEMORY DATA SELECTOR
//
// ---!!! Add description.
//
// History:
//
//   (20YY-MM-DD HH:mm:ss BRAD) Converted to Verilog.
//	???: Nets added.
//	???: Nets removed.
//   (1978-08-16 05:19:21 TK) Initial.

`timescale 1ns/1ps
`default_nettype none

module MDS(/*AUTOARG*/
   // Outputs
   mds,
   // Inputs
   busint_bus, md, ob, loadmd, mdsel, memdrive
   );

   input [31:0] busint_bus;
   input [31:0] md;
   input [31:0] ob;
   input loadmd;
   input mdsel;
   input memdrive;
   output [31:0] mds;

   ////////////////////////////////////////////////////////////////////////////////

   wire [31:0] mem;

   ////////////////////////////////////////////////////////////////////////////////

   assign mds = mdsel ? ob : mem;
   assign mem = memdrive ? md :
		loadmd ? busint_bus :
		32'b0;

endmodule

`default_nettype wire

// Local Variables:
// verilog-library-directories: ("..")
// End:
