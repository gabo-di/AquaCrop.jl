module AquaCrop
# ---- imports ----
using ComponentArrays
using TOML


# ---- includes ----
include("types.jl")
include("utils.jl")
include("outputs.jl")
include("read_toml.jl")
include("initialsettings.jl")
include("loadsimulation.jl")
include("runsim.jl")
include("FieldCrop.jl")
include("main.jl")

# ---- exports ----
export start_the_program






end
