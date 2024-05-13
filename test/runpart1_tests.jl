using AquaCrop
using Test

include("checkpoints.jl")

@testset "Load Simulation Run Project" begin
    inse, projectinput, fileok = checkpoint2()

    inse_0 = checkpoint3()

    i = 1
    AquaCrop.load_simulation_project!(inse, projectinput[i])
     

    @test isapprox(inse[:simulparam], inse_0[:simulparam])
    @test isapprox(inse[:soil], inse_0[:soil])
    @test isapprox(inse[:soil_layers], inse_0[:soil_layers])
    @test isapprox(inse[:compartments], inse_0[:compartments])
    @test isapprox(inse[:simulation], inse_0[:simulation])
    @test isapprox(inse[:total_water_content], inse_0[:total_water_content])
    @test isapprox(inse[:crop], inse_0[:crop])
    @test isapprox(inse[:management], inse_0[:management])
    @test isapprox(inse[:sumwabal], inse_0[:sumwabal])
    @test isapprox(inse[:previoussum], inse_0[:previoussum])
    @test isapprox(inse[:irri_before_season], inse_0[:irri_before_season])
    @test isapprox(inse[:irri_after_season], inse_0[:irri_after_season])
    @test isapprox(inse[:irri_ecw], inse_0[:irri_ecw])
    @test isapprox(inse[:onset], inse_0[:onset])
    @test isapprox(inse[:rain_record], inse_0[:rain_record])
    @test isapprox(inse[:eto_record], inse_0[:eto_record])
    @test isapprox(inse[:temperature_record], inse_0[:temperature_record])
    @test isapprox(inse[:perennial_period], inse_0[:perennial_period])
    @test isapprox(inse[:crop_file_set], inse_0[:crop_file_set])
    @test isapprox(inse[:array_parameters][:Tmax], inse_0[:array_parameters][:Tmax])
    @test isapprox(inse[:array_parameters][:Tmin], inse_0[:array_parameters][:Tmin])
    
end


