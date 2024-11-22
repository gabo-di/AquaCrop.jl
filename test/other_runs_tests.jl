using AquaCrop
using Test

include("checkpoints.jl")

@testset "Second run initialize" begin
    # break run.f90:RunSimulation:7846
    
    kwargs = (runtype = AquaCrop.NormalFileRun(), )

    outputs, gvars = checkpoint9()

    outputs_0, gvars_0 = checkpoint10()

    i = 2
    AquaCrop.finalize_run1!(outputs, gvars, i; kwargs...)
    AquaCrop.finalize_run2!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_run_part1!(outputs, gvars, i; kwargs...) 
    AquaCrop.initialize_climate!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_run_part2!(outputs, gvars, i; kwargs...)


    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(length(gvars[:array_parameters][:Man]), length(gvars_0[:array_parameters][:Man]))
    @test isapprox(length(gvars[:array_parameters][:DaynrEval]), length(gvars_0[:array_parameters][:DaynrEval]))

    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:onset], gvars_0[:onset])
    @test isapprox(gvars[:rain_record], gvars_0[:rain_record])
    @test isapprox(gvars[:eto_record], gvars_0[:eto_record])
    @test isapprox(gvars[:clim_record], gvars_0[:clim_record])
    @test isapprox(gvars[:temperature_record], gvars_0[:temperature_record])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:total_salt_content], gvars_0[:total_salt_content])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:previoussum], gvars_0[:previoussum])
    @test isapprox(gvars[:irri_info_record1], gvars_0[:irri_info_record1])
    @test isapprox(gvars[:irri_info_record2], gvars_0[:irri_info_record2])
    @test isapprox(gvars[:cut_info_record1], gvars_0[:cut_info_record1])
    @test isapprox(gvars[:cut_info_record2], gvars_0[:cut_info_record2])
    @test isapprox(gvars[:gwtable], gvars_0[:gwtable])
    @test isapprox(gvars[:root_zone_wc], gvars_0[:root_zone_wc])
    @test isapprox(gvars[:root_zone_salt], gvars_0[:root_zone_salt])
    @test isapprox(gvars[:transfer], gvars_0[:transfer])
    @test isapprox(gvars[:plotvarcrop], gvars_0[:plotvarcrop])
    @test isapprox(gvars[:perennial_period], gvars_0[:perennial_period])
    @test isapprox(gvars[:crop_file_set], gvars_0[:crop_file_set])
end

@testset "Second run finalize" begin
    # break run.f90:RunSimulation:7847
    
    kwargs = (runtype = AquaCrop.NormalFileRun(), )

    outputs, gvars = checkpoint10()

    outputs_0, gvars_0 = checkpoint11()

    i = 2
    AquaCrop.file_management!(outputs, gvars, i; kwargs...)


    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(length(gvars[:array_parameters][:Man]), length(gvars_0[:array_parameters][:Man]))
    @test isapprox(length(gvars[:array_parameters][:DaynrEval]), length(gvars_0[:array_parameters][:DaynrEval]))

    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content]; atol=1e-10)
    @test isapprox(gvars[:total_salt_content], gvars_0[:total_salt_content])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot]; atol=1e-10)
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:previoussum], gvars_0[:previoussum])
    @test isapprox(gvars[:irri_info_record1], gvars_0[:irri_info_record1])
    @test isapprox(gvars[:irri_info_record2], gvars_0[:irri_info_record2])
    @test isapprox(gvars[:cut_info_record1], gvars_0[:cut_info_record1])
    @test isapprox(gvars[:cut_info_record2], gvars_0[:cut_info_record2])
    @test isapprox(gvars[:gwtable], gvars_0[:gwtable])
    @test isapprox(gvars[:root_zone_wc], gvars_0[:root_zone_wc])
    @test isapprox(gvars[:root_zone_salt], gvars_0[:root_zone_salt])
    @test isapprox(gvars[:transfer], gvars_0[:transfer])
    @test isapprox(gvars[:plotvarcrop], gvars_0[:plotvarcrop])
end

@testset "Third run finalize" begin
    # break run.f90:RunSimulation:7847
    
    kwargs = (runtype = AquaCrop.NormalFileRun(), )

    outputs, gvars = checkpoint11()

    outputs_0, gvars_0 = checkpoint12()

    i = 3
    AquaCrop.finalize_run1!(outputs, gvars, i; kwargs...)
    AquaCrop.finalize_run2!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_run_part1!(outputs, gvars, i; kwargs...) 
    AquaCrop.initialize_climate!(outputs, gvars, i; kwargs...)
    AquaCrop.initialize_run_part2!(outputs, gvars, i; kwargs...)
    AquaCrop.file_management!(outputs, gvars, i; kwargs...)


    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])
    @test isapprox(length(gvars[:array_parameters][:Man]), length(gvars_0[:array_parameters][:Man]))
    @test isapprox(length(gvars[:array_parameters][:DaynrEval]), length(gvars_0[:array_parameters][:DaynrEval]))

    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:simulparam], gvars_0[:simulparam])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:management], gvars_0[:management])
    @test isapprox(gvars[:onset], gvars_0[:onset])
    @test isapprox(gvars[:rain_record], gvars_0[:rain_record])
    @test isapprox(gvars[:eto_record], gvars_0[:eto_record])
    @test isapprox(gvars[:clim_record], gvars_0[:clim_record])
    @test isapprox(gvars[:temperature_record], gvars_0[:temperature_record])
    @test isapprox(gvars[:total_water_content], gvars_0[:total_water_content])
    @test isapprox(gvars[:total_salt_content], gvars_0[:total_salt_content])
    @test isapprox(gvars[:stresstot], gvars_0[:stresstot])
    @test isapprox(gvars[:sumwabal], gvars_0[:sumwabal])
    @test isapprox(gvars[:previoussum], gvars_0[:previoussum])
    @test isapprox(gvars[:irri_info_record1], gvars_0[:irri_info_record1])
    @test isapprox(gvars[:irri_info_record2], gvars_0[:irri_info_record2])
    @test isapprox(gvars[:cut_info_record1], gvars_0[:cut_info_record1])
    @test isapprox(gvars[:cut_info_record2], gvars_0[:cut_info_record2])
    @test isapprox(gvars[:gwtable], gvars_0[:gwtable])
    @test isapprox(gvars[:root_zone_wc], gvars_0[:root_zone_wc])
    @test isapprox(gvars[:root_zone_salt], gvars_0[:root_zone_salt])
    @test isapprox(gvars[:transfer], gvars_0[:transfer])
    @test isapprox(gvars[:plotvarcrop], gvars_0[:plotvarcrop])
    @test isapprox(gvars[:perennial_period], gvars_0[:perennial_period])
    @test isapprox(gvars[:crop_file_set], gvars_0[:crop_file_set])
end
