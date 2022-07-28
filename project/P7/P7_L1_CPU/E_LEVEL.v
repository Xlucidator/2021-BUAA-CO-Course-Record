`timescale 1ns / 1ps
`include "const.v"

module E_LEVEL(
    input Clk,
    input Rst,
	 input Reg_Rst,
    input We,
	 input Req,
	 input BD_in,
    input [31:0] IR_in,
    input [31:0] PC_in,
    input [31:0] RD1_in,
    input [31:0] RD2_in,
    input [31:0] EXT_in,
	 input [4:0] ExcCode_in,
	 input [1:0] ACmpB_in,
	 input [1:0] ACmp0_in,
	 
    input [4:0] M_RFA3_in,
	 input [31:0] M_RFWD_in,
	 input M_RFWr_in,
	 input M_Forward_Ready_in,
	 input [4:0] W_RFA3_in,
	 input [31:0] W_RFWD_in,
	 input W_RFWr_in,
	 input W_Forward_Ready_in,
	 
	 output BD_out,
    output [31:0] IR_out,
    output [31:0] PC_out,
    output [31:0] Y_out,
    output [31:0] V2_out,
	 output [4:0] ExcCode_out,
	 output [1:0] ACmpB_out,
	 output [1:0] ACmp0_out,
	 output [31:0] HILO_out,
	 output Busy_out,
	 
	 output [4:0] E_RFA3_out,
	 output [31:0] E_RFWD_out,
	 output E_RFWr_out,
	 output E_Forward_Ready_out
    );
	
	wire [31:0] V1_out,V2_out0;
	wire [31:0] EXT_out;
	wire [4:0] ExcCode_former;
	E_REG E_REG (
    .Clk(Clk), 
    .Rst(Rst), 
	 .Stall(Reg_Rst), //Ϊ�˲���Stall�źŶ�ʧ����Reg_Rst�����������
    .We(We), 
    .Req(Req),
	 
	 .BD_in(BD_in),
	 .IR_in(IR_in), 
    .PC_in(PC_in), 
    .EXT_in(EXT_in), 
    .V1_in(RD1_in), 
    .V2_in(RD2_in),
	 .ExcCode_in(ExcCode_in),
	 .ACmpB_in(ACmpB_in), 
    .ACmp0_in(ACmp0_in), 
	 
	 //output
	 .BD_out(BD_out),
    .IR_out(IR_out), 
    .PC_out(PC_out), 
    .EXT_out(EXT_out), 
    .V1_out(V1_out), 
    .V2_out(V2_out0), //����V2_out������ֱ����ΪE���������Ҫ��ת���������
	 .ExcCode_out(ExcCode_former),
	 .ACmpB_out(ACmpB_out),
	 .ACmp0_out(ACmp0_out)
    );

	wire [3:0] ALUOp,HILOOp;
	wire [1:0] ALUASel,ALUBSel,EYSel;
	wire [1:0] GRFA3Sel,GRFWDSel;//������д�����ź�
	wire j_link; //������ǰָ�����ͣ����ж��Ƿ��Բ������ݿ���ת��
	CU E_CU (
	 .instr(IR_out),
    .op(IR_out[31:26]), 
    .funct(IR_out[5:0]), 
	 .rs_op(IR_out[25:21]),
    .rt_op(IR_out[20:16]),  
	 .ACmpB(ACmpB_out), 
    .ACmp0(ACmp0_out), 
	 //output
    .ALUOp(ALUOp),
	 .ALUASel(ALUASel),
    .ALUBSel(ALUBSel),
	 .HILOOp(HILOOp),
	 .EYSel(EYSel),
	 
	 .RFWr(E_RFWr_out), 
    .GRFA3Sel(GRFA3Sel), 
    .GRFWDSel(GRFWDSel),
	 //ָ����
	 .j_link(j_link)
    );
	
	assign E_RFA3_out = (GRFA3Sel == `GRFA3_rt) ? IR_out[20:16] :
							  (GRFA3Sel == `GRFA3_rd) ? IR_out[15:11] :
						     (GRFA3Sel == `GRFA3_31) ? 5'd31 :
							  (GRFA3Sel == `GRFA3_00) ? 5'd0  :
							   IR_out[20:16];
	assign E_RFWD_out = (GRFWDSel == `GRFWD_pc8) ? PC_out + 8 : 
								0 ;
	assign E_Forward_Ready_out = j_link ;
	 
	
 	wire [31:0] ALU_A, ALU_B;
	wire [31:0] FWD_RS, FWD_RT;
	assign FWD_RS = (IR_out[25:21] == 0) ? 0 :
						 (IR_out[25:21] == M_RFA3_in && M_RFWr_in && M_Forward_Ready_in) ? M_RFWD_in :
						 (IR_out[25:21] == W_RFA3_in && W_RFWr_in && W_Forward_Ready_in) ? W_RFWD_in :
							V1_out ;
	assign FWD_RT = (IR_out[20:16] == 0) ? 0 :
						 (IR_out[20:16] == M_RFA3_in && M_RFWr_in && M_Forward_Ready_in) ? M_RFWD_in :
						 (IR_out[20:16] == W_RFA3_in && W_RFWr_in && W_Forward_Ready_in) ? W_RFWD_in :
							V2_out0 ;
	assign ALU_A = (ALUASel == `ALUA_rd1)  ? FWD_RS			:  //����Ҫ����4:0 ���᲻����û���ǵ��ĵط�
						(ALUASel == `ALUA_shamt)? IR_out[10:6] : 0 ;
	assign ALU_B = (ALUBSel == `ALUB_rd2)  ? FWD_RT 		:
						(ALUBSel == `ALUB_imm)  ? EXT_out	 	: 0 ;
						
	assign V2_out = FWD_RT; //ת����������ȷ�����ݲ��ܴ�����һ��

	wire [31:0] ALU_out;
	E_ALU ALU (
    .A(ALU_A), 
    .B(ALU_B), 
    .ALUOp(ALUOp),	 
	 //output
	 .ExcOv(ExcOv),
    .Y(ALU_out)
    );
	
	assign ExcCode_out = (ExcCode_former == `Exc_Null && ExcOv) ? `Exc_Ov : ExcCode_former;
	 
	E_HILO HILO (
    .Clk(Clk), 
    .Rst(Rst), 
	 .Req(Req),
    .HILOOp(HILOOp), 
    .D1(FWD_RS), 
    .D2(FWD_RT),
	 //output
    .IsBusy(Busy_out), 
    .Out(HILO_out)
    );
	 
	 assign Y_out = (EYSel == `EY_alu) ? ALU_out  :
						 (EYSel == `EY_hilo)? HILO_out : 
						  ALU_out ;

endmodule