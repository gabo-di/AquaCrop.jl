using SafeTestsets

# @safetestset "Initial Settings" begin include("initialsettings_tests.jl") end

@safetestset "Run Part 1" begin include("runpart1_tests.jl") end
