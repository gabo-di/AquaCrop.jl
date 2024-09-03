"""
    outputs = start_the_program(parentdir::Union{String,Nothing}=nothing, runtype::Union{Symbol,Nothing}=nothing)

starts the program

startunit.f90:931
"""
function start_the_program!(outputs, parentdir; kwargs...)
    # the part of get_results_parameters is done when we create gvars
    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filename(outputs, filepaths; kwargs...)

    nprojects = length(project_filenames)
    if nprojects == 0
        add_output_in_logger!(outputs, "no project loaded")
    end

    for i in eachindex(project_filenames)
        theprojectfile = project_filenames[i]
        theprojecttype = get_project_type(theprojectfile; kwargs...)
        if theprojecttype == :typenone 
            add_output_in_logger!(outputs, "bad projecttype for "*theprojectfile)
            continue
        end

        gvars, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
        if !all_ok.logi
            add_output_in_logger!(outputs, all_ok.msg)
            continue
        end

        run_simulation!(outputs, gvars; kwargs...)
        add_output_in_logger!(outputs, "run project "*string(i))
    end

    finalize_the_program!(outputs)
    return nothing 
end 


"""
    gvars, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)

startunit.f90:535
"""
function initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    all_ok = AllOk(true, "")
    canselect = [true]
    wrongsimnr = nothing

    # check if project file exists
    testfile = joinpath(filepaths[:list], theprojectfile)
    if !isfile(testfile) 
        all_ok.logi = false
        all_ok.msg =  "did not find the file "*theprojectfile
        canselect[1] = false
    end 

    if canselect[1]
        gvars = initialize_settings(outputs, filepaths; kwargs...)
        # this function is to transfer data from resultsparameters to gvars
        actualize_gvars_resultparameters!(outputs, gvars, filepaths; kwargs...)
        setparameter!(gvars[:symbol_parameters], :theprojecttype, theprojecttype)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            initialize_project_input!(gvars, testfile, filepaths[:prog]; kwargs...)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            check_files_in_project!(fileok, canselect, gvars[:projectinput][1])

            # 4. load project parameters
            if (canselect[1]) 
                if typeof(kwargs[:runtype]) == NormalFileRun
                    auxparfile = joinpath(filepaths[:param], theprojectfile[1:end-3]*"PP1")
                elseif typeof(kwargs[:runtype]) == TomlFileRun
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
                all_ok.logi = false
                all_ok.msg = "wrong files for project nrrun "*string(wrongsimnr)
            end 

        elseif theprojecttype == :typeprm
            # 2. Assign multiple project file and read its contents
            initialize_project_input!(gvars, testfile, filepaths[:prog]; kwargs...)

            # 2bis. Get number of Simulation Runs
            totalsimruns = length(gvars[:projectinput])

            # 3. Check if Environment and Simulation Files exist for all runs
            canselect[1] = true
            simnr = 0
            fileok = RepFileOK()
            while (canselect[1] & (simnr < totalsimruns))
                simnr += simnr + 1
                check_files_in_project!(fileok, canselect, gvars[:projectinput][simnr]) 
                if (! canselect[1]) 
                    wrongsimnr = simnr
                end
            end 

            # 4. load project parameters
            if (canselect[1]) 
                if typeof(kwargs[:runtype]) == NormalFileRun
                    auxparfile = joinpath(filepaths[:param], theprojectfile[1:end-3]*"PPn")
                elseif typeof(kwargs[:runtype]) == TomlFileRun
                    auxparfile = testfile
                end
                if isfile(auxparfile)
                    load_program_parameters_project_plugin!(gvars[:simulparam], auxparfile; kwargs...)
                    gvars[:simulation].MultipleRun = true
                    gvars[:simulation].NrRuns = totalsimruns
                    runwithkeepswc, constzrxforrun = check_for_keep_swc(outputs, gvars[:projectinput], filepaths, gvars; kwargs...)
                    gvars[:simulation].MultipleRunWithKeepSWC = runwithkeepswc
                    gvars[:simulation].MultipleRunConstZrx = constzrxforrun
                    add_output_in_logger!(outputs, "Project loaded with its program parameters")
                else
                    add_output_in_logger!(outputs, "Project loaded with default parameters")
                end
            else
                all_ok.logi = false
                all_ok.msg = "wrong files for project nrrun "*string(wrongsimnr)
            end 
        end
    end

    return  gvars, all_ok 
end


"""
    run_simulation!(outputs, gvars; kwargs...)

run.f90:7779
"""
function run_simulation!(outputs, gvars; kwargs...)
    nrruns = gvars[:simulation].NrRuns 

    for nrrun in 1:nrruns
        initialize_run_part1!(outputs, gvars, nrrun; kwargs...)
        initialize_climate!(outputs, gvars, nrrun; kwargs...)
        initialize_run_part2!(outputs, gvars, nrrun; kwargs...)
        file_management!(outputs, gvars, nrrun; kwargs...)
        finalize_run1!(outputs, gvars, nrrun; kwargs...)
        finalize_run2!(outputs, gvars, nrrun; kwargs...)
    end
    return nothing
end 

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
    finalize_run2!(outputs, gvars, nrrun; kwargs...)

run.f90:4355
"""
function finalize_run2!(outputs, gvars, nrrun; kwargs...)
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

"""
    finalize_the_program!(outputs)
"""
function finalize_the_program!(outputs)
    finalize_outputs!(outputs)
    add_output_in_logger!(outputs, "program run finished")
    return nothing
end


"""
    finalize_outputs!(outputs)
"""
function finalize_outputs!(outputs)
    # delete unnecesary outputs
    delete!(outputs, :tcropsim)
    delete!(outputs, :etodatasim)
    delete!(outputs, :raindatasim)
    delete!(outputs, :tempdatasim)
    return nothing
end
