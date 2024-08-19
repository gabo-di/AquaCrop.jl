module AquaCrop
# ---- imports ----
using ComponentArrays
using TOML
using DataFrames
using Unitful: Quantity, FreeUnits, 𝐋, 𝚯, 𝐓, 𝐈, 𝐌, NoDims
using Unitful: g, kg, d, K, mm, ha, m, ppm, dS 
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
include("FieldCrop.jl")
include("main.jl")

# ---- exports ----
export start_the_program






end
