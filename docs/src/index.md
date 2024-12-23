```@meta
CurrentModule = AquaCrop
```

# Introduction 

AquaCrop is a crop growth model developed by FAO’s Land and Water Division, 
[FAO-AquaCrop](https://www.fao.org/aquacrop/en/),
to support food security and to analyze how environmental and management factors
influence crop productivity. It focuses on simulating how water availability affects 
the yield of herbaceous crops, making it ideal for situations where water is a 
primary constraint in agriculture. AquaCrop was designed to balance simplicity 
with precision and robustness. 

The original FAO's code is written in Fortran
and available on github [AquaCrop](https://github.com/KUL-RSDA/AquaCrop/). AquaCrop.jl is a julia implementation that corresponds 
to AquaCrop version 7.2, older or newer versions can have compatibility issues. 
In this repository the core code follows very closely the Fortran's original implementation. On top of this, we have an API that makes it easy to
run the simulations in several ways, and interact-explore the variables. We did this so we can follow up the updates on the original AquaCrop code, 
but at the same time have the possibility to interact with other libraries from the julia
ecosystem, like DataFrames.jl, Makie.jl, StatsModels.jl, Optimisers.jl, etc.


The model is open-source available in [AquaCrop.jl](https://github.com/gabo-di/AquaCrop.jl). 
It is developed as part of the [CAP4GI project](https://cap4gi.de/en) as a complement to the models in 
[Persefone.jl](https://persefone-model.eu)
