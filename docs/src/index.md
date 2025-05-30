```@meta
CurrentModule = AquaCrop
```

# Introduction

[![status](https://joss.theoj.org/papers/31c4de709e9417547f7f0455c7b6e773/status.svg)](https://joss.theoj.org/papers/31c4de709e9417547f7f0455c7b6e773)

`AquaCrop.jl` is a process-based crop growth modelling library designed to be used
in environmental simulation software. It simulates plant growth over time (including
canopy cover, phenology, biomass, yield, and other variables) based on management
and environmental input data. It is a direct translation of the AquaCrop model 
developed by the FAO. From their [website](https://www.fao.org/aquacrop/en/):

	AquaCrop is a crop growth model developed by FAO’s Land and Water Division to 
	address food security and assess the effect of the environment and management 
	on crop production. AquaCrop simulates the yield response of herbaceous crops 
	to water and is particularly well suited to conditions in which water is a key 
	limiting factor in crop production. AquaCrop balances accuracy, simplicity and 
	robustness. To ensure its wide applicability, it uses only a small number of 
	explicit parameters and mostly intuitive input variables that can be determined 
	using simple methods.

The original FAO's code is written in Fortran and available on [Github](https://github.com/KUL-RSDA/AquaCrop/). 
`AquaCrop.jl` is a Julia implementation that corresponds to AquaCrop version 7.2.

The core code of this package closely follows the original Fortran implementation. 
On top of the core code, we developed an API that makes it easy to configure and 
run the simulations in several ways. It enables exploring and interacting with 
state variables at run time, opening up the possibility of dynamic, bidirectional 
model coupling. These new features increase the interoperability of the model 
compared to its original implementation, making it more easily accesible to growing 
number of interdisciplinary environmental modellers working with Julia.

The model is open-source and available on [Github](https://github.com/gabo-di/AquaCrop.jl) under a BSD-3 license.
It was developed as a component of the [Persefone.jl](https://persefone-model.eu) model
of the [Helmholtz Centre for Environmental Research - UFZ](https://www.ufz.de/) and 
the [German Centre for Integrative Biodiversity Research (iDiv) Halle-Jena-Leipzig](https://www.idiv.de/).
Development was funded through the project [CAP4GI](https://cap4gi.de/en) by the 
Federal Ministry of Education and Research (BMBF), within the framework of the 
Strategy "Research for Sustainability" ([FONA](https://www.fona.de/en/)) as part of its 
Social-Ecological Research funding priority, funding no. 01UT2102A.

## Citing

If you use `AquaCrop.jl` in your scientific work, please cite the following paper 
once it is published:

	Díaz Iturry, Matthies, Pe'er, Vedder (in review) "AquaCrop.jl: A Process-Based 
	Model of Crop Growth" Journal of Open Source Software
