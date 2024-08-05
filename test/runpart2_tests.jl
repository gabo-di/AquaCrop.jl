using AquaCrop
using Test

include("checkpoints.jl")

@testset "Simulation Run Part 2" begin

    kwargs = (runtype = AquaCrop.FortranRun(), )

    outputs, gvars, projectinput = checkpoint4()

    outputs_0, gvars_0, _ = checkpoint5()

    i = 1
    AquaCrop.initialize_climate!(outputs, gvars; kwargs...)
    AquaCrop.initialize_run_part2(outputs, gvars, projectinput[i]; kwargs...)

    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])

end
