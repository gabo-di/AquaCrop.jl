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
        kwargs = (:runtype = FortranRun(),)
        add_output_in_logger!(outputs, "using default FortranRun")
    end

    filepaths, resultsparameters = initialize_the_program(outputs, parentdir; kwargs...) 
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
end # notend


"""
    gvars, projectinput, fileok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)

startunit.f90:535
"""
function initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    canselect = [true]

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = filepaths[:list] * theprojectfile
        if !isfile(testfile) 
            canselect[1] = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect[1]
        gvars = initialize_settings(outputs, filepaths; kwargs...)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            projectinput = initialize_project_input(testfile, filepaths[:prog]; kwargs...)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            check_files_in_project!(fileok, canselect, projectinput[1])

            # 4. load project parameters
            if (canselect[1]) 
                if kwargs[:runtype] == :FortranRun
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
                if kwargs[:runtype] == :FortranRun
                    auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PPn"
                else
                    auxparfile = testfile
                end
                if isfile(auxparfile)
                    load_program_parameters_project_plugin!(gvars[:simulparam], auxparfile; kwargs...)
                    gvars[:simulation].MultipleRun = true
                    gvars[:simulation].NrRuns = totalsimruns
                    runwithkeepswc, constzrxforrun = check_for_keep_swc(projectinput, filepaths, gvars)
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
        else
            add_output_in_logger!(outputs, "did not find the file "*theprojectfile)
        end
    end
    return  gvars, projectinput, fileok
end

