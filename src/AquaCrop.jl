module AquaCrop
# ---- imports ----
using ComponentArrays


# ---- includes ----
include("types.jl")
include("initialsettings.jl")
include("FieldCrop.jl")
include("main.jl")

# ---- exports ----
export starttheprogram

end
