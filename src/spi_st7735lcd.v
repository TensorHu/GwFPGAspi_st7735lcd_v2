//****************************************Copyright (c)***********************************//
//----------------------------------------------------------------------------------------
// Author：Pxm
// File name: spi_st7735lcd
// First establish Date: 2022/12/15 
// Descriptions: st7735R-SPI-LCD-demo顶层模块
// OutPin--CS    屏（从机）片选
// OutPin--RESET ST7735复位          （也有标RST）
// OutPin--DC    命令or数据指示      （也有标RS）
// OutPin--MOSI  主机输出数据给屏从机（也有标SDI）
// OutPin--SCLK  主机输出数据时钟    （也有标SCK）
// OutPin--LED   背光开关            （也有标BLK）
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  spi_st7735lcd
(
    input           xtal_clk      ,
    input           sys_rst_n     ,
    // input[3:0]      mode          ,// 模式
    // input           change_mode   , // 模式切换信号     ,
    // input   [3:0]   choice_number , // 选择数字显示的信号
    
    output          lcd_rst       ,
    output          lcd_dc        ,
    output          lcd_sclk      ,
    output          lcd_mosi      ,
    output          lcd_cs        ,
    output          lcd_led       ,
    output          testled       ,

    output          DONE          // 用于测试
    // output[3:0]     _mode         // 模式寄存器输出
);
wire    [3:0]   mode ;

wire    [8:0]   data;   
wire            en_write;
wire            wr_done; 

wire    [8:0]   init_data;
wire            en_write_init;
wire            init_done;

wire    [6:0]   ascii_num           ;
wire    [8:0]   start_x             ;
wire    [8:0]   start_y             ;

wire    [8:0]   show_char_data      ;

reg     [3:0]   mode ; // 模式寄存器

wire    [3:0]   choice_number; // 选择数字显示的信号
assign  choice_number = 4'd4; // 直接连接外部选择数字显示的信号

assign  testled = ~init_done;
assign  lcd_led = 1'b0;  //屏背光常亮

wire sys_clk;
Gowin_rPLL uPLL( .clkout(sys_clk), .clkin (xtal_clk) ); //以PLL核产生高频提升运行速度
// assign sys_clk = xtal_clk;     //不用PLL核，直接用板载12MHz主频。仿真时也改用此句，免得引入PLL仿真核。

reg change_mode;
reg [3:0] mode_d;

assign  _sys_rst_n = sys_rst_n & change_mode ; // 直接连接外部复位信号

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        mode_d <= 4'd0;
        change_mode <= 1'b1;
    end else begin
        mode_d <= mode;
        // 检测mode信号变化，产生一个下降沿
        if (mode != mode_d)
            change_mode <= 1'b0;
        else
            change_mode <= 1'b1;
    end
end


lcd_init    lcd_init_inst
(
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (sys_rst_n    ),
    .wr_done      (wr_done      ),

    .lcd_rst      (lcd_rst      ),
    .init_data    (init_data    ),
    .en_write     (en_write_init),
    .init_done    (init_done    )
);

assign DONE = en_write; // 用于测试
/** 测试结果:
* 1. init_done信号输出高电平正常
* 2. en_write_init信号输出高电平后快速恢复低电平正常
* 3. init_data信号输出正常
* 4. wr_done信号输出高电平正常
*/

wire en_write_show_char;
wire show_char_done;
wire en_size;
wire show_char_flag;

// reg [3:0] _mode; // 模式寄存器

// always@( negedge cnt or negedge _sys_rst_n)
// begin
//     if(!_sys_rst_n)
//         _mode <= 4'd0; // 初始化模式为0
//     else 
//         _mode <= _mode + 1 ; // 模式自增
// end

muxcontrol  muxcontrol_inst
(
    .sys_clk            (sys_clk           ) ,   
    .sys_rst_n          (_sys_rst_n         ) ,
    .init_done          (init_done         ) ,

    .init_data          (init_data         ) ,
    .en_write_init      (en_write_init     ) ,
    .show_char_data     (show_char_data    ) ,
    .en_write_show_char (en_write_show_char) ,

    .data               (data              ) ,
    .en_write           (en_write          )
);

lcd_write
#( .HALFBASE('d0) )     // 为适应系统时钟设置的分频比参数，>=0，保证sys_clk/（2*(2+HALFBASE))不能超过spi硬件最大速率
  lcd_write_inst (
    .sys_clk      (sys_clk      ),
    .sys_rst_n    (_sys_rst_n    ),
    .data         (data         ),
    .en_write     (en_write     ),
                                
    .wr_done      (wr_done      ),
    .cs           (lcd_cs       ),
    .dc           (lcd_dc       ),
    .sclk         (lcd_sclk     ),
    .mosi         (lcd_mosi     )
);

// always@( negedge change_mode or negedge sys_rst_n)
// begin
//     if(!sys_rst_n)
//         mode <= 4'd0; // 初始化模式为0
//     else 
//         mode <= mode + 1 ; // 模式自增
// end

show_string_number_ctrl  show_string_number_inst
(
    .sys_clk        (sys_clk        ) ,
    .sys_rst_n      (_sys_rst_n      ) ,
    .init_done      (init_done      ) ,
    .show_char_done (show_char_done ) ,
    .mode           ( mode         ) ,

    .en_size        (en_size        ) ,
    .show_char_flag (show_char_flag ) ,
    .ascii_num      (ascii_num      ) ,
    .start_x        (start_x        ) ,
    .start_y        (start_y        ) 

    // .DONE           (DONE        )  // 用于测试
);  


lcd_show_char  lcd_show_char_inst
(
    .sys_clk            (sys_clk            ),
    .sys_rst_n          (_sys_rst_n          ),
    .wr_done            (wr_done            ),
    .en_size            (en_size            ),   //为0时字体大小的12x6，为1时字体大小的16x8
    .show_char_flag     (show_char_flag     ),   //显示字符标志信号
    .ascii_num          (ascii_num          ),   //需要显示字符的ascii码
    .start_x            (start_x            ),   //起点的x坐标    
    .start_y            (start_y            ),   //起点的y坐标   
    .mode      (mode      ),   //选择数字显示的信号 

    .show_char_data     (show_char_data     ),   //传输的命令或者数据
    .en_write_show_char (en_write_show_char ),   //使能写spi信号
    .show_char_done     (show_char_done     )    //显示字符完成标志信号
);


/**
* 测试结果:
* 1. show_char_done信号输出高电平正常
* 2. show_char_flag信号输出高电平正常
* 3. wr_done信号输出高电平正常
* 4. en_write_show_char信号输出低电平，检查中
*/
// ...existing code...

reg [31:0] cnt_5s;
reg [3:0]  mode_reg;

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cnt_5s <= 32'd0;
        mode_reg <= 4'd0;
    end else if (cnt_5s >= 32'd67_499_999) begin // 27MHz时钟，5秒=2.5亿
        cnt_5s <= 32'd0;
        mode_reg <= mode_reg + 1'b1;
    end else begin
        cnt_5s <= cnt_5s + 1'b1;
    end
end

assign mode = mode_reg;

// ...existing code...

endmodule