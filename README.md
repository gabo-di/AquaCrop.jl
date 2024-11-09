# AquaCrop.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gabo-di.github.io/AquaCrop.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gabo-di.github.io/AquaCrop.jl/dev/)
[![Build Status](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml?query=branch%3Amain)

Welcome to `AquaCrop.jl`! This package is a julia implementation of FAO's [AquaCrop](https://github.com/KUL-RSDA/AquaCrop/), 
originaly written in Fortran, currently corresponds to AquaCrop version 7.1, older or newer version can have 
compatibility issues

## Install

Since the package is not yet registered, you can install it via

```julia
using Pkg
Pkg.add(url="https://github.com/gabo-di/AquaCrop.jl")
```


## Basic Run

For the basic run, first you need to specify the directory where that has all the 
required input for a common AquaCrop Fortran run and call the `basic_run` function

```julia
using AquaCrop

runtype = NormalFileRun()
parentdir = AquaCrop.test_dir  #".../AquaCrop.jl/test/testcase"

outputs = basic_run(; runtype=runtype, parentdir=parentdir)

isequal(size(outputs[:dayout]), (892, 89)) # true
```

you can see the daily result in `outputs[:dayout]` 
the result of each harvest in `outputs[:harvestsout]`
the result of the whole season in `outputs[:seasonout]`
the information for the evaluation in `outputs[:evaldataout]`
and the logger information in `outputs[:logger]`

If you prefer to use TOML and csv files as input, you can choose to run like
```julia
runtype = TomlFileRun()
parentdir = AquaCrop.test_toml_dir  #".../AquaCrop.jl/test/testcase/TOML_FILES"

outputs = basic_run(; runtype=runtype, parentdir=parentdir)

isequal(size(outputs[:dayout]), (892, 89)) # true
```


## Intermediate Run

To start a crop field you have to provide the runtype and the directory data 

```julia
using AquaCrop

runtype = TomlFileRun()
parentdir = AquaCrop.test_toml_dir #".../AquaCrop/test/testcase/TOML_FILES"

cropfield, all_ok = start_cropfield(;runtype=runtype, parentdir=parentdir)

dump(all_ok)
```

where `cropfield` is an struct of type `AquaCropField` with all the information of 
the crop field, and `all_ok` tell us if the paramers have been loaded correctly 
`all_ok.logi == true` or not `all_ok.logi == false`, in this case you can see 
the error kind in `all_ok.msg`. (Note that we do not raise exceptions in case you
want to inspect the `cropfield` variable, like `cropfield.outputs[:logger]`) 

To setup a cropfield you have to provide the runtype 
```julia
setup_cropfield!(cropfield, all_ok; runtype=runtype)

dump(all_ok)
```



To make a daily update you can use
```julia
ndays = 30
for _ in 1:ndays
    dailyupdate!(cropfield)
end

isequal(size(cropfield.dayout), (ndays, 89))
cropfield.dayout
```

To get biomass in `ton/ha` you can use
```julia
biomass(cropfield)
```

To get the amount of dry yield in `ton/ha` you can use
```julia
dryyield(cropfield)
```

To get the amount of fresh yield in `ton/ha` you can use
```julia
freshyield(cropfield)
```

To get the canopy cover in % of terrain covered by the crop you can use
```julia
canopycover(cropfield)
```

To harvest you can use
```julia
harvest!(cropfield)

cropfield.harvestsout

isequal(size(cropfield.dayout), (ndays+1, 89))
cropfield.dayout

biomass(cropfield) # biomass is zero after a harvest day
canopycover(cropfield) # canopy cover just before harvesting
canopycover(cropfield, actual=false) # canopy cover just after harvesting
```
note that now we have two days, the function `harvest!` also makes a `dailyupdate!`, 
and the harvesting is done at the end of the day, that is why we have two values of 
canopy cover

If we make another daily update the canopy cover is actualized
```julia
dailyupdate!(cropfield)
canopycover(cropfield) 
canopycover(cropfield, actual=false) # since it was not a harvesting day it does not matter if we set `actual=false`
```

To run until the end of the season you can use
```julia
season_run!(cropfield)

isequal(size(cropfield.dayout), (164, 89))
cropfield.seasonout
```

## Advanced Run

The advanced run is still experimental, the idea is to:
1. Provide more control of the variables.
1. Not use files for faster upload of values.
1. To be easy to integrate with [Persefone.jl](https://persefone-model.eu) and other julia libraries.

We can also upload the default project like this
```julia
using AquaCrop

using DataFrames
using Dates
using StableRNGs

rng = StableRNG(42)

# Function to create a mockup climate DataFrame
function create_mock_climate_dataframe(start_date::Date, end_date::Date, tmin, delta_t, eto, rain)
    # Generate the date range
    dates = collect(start_date:end_date)
    
    # Generate random climate columns (each column has the same number of rows as the date range)
    Tmin = tmin .+ rand(rng, length(dates))
    Tmax = Tmin .+ delta_t .+ rand(rng, length(dates))
    ETo = eto .* abs.(randn(rng, length(dates)))
    Rain = rain .* abs.(randn(rng, length(dates)))
    
    # Create the DataFrame
    df = DataFrame(
        Date = dates,
        Tmin = Tmin,
        Tmax = Tmax,
        ETo = ETo,
        Rain = Rain
    )
    
    return df
end

# Generate ficticius climate data
start_date = Date(2023, 1, 1) # January 1 2023
end_date = Date(2023, 6, 1) # June 1 2023
tmin = 15
delta_t = 10
eto = 1
rain = 1

df = create_mock_climate_dataframe(start_date, end_date, tmin, delta_t, eto, rain)

# Generate the keyword object for the simulation
kwargs = (

    ## Necessary keywords

    # runtype
    runtype = NoFileRun(),

    # project input
    Simulation_DayNr1 = start_date,
    Simulation_DayNrN = end_date,
    Crop_Day1 = start_date,
    Crop_DayN = end_date,

    # soil
    soil_type = "clay",

    # crop
    crop_type = "maize",

    # Climate
    InitialClimDate = start_date,



    ## Optional keyworkds
    
    # Climate
    Tmin = df.Tmin,
    Tmax = df.Tmax,
    ETo = df.ETo,
    Rain = df.Rain,

    # change soil properties
    soil_layers = Dict("Thickness" => 5.0)

)

# start cropfield
cropfield, all_ok = start_cropfield(; kwargs...)
dump(all_ok)

# setup cropfield
setup_cropfield!(cropfield, all_ok; kwargs...)
dump(all_ok)
isequal(cropfield.soil_layers[1].Thickness, 5.0)


# daily update cropfield
ndays = 30
for _ in 1:ndays
    dailyupdate!(cropfield)
end
isequal(size(cropfield.dayout), (ndays, 89))

# harvest cropfield
harvest!(cropfield)
isequal(size(cropfield.dayout), (ndays+1, 89))
isequal(size(cropfield.harvestsout), (2, 11))

# change climate data
daynri_now = cropfield.gvars[:integer_parameters][:daynri]
day_now, month_now, year_now = AquaCrop.determine_date(daynri_now)
date_now = Date(year_now, month_now, day_now)
df_new = create_mock_climate_dataframe(date_now, end_date, tmin, delta_t, eto, rain)
change_climate_data!(cropfield, df_new; kwargs...)
isapprox(cropfield.gvars[:float_parameters][:eto], df_new.ETo[1]) 
isapprox(cropfield.gvars[:float_parameters][:rain], df_new.Rain[1]) 
isapprox(cropfield.gvars[:float_parameters][:tmin], df_new.Tmin[1]) 
isapprox(cropfield.gvars[:float_parameters][:tmax], df_new.Tmax[1]) 

# run until end of season
season_run!(cropfield)
total_days = length(collect(start_date:end_date))
isequal(size(cropfield.dayout), (total_days, 89))
```
