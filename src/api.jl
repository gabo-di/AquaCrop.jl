abstract type AbstractCropField end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct AquaCropField <: AbstractCropField
    gvars::ComponentArray
    outputs::ComponentArray
    lvars::ComponentArray
    parentdir::AbstractString
end

function Base.getindex(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    else
        return getfield(b, :gvars)[s]
    end
end

function Base.getproperty(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    else
        return getfield(b, :gvars)[s]
    end
end



"""
    AquaCropField(parentdir::AbstractString, runtype=nothing)

Starts the struct AquaCropField that has all the data for the simulation of AquaCrop
"""
function AquaCropField(parentdir::AbstractString, runtype=nothing)
    cropfield, all_ok = aquacrop_initialize_cropfield(parentdir, runtype)
    return cropfield
end


"""
    aquacrop_dailyupdate!(cropfield::AquaCropField)

Updates the AquaCropField by one day
"""
function aquacrop_dailyupdate!(cropfield::AquaCropField)
    nrrun = 1
    advance_one_time_step!(cropfield.outputs, cropfield.gvars,
                           cropfield.lvars, cropfield.parentdir, nrrun)
    read_climate_nextday!(cropfield.outputs, cropfield.gvars)
    set_gdd_variables_nextday!(cropfield.gvars)
    return nothing
end


"""
    aquacrop_harvest!(cropfield::AquaCropField)

do harvest
"""
function aquacrop_harvest!(cropfield::AquaCropField)
    nrrun = 1
    gvars = cropfield.AquaCropField
    outputs = cropfield.AquaCropField

    nrcut = gvars[:integer_parameters][:nrcut]
    dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1

    setparameter!(gvars[:integer_parameters], :nrcut, nrcut + 1)
    setparameter!(gvars[:integer_parameters], :daylastcut, dayinseason)
    if gvars[:float_parameters][:cciprev] > (gvars[:management].Cuttings.CCcut/100)
        setparameter!(gvars[:float_parameters], :cciprev, gvars[:management].Cuttings.CCcut/100)
        # ook nog CCwithered
        gvars[:crop].CCxWithered = 0  # or CCiPrev ??
        setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.0) 
        # for calculation Maximum Biomass unlimited soil fertility
        gvars[:crop].CCxAdjusted = gvars[:float_parameters][:cciprev] # new
    end 
    # Record harvest
    if gvars[:bool_parameters][:part1Mult]
          record_harvest!(outputs, gvars, nrcut + 1, dayinseason, nrrun)
    end 
    # Reset
    setparameter!(gvars[:integer_parameters], :suminterval, 0)
    setparameter!(gvars[:float_parameters], :sumgddcuts, 0)
    setparameter!(gvars[:float_parameters], :bprevsum, gvars[:sumwabal].Biomass)
    setparameter!(gvars[:float_parameters], :yprevsum, gvars[:sumwabal].YieldPart)
    return nothing
end

"""
    biomass = aquacrop_biomass(cropfield::AquaCropField)

biomass in ton/ha
"""
function aquacrop_biomass(cropfield::AquaCropField)
    gvars = cropfield.gvars
    biomass = gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]
    return  biomass*ton*u"ha^-1"
end


"""
    dryyield = aquacrop_dryyield(cropfield::AquaCropField)

dryyield in ton/ha
"""
function aquacrop_dryyield(cropfield::AquaCropField)
    gvars = cropfield.gvars
    dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
    return dry_yield*ton*u"ha^-1"
end


"""
    freshyield = aquacrop_freshyield(cropfield::AquaCropField)

freshyield in ton/ha
"""
function aquacrop_freshyield(cropfield::AquaCropField)
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
    outputs = aquacrop_basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)

runs a basic AquaCrop simulation, the outputs variable has the final dataframes
with the results of the simulation

runtype allowed for now is :Fortran or :Julia  
where :Fortran will use the input from a files like in AquaCrop Fortran
and :Julia will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)`
"""

function aquacrop_basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)
    outputs = start_outputs()
    kwargs, all_ok = aquacrop_initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        return outputs
    end

    start_the_program!(outputs, parentdir; kwargs...)
    return outputs
end

"""
    kwargs, all_ok = aquacrop_initialize_kwargs(outputs, runtype)

initializes the kwargs with the proper runtype, check is all_ok.logi == true 
"""
function aquacrop_initialize_kwargs(outputs, runtype)

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
    cropfield, all_ok = aquacrop_initialize_cropfield(parentdir, runtype)

initializes the crop with the proper runtype, check is all_ok.logi == true 
"""
function aquacrop_initialize_cropfield(parentdir, runtype)
    # this variables are here in case later we want to give more control in the season (nrrun)
    # and the project number (nproject)
    nproject = 1
    nrrun = 1

    outputs = start_outputs()
    kwargs, all_ok = aquacrop_initialize_kwargs(outputs, runtype)
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

