module AquaCrop
# ---- imports ----
using ComponentArrays
using TOML
using DataFrames
using Unitful: Quantity, FreeUnits, Unit, 𝐋, 𝚯, 𝐓, 𝐈, 𝐌, NoDims
using Unitful
using Dates


# ---- includes ----
include("types.jl")
include("utils.jl")
include("outputs.jl")
include("readtoml.jl")
include("initialsettings.jl")
include("loadsimulation.jl")
include("initialize_runpart1.jl")
include("initialize_runpart2.jl")
include("filemanagement.jl")
include("budget.jl")
include("startunit.jl")
include("api.jl")

# ---- exports ----
export aquacrop_basic_run 






end
