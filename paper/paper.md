---
title: 'AquaCrop.jl: A Process-Based Model of Crop Growth'
tags:
  - agriculture
  - plant growth
  - yield forecast
authors:
  - name: Gabriel Díaz Iturry
    corresponding: true
    affiliation: "1,2"
  - name: Marco Matthies
    affiliation: "1,2"
  - name: Guy Pe'er
    affiliation: "1,2"
  - name: Daniel Vedder
    corresponding: true
    affiliation: "1,2,3"
affiliations:
 - name: Helmholtz Centre for Environmental Research - UFZ
   index: 1
   ror: 000h6jb29
 - name: German Centre for Integrative Biodiversity Research (iDiv) Halle-Jena-Leipzig
   index: 2
   ror: 01jty7g66
 - name: Friedrich-Schiller-Universität Jena
   index: 3
   ror: 05qpz1x62
date: 01 February 2025
bibliography: paper.bib
---

<!-- see documentation here: https://joss.readthedocs.io/en/latest/paper.html -->

<!-- set up a Github Action to auto-compile to PDF: https://github.com/marketplace/actions/open-journals-pdf-generator -->

# Summary

All agriculture is dependent on the growth of plants. Crop plants provide food
for humans, fodder for domestic animals, and fibre and other resources for our
manufacturing economy. Therefore, understanding how plants grow under different
conditions is important not just for farmers themselves, but also for the rest
of society. Crop models based on physical and physiological processes use information
about environmental parameters (e.g. temperature, rainfall, soil quality) and
knowledge of plant biology to simulate how crop plants grow over time and estimate
the resulting yield. Such models can be used to optimise farm management, 
forecast national or regional yields, or study climate change impacts.

# Statement of need

`AquaCrop.jl` is an independent Julia translation of the [AquaCrop](https://github.com/KUL-RSDA/AquaCrop/)
 model, originally 
developed by the FAO [@Steduto2009]. This is a well-established crop growth model that 
has been used to model numerous crops worldwide [@Mialyk2024], and is known to produce 
reliable estimates of crop phenology and yield [@Kostkova2021].

AquaCrop is already available in multiple languages. First implemented in Pascal,
it was later open-sourced in a Fortran version [@deRoos2021; @RSDA2024]. There are
also [Matlab](https://github.com/aquacropos/aquacrop-matlab) and [Python](https://github.com/aquacropos/aquacrop) 
reimplementations available [@Foster2017; @Kelly2021]. With
`AquaCrop.jl`, we want to expand this portfolio to make the model more easily 
accessible to the growing of environmental modellers working with Julia.

Beyond just adding another language, our purpose is also to provide a package that
can be readily integrated into other scientific software. Recent research has 
emphasised the need for the creation of interdisciplinary models that consider
the multiple processes inherent in global challenges such as climate change or 
biodiversity loss [@Cabral2023]. This will require the use of model coupling, and the
adaptation of existing models to be usable as components in integrated models 
[@Vedder2024]. The new API we developed for `AquaCrop.jl` is intended to do just that.

Specifically, we developed the package to use it as a component within 
[Persefone.jl](https://persefone-model.eu), a model of agricultural ecosystems [@Vedder2024a]. The aim of this 
model is to study the impact that agricultural processes have on biodiversity, for 
which the growth of crop plants is an important mediating factor.

In this repository the core code follows very closely the FAO's Fortran original implementation, this 
allows us to follow up easily the updates of the original `AquaCrop` code, which, to our knowledge,
it is not so straigtforward on the Matlab or Python implementations.

On top of the core code, we have an API that makes it easy to upload data and
run the simulations in several ways. We can also explore and interact with the variables
at run time, which leaves open the possibility of model coupling.
All this is a difficult task for non experts using the original `AquaCrop` Fortran implementation.

Finally, we have the possibility to complement the code with other libraries from the julia
ecosystem, like DataFrames.jl, Makie.jl, StatsModels.jl, Optimisers.jl, etc. Making `AquaCrop.jl`
a reliable and versatil tool for simulating and studying crop growth.

# Example 

We show an example using the data from the `AquaCrop.jl/test/testcase` directory, figure \autoref{fig:biomass}
shows how grows the Biomass as the days passes. Note that in this test case is for 3 seasons. The code for 
generating the image is the following:


```julia
using AquaCrop
using CairoMakie
using Unitful

runtype = NormalFileRun();
parentdir = AquaCrop.test_dir;  #".../AquaCrop.jl/test/testcase"

outputs = basic_run(; runtype=runtype, parentdir=parentdir);

f = Figure();
ax = Axis(f[1,1],
    title = "Biomass vs Day",
    xlabel = "Day",
    ylabel = "Biomass",
)
lines!(ax, 1:size(outputs[:dayout], 1) , ustrip.(outputs[:dayout][!, "Biomass"]))
```


![Biomass of crop as the days passes.\label{fig:biomass}](example.png)

# Acknowledgements

GDI, MM, and DV are funded through the project CAP4GI by the Federal Ministry of 
Education and Research (BMBF), within the framework of the Strategy, Research for 
Sustainability (FONA, www.fona.de/en) as part of its Social-Ecological Research 
funding priority, funding no. 01UT2102A. Responsibility for the content of this 
publication lies with the authors. MM, GP, and DV gratefully acknowledge the support 
of iDiv, funded by the German Research Foundation (DFG–FZT 118, 202548816).

# References
