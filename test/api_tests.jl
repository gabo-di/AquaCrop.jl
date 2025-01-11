using AquaCrop
using Test

@testset "Basic run" begin
    # basic run with NormalFileRun
    runtype = NormalFileRun()
    parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
    outputs = basic_run(; runtype=runtype, parentdir=parentdir)
    @test isequal(size(outputs[:dayout]), (892, 89))

    # basic run with TomlFileRun 
    runtype = TomlFileRun()
    parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"
    outputs = basic_run(; runtype=runtype, parentdir=parentdir)
    @test isequal(size(outputs[:dayout]), (892, 89))

    # basic run with no runtype 
    parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
    outputs = basic_run(; parentdir=parentdir)
    @test isequal(size(outputs[:dayout]), (892, 89))
    @test isequal(outputs[:logger][1], "using default NormalFileRun")

    # basic run with no parentdir, bad directory so no result
    runtype = TomlFileRun()
    outputs = basic_run(; runtype=runtype) 
    @test isequal(size(outputs[:dayout]), (0, 89))
    @test isequal(outputs[:logger][2], "using default parentdir pwd()")
end

@testset "Start cropfield intermediate" begin
    # good start of cropfield using NormalFileRun 
    runtype = NormalFileRun()
    parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    @test isequal(all_ok.logi, true)

    # good start of cropfield using TomlFileRun
    runtype = TomlFileRun()
    parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    @test isequal(all_ok.logi, true)

    # good start of cropfield not using runtype
    parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
    cropfield, all_ok = start_cropfield(; parentdir=parentdir)
    @test isequal(all_ok.logi, true)

    # missing observables
    # @test ismissing(biomass(cropfield))
    # @test ismissing(canopycover(cropfield))
    # @test ismissing(freshyield(cropfield))
    # @test ismissing(dryyield(cropfield))

    # observables start with 0 value
    @test isapprox( biomass(cropfield).val, 0.0 )
    @test isapprox( canopycover(cropfield), 0.0 )
    @test isapprox( freshyield(cropfield).val, 0.0 )
    @test isapprox( dryyield(cropfield).val, 0.0 )


    # bad start giving wrong runtype 
    runtype = :TomlFileRun  # or other thing
    parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    @test isequal(all_ok.logi, false)
    @test isequal(all_ok.msg, "invalid runtype "*string(runtype))

    # bad start giving not real parentdir 
    runtype = TomlFileRun()  
    parentdir = "/Not/real/directory" 
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    @test isequal(all_ok.logi, false)
    @test isequal(all_ok.msg, "invalid parentdir")

    # bad start giving real parentdir but with bad  data
    runtype = TomlFileRun()  
    parentdir = pwd() 
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    @test isequal(all_ok.logi, false)
    @test isequal(all_ok.msg, "no project loaded")

    # we can also have "bad projecttype", "did not find the projectfile", "wrong files for project nrrun"
end

# @testset "Setup cropfield intermediate" begin
#     # good setup of cropfield using NormalFileRun 
#     runtype = NormalFileRun()
#     parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
#     cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
#     @test isequal(all_ok.logi, true)
#
#     # good setup of cropfield using TomlFileRun
#     runtype = TomlFileRun()
#     parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"
#     cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
#     @test isequal(all_ok.logi, true)
#
#     # good setup of cropfield not using runtype
#     parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
#     cropfield, all_ok = start_cropfield(; parentdir=parentdir)
#     @test isequal(all_ok.logi, true)
#
#     # observables start with 0 value
#     @test isapprox( biomass(cropfield).val, 0.0 )
#     @test isapprox( canopycover(cropfield), 0.0 )
#     @test isapprox( freshyield(cropfield).val, 0.0 )
#     @test isapprox( dryyield(cropfield).val, 0.0 )
#
#     # we can have "error when settingup the cropfield"
# end

@testset "Update cropfield intermediate" begin
    # good update of cropfield using NormalFileRun 
    runtype = NormalFileRun()
    parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    ndays = 30
    for _ in 1:ndays
        dailyupdate!(cropfield)
    end
    @test isequal(size(cropfield.dayout), (ndays, 89))
    harvest!(cropfield)
    @test isequal(size(cropfield.dayout), (ndays+1, 89))
    @test isequal(size(cropfield.harvestsout), (2, 11))
    season_run!(cropfield)
    @test isequal(size(cropfield.dayout), (164, 89))



    # good update of cropfield using TomlFileRun
    runtype = TomlFileRun()
    parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"
    cropfield, all_ok = start_cropfield(; runtype=runtype, parentdir=parentdir)
    ndays = 30
    for _ in 1:ndays
        dailyupdate!(cropfield)
    end
    @test isequal(size(cropfield.dayout), (ndays, 89))
    harvest!(cropfield)
    @test isequal(size(cropfield.dayout), (ndays+1, 89))
    @test isequal(size(cropfield.harvestsout), (2, 11))
    season_run!(cropfield)
    @test isequal(size(cropfield.dayout), (164, 89))
end

@testset "AquaCropField utility functions" begin
    cropfield = AquaCropField(Dict(:foo => "bar"), Dict(), Dict(), [AquaCrop.StartCropField()])
    @test propertynames(cropfield) isa Tuple
    @test all(x -> x isa Symbol, propertynames(cropfield))
end
