module test_module (
    input clk,
    input rst,
    output reg [3:0] counter
);

    // A wire with init attribute
    wire [1:0] state /* synthesis init = "2'b01" */;
    
    // A register with initial value
    reg [3:0] internal_reg = 4'b1010;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 4'b0000;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule