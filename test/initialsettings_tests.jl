using AquaCrop
using Test

include("checkpoints.jl")

@testset "Initialize Settings" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    inse = AquaCrop.initialize_settings(true, true, filepaths)

    ini = checkpoint1()

    @test isapprox(inse[:simulparam], ini[:simulparam])
    @test isapprox(inse[:soil], ini[:soil])
    @test isapprox(inse[:soil_layers], ini[:soil_layers])
    @test isapprox(inse[:compartments], ini[:compartments])
    @test isapprox(inse[:simulation], ini[:simulation])
    @test isapprox(inse[:total_water_content], ini[:total_water_content])
    @test isapprox(inse[:crop], ini[:crop])
    @test isapprox(inse[:management], ini[:management])
    @test isapprox(inse[:sumwabal], ini[:sumwabal])
    @test isapprox(inse[:irri_before_season], ini[:irri_before_season])
    @test isapprox(inse[:irri_after_season], ini[:irri_after_season])
    @test isapprox(inse[:irri_ecw], ini[:irri_ecw])
    @test isapprox(inse[:onset], ini[:onset])
end



@testset "Initialize Project" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    i = 1
    theprojectfile = project_filenames[i]
    theprojecttype = AquaCrop.get_project_type(theprojectfile)
    inse, projectinput, fileok = AquaCrop.initialize_project(i, theprojectfile, theprojecttype, filepaths)


    ini = checkpoint2()
    # this is incorrect in fortran code, they forget to set the temperature in line startuni.f90:864
    # it should be: call SetSimulParam_Tmin(Tmin_temp)
    # ini[:simulparam].Tmin = 0 

    @test isapprox(inse[:simulation], ini[:simulation])
    @test isapprox(inse[:simulparam], ini[:simulparam])
    @test isapprox(fileok, ini[:fileok])
    @test isequal(length(projectinput),length(ini[:projectinput]))
    @test isapprox(projectinput[1], ini[:projectinput][1])
    @test isapprox(projectinput[2], ini[:projectinput][2])
    @test isapprox(projectinput[3], ini[:projectinput][3])
end





