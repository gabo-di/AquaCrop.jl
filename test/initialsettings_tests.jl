using AquaCrop
using Test

include("checkpoints.jl")

@testset "Initialize Settings" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    inse = AquaCrop.initialize_settings(true, true, filepaths)

    inse_0 = checkpoint1()

    @test isapprox(inse[:simulparam], inse_0[:simulparam])
    @test isapprox(inse[:soil], inse_0[:soil])
    @test isapprox(inse[:soil_layers], inse_0[:soil_layers])
    @test isapprox(inse[:compartments], inse_0[:compartments])
    @test isapprox(inse[:simulation], inse_0[:simulation])
    @test isapprox(inse[:total_water_content], inse_0[:total_water_content])
    @test isapprox(inse[:crop], inse_0[:crop])
    @test isapprox(inse[:management], inse_0[:management])
    @test isapprox(inse[:sumwabal], inse_0[:sumwabal])
    @test isapprox(inse[:irri_before_season], inse_0[:irri_before_season])
    @test isapprox(inse[:irri_after_season], inse_0[:irri_after_season])
    @test isapprox(inse[:irri_ecw], inse_0[:irri_ecw])
    @test isapprox(inse[:onset], inse_0[:onset])
end



@testset "Initialize Project" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    i = 1
    theprojectfile = project_filenames[i]
    theprojecttype = AquaCrop.get_project_type(theprojectfile)
    inse, projectinput, fileok = AquaCrop.initialize_project(i, theprojectfile, theprojecttype, filepaths)


    inse_0, projectinput_0, fileok_0 = checkpoint2()

    @test isapprox(inse[:simulation], inse_0[:simulation])
    @test isapprox(inse[:simulparam], inse_0[:simulparam])
    @test isapprox(fileok, fileok_0)
    @test isequal(length(projectinput),length(projectinput_0))
    @test isapprox(projectinput[1], projectinput_0[1]) 
    @test isapprox(projectinput[2], projectinput_0[2]) 
    @test isapprox(projectinput[3], projectinput_0[3]) 
end





