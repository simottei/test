module testimage_make
    #(
        // Width of S_AXI data bus
        parameter integer C_S_AXI_DATA_WIDTH    = 32,
        // Width of S_AXI address bus
        parameter integer C_S_AXI_ADDR_WIDTH    = 8
        -- Master AXI Stream Data Width
        C_M_AXIS_DATA_WIDTH : integer range 8 to 1024 := 24
    )
    (
    
    
    test
    
    input   CLK,
    input   RST,
    
    // Write Dataas
    input           TESTSTART,
    output  [31:0]  TEST_WDATA,
    output          FIFO_WR,
    input           FIFO_WREADY,

    /* REG */
    input           TESTON,
    output          TESTEND,
    output  [31:0]  TEST_PIXELCNT
    
  generic(
        -- Master AXI Stream Data Width
        C_M_AXIS_DATA_WIDTH : integer range 8 to 1024 := 24
    );
  port (
        s2mm_aclk    : out std_logic;
        s2mm_prmry_reset : in std_logic;
        s2mm_fsync        : out std_logic;

        -- Master Stream Ports
    --    m_axis_aresetn : out std_logic;
        m_axis_tdata   : out std_logic_vector(C_M_AXIS_DATA_WIDTH-1 downto 0);
        m_axis_tstrb   : out std_logic_vector((C_M_AXIS_DATA_WIDTH/8)-1 downto 0);
        m_axis_tvalid  : out std_logic;
        m_axis_tready  : in  std_logic;
        m_axis_tlast   : out std_logic;
    
    
        // Global Clock Signal
        input wire  s_axi_aclk,
        input wire  s_axi_aresetn,
        input wire [c_s_axi_addr_width-1 : 0] s_axi_awaddr,
        input wire [2 : 0] s_axi_awprot,
        input wire  s_axi_awvalid,
        output wire  s_axi_awready,
        input wire [c_s_axi_data_width-1 : 0] s_axi_wdata,    
        input wire [(c_s_axi_data_width/8)-1 : 0] s_axi_wstrb,
        input wire  s_axi_wvalid,
        output wire  s_axi_wready,
        output wire [1 : 0] s_axi_bresp,
        output wire  s_axi_bvalid,
        input wire  s_axi_bready,
        input wire [c_s_axi_addr_width-1 : 0] s_axi_araddr,
        input wire [2 : 0] s_axi_arprot,
        input wire  s_axi_arvalid,
        output wire  s_axi_arready,
        output wire [c_s_axi_data_width-1 : 0] s_axi_rdata,
        output wire [1 : 0] s_axi_rresp,
        output wire  s_axi_rvalid,
        input wire  s_axi_rready
);

reg [28:0]  pixelcnt;
wire [28:0]  pixel_data;

/* TEST画像書き込み開始（TESTONをDCLKで同期化し立ち上がりを検出） */
reg [2:0]   teston_ff; 

always @( posedge DCLK ) begin
    if ( DRST )
        teston_ff <= 3'b000;
    else begin
        teston_ff[0] <= TESTON;
        teston_ff[1] <= teston_ff[0];
        teston_ff[2] <= teston_ff[1];
    end
end

assign TESTSTART = (teston_ff[2:1] == 2'b01);


/* pixelカウンタ */
always @( posedge DCLK ) begin
    if ( DRST )
        pixelcnt <= 29'b0;
    else if(teston_ff[1])
        if ( TESTSTART )
            pixelcnt <= 29'b0;
        else if ( TESTEND )
            pixelcnt <= pixelcnt;
        else if( FIFO_WREADY )
            pixelcnt <= pixelcnt + 29'h0001; 
        else
            pixelcnt <= pixelcnt;
    else
        pixelcnt <= 29'b0;
end

assign TEST_PIXELCNT = pixelcnt;
assign pixel_data = pixelcnt +1'b1;

assign TEST_WDATA = {8'b0, pixel_data[7:0], pixel_data[7:0], pixel_data[7:0]};
assign FIFO_WR = teston_ff[2] & (! TESTEND) & FIFO_WREADY;


/* TEST画像生成終了 */
localparam integer VGA_MAX = 29'd640 * 29'd480 * 29'd1;
assign TESTEND = (pixelcnt == VGA_MAX);



endmodule
