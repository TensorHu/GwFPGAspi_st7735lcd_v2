//----------------------------------------------------------------------------------------
// File name: show_string_number_ctrl
// Descriptions: 控制展示内容的高层模块
//----------------------------------------------------------------------------------------
//****************************************************************************************//
/*
在屏幕上显示字符串
第一行中间显示“pxm hust”共8个字符；
第二行为空；
第三行最左边显示“TST6”共4个字符； 
cnt_ascii_num  0   1   2   3  4   5   6   7   8   9  10   11  
   char        p   p   m      h   u   s   t   T   S   T   6
 ascii码     112,112,109, 32,104,117,115,116, 84, 83, 84, 54 =库内码+32 
*/

module show_string_number_ctrl
(
    input       wire            sys_clk             ,
    input       wire            sys_rst_n           ,
    input       wire            init_done           ,
    input       wire            show_char_done      ,
    input       wire    [3:0]   mode                , 
    
    output      wire            en_size             ,
    output      reg             show_char_flag      ,
    output      reg     [6:0]   ascii_num           ,
    output      reg     [8:0]   start_x             ,
    output      reg     [8:0]   start_y               

    // output      reg             DONE // 用于测试        
);      
//****************** Parameter and Internal Signal *******************//  
parameter   MODE_Square     = 4'd0;   //方形模式
parameter   MODE_Sin        = 4'd1;   //正弦模式
parameter   MODE_Triangle   = 4'd2;   //三角形模式
parameter   MODE_Sawtooth   = 4'd3;   //锯齿波模式
parameter   MODE_AM         = 4'd4;   //正弦波模式
parameter   MODE_FM         = 4'd5;   //调频模式
parameter   MODE_PWM        = 4'd6;   //脉宽调制模式
parameter   MODE_HOME       = 4'd7;   //home模式

parameter   MODE_DEFAULT    = 4'd8;   //默认模式

parameter   MODE_NAME       = 4'd9;

reg     [1:0]   cnt1;            //展示 行 计数器？！？3行故cnt1值只需0，1，2
//也可能是延迟计数器，init_done为高电平后，延迟3拍，产生show_char_flag高脉冲
reg     [4:0]   cnt_ascii_num;

// reg             restart_all;      //模式改变时，重启所有寄存器

//******************************* Main Code **************************//
//en_size为1时调用字体大小为16x8，为0时调用字体大小为12x6；
assign  en_size = 1'b1;

// 模式改变时，计数器清零，标志信号清零，展示数目清零，ascii码清零，x坐标清零，y坐标清零，重新开始
// always@( mode)
// begin
//     restart_all <= 1'b1 ; // 模式改变时，重启所有寄存器
// end

//产生输出信号show_char_flag，写到第2行！？就让show_char_flag产生一个高脉冲给后面模块
always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n)
        cnt1 <= 'd0;
    else if(show_char_flag)
    begin
        // DONE <= 1'b1; // 用于测试
        cnt1 <= 'd0;
    end
    else if(init_done && cnt1 < 'd3)
        cnt1 <= cnt1 + 1'b1;
    else
        cnt1 <= cnt1;
        
always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n )
        show_char_flag <= 1'b0;
    else if(cnt1 == 'd2)
        show_char_flag <= 1'b1;
    else
        show_char_flag <= 1'b0;

always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n )
        cnt_ascii_num <= 'd0;
    else if(init_done && show_char_done)         //展示数目的计数器：初始化完成和上一个char展示完成后，数目+1
        cnt_ascii_num <= cnt_ascii_num + 1'b1;   //等于是展示字符的坐标（单位：个字符）
    else
        cnt_ascii_num <= cnt_ascii_num;

always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n )
        ascii_num <= 'd0;
    else if(init_done)
        case(mode)
            //ascii码     112,120,109, 32,104,117,115,116, 84, 83, 84, 54  =库内码+32
                /** 
                * ASCII码表（十进制-字符对照）
                * ┌─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┐
                * │ 32  │ 33  │ 34  │ 35  │ 36  │ 37  │ 38  │ 39  │ 40  │ 41  │ 42  │ 43  │ 44  │ 45  │ 46  │ 47  │
                * │ ' ' │ '!' │ '"' │ '#' │ '$' │ '%' │ '&' │ ''' │ '(' │ ')' │ '*' │ '+' │ ',' │ '-' │ '.' │ '/' │
                * ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
                * │ 48  │ 49  │ 50  │ 51  │ 52  │ 53  │ 54  │ 55  │ 56  │ 57  │ 58  │ 59  │ 60  │ 61  │ 62  │ 63  │
                * │ '0' │ '1' │ '2' │ '3' │ '4' │ '5' │ '6' │ '7' │ '8' │ '9' │ ':' │ ';' │ '<' │ '=' │ '>' │ '?' │
                * ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
                * │ 64  │ 65  │ 66  │ 67  │ 68  │ 69  │ 70  │ 71  │ 72  │ 73  │ 74  │ 75  │ 76  │ 77  │ 78  │ 79  │
                * │ '@' │ 'A' │ 'B' │ 'C' │ 'D' │ 'E' │ 'F' │ 'G' │ 'H' │ 'I' │ 'J' │ 'K' │ 'L' │ 'M' │ 'N' │ 'O' │
                * ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
                * │ 80  │ 81  │ 82  │ 83  │ 84  │ 85  │ 86  │ 87  │ 88  │ 89  │ 90  │ 91  │ 92  │ 93  │ 94  │ 95  │
                * │ 'P' │ 'Q' │ 'R' │ 'S' │ 'T' │ 'U' │ 'V' │ 'W' │ 'X' │ 'Y' │ 'Z' │ '[' │ '\' │ ']' │ '^' │ '_' │
                * ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
                * │ 96  │ 97  │ 98  │ 99  │100  │101  │102  │103  │104  │105  │106  │107  │108  │109  │110  │111  │
                * │ '`' │ 'a' │ 'b' │ 'c' │ 'd' │ 'e' │ 'f' │ 'g' │ 'h' │ 'i' │ 'j' │ 'k' │ 'l' │ 'm' │ 'n' │ 'o' │
                * ├─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┼─────┤
                * │112  │113  │114  │115  │116  │117  │118  │119  │120  │121  │122  │123  │124  │125  │126  │127  │
                * │ 'p' │ 'q' │ 'r' │ 's' │ 't' │ 'u' │ 'v' │ 'w' │ 'x' │ 'y' │ 'z' │ '{' │ '|' │ '}' │ '~' │DEL  │
                * └─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┴─────┘
                *
                * 中文字码表（十进制-字符对照）  // 注意，他没有做127所以下面减一
                * ┌────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┬────┐
                * │ 128│ 129│130 │131 │132 │133 │134 │135 │136 │137 │138 │139 │140 │141 │142 │143 │
                * │'曹'│'原' │'方'│'波'│'正'│'弦'│'三'│'角' │'锯'│'齿'│'胡'│'哲'│'玮'│    │    │    │
                * └────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┴────┘
                */
            MODE_Square   :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd129 - 8'd32;   // 方
                    1 : ascii_num <= 8'd32  - 8'd32;   // 空格
                    2 : ascii_num <= 8'd130 - 8'd32;   // 波
                    default: ascii_num <= 'd0;
                endcase
            MODE_Sin      :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd131 - 8'd32;   // 正
                    1 : ascii_num <= 8'd32  - 8'd32;   // 空格
                    2 : ascii_num <= 8'd132 - 8'd32;   // 弦
                    3 : ascii_num <= 8'd32 - 8'd32;    // 波
                    4 : ascii_num <= 8'd130 - 8'd32;   // 波
                    default: ascii_num <= 'd0;
                endcase
            MODE_Triangle :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd133 - 8'd32;   // 三
                    1 : ascii_num <= 8'd32  - 8'd32;   // 空格
                    2 : ascii_num <= 8'd134 - 8'd32;   // 角
                    3 : ascii_num <= 8'd32 - 8'd32;    // 空格
                    4 : ascii_num <= 8'd130 - 8'd32;   // 波
                    default: ascii_num <= 'd0;
                endcase
            MODE_Sawtooth :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd135 - 8'd32;   // 锯
                    1 : ascii_num <= 8'd32  - 8'd32;   // 空格
                    2 : ascii_num <= 8'd136 - 8'd32;   // 齿
                    3 : ascii_num <= 8'd32 - 8'd32;    // 空格
                    4 : ascii_num <= 8'd130 - 8'd32;   // 波
                    default: ascii_num <= 'd0;
                endcase
            MODE_AM      :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0:  ascii_num <= 8'd32 - 8'd32;   // 空格
                    1 : ascii_num <= 8'd32 - 8'd32;   // A
                    2 : ascii_num <= 8'd65 - 8'd32;   // A
                    3 : ascii_num <= 8'd77 - 8'd32;   // M
                    4:  ascii_num <= 8'd32 - 8'd32;   // 空格
                    default: ascii_num <= 'd0;
                endcase
            MODE_FM      :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0:  ascii_num <= 8'd32 - 8'd32;   // 空格
                    1 : ascii_num <= 8'd32 - 8'd32;   // 
                    2 : ascii_num <= 8'd70 - 8'd32;   // F
                    3 : ascii_num <= 8'd77 - 8'd32;   // M
                    4 : ascii_num <= 8'd32 - 8'd32;   // 空格
                    default: ascii_num <= 'd0;
                endcase
            MODE_PWM     :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0:  ascii_num <= 8'd32 - 8'd32;   // 空格
                    1 : ascii_num <= 8'd80 - 8'd32;   // P
                    2 : ascii_num <= 8'd87 - 8'd32;   // W
                    3 : ascii_num <= 8'd77 - 8'd32;   // M
                    4 : ascii_num <= 8'd32 - 8'd32;   // 空格
                    default: ascii_num <= 'd0;
                endcase

            MODE_HOME    :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd72 - 8'd32;   // H
                    1 : ascii_num <= 8'd79 - 8'd32;   // O
                    2 : ascii_num <= 8'd77 - 8'd32;   // M
                    3 : ascii_num <= 8'd69 - 8'd32;   // E 
                    // 换行
                    4 : ascii_num <= 8'd48 - 8'd32;      // '0'（方波前加数字0）
                    5 : ascii_num <= 8'd129 - 8'd32;     // 方
                    6 : ascii_num <= 8'd32  - 8'd32;     // 空格
                    7 : ascii_num <= 8'd130 - 8'd32;     // 波
                    8 : ascii_num <= 8'd49 - 8'd32;      // '1'（换行前加数字1）
                    9 : ascii_num <= 8'd131 - 8'd32;     // 正（第二行，注：无需换行）
                    10: ascii_num <= 8'd132 - 8'd32;     // 弦
                    11: ascii_num <= 8'd130 - 8'd32;     // 波
                    12: ascii_num <= 8'd50 - 8'd32;      // '2'（换行前加数字2）
                    13: ascii_num <= 8'd133 - 8'd32;     // 三（第三行，注：无需换行）
                    14: ascii_num <= 8'd134 - 8'd32;     // 角
                    15: ascii_num <= 8'd130 - 8'd32;     // 波
                    16: ascii_num <= 8'd51 - 8'd32;      // '3'（换行前加数字3）
                    17: ascii_num <= 8'd135 - 8'd32;     // 锯（第四行，注：无需换行）
                    18: ascii_num <= 8'd136 - 8'd32;     // 齿
                    19: ascii_num <= 8'd130 - 8'd32;     // 波
                    20: ascii_num <= 8'd52 - 8'd32;      // '4'
                    21: ascii_num <= 8'd65  - 8'd32;     // A
                    22: ascii_num <= 8'd77  - 8'd32;     // M
                    23: ascii_num <= 8'd32 - 8'd32;      // 空格
                    24: ascii_num <= 8'd53 - 8'd32;      // '5'
                    25: ascii_num <= 8'd80  - 8'd32;     // P
                    26: ascii_num <= 8'd77  - 8'd32;     // M
                    27: ascii_num <= 8'd32 - 8'd32;      // 空格
                    28: ascii_num <= 8'd54 - 8'd32;      // '6'
                    29: ascii_num <= 8'd80  - 8'd32;     // P
                    30: ascii_num <= 8'd87  - 8'd32;     // W
                    31: ascii_num <= 8'd77  - 8'd32;     // M

                    default: ascii_num <= 'd0;
                endcase

            MODE_DEFAULT :   //默认模式
                ascii_num <= 8'd32 - 8'd32;   // 空格

            MODE_NAME    :   //名字模式
                case(cnt_ascii_num)
                    0 : ascii_num <= 8'd32 - 8'd32;    // 空格
                    1 : ascii_num <= 8'd68 - 8'd32;    // D
                    2 : ascii_num <= 8'd68 - 8'd32;    // D
                    3 : ascii_num <= 8'd83 - 8'd32;    // S
                    4 : ascii_num <= 8'd32 - 8'd32;    // 空格
                    5 : ascii_num <= 8'd137 - 8'd32;   // 胡
                    6 : ascii_num <= 8'd138 - 8'd32;   // 哲
                    7 : ascii_num <= 8'd139 - 8'd32;   // 玮
                    8 : ascii_num <= 8'd38 - 8'd32;    // &
                    9 : ascii_num <= 8'd127 - 8'd32;   // 曹
                    10: ascii_num <= 8'd128 - 8'd32;   // 原
                    default: ascii_num <= 'd0;
                endcase

            default     :
                case(cnt_ascii_num)         //根据当前展示数目（字符坐标）给出展示内容（ascii码）
                    0 : ascii_num <= 8'd0;    // 空
                    1 : ascii_num <= 8'd0;    // 空
                    2 : ascii_num <= 8'd0;    // 空
                    3 : ascii_num <= 8'd0;    // 空
                    4 : ascii_num <= 8'd0;    // 空
                    5 : ascii_num <= 8'd0;    // 空
                    6 : ascii_num <= 8'd0;    // 空
                    7 : ascii_num <= 8'd0;    // 空
                    8 : ascii_num <= 'd0;     // 空
                    9 : ascii_num <= 'd0;     // 空
                    10: ascii_num <= 'd0;     // 空
                    11: ascii_num <= 'd0;     // 空
                    default: ascii_num <= 'd0;
                endcase
        endcase



always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n )
        start_x <= 'd0;
    else if(init_done)
        if(mode != MODE_HOME && mode != MODE_DEFAULT)  //home模式不需要计算start_x和start_y
            if(mode==MODE_NAME)
                case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,先定横向x
                    0 : start_x <= 'd104 ;  //(16x)8的字模，第一行128x128屏满行16字符；
                    1 : start_x <= 'd112 ;  //首行居中显示8个字符，起始128/4，后续++8(简单粗略)
                    2 : start_x <= 'd120 ;
                    3 : start_x <= 'd128 ;
                    4 : start_x <= 'd136 ;  //第三行最左边显示4个字符，起始128/4，后续++8(简单粗略)
                    5 : start_x <= 'd96  ;
                    6 : start_x <= 'd104 ;
                    7 : start_x <= 'd112 ;
                    8 : start_x <= 'd120 ;  //home模式第二行，起始128/2-16，后续++8(简单粗略)
                    9 : start_x <= 'd128 ;
                    10: start_x <= 'd136 ;
                    default: start_x <= 'd0;
                endcase
            else 
                case(cnt_ascii_num)
                    0 : start_x <= 'd96 ;   // 原104+8
                    1 : start_x <= 'd104 ;  // 原112+8
                    2 : start_x <= 'd112 ;  // 原120+8
                    3 : start_x <= 'd120 ;  // 原128+8
                    4 : start_x <= 'd128 ;  // 原136+8
                    default: start_x <= 'd0 ;  //home模式第二行，起始128/2-16，后续++8(简单粗略)
                endcase
        else
            case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,先定横向x
                0 : start_x <= 'd104 ;   //home模式第一行，起始128/2，后续++8(简单粗略)
                1 : start_x <= 'd112 ;
                2 : start_x <= 'd120 ;
                3 : start_x <= 'd128 ;
                4 : start_x <= 'd56 ;   //home模式第二行，起始128/2-16，后续++8(简单粗略)
                5 : start_x <= 'd64 ;
                6 : start_x <= 'd72 ;
                7 : start_x <= 'd80 ;
                8 : start_x <= 'd56 ;   //home模式第三行，起始128/2-16，后续++8(简单粗略)
                9 : start_x <= 'd64 ;
                10: start_x <= 'd72 ;
                11: start_x <= 'd80 ;
                12: start_x <= 'd56 ;   //home模式第四行，起始128/2-16，后续++8(简单粗略)
                13: start_x <= 'd64 ;
                14: start_x <= 'd72 ;
                15: start_x <= 'd80 ;
                16: start_x <= 'd56 ;   //home模式第五行，起始128/2-16，后续++8(简单粗略)
                17: start_x <= 'd64 ;
                18: start_x <= 'd72 ;
                19: start_x <= 'd80 ;
                20: start_x <= 'd56 ;   //home模式第六行，起始128/2-16，后续++8(简单粗略)
                21: start_x <= 'd64 ;
                22: start_x <= 'd72 ;
                23: start_x <= 'd80 ;
                24: start_x <= 'd56  + 64;   //home模式第七行，起始128/2-16，后续++8(简单粗略)
                25: start_x <= 'd64  + 64;
                26: start_x <= 'd72  + 64;
                27: start_x <= 'd80  + 64;
                28: start_x <= 'd56  + 64;   //home模式第八行，起始128/2-16，后续++8(简单粗略)
                29: start_x <= 'd64  + 64;
                30: start_x <= 'd72  + 64;
                31: start_x <= 'd80  + 64;
                32: start_x <= 'd56  + 64;   //home模式第九行，起始128/2-16，后续++8(简单粗略)
                33: start_x <= 'd64  + 64;
                34: start_x <= 'd72  + 64;
                35: start_x <= 'd80  + 64;
                
            

                default: start_x <= 'd0;
            endcase
    else
        start_x <= 'd0;

always@(posedge sys_clk or negedge sys_rst_n )
    if(!sys_rst_n )
        start_y <= 'd0;
    else if(init_done)
        if(mode != MODE_HOME && mode != MODE_DEFAULT )  //home模式不需要计算start_x和start_y
            if(mode==MODE_NAME)
                case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,再定纵向y
                    0 : start_y <= 'd16;   //首行居中显示8个字符，靠屏幕上边
                    1 : start_y <= 'd16;
                    2 : start_y <= 'd16;
                    3 : start_y <= 'd16;
                    4 : start_y <= 'd16;   //第三行最左边显示4个字符，靠屏幕上边
                    5 : start_y <= 'd40;   //home模式第二行，靠屏幕上边
                    6 : start_y <= 'd40;
                    7 : start_y <= 'd40;
                    8 : start_y <= 'd40;   //home模式第三行，靠屏幕上边
                    9 : start_y <= 'd40;   //home模式第二行，靠屏幕上边
                    10: start_y <= 'd40;

                    default: start_y <= 'd0;
                endcase
            else
                case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,再定纵向y
                    0 : start_y <= 'd16;   //home模式第一行，靠屏幕上边
                    1 : start_y <= 'd16;
                    2 : start_y <= 'd16;
                    3 : start_y <= 'd16;
                    4 : start_y <= 'd16;   //home模式第二行，靠屏幕上边
                    default: start_y <= 'd0;  //home模式第二行，靠屏幕上边
                endcase
        else
            case(cnt_ascii_num)        //根据当前展示数目（字符坐标）给出展示位置（屏幕坐标）,再定纵向y
                0 : start_y <= 'd16;   //首行居中显示8个字符，靠屏幕上边
                1 : start_y <= 'd16;
                2 : start_y <= 'd16;
                3 : start_y <= 'd16;
                4 : start_y <= 'd40;   //home模式第二行，靠屏幕上边
                5 : start_y <= 'd40;
                6 : start_y <= 'd40;
                7 : start_y <= 'd40;   //home模式第三行，靠屏幕上边
                8 : start_y <= 'd56;   //home模式第四行，靠屏幕上边
                9 : start_y <= 'd56;
                10: start_y <= 'd56;
                11: start_y <= 'd56;
                12: start_y <= 'd72;   //home模式第五行，靠屏幕上边
                13: start_y <= 'd72;
                14: start_y <= 'd72;
                15: start_y <= 'd72;
                16: start_y <= 'd88;   //home模式第六行，靠屏幕上边
                17: start_y <= 'd88;
                18: start_y <= 'd88;
                19: start_y <= 'd88;
                20: start_y <= 'd104;   //home模式第二行，靠屏幕上边
                21: start_y <= 'd104;
                22: start_y <= 'd104;
                23: start_y <= 'd104;   //home模式第三行，靠屏幕上边
                24: start_y <= 'd40;   //home模式第四行，靠屏幕上边
                25: start_y <= 'd40;
                26: start_y <= 'd40;
                27: start_y <= 'd40;
                28: start_y <= 'd56;   //home模式第五行，靠屏幕上边
                29: start_y <= 'd56;
                30: start_y <= 'd56;
                31: start_y <= 'd56;
                32: start_y <= 'd72;   //home模式第六行，靠屏幕上边
                33: start_y <= 'd72;
                34: start_y <= 'd72;
                35: start_y <= 'd72;
                

                default: start_y <= 'd0;
            endcase
    else
        start_y <= 'd0;

endmodule