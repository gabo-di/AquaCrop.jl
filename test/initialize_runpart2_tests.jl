using AquaCrop
using Test

include("checkpoints.jl")

@testset "Initialize Run Part 2" begin

    kwargs = (runtype = AquaCrop.FortranRun(), )

    outputs, gvars, projectinput = checkpoint4()

    outputs_0, gvars_0, _ = checkpoint5()

    i = 1
    AquaCrop.initialize_climate!(outputs, gvars; kwargs...)
    AquaCrop.initialize_run_part2!(outputs, gvars, projectinput[i], i; kwargs...)

    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot])
    @test isapprox(gvars[:cut_info_record1], gvars_0[:cut_info_record1])
    @test isapprox(gvars[:cut_info_record2], gvars_0[:cut_info_record2])
    @test isapprox(gvars[:root_zone_salt], gvars_0[:root_zone_salt])

    @test isapprox(gvars[:root_zone_wc], gvars_0[:root_zone_wc])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:total_salt_content], gvars_0[:total_salt_content])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])

end
