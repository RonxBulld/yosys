// RAML32KX32W Technology Mapping
// Maps from intermediate $__RAML32KX32W_ to actual RAML32KX32W hardware primitive

module $__RAML32KX32W_ (
	// Clock and control signals
	PORT_R_CLK,
	PORT_R_RD_EN,
	
	// Address and data ports
	PORT_R_ADDR,
	PORT_R_RD_DATA,
	
	// Optional initialization and reset values
	PORT_R_RD_INIT_VALUE,
	PORT_R_RD_SRST_VALUE,
	PORT_R_RD_SRST
);

// Parameters passed from memory_libmap
parameter INIT = 0;
parameter PORT_R_RD_INIT_VALUE = 0;
parameter PORT_R_RD_SRST_VALUE = 0;

// Port signals
input PORT_R_CLK;
input PORT_R_RD_EN;
input [14:0] PORT_R_ADDR;  // 15 bits for 32K words
output [31:0] PORT_R_RD_DATA;  // 32 bits wide
input PORT_R_RD_SRST;

// Instantiate the actual RAML32KX32W hardware primitive
RAML32KX32W #(
	.INIT(INIT),
	.INIT_VALUE(PORT_R_RD_INIT_VALUE),
	.RESET_VALUE(PORT_R_RD_SRST_VALUE)
) _TECHMAP_REPLACE_ (
	.CLK(PORT_R_CLK),
	.EN(PORT_R_RD_EN),
	.ADDR(PORT_R_ADDR),
	.DOUT(PORT_R_RD_DATA),
	.SRST(PORT_R_RD_SRST)
);

endmodule