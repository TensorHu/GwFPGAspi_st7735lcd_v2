//----------------------------------------------------------------------------------------
// File name: lcd_init
// Descriptions: st7735-SPI-LCD的初始化(控制)数据组织提供模块
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module lcd_init
#(//驱动lcd时根据硬件由调用模块修改
    parameter   TIME20MS    = 23'd1000_000,   //50MHz~-->20ms(50Hz) 适配7735 
                TIME40MS    = 23'd2000_000,   //-->40ms=20ms+20ms（前两延迟状态是连续计数的）
                TIME5MS     = 23'd250_000,    //-->5ms （第三次延迟）适配7735
                HEIGHT      =  8'd134,        //由于下方已用表达式，故此处不能再用如128-1这种表达式
                WIDTH       =  8'd239         //已留余量1
    // 仿真用
    // parameter   TIME20MS    = 23'd1_000,        //50MHz~-->20ms(50Hz) 
    //             TIME40MS    = 23'd2_000,        //-->40ms=20ms+20ms（前两延迟状态是连续计数的）
    //             TIME5MS     = 23'd2_0,         //-->5ms （第三次延迟）
    //             HEIGHT      =  8'd31,        //由于下方已用表达式，故此处不能再用如128-1这种表达式
    //             WIDTH       =  8'd13         //已留余量1
)
(
    input   wire            sys_clk ,
    input   wire            sys_rst_n     ,
    input   wire            wr_done       ,
    
    
    output  reg             lcd_rst       ,
    output  reg     [8:0]   init_data     ,
    output  wire            en_write      ,
    output  wire            init_done
);
//****************** Parameter and Internal Signal *******************//
//画笔颜色
localparam  BLUE          = 16'h001F,
            GREEN         = 16'h07E0,	  
            RED           = 16'hF800,  
            CYAN          = 16'h07FF,
            MAGENTA       = 16'hF81F,
            YELLOW        = 16'hFFE0,
            LIGHTBLUE     = 16'h841F,
            LIGHTGREEN    = 16'h87F0,
            LIGHTRED      = 16'hFC10,
            LIGHTCYAN     = 16'h87FF,
            LIGHTMAGENTA  = 16'hFC1F, 
            LIGHTYELLOW   = 16'hFFF0, 
            DARKBLUE      = 16'h0010, 
            DARKGREEN     = 16'h0400,
            DARKRED       = 16'h8000,
            DARKCYAN      = 16'h0410,
            DARKMAGENTA   = 16'h8010,
            DARKYELLOW    = 16'h8400,
            WHITE         = 16'hFFFF, //白色
            LIGHTGRAY     = 16'hD69A, //灰色
            GRAY          = 16'h8410,
            DARKGRAY      = 16'h4208,
            BLACK         = 16'h0000, //黑色
            BROWN         = 16'hA145,
            ORANGE        = 16'hFD20;

localparam  CLRSCR1  = 16'h0A1E;  
localparam  CLRSCR2  = 16'h1536;  

//----------------------------------------------------------------- 
reg [6:0]   state;
localparam  S0_DELAY_0       = 7'b0000_001,  
            S1_DELAY_1       = 7'b0000_010,
            S2_WR_0X11       = 7'b0000_100,
            S3_DELAY_3       = 7'b0001_000,
            S4_WR_INITC      = 7'b0010_000,
            S5_WR_FULLSCR    = 7'b0100_000,
            DONE             = 7'b1000_000;
            
reg [22:0]  cnt_150ms;
reg         lcd_rst_high_flag; //复位起始时刻的标识（单clk宽度），与lcd_rst关系见后面代码
reg [6:0]   cnt_s4_num;        //初始化代码计数器，不超过128个，否则改bit宽度
reg         cnt_s4_num_done; 
localparam  CNT_S4_MAX =7'd87; //初始化代码实际才87个（0--86），多备1个--反正DATA_IDLE填充即可
reg [17:0]  cnt_s5_num;
reg         cnt_s5_num_done;  
localparam  S5NUMMAX  = 240*2*135+11 ;//(WIDTH+1)*(HEIGHT+1)*2+11;  //清屏全部代码数目:W*H*2像点颜色+13设置窗口大小占的代码+备点色 
localparam  S5NUMHALF = 240*2*35+11 ;//(WIDTH+1)*(HEIGHT+1)*0.5+11; 
localparam  DATA_IDLE = 9'b1_0000_0000;
//----------------------------------------------------------------- 
//状态跳转（状态下要做的操作在其他段落）            
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        state <= S0_DELAY_0;
    else
        case(state)
            S0_DELAY_0:
                state <= (cnt_150ms == TIME20MS) ? S1_DELAY_1 : S0_DELAY_0; //1#拉低Rst后延迟满则转移到下一状态
            S1_DELAY_1:
                state <= (cnt_150ms == TIME40MS) ? S2_WR_0X11 : S1_DELAY_1; //2#拉高Rst后延迟满则转移到下一状态
            S2_WR_0X11:
                state <= (wr_done) ? S3_DELAY_3 : S2_WR_0X11;               //3#首位初始化数据传送完成则转移到下一状态
            S3_DELAY_3:
                state <= (cnt_150ms == TIME5MS) ? S4_WR_INITC : S3_DELAY_3; //4#20ms延迟到则转移到初始化数据传送状态
            S4_WR_INITC:
                state <= (cnt_s4_num_done) ? S5_WR_FULLSCR : S4_WR_INITC;   //5#硬件初始化数据传送完成则转移到清屏状态
            S5_WR_FULLSCR:
                state <= (cnt_s5_num_done) ? DONE : S5_WR_FULLSCR;          //6#清屏数据传送完成则转移到下一（结束）状态
            DONE:
                state <= DONE;
            default:
                state <= S0_DELAY_0;
        endcase

//cnt_150ms  毫秒级多延迟状态用的计数器
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_150ms <= 23'd0;
    else if(state == S0_DELAY_0 || state == S1_DELAY_1 || state == S3_DELAY_3 )
        cnt_150ms <= cnt_150ms + 1'b1;
    else
        cnt_150ms <= 23'd0;
        
//lcd_rst_high_flag 标识lcd_rst开始时刻
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        lcd_rst_high_flag <= 1'b0;
    else if(state == S0_DELAY_0 && (cnt_150ms == TIME20MS - 1'b1))  //确保开机拉低足够时长
        lcd_rst_high_flag <= 1'b1;                                  //拉低足够时长后拉高
    else
        lcd_rst_high_flag <= 1'b0;

//lcd_rst 给lcd硬件的rst信号
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        lcd_rst <= 1'b0;
    else if(lcd_rst_high_flag)  //确保是拉低足够时长后拉高
        lcd_rst <= 1'b1;
    else
        lcd_rst <= lcd_rst;     //然后一直保持高
//----------------------------------------------------------------- 
//cnt_s4_num决定要传的命令/数据
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_s4_num <= 7'd0;
    else if(state != S4_WR_INITC)
        cnt_s4_num <= 7'd0;
    else if(wr_done && state == S4_WR_INITC)  //传送初始化数据状态下，wr_done表示当前byte传送完成，准备传下一个
        cnt_s4_num <= cnt_s4_num + 1'b1;      //数据指针+1
    else
        cnt_s4_num <= cnt_s4_num;

//cnt_s4_num_done == 1'b1则S2_WR_90完成
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_s4_num_done <= 1'b0;
    else if(cnt_s4_num == CNT_S4_MAX && wr_done == 1'b1) //传送初始化数据状态下，取得标识--要求的初始化代码传送全部完成
        cnt_s4_num_done <= 1'b1;
    else
        cnt_s4_num_done <= 1'b0;
        
//init_data[8:0]
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)               init_data <= DATA_IDLE;
    else if(state == S2_WR_0X11) init_data <= 9'h0_11 ; 
    else if(state == S4_WR_INITC)
        case(cnt_s4_num)
        7'd0  : init_data <= 9'h0_36; // Memory Data Access Control
        7'd1  : init_data <= 9'h1_70; // 方向参数，0x00横屏，0x60竖屏，按实际需求
        7'd2  : init_data <= 9'h0_3A; // Interface Pixel Format
        7'd3  : init_data <= 9'h1_05; // 16bit/pixel
        7'd4  : init_data <= 9'h0_B2; // Porch Setting
        7'd5  : init_data <= 9'h1_0C;
        7'd6  : init_data <= 9'h1_0C;
        7'd7  : init_data <= 9'h1_00;
        7'd8  : init_data <= 9'h1_33;
        7'd9  : init_data <= 9'h1_33;
        7'd10 : init_data <= 9'h0_B7; // Gate Control
        7'd11 : init_data <= 9'h1_35;
        7'd12 : init_data <= 9'h0_BB; // VCOM Setting
        7'd13 : init_data <= 9'h1_19;
        7'd14 : init_data <= 9'h0_C0; // LCM Control
        7'd15 : init_data <= 9'h1_2C;
        7'd16 : init_data <= 9'h0_C2; // VDV and VRH Command Enable
        7'd17 : init_data <= 9'h1_01;
        7'd18 : init_data <= 9'h0_C3; // VRH Set
        7'd19 : init_data <= 9'h1_12;
        7'd20 : init_data <= 9'h0_C4; // VDV Set
        7'd21 : init_data <= 9'h1_20;
        7'd22 : init_data <= 9'h0_C6; // Frame Rate Control
        7'd23 : init_data <= 9'h1_0F;
        7'd24 : init_data <= 9'h0_D0; // Power Control 1
        7'd25 : init_data <= 9'h1_A4;
        7'd26 : init_data <= 9'h1_A1;
        // Gamma
        7'd27 : init_data <= 9'h0_E0;
        7'd28 : init_data <= 9'h1_D0;
        7'd29 : init_data <= 9'h1_04;
        7'd30 : init_data <= 9'h1_0D;
        7'd31 : init_data <= 9'h1_11;
        7'd32 : init_data <= 9'h1_13;
        7'd33 : init_data <= 9'h1_2B;
        7'd34 : init_data <= 9'h1_3F;
        7'd35 : init_data <= 9'h1_54;
        7'd36 : init_data <= 9'h1_4C;
        7'd37 : init_data <= 9'h1_18;
        7'd38 : init_data <= 9'h1_0D;
        7'd39 : init_data <= 9'h1_0B;
        7'd40 : init_data <= 9'h1_1F;
        7'd41 : init_data <= 9'h1_23;
        7'd42 : init_data <= 9'h0_E1;
        7'd43 : init_data <= 9'h1_D0;
        7'd44 : init_data <= 9'h1_04;
        7'd45 : init_data <= 9'h1_0C;
        7'd46 : init_data <= 9'h1_11;
        7'd47 : init_data <= 9'h1_13;
        7'd48 : init_data <= 9'h1_2C;
        7'd49 : init_data <= 9'h1_3F;
        7'd50 : init_data <= 9'h1_44;
        7'd51 : init_data <= 9'h1_51;
        7'd52 : init_data <= 9'h1_2F;
        7'd53 : init_data <= 9'h1_1F;
        7'd54 : init_data <= 9'h1_1F;
        7'd55 : init_data <= 9'h1_20;
        7'd56 : init_data <= 9'h1_23;
        7'd57 : init_data <= 9'h0_21; 
        7'd58 : init_data <= 9'h0_29; 

        default:  init_data <= DATA_IDLE;
        //init_data是在S4_WR_INITC状态下，随着cnt_s4_num变化的
        //所以FPGA时钟是高频率，但data变化节拍是看cnt_s4_num的节拍
        //而cnt_s4_num的节拍又是每个wr_done时加一，
        //所以data的节拍本质是与byte数据传送完对齐的。
            endcase
        
      else if(state == S5_WR_FULLSCR)
          case(cnt_s5_num)
            'd0 :  init_data <= 9'h0_2a;   // Display on (repeat)
            // //设置LCD显示方向
            // 'd1 :  init_data <= 9'h0_36;
            // 'd2 :  init_data <= 9'h1_C0;
            
            //LCD显示窗口设置
            'd1 :  init_data <= 9'h0_2a;
                             
            'd2 :  init_data <= 9'h1_00;
            'd3 :  init_data <= 9'h1_28;
            'd4 :  init_data <= 9'h1_01;
            'd5 :  init_data <= 9'h1_17; //{1'b1,HEIGHT};
                             
            'd6 :  init_data <= 9'h0_2b;
                             
            'd7 :  init_data <= 9'h1_00;
            'd8:  init_data <= 9'h1_35;
            'd9:  init_data <= 9'h1_00;
            'd10:  init_data <= 9'h1_BB; //{1'b1,WIDTH};

            //填充对应点的颜色                             
            'd11:  init_data <= 9'h0_2c;
          default : 
                //当cnt_s5_num大于14且为偶数时，传输颜色数据的高8位
                   if(cnt_s5_num >= 'd10 && cnt_s5_num[0] == 0) begin
                     if(cnt_s5_num >= S5NUMHALF ) init_data <= {1'b1,CLRSCR2[15:8]};
                     else init_data <= {1'b1,CLRSCR1[15:8]};
                   end
                //当cnt_s5_num大于14且为奇数时，传输颜色数据的低8位
                   else begin
                     if(cnt_s5_num >= 'd10 && cnt_s5_num[0] == 1) begin
                          if(cnt_s5_num >= S5NUMHALF ) init_data <= {1'b1,CLRSCR2[ 7:0]};
                          else init_data <= {1'b1,CLRSCR1[ 7:0]};
                     end
                     else  init_data <= DATA_IDLE;
                   end
           endcase
       else  init_data <= DATA_IDLE;

//cnt_s5_num决定清屏时要传的命令/数据
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_s5_num <= 18'd0;
    else if(state != S5_WR_FULLSCR)
        cnt_s5_num <= 18'd0;
    else if(wr_done && state == S5_WR_FULLSCR)
        cnt_s5_num <= cnt_s5_num + 1'b1;
    else                   
        cnt_s5_num <= cnt_s5_num;

//cnt_s5_num_done
always@(posedge sys_clk or negedge sys_rst_n)
    if(!sys_rst_n)
        cnt_s5_num_done <= 1'b0;
    else if(cnt_s5_num == S5NUMMAX && wr_done == 1'b1)
        cnt_s5_num_done <= 1'b1;
    else
        cnt_s5_num_done <= 1'b0;  

assign init_done = state == DONE ? 1'b1 : 1'b0; //初始化完成标志        
assign en_write = (  state == S2_WR_0X11 || state == S4_WR_INITC ||
                    (state == S5_WR_FULLSCR&&( cnt_s5_num < S5NUMMAX))) ? 1'b1 : 1'b0;  

endmodule