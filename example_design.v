// Example design with $memwr_v2 instances that will be mapped to RAML32KX32W
module top (
    input wire clk,
    input wire rst,
    input wire [14:0] addr,
    input wire [31:0] data_in,
    input wire write_en,
    output reg [31:0] data_out
);

// Memory array for demonstration
reg [31:0] memory [0:32767]; // 32K words x 32 bits

// Initialize memory
initial begin
    integer i;
    for (i = 0; i < 32768; i = i + 1) begin
        memory[i] = 32'h0;
    end
end

// Memory write operation using $memwr_v2-like behavior
always @(posedge clk) begin
    if (rst) begin
        data_out <= 32'h0;
    end else begin
        // Read operation
        data_out <= memory[addr];
        
        // Write operation
        if (write_en) begin
            memory[addr] <= data_in;
        end
    end
end

endmodule