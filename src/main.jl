# TODO make a call like   result, result_ok = somefunction(); if !result_of then logg and out

# setup

"""
    start_the_program(dir::Union{String,Nothing}=nothing)

starts the program

startunit.f90:931
"""
function start_the_program(parentdir=nothing)
    if isnothing(parentdir)
        parentdir = pwd()
    end

    filepaths, resultsparameters = initialize_the_program(parentdir) 
    project_filenames = initialize_project_filename(filepaths)

    nprojects = length(project_filenames)
    # TODO write some messages if nprojects==0 like in startunit.F90:957
    # and then early return

    for i in eachindex(project_filenames)
        theprojectfile = project_filenames[i]
        theprojecttype = get_project_type(theprojectfile)
        inse, projectinput, fileok = initialize_project(i, theprojectfile, theprojecttype, filepaths)
    end
end # not end


"""
    inse, projectinput, fileok = initialize_project(i, theprojectfile, theprojecttype, filepaths)

startunit.f90:535
"""
function initialize_project(i, theprojectfile, theprojecttype, filepaths)
    canselect = [true]

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = filepaths[:list] * theprojectfile
        if !isfile(testfile) 
            canselect[1] = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect[1]
        inse = initialize_settings(true, true, filepaths)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            projectinput = initialize_project_input(testfile)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            check_files_in_project!(fileok, canselect, projectinput[1], filepaths[:prog])

            # 4. load project parameters
            if (canselect[1]) 
                auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PP1"
                if isfile(auxparfile) 
                    load_program_parameters_project_plugin!(inse[:simulparam], auxparfile)
                    println("Project loaded with its program parameters")
                else
                    # TODO Logging
                    println("Project loaded with default parameters")
                end
            else
                wrongsimnr = 1
            end 

        elseif theprojecttype == :typeprm
            # 2. Assign multiple project file and read its contents
            projectinput = initialize_project_input(testfile)

            # 2bis. Get number of Simulation Runs
            totalsimruns = length(projectinput)

            # 3. Check if Environment and Simulation Files exist for all runs
            canselect[1] = true
            simnr = 0
            fileok = RepFileOK()
            while (canselect[1] & (simnr < totalsimruns))
                simnr += simnr + 1
                check_files_in_project!(fileok, canselect, projectinput[simnr], filepaths[:prog])
                if (! canselect[1]) 
                    wrongsimnr = simnr
                end
            end 

            # 4. load project parameters
            if (canselect[1]) 
                auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PPn"
                if isfile(auxparfile)
                    load_program_parameters_project_plugin!(inse[:simulparam], auxparfile)
                    inse[:simulation].MultipleRun = true
                    inse[:simulation].NrRuns = totalsimruns
                    runwithkeepswc, constzrxforrun = check_for_keep_swc(projectinput, filepaths, inse)
                    inse[:simulation].MultipleRunWithKeepSWC = runwithkeepswc
                    inse[:simulation].MultipleRunConstZrx = constzrxforrun
                    println("Project loaded with its program parameters")
                else
                    # TODO Logging
                    println("Project loaded with default parameters")
                end
            end 
        end
    
    else
        # TODO better logging
        if canselect[1]
            error("bad projecttype for "*theprojectfile)
        else
            error("did not find the file "*theprojectfile)
        end
    end
    return  inse, projectinput, fileok
end

