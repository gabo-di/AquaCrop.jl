# TODO make a call like   result, result_ok = somefunction(); if !result_of then logg and out

# setup

function starttheprogram(parentdir=nothing)
    if isnothing(parentdir)
        parentdir = pwd()
    end

    filepaths, resultsparameters = initializetheprogram(parentdir) 
    projectfilenames = initializeprojectfilename(filepaths)

    nprojects = length(projectfilenames)
    # TODO write some messages if nprojects==0 like in startunit.F90:957
    # and then early return

    for i in eachindex(projectfilenames)
        theprojectfile = projectfilenames[i]
        theprojecttype = getprojecttype(theprojectfile)
        initializeproject(i, theprojectfile, theprojecttype, filepaths)
        # runsimulation(theprojectfile, theprojecttype)
    end
end # not end



function initializeproject(i, theprojectfile, theprojecttype, filepaths)
    canselect = [true]

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = filepaths[:list] * theprojectfile
        if !isfile(testfile) 
            canselect[1] = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect
        inse = initializesettings(true, true, filepaths)

        if theprojecttype == :typepro
            # 2. Assign single project file and read its contents
            projectinput = initializeprojectinput(testfile)

            # 3. Check if Environment and Simulation Files exist
            fileok = RepFileOK()
            checkfilesinproject!(fileok, canselect, projectinput[1])

            # 4. load project parameters
            if (canselect[1]) 
                auxparfile = filepaths[:param]*theprojectfile[1:end-3]*"PP1"
                # HERE
                loadprogramparametersprojectplugin(inse[:simulparam], auxparfile)
                call ComposeOutputFileName(GetProjectFile())
            else
                WrongSimNr = 1
            end 

        elseif theprojecttype == :typeprm
            # something else
        end
    
    else
        # TODO better logging
        if canselect
            error("bad projecttype for "*theprojectfile)
        else
            error("did not find the file "*theprojectfile)
        end
    end
    return 
end # not end

