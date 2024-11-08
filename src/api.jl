abstract type AbstractCropField end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct AquaCropField <: AbstractCropField
    gvars::Dict
    outputs::Dict
    lvars::Dict
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
    dailyupdate!(cropfield::AquaCropField)

Updates the AquaCropField by one day
"""
function dailyupdate!(cropfield::AquaCropField)
    nrrun = 1


    repeattoday = cropfield.gvars[:simulation].ToDayNr
    if (cropfield.gvars[:integer_parameters][:daynri]) <= repeattoday
        advance_one_time_step!(cropfield.outputs, cropfield.gvars,
                              cropfield.lvars, cropfield.projectinput[nrrun].ParentDir, nrrun)
        read_climate_nextday!(cropfield.outputs, cropfield.gvars)
        set_gdd_variables_nextday!(cropfield.gvars)
    end
    return nothing
end

"""
    season_run!(cropfield::AquaCropField)

Updates the AquaCropField for all days in season 1
"""
function season_run!(cropfield::AquaCropField)
    nrrun = 1

    repeattoday = cropfield.gvars[:simulation].ToDayNr
    loopi = true
    while loopi
        dailyupdate!(cropfield)
        if (cropfield.gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    finalize_run1!(cropfield.outputs, cropfield.gvars, nrrun)
    finalize_run2!(cropfield.outputs, cropfield.gvars, nrrun)
    
    return nothing
end

"""
    harvest!(cropfield::AquaCropField)

does a daily update with harvest
"""
function harvest!(cropfield::AquaCropField)
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

    dailyupdate!(cropfield) 

    cropfield.gvars[:cut_info_record1] = cut_info_record1
    cropfield.gvars[:management].Cuttings.Considered = cutlog 
    cropfield.gvars[:management].Cuttings.Generate = genlog 
    setparameter!(cropfield.gvars[:array_parameters], :Man, Man)
    setparameter!(cropfield.gvars[:array_parameters], :Man_info, Man_info)

    return nothing
end

"""
    biomass = biomass(cropfield::AquaCropField)

biomass in ton/ha
"""
function biomass(cropfield::AquaCropField)
    gvars = cropfield.gvars
    biomass = gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]
    return  biomass*ton*u"ha^-1"
end

"""
    dryyield = dryyield(cropfield::AquaCropField)

dryyield in ton/ha
"""
function dryyield(cropfield::AquaCropField)
    gvars = cropfield.gvars
    dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
    return dry_yield*ton*u"ha^-1"
end

"""
    freshyield = freshyield(cropfield::AquaCropField)

freshyield in ton/ha
"""
function freshyield(cropfield::AquaCropField)
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

canopy cover in % of terrain, 
"""
function canopycover(cropfield::AquaCropField; actual=true)
    gvars = cropfield.gvars
    if actual 
        return gvars[:float_parameters][:cciactual] * 100
    else
        return gvars[:float_parameters][:cciprev] * 100
    end
end


"""
    outputs = basic_run(; kwargs...)

runs a basic AquaCrop simulation, the outputs variable has the final dataframes
with the results of the simulation

runtype allowed for now is NormalFileRun or TomlFileRun  
where :Fortran will use the input from a files like in AquaCrop Fortran
and :Toml will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)`
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

initializes the kwargs with the proper runtype, check if all_ok.logi == true 
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

initializes the kwargs with the proper parentdir, check if all_ok.logi == true 
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

checks if we have all the necessary keys for runtype = NoFileRun, 
check if all_ok.logi == true
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
    soil_types = ["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay"]
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
    crop_types = ["maize", "wheat", "cotton", "alfalfaGDD"]
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
    check_kwargs(outputs; kwargs...)    

chekcs the necessary kwargs, check if all_ok == true
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

starts the crop with the proper runtype, check if all_ok.logi == true 
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
        return AquaCropField(gvars, outputs, lvars), all_ok
    end

    parentdir = kwargs[:parentdir]

    all_ok = AllOk(true, "")

    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filename(outputs, filepaths; kwargs...)
    if length(project_filenames) < nproject
        all_ok.logi = false
        all_ok.msg = "no project loaded"
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars), all_ok
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
        return AquaCropField(gvars, outputs, lvars), all_ok
    end

    gvars, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars) , all_ok
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
    return AquaCropField(gvars, outputs, lvars), all_ok
end

"""
    setup_cropfield!(cropfield::AquaCropField, all_ok::AllOk; kwargs...)

setups the cropfield variables, check if all_ok.logi == true
"""
function setup_cropfield!(cropfield::AquaCropField, all_ok::AllOk; kwargs...)
    nrrun = 1

    add_output_in_logger!(cropfield.outputs, "settingup the cropfield")

    kwargs, _all_ok = check_kwargs(cropfield.outputs; kwargs...)
    if !_all_ok.logi
        all_ok.logi = _all_ok.logi
        all_ok.msg = _all_ok.msg
        add_output_in_logger!(cropfield.outputs, all_ok.msg)
        finalize_outputs!(cropfield.outputs)
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
    end
     
    lvars = initialize_lvars()
    for key in keys(lvars)
        cropfield.lvars[key] = lvars[key]
    end

    add_output_in_logger!(cropfield.outputs, "cropfield setted")
    return nothing 
end

"""
    change_climate_data!(cropfield::AquaCropField, climate_data::DataFrame; kwargs...)
"""
function change_climate_data!(cropfield::AquaCropField, climate_data::DataFrame; kwargs...)
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
    
    # set new climate for next day if necessary
    if l_date
        read_climate_nextday!(outputs, gvars)
        set_gdd_variables_nextday!(gvars)
    end

    return nothing
end
