---
title: 'AquaCrop.jl: A Process-Based Model of Crop Growth'
tags:
  - agriculture
  - plant growth
  - yield forecast
authors:
  - firstname: Gabriel 
    surname: Díaz Iturry
    corresponding: true
    affiliation: "1,2"
    orcid: 0000-0001-6011-6097
  - name: Marco C. Matthies
    affiliation: "1,2"
  - name: Guy Pe'er
    affiliation: "1,2"
    orcid: 0000-0002-7090-0560
  - name: Daniel Vedder
    corresponding: true
    affiliation: "1,2,3"
    orcid: 0000-0002-0386-9102
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

# Summary

[AquaCrop](https://www.fao.org/aquacrop/en/) is a simulation model that forecasts
the growth and yield of crop plants under different environmental and management
conditions [@Steduto2009]. As a process-based model, it can be used to optimise 
farm management, forecast regional yields, or study climate change impacts and 
sustainable farming practices. Originally developed by the Food and Agricultural 
Organization of the United Nations (FAO), it has been widely applied in agricultural 
research.

Here, we present an expanded reimplementation of the model, translating it from
Fortran to Julia [@Bezanson2017] and focussing on improving its interoperability 
with other software and models. With `AquaCrop.jl`, we want to make AquaCrop available 
to the growing number of environmental modellers working in Julia, and contribute to 
the creation of integrated, interdisciplinary models in the environmental sciences.

# Statement of need

All agriculture is dependent on the growth of plants, which provide food, fodder, 
fibre, and other resources. Forecasting and optimising crop growth is therefore
vital to address global food system challenges, including widespread malnutrition, 
agriculture-related environmental degradation, and global impacts of climate change 
[@Foley2011]. In this context, predictive crop models can be used to inform 
decision-making. These models use information about environmental parameters (e.g. 
temperature, rainfall, soil quality) and knowledge of plant biology to simulate 
crop growth over time and estimate yield.

Crop models range from simple statistical regression approaches to highly complex 
numerical simulations [@Pan2021]. Some concentrate on modelling the growth of the
plant itself [e.g. EPIC, @Williams1989], while other provide submodels for many
different aspects of agricultural systems, such as farm management, livestock, soil
processes, or water quality [e.g. APSIM, @Holzworth2014].

AquaCrop is an intermediate-complexity crop model. Its aim is to be complex enough
to be accurate but simple enough to be widely usable [@Steduto2009]. Indeed, over the 
past years, it has been used to model numerous crops worldwide [@Mialyk2024], and 
shown to produce reliable estimates of crop phenology and yield for multiple crop
species [@Kostkova2021]. First implemented in Delphi, it was later open-sourced in a 
Fortran version [@deRoos2021; @RSDA2024]. There are also versions available in 
[Matlab](https://github.com/aquacropos/aquacrop-matlab), [Python](https://github.com/aquacropos/aquacrop), and [R](https://github.com/jrodriguez88/aquacrop-R),
although currently these are not up-to-date with the most recent version (7.2) of the 
original Fortran model [@Foster2017; @Kelly2021; @CamargoRodriguez2019]. 

`AquaCrop.jl` expands this portfolio to contribute to the emerging ecosystem of
environmental research software in Julia. To our knowledge, this is the first 
process-based crop model available in this language. Our purpose is also to provide a 
package that can be readily integrated into other scientific software, in order to
facilitate the creation of multidisciplinary models of socio-environmental systems
[@Cabral2023; @Vedder2024].

Specifically, we developed the package to use it as a component within 
[`Persefone.jl`](https://persefone-model.eu), a process-based model of agricultural 
ecosystems [@Vedder2024a]. The aim of this model is to study the impact that 
agricultural management and policy has on biodiversity, for which the growth of 
crop plants is an important mediating factor.

# Comparison to original implementation

We decided to reimplement the full source code of the model rather than simply 
providing a wrapper to the original software (though we do this too, see below). 
The most important reason was that we needed to modify the structure to enable better 
interoperability when coupling the model to other software. In addition, a native 
Julia implementation allows a better integration with other Julia libraries, as well 
as allowing researchers who are familiar with Julia but not with Fortran to work with 
the model code. In our reimplementation, we followed a two-layered approach:

The core code of `AquaCrop.jl` was translated verbatim from the original Fortran 
implementation, which allows us to quickly integrate changes and updates
to the original `AquaCrop` code. `AquaCrop.jl` supports the original input file
formats, and is tested to ensure its output conforms to that of the original software
(using the data files in the `extended-tests` branch).

On top of this core code, we developed a wrapper layer with an API that improves
the interoperability of `AquaCrop.jl` when used as a package with other software. 
First, we added support for standardised input and output file formats (TOML and CSV),
and for loading input data from memory rather than disk (for example using output from
a coupled model). Second, we bundled all state variables for a simulation in one 
struct (`AquaCropField`), thereby eliminating global state and allowing multiple 
simulations to be carried out in parallel, as well as making serialisation and data 
transfer easier. Third, we enabled the model to be updated one day at a time, rather
than being executed as a singe batch job. This allows state variables to be inspected 
and changed on the go, which makes it possible to use the package for bidirectional 
model coupling as well as interactively.

Overall, we leave the scientific core of the model unchanged, but make it easier
for environmental modellers using Julia to integrate the model into their own work,
interface with other libraries for the Julia ecosystem, or adapt the model to suit
their needs.

# Examples 

Multiple tutorials for different use cases are provided in the 
[documentation](https://gabo-di.github.io/AquaCrop.jl/dev/userguide/).
A simple demonstration of a basic run using the data from the 
`AquaCrop.jl/test/testcase` directory is shown here:

```julia
using AquaCrop
using CairoMakie
using Unitful

# First, we specify the input file format:
# NormalFileRun(): use the original AquaCrop file format
# TomlFileRun(): use TOML and CSV formatting
# NoFileRun(): provide input data via the API
runtype = NormalFileRun();

# Then specify the directory containing the necessary input files
parentdir = AquaCrop.test_dir;

# Now we can do a simulation run and plot the results
outputs = basic_run(; runtype=runtype, parentdir=parentdir);
function plot_basic_out(cropfield, cols)
    x = cropfield[!, "Date"]
    aux_sz = round(Int, sqrt(length(cols)))
    f = Figure()
    for (i, coli) in enumerate(keys(cols))
        ii, jj = divrem(i-1, aux_sz)
        ax = Axis(f[ii, jj],
                title = cols[coli][1],
                xlabel = "Date",
                ylabel = cols[coli][2]
                )
        lines!(ax, x, ustrip.(cropfield[!, coli]))
        ax.xticklabelrotation = π/4
        ax.xticklabelsize = 8
        ax.yticklabelsize = 8
    end
    return f
end

f = plot_basic_out(outputs[:dayout], 
    Dict("CC"=>["Canopy Cover","%"], 
         "Tavg"=>["Temperature","K"],
         "Biomass"=>["Biomass","ton/ha"],
         "Rain"=>["Rainfall","mm"]))
```

![Simulated canopy cover and biomass of an alfalfa crop over time, together with daily temperature and rainfall.\label{fig:biomass}](example.png)

The resulting graph is shown in \autoref{fig:biomass}. Canopy cover increases during
the growing season, with regular harvests taking place. Biomass is shown accumulated
over the whole season.

\autoref{fig:beans} shows a simulation of the growth of beans (*Vicia faba*) based on 
environmental data from Thuringia, Germany, with historical yield data shown 
for comparison. This showcases that when well parameterised, `AquaCrop.jl` forecasts 
the development of yields over time quite reliably [cf. @Kostkova2021]. As the issue 
of parameterisation is a complex one, we provide a separate tutorial for this
[here](https://github.com/gabo-di/CropGrowthTutorial), using publicly available
crop data from Germany as an example.

![Simulated yield of beans (*Vicia faba*) compared to observed yields in Thuringia, Germany.\label{fig:beans}](beans.png)

To facilitate comparisons between the Fortran and Julia versions, we made the original
version available as a compiled binary using a Julia library package (JLL). This can
be called as follows:

```
import Pkg
Pkg.add("AquaCrop_jll")
import AquaCrop_jll
# setup AquaCrop Fortran code input directories and files
run(AquaCrop_jll.aquacrop())
```


# Acknowledgements

GDI, MM, and DV are funded through the project CAP4GI by the Federal Ministry of 
Education and Research (BMBF), within the framework of the Strategy, Research for 
Sustainability (FONA, www.fona.de/en) as part of its Social-Ecological Research 
funding priority, funding no. 01UT2102A. Responsibility for the content of this 
publication lies with the authors. MM, GP, and DV gratefully acknowledge the support 
of iDiv, funded by the German Research Foundation (DFG–FZT 118, 202548816).

# References
