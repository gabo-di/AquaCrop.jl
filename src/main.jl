# TODO make a call like   result, result_ok = somefunction(); if !result_of then logg and out

# setup

"""
    start_the_program(parentdir::Union{String,Nothing}=nothing, runtype::Union{Symbol,Nothing}=nothing)

starts the program

startunit.f90:931
"""
function start_the_program(parentdir=nothing, runtype=nothing)
    outputs = start_outputs()

    if isnothing(parentdir)
        parentdir = pwd()
    end
    # runtype allowed for now is :Fortran, :Julia or :Persefone 
    if isnothing(runtype)
        kwargs = (runtype = FortranRun(),)
        add_output_in_logger!(outputs, "using default FortranRun")
    end

    # the part of get_results_parameters is done when we create gvars
    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filename(outputs, filepaths; kwargs...)

    nprojects = length(project_filenames)
    # TODO write some messages if nprojects==0 like in startunit.F90:957
    # and then early return

    for i in eachindex(project_filenames)
        theprojectfile = project_filenames[i]
        theprojecttype = get_project_type(theprojectfile; kwargs...)
        gvars, projectinput, fileok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
        run_simulation!(outputs, gvars, projectinput; kwargs...)
    end

    # finalize_the_program()
    return outputs
end # notend


"""
    gvars, projectinput, fileok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)

startunit.f90:535
"""
function initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    canselect = [true]

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = joinpath(filepaths[:list], theprojectfile)
        if !isfile(testfile) 
            canselect[1] = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect[1]
        gvars = initialize_settings(outputs, filepaths; kwargs...)
        # this function is to transfer data from resultsparameters to gvars
        actualize_gvars_resultparameters!(outputs, gvars, filepaths; kwargs...)
        setparameter!(gvars[:symbol_parameters], :theprojecttype, theprojecttype)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            projectinput = initialize_project_input(testfile, filepaths[:prog]; kwargs...)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            check_files_in_project!(fileok, canselect, projectinput[1])

            # 4. load project parameters
            if (canselect[1]) 
                if typeof(kwargs[:runtype]) == FortranRun
                    auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PP1"
                else
                    auxparfile = testfile
                end
                if isfile(auxparfile) 
                    load_program_parameters_project_plugin!(gvars[:simulparam], auxparfile; kwargs...)
                    add_output_in_logger!(outputs, "Project loaded with its program parameters")
                else
                    add_output_in_logger!(outputs, "Project loaded with default parameters")
                end
            else
                wrongsimnr = 1
            end 

        elseif theprojecttype == :typeprm
            # 2. Assign multiple project file and read its contents
            projectinput = initialize_project_input(testfile, filepaths[:prog]; kwargs...)

            # 2bis. Get number of Simulation Runs
            totalsimruns = length(projectinput)

            # 3. Check if Environment and Simulation Files exist for all runs
            canselect[1] = true
            simnr = 0
            fileok = RepFileOK()
            while (canselect[1] & (simnr < totalsimruns))
                simnr += simnr + 1
                check_files_in_project!(fileok, canselect, projectinput[simnr]) 
                if (! canselect[1]) 
                    wrongsimnr = simnr
                end
            end 

            # 4. load project parameters
            if (canselect[1]) 
                if typeof(kwargs[:runtype]) == FortranRun
                    auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PPn"
                else
                    auxparfile = testfile
                end
                if isfile(auxparfile)
                    load_program_parameters_project_plugin!(gvars[:simulparam], auxparfile; kwargs...)
                    gvars[:simulation].MultipleRun = true
                    gvars[:simulation].NrRuns = totalsimruns
                    runwithkeepswc, constzrxforrun = check_for_keep_swc(outputs, projectinput, filepaths, gvars; kwargs...)
                    gvars[:simulation].MultipleRunWithKeepSWC = runwithkeepswc
                    gvars[:simulation].MultipleRunConstZrx = constzrxforrun
                    add_output_in_logger!(outputs, "Project loaded with its program parameters")
                else
                    add_output_in_logger!(outputs, "Project loaded with default parameters")
                end
            end 
        end
    else
        if canselect[1]
            add_output_in_logger!(outputs, "bad projecttype for "*theprojectfile)
            println("bad projecttype for "*theprojectfile)
        else
            add_output_in_logger!(outputs, "did not find the file "*theprojectfile)
            println("did not find the file "*theprojectfile)
        end
    end
    return  gvars, projectinput, fileok
end


"""
    run_simulation!(outputs, gvars, projectinput::Vector{ProjectInputType}; kwargs...)

run.f90:7779
"""
function run_simulation!(outputs, gvars, projectinput::Vector{ProjectInputType}; kwargs...)
    # this sets outputfiles run.f90:7786 OJO , but maybe we will use dataframes instead
    # call InitializeSimulation(TheProjectFile_, TheProjectType)
 
    nrruns = gvars[:simulation].NrRuns 

    for nrrun in 1:nrruns
        initialize_run_part1!(outputs, gvars, projectinput[nrrun]; kwargs...)
        initialize_climate!(outputs, gvars; kwargs...)
        initialize_run_part2!(outputs, gvars, projectinput[nrrun], nrrun; kwargs...)
        file_management!(outputs, gvars, projectinput[nrrun], nrrun; kwargs...)
        finalize_run1!(outputs, gvars, nrrun; kwargs...)
        finalize_run2!(outputs, gvars; kwargs...)
    end
    # here we can flush more variables ? 
    # call FinalizeSimulation()
    return nothing
end #notend

"""
    actualize_gvars_resultparameters!(outputs, gvars, filepaths; kwargs...)

this function is to transfer data from resultsparameters to gvars
not part of original code
"""

function actualize_gvars_resultparameters!(outputs, gvars, filepaths; kwargs...)

    resultsparameters = get_results_parameters(outputs, filepaths[:simul]; kwargs...)

    for key in keys(resultsparameters[:dailyresults].parameters)
        setparameter!(gvars[:bool_parameters], key, resultsparameters[:dailyresults][key])
    end

    for key in keys(resultsparameters[:aggregationresults].parameters)
        setparameter!(gvars[:integer_parameters], key, resultsparameters[:aggregationresults][key])
    end

    for key in keys(resultsparameters[:particularresults].parameters)
        setparameter!(gvars[:bool_parameters], key, resultsparameters[:particularresults][key])
    end

    return nothing
end

"""
    finalize_run1!(outputs, gvars, nrrun; kwargs...)
    
run.f90:7390
"""
function finalize_run1!(outputs, gvars, nrrun; kwargs...)
    daynri = gvars[:integer_parameters][:daynri]
    # 16. Finalise
    if (daynri-1) == gvars[:simulation].ToDayNr
        # multiple cuttings
        if gvars[:bool_parameters][:part1Mult]
            if gvars[:management].Cuttings.HarvestEnd
                # final harvest at crop maturity
                nrcut = gvars[:integer_parameters][:nrcut]
                setparameter!(gvars[:integer_parameters], :nrcut, nrcut + 1)
                dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
                record_harvest!(outputs, gvars, nrcut + 1, dayinseason, nrrun)
            end 
            dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
            record_harvest!(outputs, gvars, 9999, dayinseason, nrrun) # last line at end of season
        end 
        # intermediate results
        outputaggregate = gvars[:integer_parameters][:outputaggregate]
        if (outputaggregate == 2) | (outputaggregate == 3) & # 10-day and monthly results
            ((daynri-1) > gvars[:integer_parameters][:previoussdaynr]) 
            setparameter!(gvars[:integer_parameters], :daynri, daynri - 1)
            write_intermediate_period!(outputs, gvars)
        end 
        write_sim_period!(outputs, gvars, nrrun)
    end 

    return nothing
end

"""
    write_sim_period!(outputs, gvars, nrrun)

run.f90:6064
"""
function write_sim_period!(outputs, gvars, nrrun)
    # Start simulation run
    day1, month1, year1 = determine_date(gvars[:simulation].FromDayNr)
    # End simulation run
    dayn, monthn, yearn = determine_date(gvars[:simulation].ToDayNr)
    write_the_results!(outputs, nrrun, day1, month1, year1, dayn, monthn, yearn, 
                        gvars[:sumwabal].Rain, gvars[:float_parameters][:sumeto],
                        gvars[:float_parameters][:sumgdd], 
                        gvars[:sumwabal].Irrigation, gvars[:sumwabal].Infiltrated, 
                        gvars[:sumwabal].Runoff, gvars[:sumwabal].Drain, 
                        gvars[:sumwabal].CRwater, gvars[:sumwabal].Eact,
                        gvars[:sumwabal].Epot, gvars[:sumwabal].Tact, 
                        gvars[:sumwabal].TrW, gvars[:sumwabal].Tpot, 
                        gvars[:sumwabal].SaltIn, gvars[:sumwabal].SaltOut, 
                        gvars[:sumwabal].CRsalt, gvars[:sumwabal].Biomass, 
                        gvars[:sumwabal].BiomassUnlim, gvars[:transfer].Bmobilized, 
                        gvars[:simulation].Storage.Btotal, gvars)
    return nothing
end

"""
    finalize_run2!(outputs, gvars; kwargs...)

run.f90:4355
"""
function finalize_run2!(outputs, gvars; kwargs...)
    close_climate!(outputs, gvars; kwargs...)
    close_irrigation!(gvars; kwargs...)
    close_management!(gvars; kwargs...)
end

"""
    close_climate!(outputs, gvars; kwargs...)

delete the climate data from gvars arrays and outputs arrays
"""
function close_climate!(outputs, gvars; kwargs...)
    setparameter!(gvars[:array_parameters], :Tmin, Float64[])
    setparameter!(gvars[:array_parameters], :Tmax, Float64[])
    setparameter!(gvars[:array_parameters], :ETo, Float64[])
    setparameter!(gvars[:array_parameters], :Rain, Float64[])

    setparameter!(gvars[:float_parameters], :tmin, undef_double)
    setparameter!(gvars[:float_parameters], :tmax, undef_double)
    setparameter!(gvars[:float_parameters], :eto, undef_double)
    setparameter!(gvars[:float_parameters], :rain, undef_double)

    flush_output_tcropsim!(outputs)
    flush_output_etodatasim!(outputs)
    flush_output_raindatasim!(outputs)
    flush_output_tempdatasim!(outputs)
end

"""
    close_irrigation!(gvars; kwargs...)

delete the irrigation data from gvars arrays
"""
function close_irrigation!(gvars; kwargs...)
    setparameter!(gvars[:array_parameters], :Irri_1, Float64[])
    setparameter!(gvars[:array_parameters], :Irri_2, Float64[])
    setparameter!(gvars[:array_parameters], :Irri_3, Float64[])
    setparameter!(gvars[:array_parameters], :Irri_4, Float64[])

    setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    
    return nothing
end

"""
    close_management!(gvars; kwargs...)

delete the management data from gvars arrays
"""
function close_management!(gvars; kwargs...)
    setparameter!(gvars[:array_parameters], :Man, Float64[])
    setparameter!(gvars[:array_parameters], :Man_info, Float64[])

    setparameter!(gvars[:integer_parameters], :nrcut, 0)

    return nothing
end
