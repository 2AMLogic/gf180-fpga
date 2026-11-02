module logic_tile_routed (clk,
    cfg,
    e_in,
    e_out,
    n_in,
    n_out,
    s_in,
    s_out,
    w_in,
    w_out);
 input clk;
 input [157:0] cfg;
 input [3:0] e_in;
 output [3:0] e_out;
 input [3:0] n_in;
 output [3:0] n_out;
 input [3:0] s_in;
 output [3:0] s_out;
 input [3:0] w_in;
 output [3:0] w_out;

 wire \g_slice[0].u_slice/_00_ ;
 wire \g_slice[0].u_slice/_01_ ;
 wire \g_slice[0].u_slice/_02_ ;
 wire \g_slice[0].u_slice/_03_ ;
 wire \g_slice[0].u_slice/_04_ ;
 wire \g_slice[0].u_slice/_05_ ;
 wire \g_slice[0].u_slice/_06_ ;
 wire \g_slice[0].u_slice/_07_ ;
 wire \g_slice[0].u_slice/ff_q ;
 wire \g_slice[1].u_slice/_00_ ;
 wire \g_slice[1].u_slice/_01_ ;
 wire \g_slice[1].u_slice/_02_ ;
 wire \g_slice[1].u_slice/_03_ ;
 wire \g_slice[1].u_slice/_04_ ;
 wire \g_slice[1].u_slice/_05_ ;
 wire \g_slice[1].u_slice/_06_ ;
 wire \g_slice[1].u_slice/_07_ ;
 wire \g_slice[1].u_slice/ff_q ;
 wire \g_slice[2].u_slice/_00_ ;
 wire \g_slice[2].u_slice/_01_ ;
 wire \g_slice[2].u_slice/_02_ ;
 wire \g_slice[2].u_slice/_03_ ;
 wire \g_slice[2].u_slice/_04_ ;
 wire \g_slice[2].u_slice/_05_ ;
 wire \g_slice[2].u_slice/_06_ ;
 wire \g_slice[2].u_slice/_07_ ;
 wire \g_slice[2].u_slice/ff_q ;
 wire \g_slice[3].u_slice/_00_ ;
 wire \g_slice[3].u_slice/_01_ ;
 wire \g_slice[3].u_slice/_02_ ;
 wire \g_slice[3].u_slice/_03_ ;
 wire \g_slice[3].u_slice/_04_ ;
 wire \g_slice[3].u_slice/_05_ ;
 wire \g_slice[3].u_slice/_06_ ;
 wire \g_slice[3].u_slice/_07_ ;
 wire \g_slice[3].u_slice/ff_q ;
 wire \u_sm/_000_ ;
 wire \u_sm/_002_ ;
 wire clknet_0_clk;
 wire \u_sm/_004_ ;
 wire \u_sm/_005_ ;
 wire \u_sm/_006_ ;
 wire clknet_1_0__leaf_clk;
 wire clknet_1_1__leaf_clk;
 wire \u_sm/_009_ ;
 wire \u_sm/_010_ ;
 wire \u_sm/_011_ ;
 wire \u_sm/_012_ ;
 wire \u_sm/_013_ ;
 wire \u_sm/_014_ ;
 wire \u_sm/_015_ ;
 wire \u_sm/_016_ ;
 wire \u_sm/_017_ ;
 wire \u_sm/_018_ ;
 wire \u_sm/_019_ ;
 wire \u_sm/_020_ ;
 wire \u_sm/_021_ ;
 wire \u_sm/_022_ ;
 wire \u_sm/_023_ ;
 wire \u_sm/_024_ ;
 wire \u_sm/_025_ ;
 wire \u_sm/_026_ ;
 wire \u_sm/_027_ ;
 wire \u_sm/_028_ ;
 wire \u_sm/_029_ ;
 wire \u_sm/_030_ ;
 wire \u_sm/_031_ ;
 wire \u_sm/_032_ ;
 wire \u_sm/_033_ ;
 wire \u_sm/_034_ ;
 wire \u_sm/_035_ ;
 wire \u_sm/_036_ ;
 wire \u_sm/_037_ ;
 wire \u_sm/_038_ ;
 wire \u_sm/_039_ ;
 wire \u_sm/_040_ ;
 wire \u_sm/_041_ ;
 wire \u_sm/_042_ ;
 wire \u_sm/_043_ ;
 wire \u_sm/_044_ ;
 wire \u_sm/_045_ ;
 wire \u_sm/_046_ ;
 wire \u_sm/_047_ ;
 wire \u_sm/_048_ ;
 wire \u_sm/_049_ ;
 wire \u_sm/_050_ ;
 wire \u_sm/_051_ ;
 wire \u_sm/_052_ ;
 wire \u_sm/_053_ ;
 wire \u_sm/_054_ ;
 wire \u_sm/_055_ ;
 wire \u_sm/_056_ ;
 wire \u_sm/_057_ ;
 wire \u_sm/_058_ ;
 wire \u_sm/_059_ ;
 wire \u_sm/_060_ ;
 wire \u_sm/_061_ ;
 wire \u_sm/_062_ ;
 wire \u_sm/_063_ ;
 wire \u_sm/_064_ ;
 wire \u_sm/_065_ ;
 wire \u_sm/_066_ ;
 wire \u_sm/_067_ ;
 wire \u_sm/_068_ ;
 wire \u_sm/_069_ ;
 wire \u_sm/_070_ ;
 wire \u_sm/_071_ ;
 wire \u_sm/_072_ ;
 wire \u_sm/_073_ ;
 wire \u_sm/_074_ ;
 wire \u_sm/_075_ ;
 wire \u_sm/_076_ ;
 wire \u_sm/_077_ ;
 wire \u_sm/_078_ ;
 wire \u_sm/_079_ ;
 wire \u_sm/_080_ ;
 wire \u_sm/_081_ ;
 wire \u_sm/_082_ ;
 wire \u_sm/_083_ ;
 wire \u_sm/_084_ ;
 wire \u_sm/_085_ ;
 wire \u_sm/_086_ ;
 wire \u_sm/_087_ ;
 wire \u_sm/_088_ ;
 wire \u_sm/_089_ ;
 wire \u_sm/_090_ ;
 wire \u_sm/_091_ ;
 wire \u_sm/_092_ ;
 wire \u_sm/_093_ ;
 wire \u_sm/_094_ ;
 wire \u_sm/_095_ ;
 wire \u_sm/_096_ ;
 wire \u_sm/_097_ ;
 wire \u_sm/_098_ ;
 wire \u_sm/_099_ ;
 wire \u_sm/_100_ ;
 wire \u_sm/_101_ ;
 wire \u_sm/_102_ ;
 wire \u_sm/_103_ ;
 wire \u_sm/_104_ ;
 wire \u_sm/_105_ ;
 wire \u_sm/_106_ ;
 wire \u_sm/_107_ ;
 wire \u_sm/_108_ ;
 wire \u_sm/_109_ ;
 wire \u_sm/_110_ ;
 wire \u_sm/_111_ ;
 wire \u_sm/_112_ ;
 wire \u_sm/_113_ ;
 wire \u_sm/_114_ ;
 wire \u_sm/_115_ ;
 wire [3:0] bel_en;
 wire [3:0] bel_o;
 wire [0:0] bel_sr;
 wire [15:0] lut_in;

 gf180mcu_fd_sc_mcu7t5v0__buf_4 clkbuf_0_clk (.I(clk),
    .Z(clknet_0_clk));
 gf180mcu_fd_sc_mcu7t5v0__buf_4 clkbuf_1_0__f_clk (.I(clknet_0_clk),
    .Z(clknet_1_0__leaf_clk));
 gf180mcu_fd_sc_mcu7t5v0__buf_4 clkbuf_1_1__f_clk (.I(clknet_0_clk),
    .Z(clknet_1_1__leaf_clk));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[0].u_slice/_08_  (.I0(cfg[0]),
    .I1(cfg[1]),
    .I2(cfg[2]),
    .I3(cfg[3]),
    .S0(lut_in[0]),
    .S1(lut_in[1]),
    .Z(\g_slice[0].u_slice/_01_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[0].u_slice/_09_  (.I0(cfg[8]),
    .I1(cfg[9]),
    .I2(cfg[10]),
    .I3(cfg[11]),
    .S0(lut_in[0]),
    .S1(lut_in[1]),
    .Z(\g_slice[0].u_slice/_02_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[0].u_slice/_10_  (.I0(cfg[4]),
    .I1(cfg[5]),
    .I2(cfg[6]),
    .I3(cfg[7]),
    .S0(lut_in[0]),
    .S1(lut_in[1]),
    .Z(\g_slice[0].u_slice/_03_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[0].u_slice/_11_  (.I0(cfg[12]),
    .I1(cfg[13]),
    .I2(cfg[14]),
    .I3(cfg[15]),
    .S0(lut_in[0]),
    .S1(lut_in[1]),
    .Z(\g_slice[0].u_slice/_04_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \g_slice[0].u_slice/_12_  (.I0(\g_slice[0].u_slice/_01_ ),
    .I1(\g_slice[0].u_slice/_02_ ),
    .I2(\g_slice[0].u_slice/_03_ ),
    .I3(\g_slice[0].u_slice/_04_ ),
    .S0(lut_in[3]),
    .S1(lut_in[2]),
    .Z(\g_slice[0].u_slice/_05_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_2 \g_slice[0].u_slice/_13_  (.I0(\g_slice[0].u_slice/_05_ ),
    .I1(\g_slice[0].u_slice/ff_q ),
    .S(cfg[16]),
    .Z(bel_o[0]));
 gf180mcu_fd_sc_mcu7t5v0__inv_1 \g_slice[0].u_slice/_14_  (.I(\g_slice[0].u_slice/_05_ ),
    .ZN(\g_slice[0].u_slice/_06_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \g_slice[0].u_slice/_15_  (.A1(\g_slice[0].u_slice/ff_q ),
    .A2(bel_en[0]),
    .ZN(\g_slice[0].u_slice/_07_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi211_2 \g_slice[0].u_slice/_16_  (.A1(bel_en[0]),
    .A2(\g_slice[0].u_slice/_06_ ),
    .B(\g_slice[0].u_slice/_07_ ),
    .C(bel_sr[0]),
    .ZN(\g_slice[0].u_slice/_00_ ));
 gf180mcu_fd_sc_mcu7t5v0__dffq_1 \g_slice[0].u_slice/_17_  (.D(\g_slice[0].u_slice/_00_ ),
    .CLK(clknet_1_1__leaf_clk),
    .Q(\g_slice[0].u_slice/ff_q ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[1].u_slice/_08_  (.I0(cfg[17]),
    .I1(cfg[18]),
    .I2(cfg[19]),
    .I3(cfg[20]),
    .S0(lut_in[4]),
    .S1(lut_in[5]),
    .Z(\g_slice[1].u_slice/_01_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[1].u_slice/_09_  (.I0(cfg[25]),
    .I1(cfg[26]),
    .I2(cfg[27]),
    .I3(cfg[28]),
    .S0(lut_in[4]),
    .S1(lut_in[5]),
    .Z(\g_slice[1].u_slice/_02_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[1].u_slice/_10_  (.I0(cfg[21]),
    .I1(cfg[22]),
    .I2(cfg[23]),
    .I3(cfg[24]),
    .S0(lut_in[4]),
    .S1(lut_in[5]),
    .Z(\g_slice[1].u_slice/_03_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[1].u_slice/_11_  (.I0(cfg[29]),
    .I1(cfg[30]),
    .I2(cfg[31]),
    .I3(cfg[32]),
    .S0(lut_in[4]),
    .S1(lut_in[5]),
    .Z(\g_slice[1].u_slice/_04_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \g_slice[1].u_slice/_12_  (.I0(\g_slice[1].u_slice/_01_ ),
    .I1(\g_slice[1].u_slice/_02_ ),
    .I2(\g_slice[1].u_slice/_03_ ),
    .I3(\g_slice[1].u_slice/_04_ ),
    .S0(lut_in[7]),
    .S1(lut_in[6]),
    .Z(\g_slice[1].u_slice/_05_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_2 \g_slice[1].u_slice/_13_  (.I0(\g_slice[1].u_slice/_05_ ),
    .I1(\g_slice[1].u_slice/ff_q ),
    .S(cfg[33]),
    .Z(bel_o[1]));
 gf180mcu_fd_sc_mcu7t5v0__inv_1 \g_slice[1].u_slice/_14_  (.I(\g_slice[1].u_slice/_05_ ),
    .ZN(\g_slice[1].u_slice/_06_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \g_slice[1].u_slice/_15_  (.A1(\g_slice[1].u_slice/ff_q ),
    .A2(bel_en[1]),
    .ZN(\g_slice[1].u_slice/_07_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi211_2 \g_slice[1].u_slice/_16_  (.A1(bel_en[1]),
    .A2(\g_slice[1].u_slice/_06_ ),
    .B(\g_slice[1].u_slice/_07_ ),
    .C(bel_sr[0]),
    .ZN(\g_slice[1].u_slice/_00_ ));
 gf180mcu_fd_sc_mcu7t5v0__dffq_1 \g_slice[1].u_slice/_17_  (.D(\g_slice[1].u_slice/_00_ ),
    .CLK(clknet_1_1__leaf_clk),
    .Q(\g_slice[1].u_slice/ff_q ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[2].u_slice/_08_  (.I0(cfg[34]),
    .I1(cfg[35]),
    .I2(cfg[36]),
    .I3(cfg[37]),
    .S0(lut_in[8]),
    .S1(lut_in[9]),
    .Z(\g_slice[2].u_slice/_01_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[2].u_slice/_09_  (.I0(cfg[42]),
    .I1(cfg[43]),
    .I2(cfg[44]),
    .I3(cfg[45]),
    .S0(lut_in[8]),
    .S1(lut_in[9]),
    .Z(\g_slice[2].u_slice/_02_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[2].u_slice/_10_  (.I0(cfg[38]),
    .I1(cfg[39]),
    .I2(cfg[40]),
    .I3(cfg[41]),
    .S0(lut_in[8]),
    .S1(lut_in[9]),
    .Z(\g_slice[2].u_slice/_03_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[2].u_slice/_11_  (.I0(cfg[46]),
    .I1(cfg[47]),
    .I2(cfg[48]),
    .I3(cfg[49]),
    .S0(lut_in[8]),
    .S1(lut_in[9]),
    .Z(\g_slice[2].u_slice/_04_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \g_slice[2].u_slice/_12_  (.I0(\g_slice[2].u_slice/_01_ ),
    .I1(\g_slice[2].u_slice/_02_ ),
    .I2(\g_slice[2].u_slice/_03_ ),
    .I3(\g_slice[2].u_slice/_04_ ),
    .S0(lut_in[11]),
    .S1(lut_in[10]),
    .Z(\g_slice[2].u_slice/_05_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_2 \g_slice[2].u_slice/_13_  (.I0(\g_slice[2].u_slice/_05_ ),
    .I1(\g_slice[2].u_slice/ff_q ),
    .S(cfg[50]),
    .Z(bel_o[2]));
 gf180mcu_fd_sc_mcu7t5v0__inv_1 \g_slice[2].u_slice/_14_  (.I(\g_slice[2].u_slice/_05_ ),
    .ZN(\g_slice[2].u_slice/_06_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \g_slice[2].u_slice/_15_  (.A1(\g_slice[2].u_slice/ff_q ),
    .A2(bel_en[2]),
    .ZN(\g_slice[2].u_slice/_07_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi211_2 \g_slice[2].u_slice/_16_  (.A1(bel_en[2]),
    .A2(\g_slice[2].u_slice/_06_ ),
    .B(\g_slice[2].u_slice/_07_ ),
    .C(bel_sr[0]),
    .ZN(\g_slice[2].u_slice/_00_ ));
 gf180mcu_fd_sc_mcu7t5v0__dffq_1 \g_slice[2].u_slice/_17_  (.D(\g_slice[2].u_slice/_00_ ),
    .CLK(clknet_1_0__leaf_clk),
    .Q(\g_slice[2].u_slice/ff_q ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[3].u_slice/_08_  (.I0(cfg[51]),
    .I1(cfg[52]),
    .I2(cfg[53]),
    .I3(cfg[54]),
    .S0(lut_in[12]),
    .S1(lut_in[13]),
    .Z(\g_slice[3].u_slice/_01_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[3].u_slice/_09_  (.I0(cfg[59]),
    .I1(cfg[60]),
    .I2(cfg[61]),
    .I3(cfg[62]),
    .S0(lut_in[12]),
    .S1(lut_in[13]),
    .Z(\g_slice[3].u_slice/_02_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[3].u_slice/_10_  (.I0(cfg[55]),
    .I1(cfg[56]),
    .I2(cfg[57]),
    .I3(cfg[58]),
    .S0(lut_in[12]),
    .S1(lut_in[13]),
    .Z(\g_slice[3].u_slice/_03_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \g_slice[3].u_slice/_11_  (.I0(cfg[63]),
    .I1(cfg[64]),
    .I2(cfg[65]),
    .I3(cfg[66]),
    .S0(lut_in[12]),
    .S1(lut_in[13]),
    .Z(\g_slice[3].u_slice/_04_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \g_slice[3].u_slice/_12_  (.I0(\g_slice[3].u_slice/_01_ ),
    .I1(\g_slice[3].u_slice/_02_ ),
    .I2(\g_slice[3].u_slice/_03_ ),
    .I3(\g_slice[3].u_slice/_04_ ),
    .S0(lut_in[15]),
    .S1(lut_in[14]),
    .Z(\g_slice[3].u_slice/_05_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_2 \g_slice[3].u_slice/_13_  (.I0(\g_slice[3].u_slice/_05_ ),
    .I1(\g_slice[3].u_slice/ff_q ),
    .S(cfg[67]),
    .Z(bel_o[3]));
 gf180mcu_fd_sc_mcu7t5v0__inv_1 \g_slice[3].u_slice/_14_  (.I(\g_slice[3].u_slice/_05_ ),
    .ZN(\g_slice[3].u_slice/_06_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \g_slice[3].u_slice/_15_  (.A1(\g_slice[3].u_slice/ff_q ),
    .A2(bel_en[3]),
    .ZN(\g_slice[3].u_slice/_07_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi211_2 \g_slice[3].u_slice/_16_  (.A1(bel_en[3]),
    .A2(\g_slice[3].u_slice/_06_ ),
    .B(\g_slice[3].u_slice/_07_ ),
    .C(bel_sr[0]),
    .ZN(\g_slice[3].u_slice/_00_ ));
 gf180mcu_fd_sc_mcu7t5v0__dffq_1 \g_slice[3].u_slice/_17_  (.D(\g_slice[3].u_slice/_00_ ),
    .CLK(clknet_1_0__leaf_clk),
    .Q(\g_slice[3].u_slice/ff_q ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_116_  (.I(cfg[74]),
    .ZN(\u_sm/_000_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_118_  (.I0(w_in[2]),
    .I1(bel_o[3]),
    .S(cfg[76]),
    .Z(\u_sm/_002_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_120_  (.A1(bel_o[0]),
    .A2(cfg[74]),
    .Z(\u_sm/_004_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_121_  (.I(cfg[76]),
    .ZN(\u_sm/_005_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_122_  (.A1(\u_sm/_000_ ),
    .A2(\u_sm/_002_ ),
    .B1(\u_sm/_004_ ),
    .B2(\u_sm/_005_ ),
    .ZN(\u_sm/_006_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_125_  (.I0(e_in[2]),
    .I1(bel_o[1]),
    .I2(s_in[2]),
    .I3(bel_o[2]),
    .S0(cfg[76]),
    .S1(cfg[74]),
    .Z(\u_sm/_009_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_2 \u_sm/_126_  (.A1(cfg[75]),
    .A2(\u_sm/_009_ ),
    .ZN(\u_sm/_010_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_127_  (.A1(cfg[75]),
    .A2(\u_sm/_006_ ),
    .B(\u_sm/_010_ ),
    .ZN(n_out[2]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_128_  (.I(cfg[77]),
    .ZN(\u_sm/_011_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_129_  (.I0(w_in[3]),
    .I1(bel_o[3]),
    .S(cfg[79]),
    .Z(\u_sm/_012_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_130_  (.A1(bel_o[0]),
    .A2(cfg[77]),
    .Z(\u_sm/_013_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_131_  (.I(cfg[79]),
    .ZN(\u_sm/_014_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_132_  (.A1(\u_sm/_011_ ),
    .A2(\u_sm/_012_ ),
    .B1(\u_sm/_013_ ),
    .B2(\u_sm/_014_ ),
    .ZN(\u_sm/_015_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_133_  (.I0(e_in[3]),
    .I1(s_in[3]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[77]),
    .S1(cfg[79]),
    .Z(\u_sm/_016_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_134_  (.A1(cfg[78]),
    .A2(\u_sm/_016_ ),
    .ZN(\u_sm/_017_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_135_  (.A1(cfg[78]),
    .A2(\u_sm/_015_ ),
    .B(\u_sm/_017_ ),
    .ZN(n_out[3]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_136_  (.I(cfg[80]),
    .ZN(\u_sm/_018_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_137_  (.I0(w_in[0]),
    .I1(bel_o[3]),
    .S(cfg[82]),
    .Z(\u_sm/_019_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_138_  (.A1(bel_o[0]),
    .A2(cfg[80]),
    .Z(\u_sm/_020_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_139_  (.I(cfg[82]),
    .ZN(\u_sm/_021_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_140_  (.A1(\u_sm/_018_ ),
    .A2(\u_sm/_019_ ),
    .B1(\u_sm/_020_ ),
    .B2(\u_sm/_021_ ),
    .ZN(\u_sm/_022_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_141_  (.I0(n_in[0]),
    .I1(s_in[0]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[80]),
    .S1(cfg[82]),
    .Z(\u_sm/_023_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_142_  (.A1(cfg[81]),
    .A2(\u_sm/_023_ ),
    .ZN(\u_sm/_024_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_143_  (.A1(cfg[81]),
    .A2(\u_sm/_022_ ),
    .B(\u_sm/_024_ ),
    .ZN(e_out[0]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_144_  (.I(cfg[83]),
    .ZN(\u_sm/_025_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_145_  (.I0(w_in[1]),
    .I1(bel_o[3]),
    .S(cfg[85]),
    .Z(\u_sm/_026_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_146_  (.A1(bel_o[0]),
    .A2(cfg[83]),
    .Z(\u_sm/_027_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_147_  (.I(cfg[85]),
    .ZN(\u_sm/_028_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_148_  (.A1(\u_sm/_025_ ),
    .A2(\u_sm/_026_ ),
    .B1(\u_sm/_027_ ),
    .B2(\u_sm/_028_ ),
    .ZN(\u_sm/_029_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_149_  (.I0(n_in[1]),
    .I1(s_in[1]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[83]),
    .S1(cfg[85]),
    .Z(\u_sm/_030_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_150_  (.A1(cfg[84]),
    .A2(\u_sm/_030_ ),
    .ZN(\u_sm/_031_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_151_  (.A1(cfg[84]),
    .A2(\u_sm/_029_ ),
    .B(\u_sm/_031_ ),
    .ZN(e_out[1]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_152_  (.I(cfg[86]),
    .ZN(\u_sm/_032_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_153_  (.I0(w_in[2]),
    .I1(bel_o[3]),
    .S(cfg[88]),
    .Z(\u_sm/_033_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_154_  (.A1(bel_o[0]),
    .A2(cfg[86]),
    .Z(\u_sm/_034_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_155_  (.I(cfg[88]),
    .ZN(\u_sm/_035_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_156_  (.A1(\u_sm/_032_ ),
    .A2(\u_sm/_033_ ),
    .B1(\u_sm/_034_ ),
    .B2(\u_sm/_035_ ),
    .ZN(\u_sm/_036_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_157_  (.I0(n_in[2]),
    .I1(bel_o[1]),
    .I2(s_in[2]),
    .I3(bel_o[2]),
    .S0(cfg[88]),
    .S1(cfg[86]),
    .Z(\u_sm/_037_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_2 \u_sm/_158_  (.A1(cfg[87]),
    .A2(\u_sm/_037_ ),
    .ZN(\u_sm/_038_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_159_  (.A1(cfg[87]),
    .A2(\u_sm/_036_ ),
    .B(\u_sm/_038_ ),
    .ZN(e_out[2]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_160_  (.I(cfg[89]),
    .ZN(\u_sm/_039_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_161_  (.I0(w_in[3]),
    .I1(bel_o[3]),
    .S(cfg[91]),
    .Z(\u_sm/_040_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_162_  (.A1(bel_o[0]),
    .A2(cfg[89]),
    .Z(\u_sm/_041_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_163_  (.I(cfg[91]),
    .ZN(\u_sm/_042_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_164_  (.A1(\u_sm/_039_ ),
    .A2(\u_sm/_040_ ),
    .B1(\u_sm/_041_ ),
    .B2(\u_sm/_042_ ),
    .ZN(\u_sm/_043_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_165_  (.I0(n_in[3]),
    .I1(s_in[3]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[89]),
    .S1(cfg[91]),
    .Z(\u_sm/_044_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_166_  (.A1(cfg[90]),
    .A2(\u_sm/_044_ ),
    .ZN(\u_sm/_045_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_167_  (.A1(cfg[90]),
    .A2(\u_sm/_043_ ),
    .B(\u_sm/_045_ ),
    .ZN(e_out[3]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_168_  (.I(cfg[92]),
    .ZN(\u_sm/_046_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_169_  (.I0(w_in[0]),
    .I1(bel_o[3]),
    .S(cfg[94]),
    .Z(\u_sm/_047_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_170_  (.A1(bel_o[0]),
    .A2(cfg[92]),
    .Z(\u_sm/_048_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_171_  (.I(cfg[94]),
    .ZN(\u_sm/_049_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_172_  (.A1(\u_sm/_046_ ),
    .A2(\u_sm/_047_ ),
    .B1(\u_sm/_048_ ),
    .B2(\u_sm/_049_ ),
    .ZN(\u_sm/_050_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_173_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[92]),
    .S1(cfg[94]),
    .Z(\u_sm/_051_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_174_  (.A1(cfg[93]),
    .A2(\u_sm/_051_ ),
    .ZN(\u_sm/_052_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_175_  (.A1(cfg[93]),
    .A2(\u_sm/_050_ ),
    .B(\u_sm/_052_ ),
    .ZN(s_out[0]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_176_  (.I(cfg[95]),
    .ZN(\u_sm/_053_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_177_  (.I0(w_in[1]),
    .I1(bel_o[3]),
    .S(cfg[97]),
    .Z(\u_sm/_054_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_178_  (.A1(bel_o[0]),
    .A2(cfg[95]),
    .Z(\u_sm/_055_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_179_  (.I(cfg[97]),
    .ZN(\u_sm/_056_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_180_  (.A1(\u_sm/_053_ ),
    .A2(\u_sm/_054_ ),
    .B1(\u_sm/_055_ ),
    .B2(\u_sm/_056_ ),
    .ZN(\u_sm/_057_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_181_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[95]),
    .S1(cfg[97]),
    .Z(\u_sm/_058_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_182_  (.A1(cfg[96]),
    .A2(\u_sm/_058_ ),
    .ZN(\u_sm/_059_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_183_  (.A1(cfg[96]),
    .A2(\u_sm/_057_ ),
    .B(\u_sm/_059_ ),
    .ZN(s_out[1]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_184_  (.I(cfg[98]),
    .ZN(\u_sm/_060_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_185_  (.I0(w_in[2]),
    .I1(bel_o[3]),
    .S(cfg[100]),
    .Z(\u_sm/_061_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_186_  (.A1(bel_o[0]),
    .A2(cfg[98]),
    .Z(\u_sm/_062_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_187_  (.I(cfg[100]),
    .ZN(\u_sm/_063_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_188_  (.A1(\u_sm/_060_ ),
    .A2(\u_sm/_061_ ),
    .B1(\u_sm/_062_ ),
    .B2(\u_sm/_063_ ),
    .ZN(\u_sm/_064_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_189_  (.I0(n_in[2]),
    .I1(bel_o[1]),
    .I2(e_in[2]),
    .I3(bel_o[2]),
    .S0(cfg[100]),
    .S1(cfg[98]),
    .Z(\u_sm/_065_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_2 \u_sm/_190_  (.A1(cfg[99]),
    .A2(\u_sm/_065_ ),
    .ZN(\u_sm/_066_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_191_  (.A1(cfg[99]),
    .A2(\u_sm/_064_ ),
    .B(\u_sm/_066_ ),
    .ZN(s_out[2]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_192_  (.I(cfg[101]),
    .ZN(\u_sm/_067_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_193_  (.I0(w_in[3]),
    .I1(bel_o[3]),
    .S(cfg[103]),
    .Z(\u_sm/_068_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_194_  (.A1(bel_o[0]),
    .A2(cfg[101]),
    .Z(\u_sm/_069_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_195_  (.I(cfg[103]),
    .ZN(\u_sm/_070_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_196_  (.A1(\u_sm/_067_ ),
    .A2(\u_sm/_068_ ),
    .B1(\u_sm/_069_ ),
    .B2(\u_sm/_070_ ),
    .ZN(\u_sm/_071_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_197_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[101]),
    .S1(cfg[103]),
    .Z(\u_sm/_072_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_198_  (.A1(cfg[102]),
    .A2(\u_sm/_072_ ),
    .ZN(\u_sm/_073_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_199_  (.A1(cfg[102]),
    .A2(\u_sm/_071_ ),
    .B(\u_sm/_073_ ),
    .ZN(s_out[3]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_200_  (.I(cfg[104]),
    .ZN(\u_sm/_074_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_201_  (.I0(s_in[0]),
    .I1(bel_o[3]),
    .S(cfg[106]),
    .Z(\u_sm/_075_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_202_  (.A1(bel_o[0]),
    .A2(cfg[104]),
    .Z(\u_sm/_076_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_203_  (.I(cfg[106]),
    .ZN(\u_sm/_077_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_204_  (.A1(\u_sm/_074_ ),
    .A2(\u_sm/_075_ ),
    .B1(\u_sm/_076_ ),
    .B2(\u_sm/_077_ ),
    .ZN(\u_sm/_078_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_205_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[104]),
    .S1(cfg[106]),
    .Z(\u_sm/_079_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_206_  (.A1(cfg[105]),
    .A2(\u_sm/_079_ ),
    .ZN(\u_sm/_080_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_207_  (.A1(cfg[105]),
    .A2(\u_sm/_078_ ),
    .B(\u_sm/_080_ ),
    .ZN(w_out[0]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_208_  (.I(cfg[107]),
    .ZN(\u_sm/_081_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_209_  (.I0(s_in[1]),
    .I1(bel_o[3]),
    .S(cfg[109]),
    .Z(\u_sm/_082_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_210_  (.A1(bel_o[0]),
    .A2(cfg[107]),
    .Z(\u_sm/_083_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_211_  (.I(cfg[109]),
    .ZN(\u_sm/_084_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_212_  (.A1(\u_sm/_081_ ),
    .A2(\u_sm/_082_ ),
    .B1(\u_sm/_083_ ),
    .B2(\u_sm/_084_ ),
    .ZN(\u_sm/_085_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_213_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[107]),
    .S1(cfg[109]),
    .Z(\u_sm/_086_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_214_  (.A1(cfg[108]),
    .A2(\u_sm/_086_ ),
    .ZN(\u_sm/_087_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_215_  (.A1(cfg[108]),
    .A2(\u_sm/_085_ ),
    .B(\u_sm/_087_ ),
    .ZN(w_out[1]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_216_  (.I(cfg[110]),
    .ZN(\u_sm/_088_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_217_  (.I0(s_in[2]),
    .I1(bel_o[3]),
    .S(cfg[112]),
    .Z(\u_sm/_089_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_218_  (.A1(bel_o[0]),
    .A2(cfg[110]),
    .Z(\u_sm/_090_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_219_  (.I(cfg[112]),
    .ZN(\u_sm/_091_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_220_  (.A1(\u_sm/_088_ ),
    .A2(\u_sm/_089_ ),
    .B1(\u_sm/_090_ ),
    .B2(\u_sm/_091_ ),
    .ZN(\u_sm/_092_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_2 \u_sm/_221_  (.I0(n_in[2]),
    .I1(bel_o[1]),
    .I2(e_in[2]),
    .I3(bel_o[2]),
    .S0(cfg[112]),
    .S1(cfg[110]),
    .Z(\u_sm/_093_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_2 \u_sm/_222_  (.A1(cfg[111]),
    .A2(\u_sm/_093_ ),
    .ZN(\u_sm/_094_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_2 \u_sm/_223_  (.A1(cfg[111]),
    .A2(\u_sm/_092_ ),
    .B(\u_sm/_094_ ),
    .ZN(w_out[2]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_224_  (.I(cfg[113]),
    .ZN(\u_sm/_095_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_225_  (.I0(s_in[3]),
    .I1(bel_o[3]),
    .S(cfg[115]),
    .Z(\u_sm/_096_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_226_  (.A1(bel_o[0]),
    .A2(cfg[113]),
    .Z(\u_sm/_097_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_227_  (.I(cfg[115]),
    .ZN(\u_sm/_098_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_228_  (.A1(\u_sm/_095_ ),
    .A2(\u_sm/_096_ ),
    .B1(\u_sm/_097_ ),
    .B2(\u_sm/_098_ ),
    .ZN(\u_sm/_099_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_229_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[113]),
    .S1(cfg[115]),
    .Z(\u_sm/_100_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_230_  (.A1(cfg[114]),
    .A2(\u_sm/_100_ ),
    .ZN(\u_sm/_101_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_231_  (.A1(cfg[114]),
    .A2(\u_sm/_099_ ),
    .B(\u_sm/_101_ ),
    .ZN(w_out[3]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_232_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[116]),
    .S1(cfg[117]),
    .Z(lut_in[0]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_233_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(s_in[1]),
    .I3(w_in[1]),
    .S0(cfg[118]),
    .S1(cfg[119]),
    .Z(lut_in[1]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_234_  (.I0(n_in[2]),
    .I1(e_in[2]),
    .I2(s_in[2]),
    .I3(w_in[2]),
    .S0(cfg[120]),
    .S1(cfg[121]),
    .Z(lut_in[2]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_235_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(s_in[3]),
    .I3(w_in[3]),
    .S0(cfg[122]),
    .S1(cfg[123]),
    .Z(lut_in[3]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_236_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[124]),
    .S1(cfg[125]),
    .Z(lut_in[4]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_237_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(s_in[1]),
    .I3(w_in[1]),
    .S0(cfg[126]),
    .S1(cfg[127]),
    .Z(lut_in[5]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_238_  (.I(cfg[72]),
    .ZN(\u_sm/_102_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_239_  (.I0(s_in[1]),
    .I1(bel_o[2]),
    .S(cfg[73]),
    .Z(\u_sm/_103_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_240_  (.A1(bel_o[0]),
    .A2(cfg[72]),
    .Z(\u_sm/_104_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_241_  (.I(cfg[73]),
    .ZN(\u_sm/_105_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_242_  (.A1(\u_sm/_102_ ),
    .A2(\u_sm/_103_ ),
    .B1(\u_sm/_104_ ),
    .B2(\u_sm/_105_ ),
    .ZN(\u_sm/_106_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_243_  (.I0(e_in[1]),
    .I1(w_in[1]),
    .I2(bel_o[1]),
    .I3(bel_o[3]),
    .S0(cfg[72]),
    .S1(cfg[73]),
    .Z(\u_sm/_107_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_244_  (.A1(cfg[71]),
    .A2(\u_sm/_107_ ),
    .ZN(\u_sm/_108_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_245_  (.A1(cfg[71]),
    .A2(\u_sm/_106_ ),
    .B(\u_sm/_108_ ),
    .ZN(n_out[1]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_246_  (.I0(n_in[2]),
    .I1(e_in[2]),
    .I2(s_in[2]),
    .I3(w_in[2]),
    .S0(cfg[128]),
    .S1(cfg[129]),
    .Z(lut_in[6]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_247_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(s_in[3]),
    .I3(w_in[3]),
    .S0(cfg[130]),
    .S1(cfg[131]),
    .Z(lut_in[7]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_248_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[132]),
    .S1(cfg[133]),
    .Z(lut_in[8]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_249_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(s_in[1]),
    .I3(w_in[1]),
    .S0(cfg[134]),
    .S1(cfg[135]),
    .Z(lut_in[9]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_250_  (.I0(n_in[2]),
    .I1(e_in[2]),
    .I2(s_in[2]),
    .I3(w_in[2]),
    .S0(cfg[136]),
    .S1(cfg[137]),
    .Z(lut_in[10]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_251_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(s_in[3]),
    .I3(w_in[3]),
    .S0(cfg[138]),
    .S1(cfg[139]),
    .Z(lut_in[11]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_252_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[140]),
    .S1(cfg[141]),
    .Z(lut_in[12]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_253_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(s_in[1]),
    .I3(w_in[1]),
    .S0(cfg[142]),
    .S1(cfg[143]),
    .Z(lut_in[13]));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_254_  (.I(cfg[68]),
    .ZN(\u_sm/_109_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux2_1 \u_sm/_255_  (.I0(w_in[0]),
    .I1(bel_o[3]),
    .S(cfg[70]),
    .Z(\u_sm/_110_ ));
 gf180mcu_fd_sc_mcu7t5v0__and2_1 \u_sm/_256_  (.A1(bel_o[0]),
    .A2(cfg[68]),
    .Z(\u_sm/_111_ ));
 gf180mcu_fd_sc_mcu7t5v0__clkinv_1 \u_sm/_257_  (.I(cfg[70]),
    .ZN(\u_sm/_112_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi22_1 \u_sm/_258_  (.A1(\u_sm/_109_ ),
    .A2(\u_sm/_110_ ),
    .B1(\u_sm/_111_ ),
    .B2(\u_sm/_112_ ),
    .ZN(\u_sm/_113_ ));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_259_  (.I0(e_in[0]),
    .I1(s_in[0]),
    .I2(bel_o[1]),
    .I3(bel_o[2]),
    .S0(cfg[68]),
    .S1(cfg[70]),
    .Z(\u_sm/_114_ ));
 gf180mcu_fd_sc_mcu7t5v0__nor2_1 \u_sm/_260_  (.A1(cfg[69]),
    .A2(\u_sm/_114_ ),
    .ZN(\u_sm/_115_ ));
 gf180mcu_fd_sc_mcu7t5v0__aoi21_1 \u_sm/_261_  (.A1(cfg[69]),
    .A2(\u_sm/_113_ ),
    .B(\u_sm/_115_ ),
    .ZN(n_out[0]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_262_  (.I0(n_in[2]),
    .I1(e_in[2]),
    .I2(s_in[2]),
    .I3(w_in[2]),
    .S0(cfg[144]),
    .S1(cfg[145]),
    .Z(lut_in[14]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_263_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(s_in[3]),
    .I3(w_in[3]),
    .S0(cfg[146]),
    .S1(cfg[147]),
    .Z(lut_in[15]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_264_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[148]),
    .S1(cfg[149]),
    .Z(bel_sr[0]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_265_  (.I0(n_in[0]),
    .I1(e_in[0]),
    .I2(s_in[0]),
    .I3(w_in[0]),
    .S0(cfg[150]),
    .S1(cfg[151]),
    .Z(bel_en[0]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_266_  (.I0(n_in[1]),
    .I1(e_in[1]),
    .I2(s_in[1]),
    .I3(w_in[1]),
    .S0(cfg[152]),
    .S1(cfg[153]),
    .Z(bel_en[1]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_267_  (.I0(n_in[2]),
    .I1(e_in[2]),
    .I2(s_in[2]),
    .I3(w_in[2]),
    .S0(cfg[154]),
    .S1(cfg[155]),
    .Z(bel_en[2]));
 gf180mcu_fd_sc_mcu7t5v0__mux4_1 \u_sm/_268_  (.I0(n_in[3]),
    .I1(e_in[3]),
    .I2(s_in[3]),
    .I3(w_in[3]),
    .S0(cfg[156]),
    .S1(cfg[157]),
    .Z(bel_en[3]));
endmodule
