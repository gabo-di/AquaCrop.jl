# AquaCrop.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gabo-di.github.io/AquaCrop/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gabo-di.github.io/AquaCrop/dev/)
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

parentdir = AquaCrop.test_dir  #".../AquaCrop/test/testcase"

outputs = basic_run(parentdir)
```

you can see the daily result in `outputs[:dayout]` 
the result of each harvest in `outputs[:harvestsout]`
the result of the whole season in `outputs[:seasonout]`
the information for the evaluation in `outputs[:evaldataout]`
and the logger information in `outputs[:logger]`

If you prefer to use TOML and csv files as input, you can choose to run like
```julia
runtype = :Julia

parentdir = AquaCrop.test_toml_dir  #".../AquaCrop/test/testcase/TOML_FILES"

outputs = basic_run(parentdir, runtype)
```


## Advanced Run

To initialize a crop field you have to provide the directory data 

```julia
runtype = :Julia

parentdir = AquaCrop.test_toml_dir #".../AquaCrop/test/testcase/TOML_FILES"

cropfield, all_ok = initialize_cropfield(;runtype=runtype, parentdir=parentdir)

dump(all_ok)
```
where `cropfield` is an struct of type `AquaCropField` with all the information of 
the crop field, and `all_ok` tell us if the paramers have been loaded correctly 
`all_ok.logi == true` or not `all_ok.logi == false`, in this case you can see 
the error kind in `all_ok.msg`. (Note that we do not raise exceptions in case you
want to inspect the `cropfield` variable, like `cropfield.outputs[:logger]`) 

To make a daily update you can use
```julia
for _ in 1:30
    dailyupdate!(cropfield)
end
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

To get the canopy cover in % of terrain you can use
```julia
canopycover(cropfield)
```

To harvest you can use
```julia
harvest!(cropfield)
cropfield.harvestsout
cropfield.dayout
biomass(cropfield) # biomass is zero after a harvest day
canopycover(cropfield) # canopy cover just before harvesting
canopycover(cropfield, actual=false) # canopy cover just after harvesting
```
note that now we have two days, the function `harvest!` also makes a `dailyupdate!`

If we make another daily update the canopy cover is actualized
```julia
dailyupdate!(cropfield)
canopycover(cropfield) 
canopycover(cropfield, actual=false) 
```
to make more physical sense, the function `harvest!`  should work only if 
`canopycover(cropfield) > cropfield.management.Cuttings.CCcut`,
note that this behaviour is not considered in the orignal AquaCrop code, 
so we do not check for this automatically.

To run until the end of the season you can use
```julia
season_run!(cropfield)
cropfield.seasonout
```


We can also upload the default project like this
```julia
cropfield, all_ok = initialize_cropfield()

dump(all_ok)
cropfield.logger
```
we can see that in this case the default runtype is `JuliaRun`. 

We can edit at run time the `cropfield` variable
We can do set the soil and soil layers to a given known soil type
```julia
soil_type = "clay" # to see other options type in the repl  ?get_soil
cropfield.gvars[:soil], all_ok = get_soil(soil_type)
cropfield.gvars[:soil_layers], all_ok = get_soillayers(soil_type, Dict("Thickness" => 5.0)) #Here we manually set a value for the Thickness in the soil layer

dump(all_ok)
println(cropfield.soil_layers[1].Description)
println(cropfield.soil_layers[1].Thickness)
```

We can also change the crop type
```julia 
crop_type = "maize"
cropfield.gvars[:crop], all_ok = get_crop(crop_type)
dump(all_ok)
```

Note that if you use the default project, you will probably want to change the dates 
of the simulation 
```julia
cropfield.gvars[:simulation].FromDayNr = AquaCrop.determine_day_nr(1, 1, 1901)
cropfield.gvars[:simulation].ToDayNr = AquaCrop.determine_day_nr(31, 12, 1901)
```




