using AquaCrop
using Test

include("checkpoints.jl")

@testset "Load Simulation Run Project" begin
    outputs = AquaCrop.start_outputs()

    kwargs = (runtype = AquaCrop.NormalFileRun(),)

    gvars = checkpoint2()

    gvars_0 = checkpoint3()

    i = 1
    AquaCrop.load_simulation_project!(outputs, gvars, gvars[:projectinput][i]; kwargs...)
     

    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:previoussum], gvars_0[:previoussum])
    @test isapprox(gvars[:irri_before_season], gvars_0[:irri_before_season])
    @test isapprox(gvars[:irri_after_season], gvars_0[:irri_after_season])
    @test isapprox(gvars[:irri_ecw], gvars_0[:irri_ecw])
    @test isapprox(gvars[:onset], gvars_0[:onset])
    @test isapprox(gvars[:rain_record], gvars_0[:rain_record])
    @test isapprox(gvars[:eto_record], gvars_0[:eto_record])
    @test isapprox(gvars[:clim_record], gvars_0[:clim_record])
    @test isapprox(gvars[:temperature_record], gvars_0[:temperature_record])
    @test isapprox(gvars[:perennial_period], gvars_0[:perennial_period])
    @test isapprox(gvars[:crop_file_set], gvars_0[:crop_file_set])
    @test isapprox(gvars[:string_parameters], gvars_0[:string_parameters])
    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])

    # @test isapprox(gvars[:array_parameters][:Tmax], gvars_0[:array_parameters][:Tmax])
    # @test isapprox(gvars[:array_parameters][:Tmin], gvars_0[:array_parameters][:Tmin])
end

@testset "Initialize Run Part 1" begin
    outputs = AquaCrop.start_outputs()

    kwargs = (runtype = AquaCrop.NormalFileRun(),)

    gvars = checkpoint2()

    outputs_0, gvars_0 = checkpoint4()
    
    i = 1
    # AquaCrop.adjust_compartments!(gvars)
    # gvars[:sumwabal] = AquaCrop.RepSum()
    # AquaCrop.reset_previous_sum!(gvars)
    AquaCrop.initialize_run_part1!(outputs, gvars, i; kwargs...)


    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot])
    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(outputs[:tcropsim], outputs_0[:tcropsim])

end
