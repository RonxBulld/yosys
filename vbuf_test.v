(* blackbox=1 *)
module VBUF (O, I);
    output O;
    input  I;
endmodule

module top(input a, b, c, output o1, o2);
    wire w1, w2, w3, w4;
    
    // VBUF实例1 - 输入连接到模块输入
    VBUF vbuf1(.O(w1), .I(a));
    
    // VBUF实例2 - 输入直接连接到VBUF实例1的输出
    VBUF vbuf2(.O(w2), .I(w1));
    
    // VBUF实例3 - 输入直接连接到VBUF实例2的输出
    VBUF vbuf3(.O(w3), .I(w2));
    
    // VBUF实例4 - 输入连接到另一个信号
    VBUF vbuf4(.O(w4), .I(b));
    
    // VBUF实例5 - 输入直接连接到VBUF实例4的输出
    VBUF vbuf5(.O(o1), .I(w4));
    
    // 非VBUF实例
    assign o2 = w3 & c;
endmodule