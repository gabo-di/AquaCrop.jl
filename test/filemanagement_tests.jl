using AquaCrop
using Test

include("checkpoints.jl")

@testset "Advance one time step" begin
    # break run.f90:7772
    
    kwargs = (runtype = AquaCrop.FortranRun(), )

    outputs, gvars, projectinput = checkpoint5()

    outputs_0, gvars_0, _ = checkpoint6()

    i = 1
    float_parameters = AquaCrop.ParametersContainer(Float64)
    AquaCrop.setparameter!(float_parameters, :wpi,  0.0) #here
    AquaCrop.setparameter!(float_parameters, :preirri,  0.0) #advance_one_time_step
    AquaCrop.setparameter!(float_parameters, :fracassim, 0.0) #advance_one_time_step
    AquaCrop.setparameter!(float_parameters, :ecinfilt, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :horizontalwaterflow, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :horizontalsaltflow, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :subdrain, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :infiltratedrain, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :infiltratedirrigation, 0.0) #budget_module
    AquaCrop.setparameter!(float_parameters, :infiltratedstorage, 0.0) #budget_module

    integer_parameters = AquaCrop.ParametersContainer(Int)
    AquaCrop.setparameter!(integer_parameters, :targettimeval, 0) #advance_one_time_step
    AquaCrop.setparameter!(integer_parameters, :targetdepthval, 0) #advance_one_time_step

    bool_parameters = AquaCrop.ParametersContainer(Bool)
    AquaCrop.setparameter!(bool_parameters, :harvestnow, false) #here

    lvars = ComponentArray(
        float_parameters = float_parameters,
        bool_parameters = bool_parameters,
        integer_parameters = integer_parameters
    )
    repeattoday = gvars[:simulation].ToDayNr
    AquaCrop.advance_one_time_step!(outputs, gvars, lvars, projectinput[i])

    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])

    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:management], gvars_0[:management])
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
end

@testset "Filemanagement Complete" begin
    # break run.f90:7800

    kwargs = (runtype = AquaCrop.FortranRun(), )

    outputs, gvars, projectinput = checkpoint5()

    outputs_0, gvars_0, _ = checkpoint7()

    i = 1
    AquaCrop.file_management!(outputs, gvars, projectinput[i]; kwargs...)

    @test isapprox(gvars[:integer_parameters], gvars_0[:integer_parameters])
    @test isapprox(gvars[:bool_parameters], gvars_0[:bool_parameters])
    @test isapprox(gvars[:float_parameters], gvars_0[:float_parameters])

    @test isapprox(gvars[:crop], gvars_0[:crop])
    @test isapprox(gvars[:simulation], gvars_0[:simulation])
    @test isapprox(gvars[:soil], gvars_0[:soil])
    @test isapprox(gvars[:soil_layers], gvars_0[:soil_layers])
    @test isapprox(gvars[:compartments], gvars_0[:compartments])
    @test isapprox(gvars[:management], gvars_0[:management])
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
end
