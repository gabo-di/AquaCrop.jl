# AquaCrop.jl

[![status](https://joss.theoj.org/papers/31c4de709e9417547f7f0455c7b6e773/status.svg)](https://joss.theoj.org/papers/31c4de709e9417547f7f0455c7b6e773)
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://gabo-di.github.io/AquaCrop.jl/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://gabo-di.github.io/AquaCrop.jl/dev/)
[![Build Status](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![DOI](https://zenodo.org/badge/781757300.svg)](https://doi.org/10.5281/zenodo.15511844)


Welcome to `AquaCrop.jl`! This package is an independent Julia implementation of FAO's 
[AquaCrop](https://github.com/KUL-RSDA/AquaCrop/), a process-based crop growth model.
The package currently corresponds to AquaCrop version 7.2.

AquaCrop is a well-established crop growth model that uses environmental parameters
(e.g. precipitation, temperature, and soil quality) to predict plant growth and yield
of a large range of crop species. It was first published in three papers by
[Steduto et al. (2009)](https://doi.org/10.2134/agronj2008.0139s),
[Raes et al. (2009)](https://doi.org/10.2134/agronj2008.0140s), and
[Hsiao et al. (2009)](https://doi.org/10.2134/agronj2008.0218s). 

The core code of this package closely follows the original Fortran implementation. 
On top of the core code, we developed an API that makes it easy to configure and 
run the simulations in several ways. It enables exploring and interacting with 
state variables at run time, opening up the possibility of dynamic, bidirectional 
model coupling. These new features increase the interoperability of the model 
compared to its original implementation, making it more easily accesible to growing number of
interdisciplinary environmental modellers working with Julia.

## Installing

Since the package is not yet registered, you can install it straight from Github:

```julia
using Pkg
Pkg.add("AquaCrop")
```

## Documentation

The [documentation](https://gabo-di.github.io/AquaCrop.jl/dev/) gives examples of how 
to [use the package](https://gabo-di.github.io/AquaCrop.jl/dev/userguide/), and 
describes the [API functions](https://gabo-di.github.io/AquaCrop.jl/dev/api/).

## Basic Usage

`AquaCrop.jl` can be used with the same input files as the original model. You must
specify the directory that includes these files and then call the `basic_run` function:

```julia
using AquaCrop

runtype = NormalFileRun()
parentdir = AquaCrop.test_dir  #".../AquaCrop.jl/test/testcase"

outputs = basic_run(; runtype=runtype, parentdir=parentdir)

isequal(size(outputs[:dayout]), (892, 89)) # true
```

you can see the daily result in `outputs[:dayout]`, 
the result of each harvest in `outputs[:harvestsout]`,
the result of the whole season in `outputs[:seasonout]`,
the information for the evaluation in `outputs[:evaldataout]`,
and the logger information in `outputs[:logger]`.

You can also choose to format your input data as TOML and CSV files:

```julia
runtype = TomlFileRun()
parentdir = AquaCrop.test_toml_dir  #".../AquaCrop.jl/test/testcase/TOML_FILES"

outputs = basic_run(; runtype=runtype, parentdir=parentdir)

isequal(size(outputs[:dayout]), (892, 89)) # true
```

Finally, you can pass all variables and data using the API
([tutorial here](https://gabo-di.github.io/AquaCrop.jl/dev/userguide/#Advanced-Run)).

## Tests

This package constains tests used for CI, but can also be used to check if the package is working properly when installed. To run the tests, after adding the package, activate the package manager, by typing `]`, and write
```
pkg> test AquaCrop
```
Otherwise check the CI badge status at the beggining of this README.md

### Extended Tests
We have an additional branch named [extended-tests](https://github.com/gabo-di/AquaCrop.jl/tree/extended-tests) where we compare more results between the FAO's AquaCrop implementation and ours. The status of these tests can be seen here: 

[![Extended Tests](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/extended-tests.yml/badge.svg)](https://github.com/gabo-di/AquaCrop.jl/actions/workflows/extended-tests.yml?query=branch%3Amain)

## Contributing

We welcome questions, suggestions, bug reports, or other contributions.

- You can file issues/bugs/questions/requests using the 
[Github issue tracker](https://github.com/gabo-di/AquaCrop.jl/issues). 
For bugs, please include as much information possible, including operating system, 
Julia version, version of `AquaCrop.jl`, and all the data needed to reproduce the bug.

- To contribute to the core code or API, make a pull request. Contributions should 
include tests and a description of the problem you solve. Tests should ensure that 
new features are backwards-compatible with the original Fortran model. If necessary, 
also update the documentation describing new API functionality.

- To contribute to the documentation or tutorials, make a pull request. 
Make sure it is possible to get any necessary data.

*Please note: Questions or change requests regarding the scientific functioning 
of the model (rather than the technical details of this particular implementation) 
should be addressed to the original model developers.*


## Citing

If you use `AquaCrop.jl` in your scientific work, please cite the following paper 
once it is published:

	Díaz Iturry, Matthies, Pe'er, Vedder (in review) "AquaCrop.jl: A Process-Based 
	Model of Crop Growth" Journal of Open Source Software
