# AquaCrop

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gabo-di.github.io/AquaCrop/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gabo-di.github.io/AquaCrop/dev/)
[![Build Status](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml?query=branch%3Amain)

Welcome to `AquaCrop.jl`! This package is a julia implementation of FAO's [AquaCrop](https://github.com/KUL-RSDA/AquaCrop/), 
originaly written in Fortran 

## Install

Since the package is not yet registered, you can install it via

```julia
using Pkg
Pkg.add(url="https://github.com/gabo-di/AquaCrop.jl")
```


## Basic Run

For the basic run, first you need to specify the directory where that has all the 
required input for a common AquaCrop Fortran run and call the `aquacrop_run` function

```julia
using AquaCrop

parentdir = ".../AquaCrop/test/testcase"

outputs = aquacrop_basic_run(parentdir)
```

you can see the daily result in `outputs[:dayout]` 
the result of each harvest in `outputs[:harvestsout]`
the result of the whole season in `outputs[:seasonout]`
the information for the evaluation in `outputs[:evaldataout]`
and the logger information in `outputs[:logger]`

If you prefer to use TOML and csv files as input, you can choose to run like
```julia
runtype = :Julia

parentdir = ".../AquaCrop/test/testcase/TOML_FILES"

outputs = aquacrop_basic_run(parentdir, runtype)
```


## Advanced Run

To initialize a crop field you have to provide the directory data 

```julia
runtype = :Julia

parentdir = ".../AquaCrop/test/testcase/TOML_FILES"

cropfield, all_ok = aquacrop_initialize_cropfield(parentdir, runtype)
```
where `cropfield` is an struct of type `AquaCropField` with all the information of 
the crop field, and `all_ok` tell us if the paramers have been loaded correctly 
`all_ok.logi == true` or not `all_ok.logi == false`, in this case you can see 
the error kind in `all_ok.msg`. (Note that we do not raise exceptions in case you
want to inspect the `cropfield` variable, like `cropfield.outputs[:logger]`) 

To make a daily update you can use
```julia
aquacrop_dailyupdate!(cropfield)
```

To harvest you can use
```julia
aquacrop_harvest!(cropfield)
```

To get biomass in `ton/ha` you can use
```julia
aquacrop_biomass(cropfield)
```

To get the amount of dry yield in `ton/ha` you can use
```julia
aquacrop_dryyield(cropfield)
```

To get the amount of fresh yield in `ton/ha` you can use
```julia
aquacrop_freshyield(cropfield)
```

