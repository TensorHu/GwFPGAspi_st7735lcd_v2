//----------------------------------------------------------------------------------------
// File name: lcd_write
// Descriptions: 连接SPI-lcd控制芯片st7735R，进行写数据操作
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module  lcd_write
#(  parameter HALFBASE = 'd1    // 为适应系统时钟设置的分频比参数，系统时钟分频后不能超过spi硬件最大速率
)
(
    input   wire            sys_clk             ,  //系统工作时钟
    input   wire            sys_rst_n           ,
    input   wire    [8:0]   data                ,
    input   wire            en_write            ,  //电平或脉冲信号（几个sys_clk宽）均可

    output  wire            wr_done             ,  //给用到本模块的上级模块发脉冲通知：本批8bit数据传输结束
    output  wire            cs                  ,
    output  reg             dc                  ,
    output  reg             sclk                ,
    output  reg             mosi                
);
  localparam HALFDIV = HALFBASE + 2; 
  localparam MAXDIV  = HALFDIV *2 ; 
  reg [3:0] wclkcnt;      // wclkcnt既做分频，也成时序 微状态值，最终sclk周期=sys_clk/MAXDIV=sys_clk/(2*HALFDIV)
  reg [4:0] count ;       // 关键的 Bit计数，大状态值，传8bit-至少用8个bit时刻，加头一个count作准备，共9个时刻（0~8）。
                          
//等同安排：count大状态，1个大状态内有MAXDIV个小状态，大状态的中点值是HALFDIV，以这些变量信号来安排spi接口动作。
//      en_write来后立即进入busy（=1）态，同时数据入缓冲，wclkcnt微状态值开始计数+1，计满会使Bit计数count+1；
//      微状态=HALFDIV-1,Bit计数=0时刻，即与微状态=HALFDIV，count=0的同时有 首bit数据送到端口，并移位次bit到缓冲首位；
//      微状态= MAXDIV-1,Bit计数=0时刻，即与微状态=0，Bit计数=N(N>0)的沿同时有sclk出上升沿，数据稳定被抽样=外部模块锁定数据；
//      微状态=HALFDIV-1,Bit计数=1时刻，即与微状态=HALFDIV, Bit计数=N(N>0)的中点同时有sclk下降沿，而后续bit数据也在此刻送端口；
//      周期循环形成 每个数据都比sclkN(N=0~7)的上升沿提前HALFDIV个sys_clk送到端口，而sclkN的下降沿正是送下一数据的时刻。
//      直到所有数据已经送出，sclk8上升沿对齐Bit计数=8的开始，sclk8下升沿对齐Bit计数=8的中点，不再有sclk，而同时刻让Busy=0；
//      Busy=0也令后一刻 微状态停止（停止前正好组合产生wr_done脉冲）。busy=0产生后整个过程结束，直到下一个en_write来到。
                          
  reg [7:0] in_buffer ;   // 并行数据缓存，移位形成串行输出
  reg busy;               // 忙指示信号--增强可读性，关联cs硬件信号。
  
//****************** Parameter and Internal Signal *******************//
//spi模式0：CPOL = 0, CPHA = 0;  sclk平时低，第一上升沿对准数据中间

always@(posedge sys_clk or negedge sys_rst_n)  begin
    if(!sys_rst_n)
        wclkcnt <= 0;           // 产生大状态count的计数器，同时也用来指示状态内小状态
    else if (busy) begin        // 只有busy时才需要计数器对sys_clk分频产生状态
           if(wclkcnt==MAXDIV-1) wclkcnt <= 0;   // 产生的count频率不高于写硬件时钟上限
           else   wclkcnt <= wclkcnt + 1'b1;
         end
         else wclkcnt <= 0;     // 非busy时计数器清零
end

always@(posedge sys_clk or negedge sys_rst_n)  begin
  if(!sys_rst_n)            count <= 0;
  else  if (busy) begin                          // 只有busy时才需要count计数器产生大状态
          if ((count == 'd8)&&(wclkcnt==MAXDIV-1))  count <= 0;  //大状态计满回0（busy前提）
          else  if (wclkcnt==MAXDIV-1) count <= count + 1'b1;  // count未计满则在低一级计数满时+1
                else count <= count;             //  （busy前提）下缺省分支是保持count值
        end
        else count <= 0;                         // 非busy下，count保持0
end   

always@(posedge sys_clk or negedge sys_rst_n)  begin  
  if(!sys_rst_n)            busy <= 0;           // busy=0,闲状态 
  else  if (en_write&&!busy)      busy <= 1'b1;  // 外部写指示在非忙状态出现时，转换为忙状态
        else if ((wclkcnt==HALFDIV)&&(count==8)&&busy)   busy <= 0;  //8bit数据送完，忙状态结束，具体回0时刻
                                  //忙状态具体回0时刻比数据传输结束下降沿wclkcnt==HALFDIV-1拖后1个sys_clk
             else                busy <= busy; 
end  

  assign cs=~busy;                              // 忙状态就是为写入，当然要开cs，或者说busy就是cs的易读性名称。    
  assign wr_done = (!busy)&&(count==8);         // 忙状态=0使wclkcnt返0，波形上有1sys_clk延后，正好组合产生wr_done脉冲。


always@(posedge sys_clk or negedge sys_rst_n)  begin
  if(!sys_rst_n)            sclk <= 0;                 //给硬件的节拍信号
  else  if (busy&&(wclkcnt==MAXDIV-1)) sclk <= 1'b1;   //与count=N(N>0)的边沿同步，比数据落后半个count
        else if (busy&&(wclkcnt==HALFDIV-1)&&(count>0))  sclk <= 1'b0; //在count=N的中点，同时还会送数到端口
             else if (!busy) sclk <= 0;
                  else  sclk <= sclk;
              
end 

always@(posedge sys_clk or negedge sys_rst_n)  begin //完成MOsi数据输出操作
  if(!sys_rst_n) begin
        in_buffer <= 0;
        mosi <= 0;
  end
  else begin
    if (en_write&&!busy) begin          // (en_write&&!busy)会 busy <= 1'b1; 
          in_buffer <= data[7:0];        // 故 缓冲数据与 busy = 1'b1 变化沿 同步
          dc <= data[8];                 // 数据首位是DC（命令/数据指示）
        end 
    else   begin 
       if (busy&&(wclkcnt == HALFDIV-1))   begin    //在count=N中点送数据上端口
          mosi = in_buffer[7];          // 高位送到端口输出
          in_buffer = in_buffer << 1;   // 移位为下一次
        end 
    end    
  end
end  

endmodule
