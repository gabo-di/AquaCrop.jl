abstract type AbstractCropField end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct AquaCropField <: AbstractCropField
    gvars::ComponentArray
    outputs::Dict
    lvars::ComponentArray
    parentdir::AbstractString
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



"""
    AquaCropField(parentdir::AbstractString, runtype=nothing)

Starts the struct AquaCropField that has all the data for the simulation of AquaCrop
"""
function AquaCropField(parentdir::AbstractString, runtype=nothing)
    cropfield, all_ok = initialize_cropfield(parentdir, runtype)
    return cropfield
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
                               cropfield.lvars, cropfield.parentdir, nrrun)
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
    finalize_run2!(cropfield.outputs, cropfield.gvars)
    
    return nothing
end

"""
start cropfield season save=true/false  cropfield=nothing

reset climate

"""


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
    canopycover(cropfield::AquaCropField)

canopy cover in % of terrain
"""
function canopycover(cropfield::AquaCropField)
    gvars = cropfield.gvars
    return gvars[:float_parameters][:cciactual] * 100
end



"""
    outputs = basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)

runs a basic AquaCrop simulation, the outputs variable has the final dataframes
with the results of the simulation

runtype allowed for now is :Fortran or :Julia  
where :Fortran will use the input from a files like in AquaCrop Fortran
and :Julia will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)`
"""

function basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)
    outputs = start_outputs()
    kwargs, all_ok = initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        return outputs
    end

    start_the_program!(outputs, parentdir; kwargs...)
    return outputs
end

"""
    kwargs, all_ok = initialize_kwargs(outputs, runtype)

initializes the kwargs with the proper runtype, check is all_ok.logi == true 
"""
function initialize_kwargs(outputs, runtype)

    all_ok = AllOk(true, "") 
    # runtype allowed for now is :Fortran, :Julia or :Persefone 
    if isnothing(runtype)
        kwargs = (runtype = FortranRun(),)
        add_output_in_logger!(outputs, "using default FortranRun")
    elseif runtype == :Fortran 
        kwargs = (runtype = FortranRun(),)
        add_output_in_logger!(outputs, "using default FortranRun")
    elseif runtype == :Julia
        kwargs = (runtype = JuliaRun(),)
        add_output_in_logger!(outputs, "using default JuliaRun")
    else 
        kwargs = (runtype = nothing,)
        all_ok.logi = false
        all_ok.msg = "invalid runtype"
    end

    return kwargs, all_ok 
end

"""
    cropfield, all_ok = initialize_cropfield(parentdir, runtype)

initializes the crop with the proper runtype, check is all_ok.logi == true 
"""
function initialize_cropfield(parentdir, runtype)
    # this variables are here in case later we want to give more control in the season (nrrun)
    # and the project number (nproject)
    nproject = 1
    nrrun = 1

    outputs = start_outputs()
    kwargs, all_ok = initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    all_ok = AllOk(true, "")

    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filename(outputs, filepaths; kwargs...)
    if length(project_filenames) < nproject
        all_ok.logi = false
        all_ok.msg = "no project loaded"
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    theprojectfile = project_filenames[nproject]
    theprojecttype = get_project_type(theprojectfile; kwargs...)
    if theprojecttype == :typenone 
        all_ok.logi = false
        all_ok.msg = "bad projecttype for "*theprojectfile
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    gvars, projectinput, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    # run all previouss simulations
    for i in 1:(nrrun-1)
        run_simulation!(outputs, gvars, projectinput; kwargs...)
    end
    initialize_run_part1!(outputs, gvars, projectinput[nrrun]; kwargs...)
    initialize_climate!(outputs, gvars; kwargs...)
    initialize_run_part2!(outputs, gvars, projectinput[nrrun], nrrun; kwargs...)
    lvars = initialize_lvars()

    return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
end

