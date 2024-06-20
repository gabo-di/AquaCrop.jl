module AquaCrop
# ---- imports ----
using ComponentArrays
using TOML


# ---- includes ----
include("types.jl")
include("utils.jl")
include("initialsettings.jl")
include("runsim.jl")
include("FieldCrop.jl")
include("main.jl")

# ---- exports ----
export starttheprogram






end
