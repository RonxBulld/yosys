/*
 *  Generic Memory Usage Examples
 *  
 *  This file demonstrates various configurations of the generic_memory module
 *  for different memory types and use cases.
 */

// Example 1: Simple Single-Port Memory (1R1W)
module single_port_memory_example (
    input wire clk,
    input wire rst,
    input wire rd_en,
    input wire wr_en,
    input wire [9:0] addr,
    input wire [31:0] wr_data,
    input wire [31:0] wr_be,
    output wire [31:0] rd_data
);

generic_memory #(
    .MEMID("sp_memory"),
    .SIZE(1024),
    .ABITS(10),
    .WIDTH(32),
    .RD_PORTS(1),
    .WR_PORTS(1),
    .OPTION_RESET("SYNC")
) sp_mem (
    .RD_CLK(clk),
    .RD_EN(rd_en),
    .RD_ARST(1'b0),
    .RD_SRST(rst),
    .RD_ADDR(addr),
    .RD_DATA(rd_data),
    
    .WR_CLK(clk),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(addr),
    .WR_DATA(wr_data)
);

endmodule

// Example 2: True Dual-Port Memory (2R2W)
module dual_port_memory_example (
    input wire clk_a,
    input wire clk_b,
    input wire rst,
    
    // Port A
    input wire rd_en_a,
    input wire wr_en_a,
    input wire [10:0] addr_a,
    input wire [63:0] wr_data_a,
    input wire [63:0] wr_be_a,
    output wire [63:0] rd_data_a,
    
    // Port B  
    input wire rd_en_b,
    input wire wr_en_b,
    input wire [10:0] addr_b,
    input wire [63:0] wr_data_b,
    input wire [63:0] wr_be_b,
    output wire [63:0] rd_data_b
);

generic_memory #(
    .MEMID("dp_memory"),
    .SIZE(2048),
    .ABITS(11),
    .WIDTH(64),
    .RD_PORTS(2),
    .WR_PORTS(2),
    .RD_TRANSPARENCY(2'b11), // Both ports transparent
    .OPTION_RESET("SYNC")
) dp_mem (
    .RD_CLK({clk_b, clk_a}),
    .RD_EN({rd_en_b, rd_en_a}),
    .RD_ARST(2'b00),
    .RD_SRST({rst, rst}),
    .RD_ADDR({addr_b, addr_a}),
    .RD_DATA({rd_data_b, rd_data_a}),
    
    .WR_CLK({clk_b, clk_a}),
    .WR_EN({wr_en_b, wr_en_a}),
    .WR_BE({wr_be_b, wr_be_a}),
    .WR_ADDR({addr_b, addr_a}),
    .WR_DATA({wr_data_b, wr_data_a})
);

endmodule

// Example 3: Multi-Port Register File (8R4W)
module register_file_example (
    input wire clk,
    input wire rst,
    
    // 8 Read ports (typical for processor register file)
    input wire [7:0] rd_en,
    input wire [39:0] rd_addr,    // 8 ports * 5 bits each (32 registers)
    output wire [255:0] rd_data,  // 8 ports * 32 bits each
    
    // 4 Write ports
    input wire [3:0] wr_en,
    input wire [19:0] wr_addr,    // 4 ports * 5 bits each
    input wire [127:0] wr_data,   // 4 ports * 32 bits each
    input wire [127:0] wr_be      // Byte enables
);

generic_memory #(
    .MEMID("register_file"),
    .SIZE(32),
    .ABITS(5),
    .WIDTH(32),
    .RD_PORTS(8),
    .WR_PORTS(4),
    .RD_TRANSPARENCY(8'b11111111), // All read ports transparent
    .OPTION_RESET("SYNC")
) reg_file (
    .RD_CLK({8{clk}}),
    .RD_EN(rd_en),
    .RD_ARST(8'b0),
    .RD_SRST({8{rst}}),
    .RD_ADDR(rd_addr),
    .RD_DATA(rd_data),
    
    .WR_CLK({4{clk}}),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(wr_addr),
    .WR_DATA(wr_data)
);

endmodule

// Example 4: Cache Line Storage (2R1W, Wide Data)
module cache_line_example (
    input wire clk,
    input wire rst,
    
    // Read ports
    input wire [1:0] rd_en,
    input wire [11:0] rd_addr,    // 2 ports * 6 bits each (64 lines)
    output wire [1023:0] rd_data, // 2 ports * 512 bits each
    
    // Write port (cache line fill)
    input wire wr_en,
    input wire [5:0] wr_addr,
    input wire [511:0] wr_data,
    input wire [511:0] wr_be
);

generic_memory #(
    .MEMID("cache_lines"),
    .SIZE(64),
    .ABITS(6),
    .WIDTH(512),
    .RD_PORTS(2),
    .WR_PORTS(1),
    .RD_TRANSPARENCY(2'b01), // Only port 0 transparent
    .OPTION_RESET("NONE")    // No reset for cache
) cache_mem (
    .RD_CLK({2{clk}}),
    .RD_EN(rd_en),
    .RD_ARST(2'b00),
    .RD_SRST(2'b00),
    .RD_ADDR(rd_addr),
    .RD_DATA(rd_data),
    
    .WR_CLK(clk),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(wr_addr),
    .WR_DATA(wr_data)
);

endmodule

// Example 5: FIFO Buffer with Transparent Read
module fifo_buffer_example (
    input wire clk,
    input wire rst,
    input wire push,
    input wire pop,
    input wire [63:0] push_data,
    output wire [63:0] pop_data,
    output wire empty,
    output wire full
);

// FIFO control logic
reg [7:0] wr_ptr, rd_ptr;
reg [8:0] count;

assign empty = (count == 0);
assign full = (count == 256);

always @(posedge clk) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
        count <= 0;
    end else begin
        if (push && !full) begin
            wr_ptr <= wr_ptr + 1;
            count <= count + 1;
        end
        if (pop && !empty) begin
            rd_ptr <= rd_ptr + 1;
            count <= count - 1;
        end
        if (push && pop && !empty && !full) begin
            // Push and pop simultaneously
            wr_ptr <= wr_ptr + 1;
            rd_ptr <= rd_ptr + 1;
            // count unchanged
        end
    end
end

generic_memory #(
    .MEMID("fifo_buffer"),
    .SIZE(256),
    .ABITS(8),
    .WIDTH(64),
    .RD_PORTS(1),
    .WR_PORTS(1),
    .RD_TRANSPARENCY(1'b1), // Transparent for FIFO operation
    .OPTION_RESET("NONE")
) fifo_mem (
    .RD_CLK(clk),
    .RD_EN(pop && !empty),
    .RD_ARST(1'b0),
    .RD_SRST(1'b0),
    .RD_ADDR(rd_ptr),
    .RD_DATA(pop_data),
    
    .WR_CLK(clk),
    .WR_EN(push && !full),
    .WR_BE({64{1'b1}}), // Write all bits
    .WR_ADDR(wr_ptr),
    .WR_DATA(push_data)
);

endmodule

// Example 6: Asymmetric Multi-Port Memory (4R2W with different clocks)
module asymmetric_multiport_example (
    input wire fast_clk,    // Fast clock for reads
    input wire slow_clk,    // Slow clock for writes
    input wire rst,
    
    // 4 Read ports on fast clock
    input wire [3:0] rd_en,
    input wire [35:0] rd_addr,    // 4 ports * 9 bits each
    output wire [63:0] rd_data,   // 4 ports * 16 bits each
    
    // 2 Write ports on slow clock
    input wire [1:0] wr_en,
    input wire [17:0] wr_addr,    // 2 ports * 9 bits each
    input wire [31:0] wr_data,    // 2 ports * 16 bits each
    input wire [31:0] wr_be
);

generic_memory #(
    .MEMID("asymmetric_mem"),
    .SIZE(512),
    .ABITS(9),
    .WIDTH(16),
    .RD_PORTS(4),
    .WR_PORTS(2),
    .RD_CLK_ENABLE(4'b1111),      // All read ports clocked
    .RD_CLK_POLARITY(4'b1111),    // All positive edge
    .WR_CLK_ENABLE(2'b11),        // Both write ports clocked
    .WR_CLK_POLARITY(2'b11),      // Both positive edge
    .RD_TRANSPARENCY(4'b0000),    // No transparency due to different clocks
    .OPTION_RESET("SYNC")
) asym_mem (
    .RD_CLK({4{fast_clk}}),
    .RD_EN(rd_en),
    .RD_ARST(4'b0000),
    .RD_SRST({4{rst}}),
    .RD_ADDR(rd_addr),
    .RD_DATA(rd_data),
    
    .WR_CLK({2{slow_clk}}),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(wr_addr),
    .WR_DATA(wr_data)
);

endmodule

// Example 7: Memory with Asynchronous Reset
module async_reset_memory_example (
    input wire clk,
    input wire arst,    // Asynchronous reset
    input wire rd_en,
    input wire wr_en,
    input wire [7:0] addr,
    input wire [31:0] wr_data,
    input wire [31:0] wr_be,
    output wire [31:0] rd_data
);

generic_memory #(
    .MEMID("async_reset_mem"),
    .SIZE(256),
    .ABITS(8),
    .WIDTH(32),
    .RD_PORTS(1),
    .WR_PORTS(1),
    .RD_ARST_VALUE(32'hDEADBEEF), // Reset value for read data
    .OPTION_RESET("ASYNC")
) arst_mem (
    .RD_CLK(clk),
    .RD_EN(rd_en),
    .RD_ARST(arst),
    .RD_SRST(1'b0),
    .RD_ADDR(addr),
    .RD_DATA(rd_data),
    
    .WR_CLK(clk),
    .WR_EN(wr_en),
    .WR_BE(wr_be),
    .WR_ADDR(addr),
    .WR_DATA(wr_data)
);

endmodule

// Example 8: ROM (Read-Only Memory) using 0 write ports
module rom_example (
    input wire clk,
    input wire rd_en,
    input wire [9:0] addr,
    output wire [31:0] rd_data
);

// Pre-initialize memory with content
localparam [32*1024-1:0] ROM_INIT = {
    // Initialize with some pattern - in practice this would be
    // loaded from a file or generated
    32'h12345678, 32'h9ABCDEF0, 32'hFEDCBA98, 32'h76543210,
    // ... repeat for all 1024 words
    {1020{32'h00000000}}
};

generic_memory #(
    .MEMID("rom_memory"),
    .SIZE(1024),
    .ABITS(10),
    .WIDTH(32),
    .RD_PORTS(1),
    .WR_PORTS(0),           // No write ports = ROM
    .INIT(ROM_INIT),
    .OPTION_RESET("NONE")
) rom_inst (
    .RD_CLK(clk),
    .RD_EN(rd_en),
    .RD_ARST(1'b0),
    .RD_SRST(1'b0),
    .RD_ADDR(addr),
    .RD_DATA(rd_data),
    
    // No write port connections needed
    .WR_CLK(),
    .WR_EN(),
    .WR_BE(),
    .WR_ADDR(),
    .WR_DATA()
);

endmodule