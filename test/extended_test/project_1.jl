using AquaCrop
using Test

include("checkpoints.jl")

@testset "Initialize Project 1" begin
    parentdir = pwd()*"/extended_test/fortranrun"
    outputs = AquaCrop.start_outputs()

    kwargs = (runtype = AquaCrop.NormalFileRun(),)

    filepaths = AquaCrop.initialize_the_program(outputs, parentdir; kwargs...)
    project_filenames = AquaCrop.initialize_project_filenames(outputs, filepaths; kwargs...)
    i = 1
    theprojectfile = project_filenames[i]
    theprojecttype = AquaCrop.get_project_type(theprojectfile; kwargs...)
    gvars, _ = AquaCrop.initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)


    gvars_0 = checkpoint_project1_2()

    projectinput = gvars[:projectinput]
    projectinput_0 = gvars_0[:projectinput]

    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:irri_before_season], gvars_0[:irri_before_season])
    @test isapprox(gvars[:irri_after_season], gvars_0[:irri_after_season])
    @test isapprox(gvars[:irri_ecw], gvars_0[:irri_ecw])
    @test isapprox(gvars[:onset], gvars_0[:onset])
    @test isequal(length(projectinput),length(projectinput_0))
    @test isapprox(projectinput[1], projectinput_0[1]) 
end


@testset "Initialize Run Project 1" begin

    kwargs = (runtype = AquaCrop.NormalFileRun(), )
    outputs = AquaCrop.start_outputs()

    gvars = checkpoint_project1_2()

    outputs_0, gvars_0 = checkpoint_project1_3()

    i = 1
    AquaCrop.initialize_run_part1!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_climate!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_run_part2!(outputs, gvars, i; kwargs...)

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
    # @test isapprox(gvars[:string_parameters], gvars_0[:string_parameters])
    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot])
    @test isapprox(gvars[:cut_info_record1], gvars_0[:cut_info_record1])
    @test isapprox(gvars[:cut_info_record2], gvars_0[:cut_info_record2])
    @test isapprox(gvars[:root_zone_salt], gvars_0[:root_zone_salt])
    @test isapprox(gvars[:root_zone_wc], gvars_0[:root_zone_wc])
    @test isapprox(gvars[:total_salt_content], gvars_0[:total_salt_content])
end
