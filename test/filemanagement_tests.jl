using AquaCrop
using Test

include("checkpoints.jl")

@testset "Filemanagement" begin

    kwargs = (runtype = AquaCrop.FortranRun(), )

    outputs, gvars, projectinput = checkpoint5()

    outputs_0, gvars_0, _ = checkpoint6()

    i = 1
    AquaCrop.file_management!(outputs, gvars, projectinput[i]; kwargs...)

    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])

end
