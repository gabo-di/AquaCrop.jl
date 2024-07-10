using AquaCrop
using Test

include("checkpoints.jl")

@testset "Initialize Settings" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    gvars = AquaCrop.initialize_settings(true, true, filepaths)

    gvars_0 = checkpoint1()

    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:irri_before_season], gvars_0[:irri_before_season])
    @test isapprox(gvars[:irri_after_season], gvars_0[:irri_after_season])
    @test isapprox(gvars[:irri_ecw], gvars_0[:irri_ecw])
    @test isapprox(gvars[:onset], gvars_0[:onset])
end



@testset "Initialize Project" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    i = 1
    theprojectfile = project_filenames[i]
    theprojecttype = AquaCrop.get_project_type(theprojectfile)
    gvars, projectinput, fileok = AquaCrop.initialize_project(i, theprojectfile, theprojecttype, filepaths)


    gvars_0, projectinput_0, fileok_0 = checkpoint2()

    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(fileok, fileok_0)
    @test isequal(length(projectinput),length(projectinput_0))
    @test isapprox(projectinput[1], projectinput_0[1]) 
    @test isapprox(projectinput[2], projectinput_0[2]) 
    @test isapprox(projectinput[3], projectinput_0[3]) 
end





