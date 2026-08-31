// ALU OPs --------------------------------------------------------------
`define ALU_NOT  3'b000
`define ALU_AND  3'b001
`define ALU_ORA  3'b010
`define ALU_ADD  3'b011
`define ALU_SUB  3'b100
`define ALU_XOR  3'b101
`define ALU_INC  3'b110

// ISA --------------------------------------------------------------
//-- R level
`define MVR 4'b0000            // Move Register
`define LDB 4'b0001            // Load Byte into Regsiter
`define STB 4'b0010            // Store Byte from Regsiter
`define RDS 4'b0011            // Read (store) processor status
// 1'b0100 NOP
// 1'b0101 NOP
// 1'b0110 NOP
// 1'b0111 NOP

//-- Arithmatics
`define NOT {1'b1, `ALU_NOT}
`define AND {1'b1, `ALU_AND}
`define ORA {1'b1, `ALU_ORA}
`define ADD {1'b1, `ALU_ADD}
`define SUB {1'b1, `ALU_SUB}
`define XOR {1'b1, `ALU_XOR}
`define INC {1'b1, `ALU_INC}
// 1'b1111 NOP

// --------------------------------------------------------------------
//
//---------------------------------------------------------------------

`default_nettype none

module tt_um_8bit_cpu (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    assign uio_oe  = 0;
    assign uio_out = 0;

    reg [7:0] data_out;
    assign uo_out = data_out;

    wire rst = !rst_n;

    wire [3:0] inst = ui_in[7:4];         // instuction op code
    wire [3:0] r1 = ui_in[3:0];           // R instruction R1
    wire [3:0] r2 = uio_in[7:4];          // R instruction R2
    wire [3:0] r3 = uio_in[3:0];          // R instruction R3
    wire [7:0] in_data = uio_in[7:0];     // LD instruction 8-bit data

    reg processor_stat;             // For now just ALU carry

    reg [7:0] alu_in1;
    reg [7:0] alu_in2;
    reg [2:0] alu_op;
    reg [7:0] alu_out;
    reg alu_c;

    alu ALU1(
	   .in1(alu_in1),
	   .in2(alu_in2),
	   .op(alu_op),
	   .out(alu_out),
	   .c(alu_c)
	);

    reg write;
    reg [3:0] r_reg1;
    reg [3:0] r_reg2;
    reg [3:0] w_reg;
    reg [7:0] w_data;
    reg [7:0] r_d1;
    reg [7:0] r_d2;

    reg_file RF1(
        .clk(clk),
        .rst(rst),
        .write(write),
        .w_reg(w_reg),
        .w_d (w_data),
        .r_reg1(r_reg1),
        .r_reg2(r_reg2),
        .r_d1(r_d1),
        .r_d2(r_d2)
    );


    reg mux_new_data_out;
    reg mux_processor_stat_data_out;

    reg mux_new_processor_stat;

    always @(*) begin
        case(inst)
            `MVR: begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 0;
                r_reg1 = r1;
                r_reg2 = 4'bxxxx;
                w_reg = r2;
                w_data = r_d1;
                write = 1'b1;
                alu_in1 = 8'hxx;
                alu_in2 = 8'hxx;
                alu_op = 3'bxxx;
            end
            `LDB: begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 0;
                alu_in1 = 8'hxx;
                alu_in2 = 8'hxx;
                alu_op = 3'bxxx;
                r_reg1 = 4'bxxxx;
                r_reg2 = 4'bxxxx;
                w_reg = r1;
                w_data = in_data;
                write = 1'b1;
            end
            `STB:  begin
                mux_new_data_out = 1;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 0;
                r_reg1 = r1;
                r_reg2 = 4'bxxxx;
                w_reg = 4'bxxxx;
                w_data = 8'hxx;
                write = 1'b0;
                alu_in1 = 8'hxx;
                alu_in2 = 8'hxx;
                alu_op = 3'bxxx;
            end
            `RDS:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 1;
                mux_new_processor_stat = 0;
                r_reg1 = 4'bxxxx;
                r_reg2 = 4'bxxxx;
                w_reg = 4'bxxxx;
                w_data = 8'hxx;
                write = 1'b0;
                alu_in1 = 8'hxx;
                alu_in2 = 8'hxx;
                alu_op = 3'bxxx;
            end
            `NOT:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                alu_in1 = r_d1;
                alu_in2 = 8'hxx;
                alu_op = `ALU_NOT;
                r_reg1 = r1;
                r_reg2 = 4'bxxxx;
                w_reg = r2;
                w_data = alu_out;
                write = 1'b1;
            end
            `AND:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r2;
                r_reg2 = r3;
                w_reg = r1;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = r_d2;
                alu_op = `ALU_AND;
            end
            `ORA:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r1;
                r_reg2 = r2;
                w_reg = r3;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = r_d2;
                alu_op = `ALU_ORA;
            end
            `ADD:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r2;
                r_reg2 = r3;
                w_reg = r1;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = r_d2;
                alu_op = `ALU_ADD;
            end
            `SUB:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r2;
                r_reg2 = r3;
                w_reg = r1;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = r_d2;
                alu_op = `ALU_SUB;
            end
            `XOR:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r2;
                r_reg2 = r3;
                w_reg = r1;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = r_d2;
                alu_op = `ALU_XOR;
            end
            `INC:  begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 1;
                r_reg1 = r2;
                r_reg2 = 4'bxxxx;
                w_reg = r1;
                w_data = alu_out;
                write = 1'b1;
                alu_in1 = r_d1;
                alu_in2 = 8'hxx;
                alu_op = `ALU_INC;
            end
            default: begin
                mux_new_data_out = 0;
                mux_processor_stat_data_out = 0;
                mux_new_processor_stat = 0;
                r_reg1 = 4'bxxxx;
                r_reg2 = 4'bxxxx;
                w_reg = 4'bxxxx;
                w_data = 8'hxx;
                write = 1'b0;
                alu_in1 = 8'hxx;
                alu_in2 = 8'hxx;
                alu_op = 3'bxxx;
            end
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 8'b0000_0000;
            processor_stat <= 1'b0;
        end
        else begin
            if (mux_new_processor_stat) begin
                processor_stat <= alu_c;
                data_out <= data_out;
            end
            else if (mux_processor_stat_data_out) begin
                data_out <= {7'b0000000, processor_stat};
                processor_stat <= processor_stat;
            end
            else if (mux_new_data_out) begin
                data_out <= r_d1;
                processor_stat <= processor_stat;
            end
            else begin
                data_out <= data_out;
                processor_stat <= processor_stat;
            end
        end
    end

endmodule

// register file --------------------------------------------------------------
module reg_file #(
    parameter BIT_WIDTH_REG = 8,
    parameter REG_COUNT = 14,
    parameter LOG_REG_COUNT = 4
)(
    input                               clk,
    input                               rst,
    input                               write,
    input       [LOG_REG_COUNT-1:0]     w_reg,
    input       [BIT_WIDTH_REG-1:0]     w_d,
    input       [LOG_REG_COUNT-1:0]     r_reg1,
    input       [LOG_REG_COUNT-1:0]     r_reg2,
    output reg  [BIT_WIDTH_REG-1:0]     r_d1,
    output reg  [BIT_WIDTH_REG-1:0]     r_d2
);

    reg [BIT_WIDTH_REG-1:0] reg_data [0:REG_COUNT-1];

    assign r_d1 = reg_data[r_reg1];
    assign r_d2 = reg_data[r_reg2];

    always @(posedge clk or posedge rst) begin
    if(rst) begin
        integer i;
        for(i = 0; i < REG_COUNT; i = i + 1) begin
        reg_data[i] <= {BIT_WIDTH_REG{1'b0}};
        end
    end
        else if(write) begin
            reg_data[w_reg] <= w_d;
        end
    end

    endmodule

// ALU --------------------------------------------------------------
module alu #(
    parameter BIT_WIDTH_REG = 8
)(
   input 		[BIT_WIDTH_REG-1:0]	in1,
   input 		[BIT_WIDTH_REG-1:0]	in2,
   input 		[2:0]	            op,
   output reg   [BIT_WIDTH_REG-1:0]	out,
   output reg   c
);

    reg [BIT_WIDTH_REG:0] temp;

    always @(*)
        case(op)
            `ALU_NOT: begin
                    out = ~in1;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
                    end
            `ALU_AND: begin
                    out = in1 & in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
                    end
            `ALU_ORA: begin
                    out = in1 | in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
                    end
            `ALU_ADD: begin
                    temp = {1'b0, in1} + {1'b0, in2};
                    out = temp[BIT_WIDTH_REG-1:0];
                    c = temp[BIT_WIDTH_REG];
                    end
            `ALU_SUB: begin
                    out = in1 - in2;
                    c = in1 < in2;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
                    end
            `ALU_XOR: begin
                    out = in1 ^ in2;
                    c = 1'b0;
                    temp = {BIT_WIDTH_REG+1{1'bx}};
                    end
            `ALU_INC: begin
                    out = in1 + 1;
                    c = in1[7] & ~out[7];
                    temp = {BIT_WIDTH_REG+1{1'bx}};
            end
            default: begin
                        out={BIT_WIDTH_REG{1'b0}};
                        c = 1'b0;
                        temp = {BIT_WIDTH_REG+1{1'bx}};
                        end
        endcase

endmodule
