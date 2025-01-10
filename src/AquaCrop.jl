module AquaCrop
# ---- imports ----
using TOML
using DataFrames
using Unitful: Quantity, FreeUnits, Unit, 𝐋, 𝚯, 𝐓, 𝐈, 𝐌, NoDims
using Unitful
using Dates
using CSV


# ---- includes ----
include("types.jl")
include("utils.jl")
include("outputs.jl")
include("loadvardict.jl")
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
export AquaCropField,
       NormalFileRun,
       TomlFileRun,
       NoFileRun,
       basic_run,
       canopycover,
       biomass,
       dryyield,
       freshyield,
       harvest!,
       dailyupdate!,
       season_run!,
       start_cropfield,
       setup_cropfield!,
       change_climate_data!,
       isharvestable,
       timetoharvest,
       write_out_csv
end

