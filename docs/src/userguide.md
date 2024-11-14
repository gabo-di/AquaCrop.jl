```@meta
CurrentModule = AquaCrop
DocTestSetup = quote
    using AquaCrop
end
```

```@contents
Pages = ["userguide.md"]
```

## Basic Run
For an example of a basic run using the function [`basic_run`](@ref) see the section [Basic Run](@ref basic_run_section)
in [Getting Started](@ref Install)


## Intermediate Run

We start a crop field, to do this we need to set a runtype and the data directory 
```jldoctest intermediate_run_example; output = false
using AquaCrop

parentdir = AquaCrop.test_toml_dir #".../AquaCrop.jl/test/testcase/TOML_FILES"
runtype = TomlFileRun()

# output
TomlFileRun()
```

The crop field is started using the function [`start_cropfield`](@ref)
```jldoctest intermediate_run_example
cropfield, all_ok = start_cropfield(;runtype=runtype, parentdir=parentdir);
dump(all_ok)

# output
AquaCrop.AllOk
  logi: Bool true
  msg: String ""
```

where `cropfield` is an struct of type `AquaCropField` with all the information of 
the crop field, and `all_ok` tell us if the paramers have been loaded correctly 
`all_ok.logi == true`, or not `all_ok.logi == false`. When this happens, you can see 
the error kind in `all_ok.msg`. (Note that we do not raise exceptions in case you
want to inspect the `cropfield` variable, like `cropfield.outputs[:logger]`). 
In out example we see that `all_ok.logi == true`, so all went well up to now. 

We have a `cropfield::AquaCropField` variable with the soil and crop data, 
and we have checked that the config files exist. Now we have to setup the `cropfield` 
using the function [`setup_cropfield!`](@ref),
this will read the climate data, setup the cropfield, among other things.

```jldoctest intermediate_run_example
setup_cropfield!(cropfield, all_ok; runtype=runtype);
dump(all_ok)

# output
AquaCrop.AllOk
  logi: Bool true
  msg: String ""
```
We see that `all_ok.logi == true` so we have read all the data. We can update the cropfield day by day, this is done 
using the [`dailyupdate!`](@ref) function


```jldoctest intermediate_run_example
ndays = 30
for _ in 1:ndays
    dailyupdate!(cropfield)
end

isequal(size(cropfield.dayout), (ndays, 89))

# output
true
```

we can see the daily output DataFrame in the field
```jldoctest intermediate_run_example
cropfield.dayout

# output
30×89 DataFrame
 Row │ RunNr  Date        DAP    Stage  WC()        Rain       Irri       Surf ⋯
     │ Int64  Date        Int64  Int64  Quantity…   Quantity…  Quantity…  Quan ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1  2014-05-21      1      1  866.491 mm     0.1 mm     0.0 mm     0 ⋯
   2 │     1  2014-05-22      2      2  864.965 mm     1.9 mm     0.0 mm     0
   3 │     1  2014-05-23      3      2   864.28 mm     2.4 mm     0.0 mm     0
   4 │     1  2014-05-24      4      2  862.077 mm     1.2 mm     0.0 mm     0
   5 │     1  2014-05-25      5      2  859.819 mm     1.3 mm     0.0 mm     0 ⋯
   6 │     1  2014-05-26      6      2  858.465 mm     1.2 mm     0.0 mm     0
   7 │     1  2014-05-27      7      2  857.867 mm     2.4 mm     0.0 mm     0
   8 │     1  2014-05-28      8      2  856.889 mm     0.4 mm     0.0 mm     0
  ⋮  │   ⋮        ⋮         ⋮      ⋮        ⋮           ⋮          ⋮           ⋱
  24 │     1  2014-06-13     24      2  884.881 mm    17.4 mm     0.0 mm     0 ⋯
  25 │     1  2014-06-14     25      2  874.395 mm     3.8 mm     0.0 mm     0
  26 │     1  2014-06-15     26      2  866.108 mm     0.1 mm     0.0 mm     0
  27 │     1  2014-06-16     27      2  862.106 mm     0.2 mm     0.0 mm     0
  28 │     1  2014-06-17     28      2  868.995 mm    11.0 mm     0.0 mm     0 ⋯
  29 │     1  2014-06-18     29      2  868.812 mm     4.1 mm     0.0 mm     0
  30 │     1  2014-06-19     30      2  863.843 mm     0.2 mm     0.0 mm     0
                                                  82 columns and 15 rows omitted
```
if we want to know the biomass of the current day we use [`biomass`](@ref) function
```jldoctest intermediate_run_example
biomass(cropfield)

# output
1.9209359227956477 ton ha⁻¹
```
note that the result is in `ton/ha`, metric tonelades per hectare. The amount of dry yield
of the current day is given by the [`dryyield`](@ref) function
```jldoctest intermediate_run_example
dryyield(cropfield)

# output
1.762886258750845 ton ha⁻¹
```
and the fresh yield by the [`freshyield`](@ref) function
```jldoctest intermediate_run_example
freshyield(cropfield)

# output
8.814431293754224 ton ha⁻¹
```

The canopy cover is given by the percentage of terrain covered by the crop, 
for this use the function [`canopycover`](@ref)
```jldoctest intermediate_run_example
canopycover(cropfield)

# output
49.26884612609828
```

If we want to make a harvest in the current day use [`harvest!`](@ref) function 

```jldoctest intermediate_run_example
harvest!(cropfield)

cropfield.harvestsout

# output
2×11 DataFrame
 Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯
     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1      0  2014-05-21      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯
   2 │     1      1  2014-06-20     31     31.0 d  2.03767 ton ha⁻¹  2.03767 t
                                                               5 columns omitted
```

note that [`harvest!`](@ref) also makes a daily update,
now we have `ndays+1` days

```jldoctest intermediate_run_example
isequal(size(cropfield.dayout), (ndays+1, 89))

# output
true
```

another effect of the [`harvest!`](@ref) function is that
changes the biomass
```jldoctest intermediate_run_example
biomass(cropfield) # biomass is zero after a harvest day

# output
0.0 ton ha⁻¹
```

it also changes the canopy cover, we can see the value of it just
before harvesting
```jldoctest intermediate_run_example
canopycover(cropfield) # canopy cover just before harvesting

# output
49.904006947723616
```

and just after harvesting
```jldoctest intermediate_run_example
canopycover(cropfield, actual=false) # canopy cover just after harvesting

# output
25.0
```

the harvesting is done at the end of the day, that is why we have two values
of canopy cover.

If we make another daily update the canopy cover is actualized

```jldoctest intermediate_run_example
dailyupdate!(cropfield)
canopycover(cropfield) 

# output
27.827808455159015
```

since it was not a harvesting day it does not matter if we set `actual=false`
```jldoctest intermediate_run_example
canopycover(cropfield, actual=false) 

# output
27.827808455159015
```

finally we can run until the end of the season using [`season_run!`](@ref) function
```jldoctest intermediate_run_example
season_run!(cropfield)

isequal(size(cropfield.dayout), (164, 89))

# output
true
```

and check the output dataframe of the season using

```jldoctest intermediate_run_example
cropfield.seasonout

# output
1×36 DataFrame
 Row │ RunNr  Date1       Rain       ETo        GD       CO2         Irri      ⋯
     │ Int64  Date        Quantity…  Quantity…  Float64  Quantity…   Quantity… ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1  2014-05-21   487.5 mm   431.0 mm   1802.6  398.81 ppm     0.0 mm ⋯
                                                              29 columns omitted
```

## Advanced Run

The advanced run is still experimental, the idea is to:
1. Provide more control of the variables.
1. Not use files for faster upload of values.
1. To be easy to integrate with [Persefone.jl](https://persefone-model.eu) and other julia libraries.

Let's start calling some libraries and creating some variables
```jldoctest advanced_run_example; output=false
using AquaCrop
using DataFrames
using Dates
using StableRNGs

rng = StableRNG(42)

# Auxiliar variables to generate ficticius climate data
start_date = Date(2023, 1, 1) # January 1 2023
end_date = Date(2023, 6, 1) # June 1 2023
tmin = 15 # daily minimum temperature will be around this
delta_t = 10 # daily maximum temperature will be around tmin + delta_t
eto = 1 # daily ETo will be around this 
rain = 1 # daily rain will be around this

# output
1
```

Now we will create a function to mockup some climate DataFrame


```jldoctest advanced_run_example
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

df = create_mock_climate_dataframe(start_date, end_date, tmin, delta_t, eto, rain)

# output
152×5 DataFrame
 Row │ Date        Tmin     Tmax     ETo        Rain
     │ Date        Float64  Float64  Float64    Float64
─────┼────────────────────────────────────────────────────
   1 │ 2023-01-01  15.5805  25.7028  0.651892   2.91776
   2 │ 2023-01-02  15.1912  25.8489  1.27642    0.633148
   3 │ 2023-01-03  15.9711  26.3123  0.815404   1.05268
   4 │ 2023-01-04  15.7434  26.2699  1.28974    0.205817
   5 │ 2023-01-05  15.171   25.5827  0.21546    0.0733287
   6 │ 2023-01-06  15.7048  26.1394  0.0967601  1.52228
   7 │ 2023-01-07  15.441   26.284   0.238206   0.446309
   8 │ 2023-01-08  15.804   26.2381  0.43073    0.539408
  ⋮  │     ⋮          ⋮        ⋮         ⋮          ⋮
 146 │ 2023-05-26  15.3848  26.1798  0.857995   0.433004
 147 │ 2023-05-27  15.6592  26.1444  1.41443    2.38353
 148 │ 2023-05-28  15.5007  26.292   0.226759   0.429369
 149 │ 2023-05-29  15.6813  26.624   0.220586   0.88746
 150 │ 2023-05-30  15.8692  26.2971  0.142944   0.235242
 151 │ 2023-05-31  15.6776  26.629   0.331443   0.851964
 152 │ 2023-06-01  15.9877  26.9083  0.160163   1.67827
                                          137 rows omitted
```

this advanced run depends on sending all the configuration
via a keyword variable 

```jldoctest advanced_run_example; output=false
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
nothing # ignore this line

# output

```

the variable `kwargs` has some necessary keywords, like the runtype 
where we specify that we will not use files to make the configuration 
`runtype = NoFileRun()`, see [`NoFileRun`](@ref),
and some optional keywords, to pass the climate data, like temperature `Tmin = df.Tmin`,
or additional information to change some properties of the variables, like `soil_layers = Dict("Thickness" => 5.0)`
To know more about the keywords see [`AquaCrop.check_nofilerun`](@ref).

Once that we have created the `kwargs` we can start a cropfield
```jldoctest advanced_run_example
# start cropfield
cropfield, all_ok = start_cropfield(; kwargs...)
dump(all_ok)

# output
AquaCrop.AllOk
  logi: Bool true
  msg: String ""
```

see that the climate is empty

```jldoctest advanced_run_example
cropfield.raindatasim

# output
Float64[]
```

now we setup the `cropfield`
```jldoctest advanced_run_example
setup_cropfield!(cropfield, all_ok; kwargs...)
dump(all_ok)

# output
AquaCrop.AllOk
  logi: Bool true
  msg: String ""
```

and the climate is no longer empty

```jldoctest advanced_run_example
cropfield.raindatasim

# output
152-element Vector{Float64}:
 2.9177565288611698
 0.6331479661044
 1.0526800752671774
 0.20581692403731217
 0.07332874480489955
 1.5222784325808019
 0.44630933889682284
 0.5394084077226324
 0.4667865106229535
 0.9548987102476532
 ⋮
 0.09979662306558626
 0.8290059898452288
 0.43300412658464604
 2.383533709338484
 0.429368530738495
 0.8874604322470359
 0.23524192561168275
 0.8519635419668649
 2.9177565288611698
```

Now that we have finished setting up the `cropfield`, we
can update the cropfield day by day, this is done 
using the [`dailyupdate!`](@ref) function

```jldoctest advanced_run_example
# daily update cropfield
ndays = 30
for _ in 1:ndays
    dailyupdate!(cropfield)
end
isequal(size(cropfield.dayout), (ndays, 89))

# output
true
```

similarly to [Intermediate Run](@ref), 
if we want to make a harvest in the current day use [`harvest!`](@ref) function 

```jldoctest advanced_run_example
# harvest cropfield
harvest!(cropfield)

cropfield.harvestsout

# output
2×11 DataFrame
 Row │ RunNr  Nr     Date        DAP    Interval   Biomass           Sum(B)    ⋯
     │ Int64  Int64  Date        Int64  Quantity…  Quantity…         Quantity… ⋯
─────┼──────────────────────────────────────────────────────────────────────────
   1 │     1      0  2023-01-01      0      0.0 d      0.0 ton ha⁻¹      0.0 t ⋯
   2 │     1      1  2023-01-31     31      1.0 d  0.23564 ton ha⁻¹  0.23564 t
                                                               5 columns omitted
```

We can also change the climate data in the middle of the run, first we create 
a new mockup climate with the current simulation date of the `cropfield`

```jldoctest advanced_run_example
# change climate data
daynri_now = cropfield.gvars[:integer_parameters][:daynri]
day_now, month_now, year_now = AquaCrop.determine_date(daynri_now)
date_now = Date(year_now, month_now, day_now)
df_new = create_mock_climate_dataframe(date_now, end_date, tmin, delta_t, eto, rain)

# output
121×5 DataFrame
 Row │ Date        Tmin     Tmax     ETo        Rain
     │ Date        Float64  Float64  Float64    Float64
─────┼────────────────────────────────────────────────────
   1 │ 2023-02-01  15.6869  26.5836  1.71291    1.8238
   2 │ 2023-02-02  15.9483  26.2946  0.100485   0.979034
   3 │ 2023-02-03  15.2689  26.0057  0.482743   0.704698
   4 │ 2023-02-04  15.7582  26.7011  0.503668   1.39689
   5 │ 2023-02-05  15.4462  25.5794  1.34735    1.70537
   6 │ 2023-02-06  15.1402  25.4986  0.49967    0.403604
   7 │ 2023-02-07  15.0549  25.8906  0.225304   1.40783
   8 │ 2023-02-08  15.715   26.1469  0.0636065  0.909276
  ⋮  │     ⋮          ⋮        ⋮         ⋮          ⋮
 115 │ 2023-05-26  15.5075  25.8814  1.00945    0.741913
 116 │ 2023-05-27  15.6137  26.5237  0.9474     0.0554669
 117 │ 2023-05-28  15.7396  25.877   0.684951   0.179529
 118 │ 2023-05-29  15.8959  26.1849  1.82466    1.01259
 119 │ 2023-05-30  15.1694  26.0627  1.5105     0.31451
 120 │ 2023-05-31  15.2946  25.4924  2.04355    1.40788
 121 │ 2023-06-01  15.9661  26.0386  0.835019   0.0228998
                                          106 rows omitted
```

and change the climate using [`change_climate_data!`](@ref) function
```jldoctest advanced_run_example
change_climate_data!(cropfield, df_new; kwargs...)

isapprox(cropfield.gvars[:float_parameters][:rain], df_new.Rain[1]) 

# output
true
```

finally we can run until the end of the season using [`season_run!`](@ref) function
```jldoctest advanced_run_example
season_run!(cropfield)
total_days = length(collect(start_date:end_date))
isequal(size(cropfield.dayout), (total_days, 89))

# output
true
```
