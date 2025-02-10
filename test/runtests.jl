using SafeTestsets

# @safetestset "Initial Settings" begin include("initialsettings_tests.jl") end
#
# @safetestset "Initialize Run Part 1" begin include("initialize_runpart1_tests.jl") end
#
# @safetestset "TOML Integration" begin include("readtoml_tests.jl") end
#
# @safetestset "Initialize Run Part 2" begin include("initialize_runpart2_tests.jl") end
#
# @safetestset "Filemanagement" begin include("filemanagement_tests.jl") end
#
# @safetestset "Other Runs" begin include("other_runs_tests.jl") end
#
# @safetestset "API" begin include("api_tests.jl") end
#
# @safetestset "API advanced" begin include("api_advanced_tests.jl") end

@safetestset "Extended Test Project 1" begin include("./extended_test/project_1.jl") end

@safetestset "Extended Test Project 2" begin include("./extended_test/project_2.jl") end
