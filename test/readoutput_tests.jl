using AquaCrop
using Test
using DataFrames

@testset "read_orig_ac_output_dayout" begin
    # 4 lines of header, 4 lines of data
    input = """AquaCrop 7.2 (August 2024) - Output created on (date) : 05-02-2025   at (time) : 18:53:58

   Day Month  Year   DAP Stage   WC(2.30)   Rain     Irri   Surf   Infilt   RO    Drain       CR    Zgwt       Ex       E     E/Ex     Trx       Tr  Tr/Trx    ETx      ET  ET/ETx      GD       Z     StExp  StSto  StSen StSalt StWeed   CC      CCw     StTr  Kc(Tr)     Trx       Tr      TrW  Tr/Trx   WP    Biomass     HI    Y(dry)  Y(fresh)  Brelative    WPet      Bin     Bout  WC(2.30) Wr(2.30)     Z       Wr    Wr(SAT)    Wr(FC)   Wr(exp)   Wr(sto)   Wr(sen)   Wr(PWP)    SaltIn    SaltOut   SaltUp   Salt(2.30)  SaltZ     Z       ECe    ECsw   StSalt  Zgwt    ECgw       WC01       WC 2       WC 3       WC 4       WC 5       WC 6       WC 7       WC 8       WC 9       WC10       WC11       WC12      ECe01      ECe 2      ECe 3      ECe 4      ECe 5      ECe 6      ECe 7      ECe 8      ECe 9      ECe10      ECe11      ECe12     Rain       ETo      Tmin      Tavg      Tmax      CO2
                                      mm      mm       mm     mm     mm     mm       mm       mm      m        mm       mm     %        mm       mm    %        mm      mm       %  degC-day     m       %      %      %      %      %      %       %       %       -        mm       mm       mm    %     g/m2    ton/ha      %    ton/ha   ton/ha       %       kg/m3   ton/ha   ton/ha      mm       mm       m       mm        mm        mm        mm        mm        mm         mm    ton/ha    ton/ha    ton/ha    ton/ha    ton/ha     m      dS/m    dS/m      %     m      dS/m       0.05       0.18       0.33       0.48       0.63       0.80       1.00       1.20       1.43       1.68       1.93       2.18       0.05       0.18       0.33       0.48       0.63       0.80       1.00       1.20       1.43       1.68       1.93       2.18       mm        mm     degC      degC      degC       ppm
    22     4  2015    -9     0     712.5     1.1      0.0    0.0    1.1    0.0      0.0      0.0   -9.90      1.7      1.6     99      0.0      0.0   100      1.7     1.6      99      0.0    0.00     -9     -9     -9     -9     -9     0.0     0.0      0    -9.00      0.0      0.0      0.0   100     0.0     0.000    -9.9    0.000    0.000      -9        0.00    0.000    0.000     712.5     -9.9    0.00    -9.9      -9.9      -9.9      -9.9      -9.9      -9.9      -9.9    0.000     0.000     0.000     0.000    -9.000    0.00    -9.00   -9.00      0   -9.90   -9.00       30.5       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0      1.1       1.5       0.1       5.6      11.1    402.72
    23     4  2015    -9     0     710.1     0.0      0.0    0.0    0.0    0.0      0.0      0.0   -9.90      2.9      2.3     81      0.0      0.0   100      2.9     2.3      81      0.0    0.00     -9     -9     -9     -9     -9     0.0     0.0      0    -9.00      0.0      0.0      0.0   100     0.0     0.000    -9.9    0.000    0.000      -9        0.00    0.000    0.000     710.1     -9.9    0.00    -9.9      -9.9      -9.9      -9.9      -9.9      -9.9      -9.9    0.000     0.000     0.000     0.000    -9.000    0.00    -9.00   -9.00      0   -9.90   -9.00       28.1       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0      0.0       2.6      -1.5       8.0      17.5    402.72
    24     4  2015    -9     0     707.6     0.0      0.0    0.0    0.0    0.0      0.0      0.0   -9.90      4.2      2.6     61      0.0      0.0   100      4.2     2.6      61      3.1    0.00     -9     -9     -9     -9     -9     0.0     0.0      0    -9.00      0.0      0.0      0.0   100     0.0     0.000    -9.9    0.000    0.000      -9        0.00    0.000    0.000     707.6     -9.9    0.00    -9.9      -9.9      -9.9      -9.9      -9.9      -9.9      -9.9    0.000     0.000     0.000     0.000    -9.000    0.00    -9.00   -9.00      0   -9.90   -9.00       25.6       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0      0.0       3.8       0.6      11.1      21.5    402.72
    25     4  2015    -9     0     706.1     0.0      0.0    0.0    0.0    0.0      0.0      0.0   -9.90      3.0      1.4     48      0.0      0.0   100      3.0     1.4      48      4.7    0.00     -9     -9     -9     -9     -9     0.0     0.0      0    -9.00      0.0      0.0      0.0   100     0.0     0.000    -9.9    0.000    0.000      -9        0.00    0.000    0.000     706.1     -9.9    0.00    -9.9      -9.9      -9.9      -9.9      -9.9      -9.9      -9.9    0.000     0.000     0.000     0.000    -9.000    0.00    -9.00   -9.00      0   -9.90   -9.00       24.1       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0       31.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0        0.0      0.0       2.7       4.8      12.7      20.6    402.72"""

    # test reading from IO
    df = AquaCrop.read_orig_ac_output_dayout(IOBuffer(input))
    @test ncol(df) == 98
    @test nrow(df) == 4

    # test reading from file
    mktemp() do path, io
        write(io, input)
        flush(io)
        df = AquaCrop.read_orig_ac_output_dayout(path)
        @test ncol(df) == 98
        @test nrow(df) == 4
    end

    # test errors
    @test_throws ArgumentError AquaCrop.read_orig_ac_output_dayout(IOBuffer(""))
    @test_throws ArgumentError AquaCrop.read_orig_ac_output_dayout(IOBuffer("AquaCrop 7.0\n\n\n\n"))
    @test_throws ArgumentError AquaCrop.read_orig_ac_output_dayout(IOBuffer("AquaCrop 7.2\nNOTEMPTY\n\n\n"))
    @test_throws ArgumentError AquaCrop.read_orig_ac_output_dayout(IOBuffer("AquaCrop 7.2\n\nA B\n\n"))
    @test_throws ArgumentError AquaCrop.read_orig_ac_output_dayout(IOBuffer("AquaCrop 7.2\n\nA B\nA B\n"))
end
