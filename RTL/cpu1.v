//Module: CPU
//Function: CPU is the top design of the processor
//Inputs:
//	clk: main clock
//	arst_n: reset 
// 	enable: Starts the execution
//	addr_ext: Address for reading/writing content to Instruction Memory
//	wen_ext: Write enable for Instruction Memory
// 	ren_ext: Read enable for Instruction Memory
//	wdata_ext: Write word for Instruction Memory
//	addr_ext_2: Address for reading/writing content to Data Memory
//	wen_ext_2: Write enable for Data Memory
// 	ren_ext_2: Read enable for Data Memory
//	wdata_ext_2: Write word for Data Memory
//Outputs:
//	rdata_ext: Read data from Instruction Memory
//	rdata_ext_2: Read data from Data Memory



module cpu1(
		input  wire			  clk,
		input  wire         arst_n,
		input  wire         enable,
		input  wire	[31:0]  addr_ext,
		input  wire         wen_ext,
		input  wire         ren_ext,
		input  wire [31:0]  wdata_ext,
		input  wire	[31:0]  addr_ext_2,
		input  wire         wen_ext_2,
		input  wire         ren_ext_2,
		input  wire [31:0]  wdata_ext_2,
		
		output wire	[31:0]  rdata_ext,
		output wire	[31:0]  rdata_ext_2

   );

wire              zero_flag;
wire [      31:0] branch_pc,updated_pc,current_pc,jump_pc,
                  instruction;
wire [       1:0] alu_op;
wire [       3:0] alu_control;
wire              reg_dst,branch,mem_read,mem_2_reg,
                  mem_write,alu_src, reg_write, jump;
wire [       4:0] regfile_waddr;
wire [      31:0] regfile_wdata, dram_data,alu_out,
                  regfile_data_1,regfile_data_2,
                  alu_operand_2;

wire signed [31:0] immediate_extended;
wire [31:0] instruction_IF_ID;

assign immediate_extended = $signed(instruction_IF_ID[15:0]);

		wire branch_EX_MEM, jump_EX_MEM;
		wire branch_pc_EX_MEM, jump_pc_EX_MEM, zero_flag_EX_MEM; 
pc #(
   .DATA_W(32)
) program_counter (
   .clk       (clk       ),
   .arst_n    (arst_n    ),
   		.branch_pc (branch_pc_EX_MEM ),
   		.jump_pc   (jump_pc_EX_MEM   ),
   		.zero_flag (zero_flag_EX_MEM ),
   		.branch    (branch_EX_MEM    ),
   		.jump      (jump_EX_MEM      ),
   .current_pc(current_pc),
   .enable    (enable    ),
   .updated_pc(updated_pc)
);


sram #(
   .ADDR_W(9 ),
   .DATA_W(32)
) instruction_memory(
   .clk      (clk           ),
   .addr     (current_pc    ),
   .wen      (1'b0          ),
   .ren      (1'b1          ),
   .wdata    (32'b0         ),
   .rdata    (instruction   ),   
   .addr_ext (addr_ext      ),
   .wen_ext  (wen_ext       ), 
   .ren_ext  (ren_ext       ),
   .wdata_ext(wdata_ext     ),
   .rdata_ext(rdata_ext     )
);

reg_arstn_en #(.DATA_W(32)) instruction_pipe_IF_ID_1(
	.clk(clk),
	.arst_n(arst_n),
	.din(instruction),
	.en(enable),
	.dout(instruction_IF_ID)
);

wire [31:0] updated_pc_IF_ID;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_IF_ID_2(
	.clk(clk),
	.arst_n(arst_n),
	.din(updated_pc),
	.en(enable),
	.dout(updated_pc_IF_ID)
);




control_unit control_unit(
   .opcode   (instruction_IF_ID[31:26]),
   .reg_dst  (reg_dst           ),
   .branch   (branch            ),
   .mem_read (mem_read          ),
   .mem_2_reg(mem_2_reg         ),
   .alu_op   (alu_op            ),
   .mem_write(mem_write         ),
   .alu_src  (alu_src           ),
   .reg_write(reg_write         ),
   .jump     (jump              )
);

wire [31:0] instruction_ID_EX;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EX_1(
	.clk(clk),
	.arst_n(arst_n),
	.din(instruction_IF_ID),
	.en(enable),
	.dout(instruction_ID_EX)
);

wire [31:0] immediate_extended_ID_EX;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EX_2(
	.clk(clk),
	.arst_n(arst_n),
	.din(immediate_extended),
	.en(enable),
	.dout(immediate_extended_ID_EX)
);

wire reg_dst_ID_EX;
mux_2 #(
   .DATA_W(5)
) regfile_dest_mux (
   .input_a (instruction_ID_EX[15:11]),
   .input_b (instruction_ID_EX[20:16]),
   .select_a(reg_dst_ID_EX          ),
   .mux_out (regfile_waddr     )
);
wire  reg_write_MEM_WB;
wire [4:0] regfile_waddr_MEM_WB;
register_file #(
   .DATA_W(32)
) register_file(
   .clk      (clk               ),
   .arst_n   (arst_n            ),
   .reg_write(reg_write_MEM_WB         ),
   .raddr_1  (instruction_IF_ID[25:21]),
   .raddr_2  (instruction_IF_ID[20:16]),
   .waddr    (regfile_waddr_MEM_WB     ),
   .wdata    (regfile_wdata     ),
   .rdata_1  (regfile_data_1    ),
   .rdata_2  (regfile_data_2    )
);

wire [31:0] updated_pc_ID_EX;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EX_3(
	.clk(clk),
	.arst_n(arst_n),
	.din(updated_pc_IF_ID),
	.en(enable),
	.dout(updated_pc_ID_EX)
);

wire [31:0] regfile_data_1_ID_EX;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EX_4(
	.clk(clk),
	.arst_n(arst_n),
	.din(regfile_data_1),
	.en(enable),
	.dout(regfile_data_1_ID_EX)
);

wire [31:0] regfile_data_2_ID_EX;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_ID_EX_5(
	.clk(clk),
	.arst_n(arst_n),
	.din(regfile_data_2),
	.en(enable),
	.dout(regfile_data_2_ID_EX)
);

wire mem_read_ID_EX, mem_2_reg_ID_EX, mem_write_ID_EX, alu_src_ID_EX, reg_write_ID_EX;
wire [1:0] alu_op_ID_EX;
reg_arstn_en #(.DATA_W(10)) control_pipe_ID_EX(
	.clk(clk),
	.arst_n(arst_n),
	.din({reg_dst,branch,mem_read,mem_2_reg,alu_op,mem_write,alu_src,reg_write,jump}),
	.en(enable),
	.dout({reg_dst_ID_EX,branch_ID_EX,mem_read_ID_EX,mem_2_reg_ID_EX,alu_op_ID_EX,mem_write_ID_EX,alu_src_ID_EX,reg_write_ID_EX,jump_ID_EX})
);


alu_control alu_ctrl(
   .function_field (instruction_ID_EX[5:0]),
   .alu_op         (alu_op_ID_EX          ),
   .alu_control    (alu_control     )
);

mux_2 #(
   .DATA_W(32)
) alu_operand_mux (
   .input_a (immediate_extended_ID_EX),
   .input_b (regfile_data_2_ID_EX    ),
   .select_a(alu_src_ID_EX           ),
   .mux_out (alu_operand_2     )
);


alu#(
   .DATA_W(32)
) alu(
   .alu_in_0 (regfile_data_1_ID_EX),
   .alu_in_1 (alu_operand_2 ),
   .alu_ctrl (alu_control   ),
   .alu_out  (alu_out       ),
   .shft_amnt(instruction_ID_EX[10:6]),
   .zero_flag(zero_flag     ),
   .overflow (              )
);

wire [31:0] alu_out_EX_MEM;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_EX_MEM_1(
	.clk(clk),
	.arst_n(arst_n),
	.din(alu_out),
	.en(enable),
	.dout(alu_out_EX_MEM)
);

wire [31:0] regfile_data_2_EX_MEM;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_EX_MEM_2(
	.clk(clk),
	.arst_n(arst_n),
	.din(regfile_data_2_ID_EX),
	.en(enable),
	.dout(regfile_data_2_EX_MEM)
);

wire [4:0] regfile_waddr_EX_MEM;
reg_arstn_en #(.DATA_W(5)) instruction_pipe_EX_MEM_3(
	.clk(clk),
	.arst_n(arst_n),
	.din(regfile_waddr),
	.en(enable),
	.dout(regfile_waddr_EX_MEM)
);

		
		reg_arstn_en #(.DATA_W(65)) instruction_pipe_EX_MEM_4(
		.clk(clk),
		.arst_n(arst_n),
		.din({branch_pc, jump_pc, zero_flag}),
		.en(enable),
		.dout({branch_pc_EX_MEM, jump_pc_EX_MEM, zero_flag_EX_MEM})
		);

wire mem_read_EX_MEM, mem_2_reg_EX_MEM, mem_write_EX_MEM, reg_write_EX_MEM; 
			reg_arstn_en #(.DATA_W(6)) control_pipe_EX_MEM(
	.clk(clk),
	.arst_n(arst_n),
			.din({branch_ID_EX, jump_ID_EX, mem_read_ID_EX,mem_2_reg_ID_EX,mem_write_ID_EX,reg_write_ID_EX}),
	.en(enable),
			.dout({branch_EX_MEM, jump_EX_MEM, mem_read_EX_MEM,mem_2_reg_EX_MEM,mem_write_EX_MEM,reg_write_EX_MEM})
);


sram #(
   .ADDR_W(10),
   .DATA_W(32)
) data_memory(
   .clk      (clk           ),
   .addr     (alu_out_EX_MEM       ),
   .wen      (mem_write_EX_MEM     ),
   .ren      (mem_read_EX_MEM      ),
   .wdata    (regfile_data_2_EX_MEM),
   .rdata    (dram_data     ),   
   .addr_ext (addr_ext_2    ),
   .wen_ext  (wen_ext_2     ),
   .ren_ext  (ren_ext_2     ),
   .wdata_ext(wdata_ext_2   ),
   .rdata_ext(rdata_ext_2   )
);

wire [31:0] dram_data_MEM_WB;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_MEM_WB_1(
	.clk(clk),
	.arst_n(arst_n),
	.din(dram_data),
	.en(enable),
	.dout(dram_data_MEM_WB)
);

wire [31:0] alu_out_MEM_WB;
reg_arstn_en #(.DATA_W(32)) instruction_pipe_MEM_WB_2(
	.clk(clk),
	.arst_n(arst_n),
	.din(alu_out_EX_MEM),
	.en(enable),
	.dout(alu_out_MEM_WB)
);


reg_arstn_en #(.DATA_W(5)) instruction_pipe_MEM_WB_3(
	.clk(clk),
	.arst_n(arst_n),
	.din(regfile_waddr_EX_MEM),
	.en(enable),
	.dout(regfile_waddr_MEM_WB)
);

wire mem_2_reg_MEM_WB; 
reg_arstn_en #(.DATA_W(2)) control_pipe_MEM_WB(
	.clk(clk),
	.arst_n(arst_n),
	.din({mem_2_reg_EX_MEM,reg_write_EX_MEM}),
	.en(enable),
	.dout({mem_2_reg_MEM_WB,reg_write_MEM_WB})
);

mux_2 #(
   .DATA_W(32)
) regfile_data_mux (
   .input_a  (dram_data_MEM_WB    ),
   .input_b  (alu_out_MEM_WB      ),
   .select_a (mem_2_reg_MEM_WB     ),
   .mux_out  (regfile_wdata)
);



branch_unit#(
   .DATA_W(32)
)branch_unit(
   .updated_pc   (updated_pc_ID_EX        ),
   .instruction  (instruction_ID_EX       ),
   .branch_offset(immediate_extended_ID_EX),
   .branch_pc    (branch_pc         ),
   .jump_pc      (jump_pc         )
);



endmodule


