abstract type AbstractCropField end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct AquaCropField <: AbstractCropField
    gvars::ComponentArray
    outputs::ComponentArray
    lvars::ComponentArray
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
    AquaCropField(parentdir::AbstractString)

Starts the struct AquaCropField that has all the data for the simulation of AquaCrop
"""
function AquaCropField(parentdir::AbstractString)
    runtype = :Julia
    cropfield, all_ok = aquacrop_initialize_cropfield(parentdir, runtype; nproject=1, nrrun=1)
    return cropfield
end


"""
    dailyupdate!(cropfield::AquaCropField)

Updates the AquaCropField by one day
"""
function dailyupdate!(cropfield::AquaCropField)
    return nothing
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
    cropfield, all_ok = aquacrop_initialize_cropfield(parentdir, runtype; nproject=1, nrrun=1)

initializes the crop with the proper runtype, check is all_ok.logi == true 
in case you have more than one project give the nproject
in case you have more than one season give the season number nrrun
"""
function aquacrop_initialize_cropfield(parentdir, runtype; nproject=1, nrrun=1)
    outputs = start_outputs()
    kwargs, all_ok = aquacrop_initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars), all_ok
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
        return AquaCropField(gvars, outputs, lvars), all_ok
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
        return AquaCropField(gvars, outputs, lvars), all_ok
    end



    gvars, projectinput, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = ComponentArray()
        lvars = ComponentArray()
        return AquaCropField(gvars, outputs, lvars), all_ok
    end

    # run all previouss simulations
    for i in 1:(nrrun-1)
        run_simulation!(outputs, gvars, projectinput; kwargs...)
    end
    initialize_run_part1!(outputs, gvars, projectinput[nrrun]; kwargs...)
    initialize_climate!(outputs, gvars; kwargs...)
    initialize_run_part2!(outputs, gvars, projectinput[nrrun], nrrun; kwargs...)
    lvars = initialize_lvars()

    return AquaCropField(gvars, outputs, lvars), all_ok
end

