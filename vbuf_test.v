// VBUF模块定义
(* blackbox=1 *)
module VBUF (O, I);
    output O;
    input  I;
endmodule

// 测试模块，包含多种VBUF连接情况
module test_vbuf_connections;
    wire net1, net2, net3, net4, net5, net6;
    wire input_sig, output_sig;
    
    // 情况1：直接连接的VBUF链 - vbuf1的输出连接到vbuf2的输入
    VBUF vbuf1 (.I(input_sig), .O(net1));
    VBUF vbuf2 (.I(net1), .O(net2));        // 这个应该被选中
    
    // 情况2：另一个直接连接的VBUF链
    VBUF vbuf3 (.I(net2), .O(net3));        // 这个也应该被选中
    VBUF vbuf4 (.I(net3), .O(output_sig));  // 这个也应该被选中
    
    // 情况3：独立的VBUF，没有连接到其他VBUF
    VBUF vbuf5 (.I(input_sig), .O(net4));   // 这个不应该被选中（输出没连到其他VBUF）
    
    // 情况4：输入没有连接到其他VBUF的输出
    VBUF vbuf6 (.I(net5), .O(net6));        // 这个不应该被选中（输入没连到其他VBUF输出）
    
    // 假设net5来自其他源，不是VBUF的输出
    assign net5 = input_sig;
    
endmodule