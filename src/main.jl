# TODO make a call like   result, result_ok = somefunction(); if !result_of then logg and out

# setup

function starttheprogram(parentdir=nothing)
    if isnothing(parentdir)
        parentdir = pwd()
    end

    filepaths, resultsparameters = initializetheprogram(parentdir) 
    projectfilenames = initializeprojectfilename(filepaths)
    # @infiltrate

    nprojects = length(projectfilenames)
    # TODO write some messages if nprojects==0 like in startunit.F90:957
    # and then early return

    for i in eachindex(projectfilenames)
        theprojectfile = projectfilenames[i]
        theprojecttype = getprojecttype(theprojectfile)
        inse, projectinput, fileok = initializeproject(i, theprojectfile, theprojecttype, filepaths)
    end
end # not end


"""
    inse, projectinput, fileok = initializeproject(i, theprojectfile, theprojecttype, filepaths)
"""
function initializeproject(i, theprojectfile, theprojecttype, filepaths)
    canselect = [true]

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = filepaths[:list] * theprojectfile
        if !isfile(testfile) 
            canselect[1] = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect[1]
        inse = initializesettings(true, true, filepaths)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            projectinput = initializeprojectinput(testfile)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            checkfilesinproject!(fileok, canselect, projectinput[1], filepaths[:prog])

            # 4. load project parameters
            if (canselect[1]) 
                auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PP1"
                if isfile(auxparfile) 
                    loadprogramparametersprojectplugin!(inse[:simulparam], auxparfile)
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
            projectinput = initializeprojectinput(testfile)

            # 2bis. Get number of Simulation Runs
            totalsimruns = length(projectinput)

            # 3. Check if Environment and Simulation Files exist for all runs
            canselect[1] = true
            simnr = 0
            fileok = RepFileOK()
            while (canselect[1] & (simnr < totalsimruns))
                simnr += simnr + 1
                checkfilesinproject!(fileok, canselect, projectinput[simnr], filepaths[:prog])
                if (! canselect[1]) 
                    wrongsimnr = simnr
                end
            end 

            # 4. load project parameters
            if (canselect[1]) 
                auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PPn"
                if isfile(auxparfile)
                    loadprogramparametersprojectplugin!(inse[:simulparam], auxparfile)
                    inse[:simulation].MultipleRun = true
                    inse[:simulation].NrRuns = totalsimruns
                    runwithkeepswc, constzrxforrun = checkforkeepswc(projectinput, filepaths, inse)
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
    # @infiltrate
    return  inse, projectinput, fileok
end

