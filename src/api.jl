abstract type AbstractCropField end


"""
   AquaCropField 

Has all the data for the simulation of a `cropfield::AquaCropField` variable
stored in dictionaries.

Initialize an object of this type using the function
[`start_cropfield`](@ref) or making a `deepcopy` of another
`cropfield`.

See also [`start_cropfield`](@ref)
""" 
struct AquaCropField <: AbstractCropField
    "global variables"
    gvars::Dict
    "outputs variables"
    outputs::Dict
    "local variables"
    lvars::Dict
    "cropfield status"
    status::Vector{AbstractCropFieldStatus}
end

function Base.getindex(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    elseif s in keys(b.outputs)
        return getfield(b, :outputs)[s]
    else
        return getfield(b, :gvars)[s]
    end
end

function Base.getproperty(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    elseif s in keys(b.outputs)
        return getfield(b, :outputs)[s]
    else
        return getfield(b, :gvars)[s]
    end
end


function Base.propertynames(b::AquaCropField, private::Bool=false)
    # TODO: private is currently ignored
    return tuple(union(
        fieldnames(AquaCropField),
        keys(getfield(b, :outputs)),
        keys(getfield(b, :gvars))
    )...)
end

"""
    status = BadCropField()

Indicates the cropfield can not be run
"""
struct BadCropField <: AbstractCropFieldStatus end

"""
    status = StartCropField()

Indicates the cropfield has been started
"""
struct StartCropField <: AbstractCropFieldStatus end

"""
    status = SetupCropField()

Indicates the cropfield has been seted up
"""
struct SetupCropField <: AbstractCropFieldStatus end


"""
    status = SetupCropField()

Indicates the cropfield has finished running
"""
struct FinishCropField <: AbstractCropFieldStatus end


"""
    dailyupdate!(cropfield::AquaCropField)

Updates the `cropfield` by one day
"""
function dailyupdate!(cropfield::AquaCropField)
    _dailyupdate!(cropfield.status[1], cropfield)
end

function _dailyupdate!(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing
end

function _dailyupdate!(status::SetupCropField, cropfield::AquaCropField)
    # the status is correct then do something
    nrrun = 1

    repeattoday = cropfield.gvars[:simulation].ToDayNr
    if (cropfield.gvars[:integer_parameters][:daynri]) <= repeattoday
        advance_one_time_step!(cropfield.outputs, cropfield.gvars,
                              cropfield.lvars, cropfield.projectinput[nrrun].ParentDir, nrrun)
        read_climate_nextday!(cropfield.outputs, cropfield.gvars)
        set_gdd_variables_nextday!(cropfield.gvars)
    end
    if (cropfield.gvars[:integer_parameters][:daynri] - 1) == repeattoday
        finalize_run1!(cropfield.outputs, cropfield.gvars, nrrun)
        finalize_run2!(cropfield.outputs, cropfield.gvars, nrrun)
        cropfield.status[1] = FinishCropField()
    end
    return nothing
end

"""
    season_run!(cropfield::AquaCropField)

Updates the `cropfield` for all days in the current season
"""
function season_run!(cropfield::AquaCropField)
    _season_run!(cropfield.status[1], cropfield)
end

function _season_run!(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing
end

function _season_run!(status::SetupCropField, cropfield::AquaCropField)
    # the status is correct then do something
    nrrun = 1

    repeattoday = cropfield.gvars[:simulation].ToDayNr
    loopi = true
    while loopi
        _dailyupdate!(status, cropfield)
        if (cropfield.gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    return nothing
end

"""
    harvest!(cropfield::AquaCropField) 

Indicates to make a harvest on the `cropfield` 
it also makes a daily update along with the harvest
"""
function harvest!(cropfield::AquaCropField) 
    _harvest!(cropfield.status[1], cropfield)
end

function _harvest!(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing
end

function _harvest!(status::SetupCropField, cropfield::AquaCropField)
    th, logi = _timetoharvest(status, cropfield)

    if !logi
        # the crop is not harvestable only do a dailyupdate
        _dailyupdate!(status, cropfield)
        return nothing
    end 



    # the status is correct then do something
    gvars = cropfield.gvars

    cutlog = gvars[:management].Cuttings.Considered 
    gvars[:management].Cuttings.Considered = true

    genlog = gvars[:management].Cuttings.Generate
    gvars[:management].Cuttings.Generate = false

    if gvars[:management].Cuttings.FirstDayNr != undef_int 
       # adjust DayInSeason
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:management].Cuttings.FirstDayNr + 1
    else
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
    end 

    cut_info_record1 = deepcopy(gvars[:cut_info_record1])
    gvars[:cut_info_record1].FromDay = dayinseason
    gvars[:cut_info_record1].NoMoreInfo = false 

    Man = deepcopy(gvars[:array_parameters][:Man])
    Man_info = deepcopy(gvars[:array_parameters][:Man_info])

    _dailyupdate!(status, cropfield) 

    cropfield.gvars[:cut_info_record1] = cut_info_record1
    cropfield.gvars[:management].Cuttings.Considered = cutlog 
    cropfield.gvars[:management].Cuttings.Generate = genlog 
    setparameter!(cropfield.gvars[:array_parameters], :Man, Man)
    setparameter!(cropfield.gvars[:array_parameters], :Man_info, Man_info)

    return nothing
end

"""
    biomass = biomass(cropfield::AquaCropField)

Returns the biomass of the `cropfield` with units `ton/ha`
"""
function biomass(cropfield::AquaCropField)
    _biomass(cropfield.status[1], cropfield)
end

function _biomass(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default return missing 
    missing
end

function _biomass(status::T, cropfield::AquaCropField) where {T<:Union{SetupCropField, FinishCropField}}
    # the status is correct then return something
    gvars = cropfield.gvars
    biomass = gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]
    return  biomass*ton*u"ha^-1"
end

"""
    dryyield = dryyield(cropfield::AquaCropField)

Returns the dry yield of the `cropfield` with units `ton/ha`
"""
function dryyield(cropfield::AquaCropField)
    _dryyield(cropfield.status[1], cropfield)
end

function _dryyield(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default return missing 
    missing
end

function _dryyield(status::T, cropfield::AquaCropField) where {T<:Union{SetupCropField, FinishCropField}}
    # the status is correct then return something
    gvars = cropfield.gvars
    dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
    return dry_yield*ton*u"ha^-1"
end

"""
    freshyield = freshyield(cropfield::AquaCropField)

Returns the fresh yield of the `cropfield` with units `ton/ha`
"""
function freshyield(cropfield::AquaCropField)
    _freshyield(cropfield.status[1], cropfield)
end

function _freshyield(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default return missing 
    missing
end

function _freshyield(status::T, cropfield::AquaCropField) where {T<:Union{SetupCropField, FinishCropField}}
    # the status is correct then return something
    gvars = cropfield.gvars
    if gvars[:crop].DryMatter == undef_int
        fresh_yield = 0
    else
        dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
        fresh_yield = dry_yield/(gvars[:crop].DryMatter/100)
    end
    return fresh_yield*ton*u"ha^-1"
end

"""
    canopycover(cropfield::AquaCropField; actual=true)

Returns the canopy cover of the `cropfield` in percentage of terrain covered.

If `actual=true`, returns the canopy cover just before harvesting,
otherwise returns the canopy cover just after harvesting

The harvesting is done at the end of the day.
"""
function canopycover(cropfield::AquaCropField; actual=true)
    _canopycover(cropfield.status[1], cropfield, actual)
end

function _canopycover(status::T, cropfield::AquaCropField, actual) where T<:AbstractCropFieldStatus
    # by default return missing 
    missing
end

function _canopycover(status::T, cropfield::AquaCropField, actual) where {T<:Union{SetupCropField, FinishCropField}}
    # the status is correct then return something
    gvars = cropfield.gvars
    if actual 
        return gvars[:float_parameters][:cciactual] * 100
    else
        return gvars[:float_parameters][:cciprev] * 100
    end
end


"""
    outputs = basic_run(; kwargs...)

Runs a basic AquaCrop simulation, the `outputs` variable has the final dataframes
with the results of the simulation

`runtype` allowed for now is `NormalFileRun` or `TomlFileRun` 

`NormalFileRun` will use the input from a files like in AquaCrop Fortran (see AquaCrop.jl/test/testcase)

`TomlFileRun` will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)

You can see the daily result in `outputs[:dayout]` 
the result of each harvest in `outputs[:harvestsout]`
the result of the whole season in `outputs[:seasonout]`
the information for the evaluation in `outputs[:evaldataout]`
and the logger information in `outputs[:logger]`
"""
function basic_run(; kwargs...) 
    outputs = start_outputs()
    kwargs, all_ok = check_kwargs(outputs; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        return outputs 
    end

    parentdir = kwargs[:parentdir]

    start_the_program!(outputs, parentdir; kwargs...)
    return outputs 
end

"""
    kwargs, all_ok = check_runtype(outputs; kwargs...)

If we do not have a `kwarg` for `:runtype` it sets it to `NormalFileRun`.
If we do have that `kwarg`, then checks if it is an `AbstractRunType`.

After calling this function check if `all_ok.logi == true`
        
## Examples
```jldoctest
julia> kwargs, all_ok = AquaCrop.check_runtype(Dict(:logger => String[]); runtype = TomlFileRun());

julia> all_ok.logi == true
true
```
"""
function check_runtype(outputs; kwargs...)
    all_ok = AllOk(true, "") 
    if !haskey(kwargs, :runtype) 
        kwargs = merge(kwargs, Dict(:runtype => NormalFileRun()))
        add_output_in_logger!(outputs, "using default NormalFileRun")
    elseif typeof(kwargs[:runtype]) <: AbstractRunType 
        add_output_in_logger!(outputs, "using runtype "*string(kwargs[:runtype]))
    else 
        all_ok.logi = false
        all_ok.msg = "invalid runtype "*string(kwargs[:runtype])
    end

    return kwargs, all_ok 
end

"""
    kwargs, all_ok = check_parentdir(outputs; kwargs...)

If we do not have a `kwarg` for `parentdir` it sets it to `pwd()`.
If we do have that `kwarg`, then checks if that directory exists. 

After calling this function check if `all_ok.logi == true`

## Examples
```jldoctest
julia> kwargs, all_ok = AquaCrop.check_parentdir(Dict(:logger => String[]); parentdir=pwd());

julia> all_ok.logi == true
true
```
"""
function check_parentdir(outputs; kwargs...)
    all_ok = AllOk(true, "") 
    if !haskey(kwargs, :parentdir) 
        kwargs = merge(kwargs, Dict(:parentdir => pwd()))
        add_output_in_logger!(outputs, "using default parentdir pwd()")
    elseif isdir(kwargs[:parentdir]) 
        add_output_in_logger!(outputs, "using given parentdir")
    else 
        all_ok.logi = false
        all_ok.msg = "invalid parentdir"
    end

    return kwargs, all_ok 
end

"""
    kwargs, all_ok = check_nofilerun(outputs; kwargs...)

In case we select a `runtype = NoFileRun()` checks that we have all
the necessary `kwargs`, these are:

For the project input we have the following
necessary keywords: `Simulation_DayNr1`, `Simulation_DayNrN`, `Crop_Day1`, `Crop_DayN`, `InitialClimDate`
each one of them must be a `Date` type.


The `soil_type` must be one of these strings indicating the soil type:
`["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay",
"sandy clay loam", "sandy loam", "silty clay loam", "paddy"]`

The `crop_type` must be one of these  strings indicating the crop type:
`["maize", "wheat", "cotton", "alfalfaGDD", "barley", "barleyGDD", "cottonGDD", "drybean", "drybeanGDD",
"maizeGDD", "wheatGDD", "sugarbeet", "sugarbeetGDD", "sunflower", "sunflowerGDD", "sugarcane"]`

We also have the optional keys:
`[:co2i, :crop, :perennial_period, :soil, :soil_layers, :simulparam,
:Tmin, :Tmax, :ETo, :Rain, :temperature_record, :eto_record, :rain_record,
:management (with this we need to change projectinput.Management_Filename too)]`
which give more control when configurating the `cropfield::AquaCropField`,
similarly to using `NormalFileRun` or `TomlFileRun`.

After calling this function check if `all_ok.logi == true`

## Examples
```jldoctest
julia> using Dates

julia> start_date = Date(2023, 1, 1); # January 1 2023

julia> end_date = Date(2023, 6, 1); # June 1 2023

julia> kwargs = (runtype = NoFileRun(), Simulation_DayNr1 = start_date, Simulation_DayNrN = end_date, Crop_Day1 = start_date, Crop_DayN = end_date, soil_type = "clay", crop_type = "maize", InitialClimDate = start_date);

julia> kwargs, all_ok = AquaCrop.check_nofilerun(Dict(:logger => String[]); kwargs...);

julia> all_ok.logi == true
true
```
"""
function check_nofilerun(outputs; kwargs...)
    all_ok = AllOk(true, "") 

    ## These are keys for starting the cropfield
    # project input
    necessary_keys = [:Simulation_DayNr1, :Simulation_DayNrN, :Crop_Day1, :Crop_DayN]
    for key in necessary_keys
        if !haskey(kwargs, key)
            all_ok.logi = false
            all_ok.msg = "missing necessary keyword :"*string(key)
            return kwargs, all_ok
        end
    end

    # soil
    soil_types = ["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay",
                  "sandy clay loam", "sandy loam", "silty clay loam", "paddy"]
    if !haskey(kwargs, :soil_type) 
        all_ok.logi = false
        all_ok.msg = "missing  necessary keyword :soil_type"
        return kwargs, all_ok
    elseif !(kwargs[:soil_type] in soil_types)
        all_ok.logi = false
        all_ok.msg = "invalid soil_type "*string(kwargs[:soil_type])*" must be one of "*
                      join(soil_types, " , ")
        return kwargs, all_ok
    end

    ## These are keys for making a setup of the cropfield althoug soil_type also can be changed here
    # crop
    crop_types = ["maize", "wheat", "cotton", "alfalfaGDD", "barley", "barleyGDD", "cottonGDD", "drybean", "drybeanGDD",
                  "maizeGDD", "wheatGDD", "sugarbeet", "sugarbeetGDD", "sunflower", "sunflowerGDD", "sugarcane"]
    if !haskey(kwargs, :crop_type) 
        all_ok.logi = false
        all_ok.msg = "missing  necessary keyword :crop_type"
    elseif !(kwargs[:crop_type] in crop_types)
        all_ok.logi = false
        all_ok.msg = "invalid crop_type "*string(kwargs[:crop_type])*" must be one of "*
                     join(crop_types, " , ")
        return kwargs, all_ok
    end

    # Climate dates
    if !haskey(kwargs, :InitialClimDate)
        all_ok.logi = false
        all_ok.msg = "missing  necessary keyword :InitialClimDate"
        return kwargs, all_ok
    end

    # optional keys [:co2i, :crop, :perennial_period, :soil, :soil_layers, :simulparam,
    # :Tmin, :Tmax, :ETo, :Rain, :temperature_record, :eto_record, :rain_record,
    # :management (with this we need to change projectinput.Management_Filename too)]


    return kwargs, all_ok
end


"""
    kwargs, all_ok = check_kwargs(outputs; kwargs...)    

Runs all the necessary checks on the `kwargs`.

After calling this function check if `all_ok.logi == true`

See also [`check_runtype`](@ref), [`check_parentdir`](@ref), [`check_nofilerun`](@ref)

## Examples
```jldoctest
julia> kwargs, all_ok = AquaCrop.check_kwargs(Dict(:logger => String[]); runtype=TomlFileRun(), parentdir=pwd());

julia> all_ok.logi == true
true
```
"""
function check_kwargs(outputs; kwargs...)
    kwargs, all_ok = check_runtype(outputs; kwargs...)
    if !all_ok.logi
        return kwargs, all_ok
    end

    kwargs, all_ok = check_parentdir(outputs; kwargs...)
    if !all_ok.logi
        return kwargs, all_ok
    end

    if kwargs[:runtype] == NoFileRun
        kwargs, all_ok = check_nofilerun(outputs; kwargs...)
        if !all_ok.logi
            return kwargs, all_ok
        end
    end
    
    return kwargs, all_ok
end


"""
    cropfield, all_ok = start_cropfield(; kwargs...)

Starts the `cropfield::AquaCropField` with the proper runtype. 
it uses default values for `runtype` and `parentdir` if these
`kwargs` are missing.

It returns a `cropfield` with default values for crop, soil, etc.
You need to call the function [`setup_cropfield!`](@ref) to actually
load the values that you want for these variables.

After calling this function check if `all_ok.logi == true`

See also [`setup_cropfield!`](@ref)
"""
function start_cropfield(; kwargs...)
    # this variables are here in case later we want to give more control in the season (nrrun)
    # and the project number (nproject)
    nproject = 1
    nrrun = 1

    outputs = start_outputs()
    add_output_in_logger!(outputs, "starting the cropfield")
    kwargs, all_ok = check_kwargs(outputs; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, [BadCropField()]), all_ok
    end

    parentdir = kwargs[:parentdir]

    all_ok = AllOk(true, "")

    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filenames(outputs, filepaths; kwargs...)
    if length(project_filenames) < nproject
        all_ok.logi = false
        all_ok.msg = "no project loaded"
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, [BadCropField()]), all_ok
    end

    theprojectfile = project_filenames[nproject]
    theprojecttype = get_project_type(theprojectfile; kwargs...)
    if theprojecttype == :typenone 
        all_ok.logi = false
        all_ok.msg = "bad projecttype for "*theprojectfile
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, [BadCropField()]), all_ok
    end

    gvars, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, [BadCropField()]) , all_ok
    end

    # run all previouss simulations
    for i in 1:(nrrun-1)
        initialize_run_part1!(outputs, gvars, nrrun; kwargs...)
        initialize_climate!(outputs, gvars, nrrun; kwargs...)
        initialize_run_part2!(outputs, gvars, nrrun; kwargs...)
        file_management!(outputs, gvars, nrrun; kwargs...)
        finalize_run1!(outputs, gvars, nrrun; kwargs...)
        finalize_run2!(outputs, gvars, nrrun; kwargs...)
    end

    add_output_in_logger!(outputs, "cropfield started")
    lvars = Dict()
    return AquaCropField(gvars, outputs, lvars, [StartCropField()]), all_ok
end

"""
    setup_cropfield!(cropfield::AquaCropField, all_ok::AllOk; kwargs...)

Setups the `cropfield` variable,  and reads the configuration files 
with information about the climate.

After calling this function check if `all_ok.logi == true`

See also [`start_cropfield`](@ref)
"""
function setup_cropfield!(cropfield::AquaCropField, all_ok::AllOk; kwargs...)
    _setup_cropfield!(cropfield.status[1], cropfield, all_ok; kwargs...)
end

function _setup_cropfield!(status::T, cropfield::AquaCropField, all_ok::AllOk; kwargs...) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing
end

function _setup_cropfield!(status::StartCropField, cropfield::AquaCropField, all_ok::AllOk; kwargs...)
    # the status is correct then do something
    nrrun = 1

    add_output_in_logger!(cropfield.outputs, "settingup the cropfield")

    kwargs, _all_ok = check_kwargs(cropfield.outputs; kwargs...)
    if !_all_ok.logi
        all_ok.logi = _all_ok.logi
        all_ok.msg = _all_ok.msg
        add_output_in_logger!(cropfield.outputs, all_ok.msg)
        finalize_outputs!(cropfield.outputs)
        cropfield.status[1] = BadCropField()
        return nothing
    end
    
    try 
        initialize_run_part1!(cropfield.outputs, cropfield.gvars, nrrun; kwargs...)
        initialize_climate!(cropfield.outputs, cropfield.gvars, nrrun; kwargs...)
        initialize_run_part2!(cropfield.outputs, cropfield.gvars, nrrun; kwargs...)
    catch e
        all_ok.logi = false
        all_ok.msg = "error when settingup the cropfield "*e.msg
        add_output_in_logger!(cropfield.outputs, all_ok.msg)
        finalize_outputs!(cropfield.outputs)
        cropfield.status[1] = BadCropField()
        return nothing
    end
     
    lvars = initialize_lvars()
    for key in keys(lvars)
        cropfield.lvars[key] = lvars[key]
    end

    add_output_in_logger!(cropfield.outputs, "cropfield setted")
    cropfield.status[1] = SetupCropField()
    return nothing 
end

"""
    change_climate_data!(cropfield::AquaCropField, climate_data::DataFrame; kwargs...)

Changes the climate data in the `cropfield` using the data in `climate_data`.

Note that `climate_data` must have a column
with `:Date` property, other wise we do not change anything.
The function assumes that `:Date` goes day by day.

`climate_data` must also have one of the following climate properties
`[:Tmin, :Tmax, :ETo, :Rain]`.
"""
function change_climate_data!(cropfield::AquaCropField, climate_data::DataFrame; kwargs...)
    _change_climate_data!(cropfield.status[1], cropfield, climate_data; kwargs...)
end

function _change_climate_data!(status::T, cropfield::AquaCropField, climate_data::DataFrame; kwargs...) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing
end

function _change_climate_data!(status::SetupCropField, cropfield::AquaCropField, climate_data::DataFrame; kwargs...)
    # the status is correct then do something

    # check if have the :Date column in climate_data
    if !hasproperty(climate_data, :Date)
        # Silent early return
        add_output_in_logger!(cropfield.outputs, "Did not find :Date on climate_data")
        return nothing
    end

    # Go on
    gvars = cropfield.gvars
    outputs = cropfield.outputs

    # get current date
    daynri_now = gvars[:integer_parameters][:daynri]
    day_now, month_now, year_now = determine_date(daynri_now)
    date_now = Date(year_now, month_now, day_now)

    l_date = climate_data.Date[1] == date_now


    # reset sumgdd if necessary
    if l_date
        reset_gdd_variables!(gvars)
    end

    # change the climate 
    l_tmin = hasproperty(climate_data, :Tmin)
    l_tmax = hasproperty(climate_data, :Tmax)
    l_eto = hasproperty(climate_data, :ETo)
    l_rain = hasproperty(climate_data, :Rain)
    
    if |(l_rain, l_eto, l_tmax, l_tmin)
        for row in eachrow(climate_data)
            date = row.Date
            day_i = determine_day_nr(date)
            i = day_i - gvars[:simulation].FromDayNr + 1
            
            # temperature
            if l_tmin & l_tmax
                if length(outputs[:tempdatasim][:tlow]) > i 
                    outputs[:tempdatasim][:tlow][i] = row.Tmin
                    outputs[:tempdatasim][:thigh][i] = row.Tmax
                end
            end

            # eto
            if l_eto
                if length(outputs[:etodatasim]) > i
                    outputs[:etodatasim][i] = row.ETo
                end
            end

            # rain
            if l_rain
                if length(outputs[:raindatasim]) > i
                    outputs[:raindatasim][i] = row.Rain
                end
            end
        end
    end
    
    # set new climate for next day if necessary
    if l_date
        read_climate_nextday!(outputs, gvars)
        set_gdd_variables_nextday!(gvars)
    end

    return nothing
end


"""
    logi = isharvestable(cropfield::AquaCropField)

If a crop is harvestable returns `true` 

See also [`timetoharvest`](@ref)
"""
function isharvestable(cropfield::AquaCropField)
    return _timetoharvest(cropfield.status[1], cropfield)[2] 
end

"""
    th = timetoharvest(cropfield::AquaCropField)

If a crop is not harvestable returns the minimum amount of simulation days until is harvestable.

If a crop is already harvestable returns how many simulations days until crop reaches maturity.

See also [`isharvestable`](@ref)
"""
function timetoharvest(cropfield::AquaCropField)
    return _timetoharvest(cropfield.status[1], cropfield)[1]
end

function _timetoharvest(status::T, cropfield::AquaCropField) where T<:AbstractCropFieldStatus
    # by default do nothing
    return nothing, nothing 
end


function _timetoharvest(status::T, cropfield::AquaCropField) where {T<:Union{SetupCropField, FinishCropField}}
    # this function relies in determine_growth_stage
    crop = cropfield.gvars[:crop]
    simulation = cropfield.gvars[:simulation]
    dayi = cropfield.gvars[:integer_parameters][:daynri]

    virtualday = dayi - simulation.DelayedDays - crop.Day1
    
    dm = sum(crop.Length[1:4]) # virtual days until crop maturity

    # virtual day is further than crop maturity 
    if virtualday >= dm
        th = -1 # allready reached crop maturity
        logi = true # maybe should be harvestable
    else
        if crop.subkind == :Grain 
            dy = (crop.DaysToFlowering + crop.LengthFlowering) - virtualday # remaining days until yield formation
        elseif crop.subkind == :Tubber
            dy = crop.DaysToFlowering - virtualday # remaining days until yield formation
        else
            dy = crop.DaysToGermination - virtualday # remaining days until vegetative formation
        end
        if dy > 0
            th = dy  # missing time until yield formation
            logi = false # not harvestable yet
        else
            th = dm - virtualday  # missing time until crop maturity
            logi = true # harvestable
        end
    end
    return th, logi
end
