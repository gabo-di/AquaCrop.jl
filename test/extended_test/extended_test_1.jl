using AquaCrop
using Test

include("checkpoints.jl")

@testset "Basic run" begin
    parentdir = pwd()*"/testcase"
    outputs = AquaCrop.start_outputs()

    kwargs = (runtype = AquaCrop.NormalFileRun(),)

    filepaths = AquaCrop.initialize_the_program(outputs, parentdir; kwargs...)
    project_filenames = AquaCrop.initialize_project_filenames(outputs, filepaths; kwargs...)
    gvars = AquaCrop.initialize_settings(outputs, filepaths; kwargs...)

    gvars_0 = checkpoint1()

    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
end
