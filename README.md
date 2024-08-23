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

outputs, _ = aquacrop_run(parentdir)
```

you can see the daily result in `outputs[:dayout]` 
the result of each harvest in `outputs[:harvestsout]`
the result of the whole season in `outputs[:seasonout]`
the information for the evaluation in `outputs[:evaldataout]`
and the logger information in `outputs[:logger]`

If you prefer to use TOML and csv files you can choose to run like
```julia
runtype = :Julia

parentdir = ".../AquaCrop/test/testcase/TOML_FILES"

outputs, _ = aquacrop_run(parentdir, runtype)
```


## Advanced Run

To initialize a crop field you have to provide the  directory data 

```julia
runtype = :Julia

parentdir = ".../AquaCrop/test/testcase/TOML_FILES"

outputs, _ = aquacrop_initialize_cropfield(parentdir, runtype)
```
