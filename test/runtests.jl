using SafeTestsets

@safetestset "Initial Settings" begin include("initialsettings_tests.jl") end

@safetestset "Run Part 1" begin include("runpart1_tests.jl") end

@safetestset "TOML Integration" begin include("readtoml_tests.jl") end

@safetestset "Run Part 2" begin include("runpart2_tests.jl") end

@safetestset "Filemanagement" begin include("filemanagement_tests.jl") end

@safetestset "Second Run" begin include("secondrun_tests.jl") end
