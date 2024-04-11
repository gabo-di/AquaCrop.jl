
"""
   runwithkeepswc, constzrxforrun = checkforkeepswc(projectinput::Vector{ProjectInputType}, filepaths, inse)
"""
function checkforkeepswc(projectinput::Vector{ProjectInputType}, filepaths, inse)
    # @NOTE This procedure will try to read from the soil profile file.
    # If this file does not exist, the necessary information is gathered
    # from the attributes of the Soil global variable instead.

    # 1. Initial settings
    runwithkeepswc = false
    constzrxforrun =  undef_double

    # 2. Look for restrictive soil layer
    # restricted to run 1 since with KeepSWC,
    # the soil file has to be common between runs
    previousproffilefull = filepaths[:simul]*"DEFAULT.SOL" # keep name soil file (to restore after check)

    filename = projectinput[1].Soil_Filename
    has_external = filename == "(External)"

    if (has_external) 
        # Note: here we use the AquaCrop version number and assume that
        # the same version can be used in finalizing the soil settings.
        soil = inse[:soil]
        soillayers = inse[:soillayers]
        compartments = inse[:compartments]
    elseif (filename == "(None)") 
        soil = inse[:soil]
        soillayers = inse[:soillayers]
        compartments = inse[:compartments]
    else
        soil, soillayers, compartments = loadprofile(projectinput[1].Soil_Directory*filename)
    end 

    thenrsoillayers = length(soillayers)

    # 3. Check if runs with KeepSWC exist
    runi = 1
    totalnrofruns = length(projectinput)
    while ((runwithkeepswc == false) & (runi <= totalnrofruns))
        if (projectinput[runi].SWCIni_Filename == "KeepSWC") 
            runwithkeepswc = true
        end 
        runi = runi + 1
    end 

    if (runwithkeepswc == false) 
        constzrxforrun = undef_double # reset
    end 

    # 4. Look for maximum root zone depth IF RunWithKeepSWC
    if (runwithkeepswc == true)
        runi = 1
        while (runi <= totalnrofruns)
            # Obtain maximum rooting depth from the crop file
            fullfilename = projectinput[runi].Crop_Directory*projectinput[runi].Crop_Filename

            open(fullfilename, "r") do file
                readline(file) # description
                versionnr = parse(Float64,strip(readline(file))[1:4])
                for i in 1:34
                    readline(file) 
                end 
                zrni = parse(Float64,strip(readline(file))[1:6])
                zrxi = parse(Float64,strip(readline(file))[1:6])
            end
                zrsoili = rootmaxinsoilprofile(zmaxcrop, soillayers)
                if (zrsoili > constzrxforrun) 
                    constzrxforrun = zrsoili
                end 
            runi = runi + 1
        end 
    end 

    # 5. Reload existing soil file is not necessary since we do not change any variables

    return runwithkeepswc, constzrxforrun
end 




"""
    loadprogramparametersprojectplugin!(simulparam::RepParam, auxparfile)
"""
function loadprogramparametersprojectplugin!(simulparam::RepParam, auxparfile)
    open(auxparfile, "r") do file
        # crop
        simulparam.EvapDeclineFactor =  parse(Float64,strip(readline(file))[1:6]) # evaporation decline factor in stage 2
        simulparam.KcWetBare = parse(Float64,strip(readline(file))[1:6]) # Kc wet bare soil [-]
        simulparam.PercCCxHIfinal = parse(Float64,strip(readline(file))[1:6]) # CC threshold below which HI no longer increase(% of 100)
        simulparam.RootPercentZmin = parse(Float64,strip(readline(file))[1:6]) # Starting depth of root sine function (% of Zmin)
        simulparam.MaxRootZoneExpansion = parse(Float64,strip(readline(file))[1:6]) # cm/day
        simulparam.MaxRootZoneExpansion = 5.0 # fixed at 5 cm/day
        simulparam.KsShapeFactorRoot = parse(Float64,strip(readline(file))[1:6]) # Shape factor for effect water stress on rootzone expansion
        simulparam.TAWGermination = parse(Float64,strip(readline(file))[1:6]) # Soil water content (% TAW) required at sowing depth for germination
        simulparam.pAdjFAO = parse(Float64,strip(readline(file))[1:6])  # Adjustment factor for FAO-adjustment soil water depletion  (p) for various ET
        simulparam.DelayLowOxygen = parse(Float64,strip(readline(file))[1:6]) # number of days for full effect of deficient aeration
        simulparam.ExpFsen = parse(Float64,strip(readline(file))[1:6]) # exponent of senescence factor adjusting drop in photosynthetic activity of dying crop
        simulparam.Beta = parse(Float64,strip(readline(file))[1:6]) # Decrease (percentage) of p(senescence) once early canopy senescence is triggered
        simulparam.ThicknessTopSWC = parse(Float64,strip(readline(file))[1:6]) # Thickness top soil (cm) in which soil water depletion has to be determined field
        simulparam.EvapZmax = parse(Float64,strip(readline(file))[1:6]) # maximum water extraction depth by soil evaporation [cm] soil
        simulparam.RunoffDepth = parse(Float64,strip(readline(file))[1:6]) # considered depth (m) of soil profile for calculation of mean soil water content
        i = parse(Int,strip(readline(file))[1:6])
        if (i == 1) 
            simulparam.CNcorrection = true
        else
            simulparam.CNcorrection = false
        end 
        simulparam.SaltDiff = parse(Float64,strip(readline(file))[1:6]) # salt diffusion factor (%)
        simulparam.SaltSolub = parse(Float64,strip(readline(file))[1:6]) # salt solubility (g/liter)
        simulparam.RootNrDF = parse(Float64,strip(readline(file))[1:6]) # shape factor capillary rise factor
        simulparam.IniAbstract = 5 # fixed in Version 5.0 cannot be changed since linked with equations for CN AMCII and CN converions

        # Temperature
        simulparam.Tmin = parse(Float64,strip(readline(file))[1:6]) # Default minimum temperature (degC) if no temperature file is specified
        simulparam.Tmax = parse(Float64,strip(readline(file))[1:6]) # Default maximum temperature (degC) if no temperature file is specified
        simulparam.GDDMethod = parse(Float64,strip(readline(file))[1:6]) # Default method for GDD calculations
        if (simulparam.GDDMethod > 3) 
            simulparam.GDDMethod = 3
        end 
        if (simulparam.GDDMethod < 1) 
            simulparam.GDDMethod = 1
        end 

        # Rainfall
        i = parse(Int,strip(readline(file))[1:6])
        if (i==0)
            simulparam.EffectiveRain.method = :Full
        elseif (i==1)
            simulparam.EffectiveRain.method = :USDA
        elseif (i==2)
            simulparam.EffectiveRain.method = :Percentage
        end 

        simulparam.EffectiveRain_PercentEffRain = parse(Float64,strip(readline(file))[1:6]) # IF Method is Percentage
        simulparam.EffectiveRain_ShowersInDecade = parse(Float64,strip(readline(file))[1:6])# For estimation of surface run-off
        simulparam.EffectiveRain_RootNrEvap = parse(Float64,strip(readline(file))[1:6]) # For reduction of soil evaporation
    end
    return nothing
end

"""
    checkfilesinproject!(fileok::RepFileOK, allok, input::ProjectInputType)
"""
function checkfilesinproject!(fileok::RepFileOK, allok, input::ProjectInputType)
    allok[1] = true

    function check_file(directory, filename)
        # sets allok to false if expected file does not exist.
        if (filename != "(None)") 
            if !isfile(directory*filename) 
                allok[1] = false
                fileok_tmp = false
            else
                fileok_tmp = true
            end 
        else
            fileok_tmp = true
        end 
        return fileok_tmp
    end

    # Check the 14 files
    fileok_tmp = check_file(input.Climate_Directory, input.Climate_Filename)
    fileok.Climate_Filename = fileok_tmp
    fileok_tmp = check_file(input.Temperature_Directory, input.Temperature_Filename)
    fileok.Temperature_Filename = fileok_tmp
    fileok_tmp = check_file(input.ETo_Directory, input.ETo_Filename)
    fileok.ETo_Filename = fileok_tmp
    fileok_tmp = check_file(input.Rain_Directory, input.Rain_Filename)
    fileok.Rain_Filename = fileok_tmp
    fileok_tmp = check_file(input.CO2_Directory, input.CO2_Filename)
    fileok.CO2_Filename = fileok_tmp
    fileok_tmp = check_file(input.Calendar_Directory, input.Calendar_Filename)
    fileok.Calendar_Filename = fileok_tmp
    fileok_tmp = check_file(input.Crop_Directory, input.Crop_Filename)
    fileok.Crop_Filename = fileok_tmp
    fileok_tmp = check_file(input.Irrigation_Directory, input.Irrigation_Filename)
    fileok.Irrigation_Filename = fileok_tmp
    fileok_tmp = check_file(input.Management_Directory, input.Management_Filename)
    fileok.Management_Filename = fileok_tmp
    fileok_tmp = check_file(input.GroundWater_Directory, input.GroundWater_Filename)
    fileok.GroundWater_Filename = fileok_tmp
    fileok_tmp = check_file(input.Soil_Directory, input.Soil_Filename)
    fileok.Soil_Filename = fileok_tmp

    if (input.SWCIni_Filename != "KeepSWC") 
        fileok_tmp = check_file(input.SWCIni_Directory, input.SWCIni_Filename)
        fileok.SWCIni_Filename = fileok_tmp
    end 

    fileok_tmp = check_file(input.OffSeason_Directory, input.OffSeason_Filename)
    fileok.OffSeason_Filename = fileok_tmp
    fileok_tmp = check_file(input.Observations_Directory, input.Observations_Filename)
    fileok.Observations_Filename = fileok_tmp

    return nothing
end


"""
    projectinput = initializeprojectinput(filename)
"""
function initializeprojectinput(filename)
    projectinput = ProjectInputType[]
    open(filename,"r") do file
        description = strip(readline(file))
        versionnr = parse(Float64,strip(readline(file))[1:4])
        while !eof(file)
            self = ProjectInputType()
            self.Description = description
            self.VersionNr = versionnr

            # 0. Year of cultivation and Simulation and Cropping period
            self.Simulation_YearSeason = parse(Int,strip(readline(file))[1:6])
            self.Simulation_DayNr1 = parse(Int,strip(readline(file))[1:6])
            self.Simulation_DayNrN = parse(Int,strip(readline(file))[1:6])
            self.Crop_Day1 = parse(Int,strip(readline(file))[1:6])
            self.Crop_DayN = parse(Int,strip(readline(file))[1:6])

            # 1. Climate
            self.Climate_Info = strip(readline(file))
            self.Climate_Filename = strip(readline(file))
            self.Climate_Directory = strip(readline(file))

            # 1.1 Temperature
            self.Temperature_Info = strip(readline(file))
            self.Temperature_Filename = strip(readline(file))
            self.Temperature_Directory = strip(readline(file))

            # 1.2 ETo
            self.ETo_Info = strip(readline(file))
            self.ETo_Filename = strip(readline(file))
            self.ETo_Directory = strip(readline(file))

            # 1.3 Rain
            self.Rain_Info = strip(readline(file))
            self.Rain_Filename = strip(readline(file))
            self.Rain_Directory = strip(readline(file))

            # 1.4 CO2
            self.CO2_Info = strip(readline(file))
            self.CO2_Filename = strip(readline(file))
            self.CO2_Directory = strip(readline(file))

            # 2. Calendar
            self.Calendar_Info = strip(readline(file))
            self.Calendar_Filename = strip(readline(file))
            self.Calendar_Directory = strip(readline(file))

            # 3. Crop
            self.Crop_Info = strip(readline(file))
            self.Crop_Filename = strip(readline(file))
            self.Crop_Directory = strip(readline(file))

            self.Irrigation_Info = strip(readline(file))
            self.Irrigation_Filename = strip(readline(file))
            self.Irrigation_Directory = strip(readline(file))

            # 5. Field Management
            self.Management_Info = strip(readline(file))
            self.Management_Filename = strip(readline(file))
            self.Management_Directory = strip(readline(file))

            # 6. Soil Profile
            self.Soil_Info = strip(readline(file))
            self.Soil_Filename = strip(readline(file))
            self.Soil_Directory = strip(readline(file))

            # 7. GroundWater
            self.GroundWater_Info = strip(readline(file))
            self.GroundWater_Filename = strip(readline(file))
            self.GroundWater_Directory = strip(readline(file))

            # 8. Initial conditions
            self.SWCIni_Info = strip(readline(file))
            self.SWCIni_Filename = strip(readline(file))
            self.SWCIni_Directory = strip(readline(file))

            # 9. Off-season conditions
            self.OffSeason_Info = strip(readline(file))
            self.OffSeason_Filename = strip(readline(file))
            self.OffSeason_Directory = strip(readline(file))

            # 10. Field data
            self.Observations_Info = strip(readline(file))
            self.Observations_Filename = strip(readline(file))
            self.Observations_Directory = strip(readline(file))

            push!(projectinput, self)
        end
    end
    return projectinput
end


"""
    inse = initializesettings(usedefaultsoilfile, usedefaultcropfile, filepaths)

gets the initial settings.
"""
function initializesettings(usedefaultsoilfile, usedefaultcropfile, filepaths)
    # 1. Program settings
    simulparam = RepParam()



    # TODO 2a. Ground water table initialsettings.f90:311
    # note that we allready did the set of simulparam.ConstGwt=true like in initialsettings.f90:317

    # 2b. Soil profile and initial soil water content
    # TODO save soil profile defaultcropsoil.f90:322 maybe write a @show method?
    # OJO do not change soil.RootMax like in global.f90:4029 since it will be taken care later

    if usedefaultsoilfile
        soil, soillayers, compartments = loadprofile(filepaths[:simul]*"DEFAULT.SOL", simulparam)
    else
        soil = RepSoil()
        soillayers = [SoilLayerIndividual()]
        compartments = fill(CompartmentIndividual(Thickness=simulparam.CompDefThick), max_No_compartments)
        determinate_soilclass!(soillayers[1])
        determinate_coeffcapillaryrise!(soillayers[1])
    end
    
    simulation = RepSim()
    totalwatercontent = RepContent()
    completeprofiledescription!(soillayers, compartments, simulation, totalwatercontent)


    # 3. Crop characteristics and cropping period
    crop = RepCrop()
    # TODO save crop profile defaultcropsoil.f90:284  maybe write a @show method?
    soil.RootMax = rootmaxinsoilprofile(crop.RootMax, soillayers)

    # determine miscellaneous
    crop.Day1 = simulparam.CropDay1
    management = RepManag()
    completecropdescription!(crop, simulation, management)


    # 4. Field Management
    management.FertilityStress = 0
    cropstressparameterssoilfertility!(simulation.EffectStress, crop.StressResponse, management.FertilityStress) 

    sumwabal = RepSum()
    
    # 5. Climate
    # 5.6 Set Climate and Simulation Period
    crop.DayN = crop.Day1 + crop.DaysToHarvest - 1
    # adjusting simulation period
    simulation.FromDayNr = crop.Day1
    simulation.ToDayNr = crop.DayN

    # 6. irrigation
    irribeforeseason = fill(RepDayEventInt(), 5)
    irriafterseason = fill(RepDayEventInt(), 5)
    irriecw = RepIrriECw()

    #  11. Onset
    onset = RepOnset()

    # 12. Simulation run
    floatparameters = ParametersContainer(Float64)
    setparameter!(floatparameters, :eto, 5.0)
    setparameter!(floatparameters, :rain, 0.0)
    setparameter!(floatparameters, :irrigation, 0.0)
    setparameter!(floatparameters, :surfacestorage, 0.0)
    setparameter!(floatparameters, :ecstorage, 0.0)
    setparameter!(floatparameters, :drain, 0.0)
    setparameter!(floatparameters, :runoff, 0.0)
    setparameter!(floatparameters, :infiltrated, 0.0)
    setparameter!(floatparameters, :crwater, 0.0)
    setparameter!(floatparameters, :crsalti, 0.0)

    symbolparameters = ParametersContainer(Symbol)
    setparameter!(symbolparameters, :mode, :NoIrri)
    setparameter!(symbolparameters, :method, :MSprinkler)
    setparameter!(symbolparameters, :timemode, :AllRAW)
    setparameter!(symbolparameters, :depthmode, :ToFC)

    integerparameters = ParametersContainer(Int)
    setparameter!(integerparameters, :iniperctaw, 50)
    setparameter!(integerparameters, :daysubmerged, 0)
    setparameter!(integerparameters, :maxplotnew, 50)
    setparameter!(integerparameters, :maxplottr, 10)

    boolparameters = ParametersContainer(Bool)
    setparameter!(boolparameters, :preday, false)



    return ComponentArray(
        simulparam = simulparam,
        soil = soil,
        soillayers = soillayers,
        compartments = compartments,
        simulation = simulation,
        totalwatercontent = totalwatercontent,
        crop = crop,
        management = management,
        sumwabal = sumwabal,
        irribeforeseason = irribeforeseason,
        irriafterseason = irriafterseason,
        irriecw = irriecw,
        onset = onset,
        floatparameters = floatparameters,
        symbolparameters = symbolparameters,
        integerparameters = integerparameters,
        boolparameters = boolparameters,
    )
end


"""
    cropstressparameterssoilfertility!(stressout::RepEffectStress, cropsresp::RepShapes, stresslevel)
"""
function cropstressparameterssoilfertility!(stressout::RepEffectStress, cropsresp::RepShapes, stresslevel)
    pllactual = 1

    # decline canopy growth coefficient (cgc)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCGC)
    stressout.RedCGC = round(Int,(1-ksi)*100)      
    # decline maximum canopy cover (ccx)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCCX)
    stressout.RedCCX = round(Int, (1-ksi)*100)
    # decline crop water productivity (wp)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeWP)
    stressout.RedWP = round(Int, (1-ksi)*100)
    # decline canopy cover (cdecline)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCDecline)
    stressout.CDecline = 1 - ksi
    # inducing stomatal closure (kssto) not applicable
    ksi = 1
    stressout.RedKsSto = round(Int, (1-ksi)*100)
end 

"""
    ksval = ksany(wrel, pulactual, pllactual, shapefactor)
"""
function ksany(wrel, pulactual, pllactual, shapefactor)
    pulactual_local = pulactual

    if ((pllactual - pulactual_local) < 0.0001) 
        pulactual_local = pllactual - 0.0001
    end 

    prelativellul = (wrel - pulactual_local)/(pllactual - pulactual_local)

    if (prelativellul <= 0) 
        ksval = 1
    elseif (prelativellul >= 1) 
        ksval = 0
    else
        if (round(Int,10*shapefactor) == 0)  # straight line
            ksval = 1 - (exp(prelativellul*0.01)-1.)/(exp(0.01)-1)
        else
            ksval = 1 - (exp(prelativellul*shapefactor)-1)/(exp(shapefactor)-1)
        end 
        if (ksval > 1) 
            ksval = 1
        end 
        if (ksval < 0) 
            ksval = 0
        end 
    end 
    return ksval
end


"""
    completecropdescription!(crop::RepCrop, simulation::RepSim, management::RepManag)
"""
function completecropdescription!(crop::RepCrop, simulation::RepSim, management::RepManag)
    if ((crop.subkind == :Vegetative) |
        (crop.subkind == :Forage)) 
        if (crop.DaysToHIo > 0) 
            if (crop.DaysToHIo > crop.DaysToHarvest)
                crop.dHIdt = crop.HI/crop.DaysToHarvest
            else
                crop.dHIdt = crop.HI/crop.DaysToHIo
            end 
            if (crop.dHIdt > 100) 
                crop.dHIdt = 100
            end 
        else
            crop.dHIdt = 100
        end 
    else
        #  grain or tuber crops
        if (crop.DaysToHIo > 0) 
            crop.dHIdt = crop.HI/crop.DaysToHIo
        else
            crop.dHIdt = undef_double
        end
    end

    if (crop.ModeCycle == :CalendarDays) 
        crop.DaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                       crop.SizePlant, crop.CCx, crop.CGC)
        crop.DaysToFullCanopy = daystoreachccwithgivencgc(0.98*crop.CCx, crop.CCo, crop.CCx,
                                                          crop.CGC, crop.DaysToGermination)
        if (management.FertilityStress != 0) 
            fertstress = management.FertilityStress
            daystofullcanopy, RedCGC_temp, RedCCX_temp, fertstress = timetomaxcanopysf(crop.CCo, crop.CGC, crop.CCx,
                              crop.DaysToGermination,
                              crop.DaysToFullCanopy,
                              crop.DaysToSenescence,
                              crop.DaysToFlowering,
                              crop.LengthFlowering,
                              crop.DeterminancyLinked,
                              crop.DaysToFullCanopySF,
                              simulation.EffectStress.RedCGC,
                              simulation.EffectStress.RedCCX,
                              management.FertilityStress
                              )
            management.FertilityStress = fertstress
            simulation.EffectStress.RedCGC = RedCGC_temp
            simulation.EffectStress.RedCCX = RedCCX_temp
            crop.DaysToFullCanopySF = daystofullcanopy
        else
            crop.DaysToFullCanopySF = crop.DaysToFullCanopy 
        end 
    else
        crop.GDDaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                         crop.SizePlant, crop.CCx, crop.GDDCGC)
        crop.DaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                         crop.SizePlant, crop.CCx, crop.CGC)
        crop.GDDaysToFullCanopy = daystoreachccwithgivencgc(0.98*crop.CCx, crop.CCo, crop.CCx,
                                                          crop.GDDCGC, crop.GDDaysToGermination)
    end 

    cgcisgiven = true # required to adjust crop.daystofullcanopy (does not exist)
    length123, stlength, length12, cgcval = determinelengthgrowthstages(crop.CCo, crop.CCx, 
                                                            crop.CDC, crop.DaysToGermination,
                                                            crop.DaysToHarvest, cgcisgiven,
                                                            crop.DaysToCCini, crop.Planting,
                                                            crop.DaysToSenescence, crop.Length,
                                                            crop.DaysToFullCanopy, crop.CGC)
    crop.DaysToSenescence = length123
    crop.Length .= stlength
    crop.DaysToFullCanopy = length12
    crop.CGC = cgcval

    crop.CCoAdjusted = crop.CCo
    crop.CCxAdjusted = crop.CCx
    crop.CCxWithered = crop.CCx
end 


"""
    length123, stlength, length12, cgcval = determinelengthgrowthstages(ccoval, ccxval, cdcval, l0, totallength, 
                                                                        cgcgiven, thedaystoccini, theplanting, 
                                                                        length123, stlength, length12, cgcval)
"""
function determinelengthgrowthstages(ccoval, ccxval, cdcval, l0, totallength, 
                                     cgcgiven, thedaystoccini, theplanting, 
                                     length123, stlength, length12, cgcval)
    #OJO this function might have problems
    if (length123 < length12) 
        length123 = length12
    end 

    # 1. Initial and 2. Crop Development stage
    # CGC is given and Length12 is already adjusted to it
    # OR Length12 is given and CGC has to be determined
    if ((ccoval >= ccxval) | (length12 <= l0)) 
        length12 = 0
        stlength[1] = 0
        stlength[2] = 0
        cgcval = undef_int
    else
        if (!cgcgiven)  # length12 is given and cgc has to be determined
            cgcval = log((0.25*ccxval/ccoval)/(1-0.98))/(length12-l0)
            # check if cgc < maximum value (0.40) and adjust length12 if required
            if (cgcval > 0.40) 
                cgcval = 0.40
                ccxval_scaled = 0.98*ccxval
                length12 = daystoreachccwithgivencgc(ccxval_scaled , ccoval, 
                                                             ccxval, cgcval, l0)
                if (length123 < length12) 
                    length123 = length12
                end 
            end 
        end 
        # find stlength[1]
        cctoreach = 0.10
        stlength[1] = daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, 
                                                                    cgcval, l0)
        # find stlength[2]
        stlength[2] = length12 - stlength[1]
    end 
    l12adj = length12

    # adjust Initial and Crop Development stage, in case crop starts as regrowth
    if (theplanting == :Regrowth) 
        if (thedaystoccini == undef_int) 
            # maximum canopy cover is already reached at start season
            l12adj = 0
            stlength[1] = 0
            stlength[2] = 0
        else
            if (thedaystoccini == 0) 
                # start at germination
                l12adj = length12 - l0
                stlength[1] = stlength[1] - l0
            else
                # start after germination
                l12adj = length12 - (l0 + thedaystoccini)
                stlength[1] = stlength[1] - (l0 + thedaystoccini)
            end 
            if (stlength[1] < 0) 
                stlength[1] = 0
            end
            stlength[2] = l12adj - stlength[1]
        end 
    end 

    # 3. Mid season stage
    stlength[3] = length123 - l12adj

    # 4. Late season stage
    stlength[4] = lengthcanopydecline(ccxval, cdcval)

    # final adjustment
    if (stlength[1] > totallength) 
        stlength[1] = totallength
        stlength[2] = 0
        stlength[3] = 0
        stlength[4] = 0
    else
        if ((stlength[1]+stlength[2]) > totallength) 
            stlength[2] = totallength - stlength[1]
            stlength[3] = 0
            stlength[4] = 0
        else
            if ((stlength[1]+stlength[2]+stlength[3]) > totallength) 
                stlength[3] = totallength - stlength[1] - stlength[2]
                stlength[4] = 0
            elseif ((stlength[1]+stlength[2]+stlength[3]+stlength[4]) > totallength) 
                stlength[4] = totallength - stlength[1] - stlength[2] - stlength[3]
            end 
        end 
    end 

    return length123, stlength, length12, cgcval
end


"""
    nd = lengthcanopydecline(ccx, cdc)
"""
function lengthcanopydecline(ccx, cdc)
    nd = 0
    if (ccx > 0) 
        if (cdc <= eps(1.0)) 
            nd = undef_int
        else
            nd = round(Int, (((ccx+2.29)/(cdc*3.33))*log(1 + 1/0.05) + 0.50))
                         # + 0.50 to guarantee that cc is zero
        end 
    end 
    return nd
end



"""
    l12sf, redcgc, redccx, classsf = timetomaxcanopysf(cco, cgc, ccx, l0, l12, l123, ltoflor, lflor, determinantcrop, l12sf, redcgc, redccx, classsf)
"""
function timetomaxcanopysf(cco, cgc, ccx, l0, l12, l123, ltoflor, lflor, determinantcrop, l12sf, redcgc, redccx, classsf)
    if ((classsf == 0) | ((redccx == 0) & (redcgc == 0))) 
        l12sf = l12
    else
        cctoreach = 0.98*(1-redccx/100)*ccx
        l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
        # determine l12sfmax
        if (determinantcrop) 
            l12sfmax = ltoflor + round(Int, lflor/2)
        else
            l12sfmax = l123
        end
        # check for l12sfmax
        if (l12sf > l12sfmax) 
            # full canopy cannot be reached in potential period for vegetative growth
            # classsf := undef_int; ! switch to user defined soil fertility
            # 1. increase cgc(soil fertility)
            while ((l12sf > l12sfmax) & (redcgc > 0))
                redcgc = redcgc - 1
                l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
            end
            # 2. if not sufficient decrease ccx(soil fertility)
            while ((l12sf > l12sfmax) & ( ((1-redccx/100)*ccx) > 0.10) & (redccx <= 50))
                redccx = redccx + 1
                cctoreach = 0.98*(1-redccx/100)*ccx
                l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
            end
        end 
    end 
    return l12sf, redcgc, redccx, classsf
end

"""
    daystoresult = daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, cgcval, l0)
"""
function daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, cgcval, l0)
    cctoreach_local = cctoreach
    if ((ccoval > cctoreach_local) | (ccoval >= ccxval)) 
        l = 0
    else
        if (cctoreach_local > (0.98*ccxval)) 
            cctoreach_local = 0.98*ccxval
        end 
        if (cctoreach_local <= ccxval/2) 
            l = log(cctoreach_local/ccoval)/cgcval
        else
            l = log((0.25*ccxval*ccxval/ccoval)/(ccxval-cctoreach_local))/cgcval
        end
    end 
    daystoresult = l0 + round(Int, l)
    return daystoresult
end

"""
    elapsedtime = timetoccini(theplantingtype, thecropplantingdens, 
                          thesizeseedling, thesizeplant, thecropccx, thecropcgc)
"""
function timetoccini(theplantingtype, thecropplantingdens, 
                          thesizeseedling, thesizeplant, thecropccx, thecropcgc)
    if ((theplantingtype == :Seed) | (theplantingtype == :Transplant) |
        (thesizeseedling >= thesizeplant))
        elapsedtime = 0
    else
        thecropcco = (thecropplantingdens/10000) * (thesizeseedling/10000)
        thecropccini = (thecropplantingdens/10000) * (thesizeplant/10000)
        if (thecropccini >= (0.98*thecropccx)) 
            elapsedtime = undef_int
        else
            elapsedtime = daystoreachccwithgivencgc(thecropccini, thecropcco, 
                                                    thecropccx, thecropcgc, 0)
        end 
    end 
    return elapsedtime
end

"""
    zmax = rootmaxinsoilprofile(zmaxcrop, soillayers::Vector{SoilLayerIndividual})
"""
function rootmaxinsoilprofile(zmaxcrop, soillayers::Vector{SoilLayerIndividual})
    nrsoillayers = length(soillayers)
    zmax = zmaxcrop
    zsoil = 0

    layi = 0
    while ((layi < nrsoillayers) & (zmax > 0))
        layi = layi + 1

        if ((soillayers[layi].Penetrability < 100) &
            (round(Int, zsoil*1000) < round(Int, zmaxcrop*1000))) 
            zmax = undef_double
        end 

        zsoil += soillayers[layi].Thickness
    end 

    if (zmax < 0) 
        zmax = zradjustedtorestrictivelayers(zmaxcrop, soillayers)
    end 

    return zmax
end

"""
    zrout = zradjustedtorestrictivelayers(zrin, soillayers::Vector{SoilLayerIndividual})
"""
function zradjustedtorestrictivelayers(zrin, soillayers::Vector{SoilLayerIndividual})
    nrsoillayers = length(soillayers)

    zrout = zrin

    # initialize (layer 1)
    layi = 1
    zsoil = soillayers[layi].Thickness
    zradj = 0
    zrremain = zrin
    deltaz = zsoil
    theend = false

    # check succesive layers
    while !theend
        zrtest = zradj + zrremain * (soillayers[layi].Penetrability/100)

        if ((layi == nrsoillayers) |
            (soillayers[layi].Penetrability == 0) |
            (round(Int, ZrTest*10000) <= round(Int, Zsoil*10000))) 
            # no root expansion in layer
            zrout = zrtest
            theend = true
        else
            zradj = zsoil
            zrremain -= deltaz/(soillayers[layi].Penetrability/100)
            layi += 1
            zsoil += zsoil + soillayers[layi].Thickness
            deltaz = soillayers[layi].Thickness
        end
    end 
    return zrout
end

"""
    completeprofiledescription!(soillayers::Vector{SoilLayerIndividual}, 
            compartments::Vector{CompartmentIndividual}, simulation::RepSim, totalwatercontent::RepContent)  
"""
function completeprofiledescription!(soillayers::Vector{SoilLayerIndividual}, 
            compartments::Vector{CompartmentIndividual}, simulation::RepSim, totalwatercontent::RepContent)  
    nrcompartments = length(compartments)
    nrsoillayers = length(soillayers)
    designate_soillayer_to_compartments!(compartments, soillayers)

    for compi in 1:nrcompartments
        compartments[compi].theta = soillayers[compartments[compi].Layer].FC/100
        compartments[compi].FCadj = soillayers[compartments[compi].Layer].FC 

        simulation.ThetaIni[compi] = compartments[compi].theta

        soillayers[compartments[compi].Layer].WaterContent += 
            simulation.ThetaIni[compi]*100 * 10*compartments[compi].Thickness
    end

    total = 0
    for layeri in 1:nrsoillayers
        total += soillayers[layeri].WaterContent
    end 
    totalwatercontent.BeginDay = total

    # initial soil water content and no salts
    simulation.IniSWC.NrLoc = nrsoillayers

    for layeri in 1:nrsoillayers
        simulation.IniSWC.Loc[layeri] = soillayers[layeri].Thickness
        simulation.IniSWC.VolProc[layeri] = soillayers[layeri].FC
        simulation.IniSWC.SaltECe[layeri] = 0
    end 
    return nothing
end 

"""
    designate_soillayer_to_compartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual})
"""
function designate_soillayer_to_compartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual})
    nrsoillayers = length(soillayers)
    nrcompartments = length(compartments)
    depth = 0
    depthi = 0
    layeri = 1
    compi = 1
    
    outer_loop = true
    while outer_loop 
        depth = depth + soillayers[layeri].Thickness
        inner_loop = true
        finished = false
        while inner_loop
            depthi = depthi + compartments[compi].Thickness/2

            if (depthi <= depth) 
                compartments[compi].Layer = layeri
                nextlayer = false
                depthi = depthi + compartments[compi].Thickness/2 
                compi = compi + 1
                finished = (compi > nrcompartments)
            else
                depthi = depthi - compartments[compi].Thickness/2 
                nextlayer = true
                layeri = layeri + 1
                finished = (layeri > nrsoillayers)
            end 

            if (finished | nextlayer) 
                inner_loop = false
            end
        end

        if (finished)
            outer_loop = false
        end
    end

    for i in compi:nrcompartments
        compartments[i].Layer = nrsoillayers
    end 
    return nothing
end 

"""
    soil, soillayers, compartments = loadprofile(filepath, simulparam::RepParam)

loads data from filepath.
"""
function loadprofile(filepath, simulparam::RepParam)
    # note that we only consider version 7.1 parsing style
    soil = RepSoil()
    soillayers = SoilLayerIndividual[]
    compartments = CompartmentIndividual[]

    open(filepath, "r") do file
        profdescriptionlocal = strip(readline(file))
        versionnr = parse(Float64,strip(readline(file))[1:4])
        cnvalue = parse(Int,strip(readline(file))[1:4])
        soil.CNValue = cnvalue
        rew = parse(Int,strip(readline(file))[1:4])
        soil.REW = rew
        nrsoillayers = parse(Int,strip(readline(file))[1:4])
        soil.NrSoilLayers = nrsoillayers
        readline(file)
        readline(file)
        readline(file)
        for i in 1:nrsoillayers
            soillayer = SoilLayerIndividual()

            splitedline = split(readline(file))

            thickness_temp = parse(Float64,popfirst!(splitedline))
            soillayer.Thickness = thickness_temp
            SAT_temp = parse(Float64,popfirst!(splitedline))
            soillayer.SAT = SAT_temp
            FC_temp = parse(Float64,popfirst!(splitedline))
            soillayer.FC = FC_temp
            WP_temp = parse(Float64,popfirst!(splitedline))
            soillayer.WP = WP_temp
            infrate_temp = parse(Float64,popfirst!(splitedline))
            soillayer.InfRate = infrate_temp
            penetrability_temp = parse(Int,popfirst!(splitedline))
            soillayer.Penetrability = penetrability_temp
            gravelm_temp = parse(Int,popfirst!(splitedline))
            soillayer.GravelMass = gravelm_temp
            cra_temp = parse(Float64,popfirst!(splitedline))
            soillayer.CRa = cra_temp
            crb_temp = parse(Float64,popfirst!(splitedline))
            soillayer.CRb = crb_temp
            description_temp = join(splitedline," ") 
            soillayer.Description = description_temp
            gravelv_temp = from_gravelmass_to_gravelvol(SAT_temp, gravelm_temp)
            soillayer.GravelVol = gravelv_temp
            push!(soillayers, soillayer)
        end
    end

    loadprofileprocessing!(soil, soillayers, compartments, simulparam)

    return soil, soillayers, compartments
end

"""
    loadprofileprocessing!(soil::RepSoil, soillayers::Vector{SoilLayerIndividual},
        compartments::Vector{CompartmentIndividual}, simulparam::RepParam)

loads some data.
"""
function loadprofileprocessing!(soil::RepSoil, soillayers::Vector{SoilLayerIndividual},
        compartments::Vector{CompartmentIndividual}, simulparam::RepParam)

    # OJO set simulation parameters from global.f90:7691 done with @kwdef

    for i in eachindex(soillayers)
        soillayer = soillayers[i]
        
        # determine drainage coefficient
        tau = taufromksat(soillayer.InfRate)
        soillayer.tau = tau

        # determine number of salt cells based on infiltration rate
        if soillayer.InfRate < 112
            scp1 = 11
        else
            scp1 = round(Int, 1.6 + 1000/soillayer.InfRate )
            if scp1<2
                scp1 = 2
            end
        end
        soillayer.SCP1 = scp1

        # determine parameters for soil salinity
        sc = scp1 - 1
        soillayer.SC = sc
        Macro = round(Int, soillayer.FC)
        soillayer.Macro = Macro
        ul = soillayer.SAT/100 * sc/(sc + 2) # m3/m3
        soillayer.UL
        dx = ul / sc
        soillayer.Dx = dx

        calculate_saltmobility!(soillayer, simulparam.SaltDiff)

        # determine default parameters for capillary rise if missing
        determinate_soilclass!(soillayer)
    end

    determinenrandthicknesscompartments!(compartments, soillayers, simulparam.CompDefThick)

    # OJO do not call set soil root max like in global.f90:7744 since it we need crop data
    return nothing
end


"""
    determinenrandthicknesscompartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual}, compdefthick)
"""
function determinenrandthicknesscompartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual}, compdefthick)
    totaldepthl = 0
    for i in eachindex(soillayers)
        totaldepthl += soillayers[i].Thickness
    end 
    totaldepthc = 0
    nrcompartments = 0
    loopi = true
    while loopi
        compartment = CompartmentIndividual()
        deltaz = (totaldepthl - totaldepthc)
        nrcompartments += 1
        if (deltaz > compdefthick)
            compartment.Thickness = compdefthick
        else
            compartment.Thickness = deltaz
        end 
        totaldepthc += compartment.Thickness
        push!(compartments, compartment)
        if ((nrcompartments == max_No_compartments) | (abs(totaldepthc - totaldepthl) < 0.0001))
            loopi = false
        end
    end
    return nothing
end


"""
    calculate_saltmobility!(soillayer::SoilLayerIndividual, saltdiffusion)

sets the salt mobility
"""
function calculate_saltmobility!(soillayer::SoilLayerIndividual, saltdiffusion)
    Macro = soillayer.Macro
    Mobil = soillayer.SaltMobility

    Mix = saltdiffusion/100 # global salt mobility expressed as a fraction
    UL = soillayer.UL * 100 # upper limit in VOL% of SC cell

    # 1. convert Macro (vol%) in SaltCelNumber
    if (Macro > UL) 
        CelMax = soillayer.SCP1 
    else
        CelMax = round(Int, (Macro/UL)*soillayer.SC)
    end 

    if (CelMax <= 0) 
        CelMax = 1
    end

    # 2. find a and b
    if (Mix < 0.5) 
        a = Mix * 2
        b = exp(10*(0.5-Mix)*log(10))
    else
        a = 2 * (1 - Mix)
        b = exp(10*(Mix-0.5)*log(10))
    end 

    # 3. calculate mobility for cells = 1 to Macro
    for i in 1:CelMax-1
        xi = i *1 / (CelMax-1)
        if (Mix > 0) 
            if (Mix < 0.5) 
                yi = exp(log(a)+xi*log(b))
                Mobil[i] = (yi-a)/(a*b-a)
            elseif ((Mix >= 0.5 - eps(0.0)) & (Mix <= 0.5 + eps(0.0)))
                Mobil[i] = xi
            elseif (Mix < 1) 
                yi = exp(log(a)+(1-xi)*log(b))
                Mobil[i] = 1 - (yi-a)/(a*b-a)
            else
                Mobil[i] = 1
            end 
        else
            Mobil[i] = 0
        end 
    end 

    # 4. Saltmobility between Macro and SAT
    for i in CelMax:soillayer.SCP1 
        Mobil[i] = 1
    end 
    return nothing
end 

"""
    tau = taufromksat(ksat)
"""
function taufromksat(ksat)
    if (abs(ksat) < eps(1.0)) 
        tau = 0
    else
        tautemp = round(Int,100.0*0.0866*exp(0.35*log(ksat)))
        if (tautemp < 0) 
            tautemp = 0
        end 
        if (tautemp > 100) 
            tautemp = 100
        end 
        tau = tautemp/100.0
    end 
    return tau
end


"""
    gravelvol = from_gravelmass_to_gravelvol(porositypercent, gravelmasspercent)

calculates the gravel volume of soil layer.
"""
function from_gravelmass_to_gravelvol(porositypercent, gravelmasspercent)
    mineralbd = 2.65 # mg/m3
    if (gravelmasspercent > 0) 
        matrixbd = mineralbd * (1.0 - porositypercent/100.0)
        soilbd = 100.0/(gravelmasspercent/mineralbd + (100.0-gravelmasspercent)/matrixbd)
        fromgravelmasstogravelvolume = gravelmasspercent * (soilbd/mineralbd)
    else
       fromgravelmasstogravelvolume = 0.0
    end
    return fromgravelmasstogravelvolume
end

"""
    determinate_soilclass!(soillayer::SoilLayerIndividual)

sets the soil class of soillayer considering its own data.
"""
function determinate_soilclass!(soillayer::SoilLayerIndividual) 
    satvolpro = soillayer.SAT
    fcvolpro = soillayer.FC
    pwpvolpro = soillayer.WP
    ksatmm = soillayer.InfRate

    if (satvolpro <= 55.0) 
        if (pwpvolpro >= 20.0)
            if ((satvolpro >= 49.0) & (fcvolpro >= 40.0))
                numbersoilclass = 4  # silty clayey soils
            else
                numbersoilclass = 3  # sandy clayey soils
            end
        else
            if (fcvolpro < 23.0)
                numbersoilclass = 1 # sandy soils
            else
                if ((pwpvolpro > 16.0) & (ksatmm < 100.0)) 
                    numbersoilclass = 3 # sandy clayey soils
                else
                    if ((pwpvolpro < 6.0) & (fcvolpro < 28.0) & (ksatmm >750.0)) 
                        numbersoilclass = 1 # sandy soils
                    else
                        numbersoilclass = 2  # loamy soils
                    end 
                end 
            end 
        end 
    else
        numbersoilclass = 4 # silty clayey soils
    end 
    soillayer.SoilClass = numbersoilclass
    return nothing
end 

"""
    determinate_coeffcapillaryrise!(soillayer::SoilLayerIndividual)

sets the coefficients for capillary rise of soillayer considering its own data.
"""
function determinate_coeffcapillaryrise!(soillayer::SoilLayerIndividual)
    soilclass = soillayer.SoilClass
    ksatmm = soillayer.InfRate

    # determine parameters
    if (round(ksatmm*1000) <= 0)
        aparam = undef_double
        bparam = undef_double
    else
        if soilclass == 1
            aparam = -0.3112 - ksatmm/100000.0
            bparam = -1.4936 + 0.2416*log(ksatmm)
        elseif soilclass == 2
            aparam = -0.4986 + 9.0*ksatmm/100000.0
            bparam = -2.1320 + 0.4778*log(ksatmm)
        elseif soilclass == 3 
            aparam = -0.5677 - 4.0*ksatmm/100000.0
            bparam = -3.7189 + 0.5922*log(ksatmm)
        else
            aparam = -0.6366 + 8.0*ksatmm/10000.0
            bparam = -1.9165 + 0.7063*log(ksatmm)
        end
    end

    soillayer.CRa = aparam
    soillayer.CRb = bparam
    return nothing
end

"""
    pt = getprojecttype(theprojectfile)

gets the project type for a given file.
"""
function getprojecttype(theprojectfile)
    if endswith(theprojectfile, "PRO")
        theprojecttype = :typepro
    elseif endswith(theprojectfile, "PRM")
        theprojecttype = :typeprm
    else
        theprojecttype = :typenone
    end
    return theprojecttype
end


"""
    projectfilenames = initializeprojectfilename(filepaths)

Gets all the names of the projects files.
"""
function initializeprojectfilename(filepaths)
    projectfilenames = String[]

    listprojectsfile = filepaths[:list]*"ListProjects.txt"
    listprojectsfileexist = isfile(listprojectsfile)

    if !listprojectsfileexist
        cmd_1 = `ls -1 $(filepaths[:list])`
        cmd_2 = `grep -E ".*.PR[O,M]\$"`
        rc = run(pipeline( pipeline(cmd_1,cmd_2), stdout = listprojectsfile))
        if rc.exitcode != 0
            error("Failed to create "*listprojectsfile)
        end
    end

    open(listprojectsfile, "r") do file
        for line in eachline(file)
            projectfile = strip(line)
            if !isempty(projectfile)
                push!(projectfilenames, projectfile)
            end
        end
    end
    return projectfilenames
end

"""
    filepaths, resultsparameters = initializetheprogram(parentdir)
    
Gets the file paths and the simulation parameters.
"""
function initializetheprogram(parentdir)
    filepaths = defaultfilepaths(parentdir)

    resultsparameters = getresultsparameters(filepaths[:simul])

    # TODO startunit.F90:429  PrepareReport()

    return filepaths, resultsparameters 
end


"""
    fl = defaultfilepaths(parentdir::AbstractString)

sets the default directories for the input files.
"""
function defaultfilepaths(parentdir::AbstractString)
    return ComponentArray(
    outp=parentdir*"OUTP/",
    simul=parentdir*"SIMUL/",
    list=parentdir*"LIST/",
    param=parentdir*"PARAM/",
    prog=parentdir*"")
end

"""
    resultsparameters = getresultsparameters(path::String)

gets all the results parameters in filepaths[:simul].
"""
function getresultsparameters(path::String)
    aggregationresultsparameters = ParametersContainer(Symbol)
    filename = path*"AggregationResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            aggregationtype = strip(readline(file))[1]
            if aggregationtype == '1'
                setparameter!(aggregationresultsparameters, :outputaggregate, :daily)
            elseif aggregationtype == '2'
                setparameter!(aggregationresultsparameters, :outputaggregate, :daily_10)
            elseif  aggregationtype == '3'
                setparameter!(aggregationresultsparameters, :outputaggregate, :monthly)
            else
                setparameter!(aggregationresultsparameters, :outputaggregate, :seasonal)
            end
        end
    end

    dailyresultsparameters = ParametersContainer(Bool)
    filename = path*"DailyResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            for line in eachline(file)
                if isempty(line)
                    break
                end
                outpar = strip(line)[1]
                if outpar == '1'
                    setparameter!(dailyresultsparameters, :out1Wabal, true)
                elseif outpar == '2'
                    setparameter!(dailyresultsparameters, :out2Crop, true)
                elseif outpar == '3'
                    setparameter!(dailyresultsparameters, :out3Prof, true)
                elseif outpar == '4'
                    setparameter!(dailyresultsparameters, :out4Salt, true)
                elseif outpar == '5'
                    setparameter!(dailyresultsparameters, :out5CompWC, true)
                elseif outpar == '6'
                    setparameter!(dailyresultsparameters, :out6CompEC, true)
                elseif outpar == '7'
                    setparameter!(dailyresultsparameters, :out7Clim, true)
                end
            end
            if ( dailyresultsparameters[:out1Wabal] | dailyresultsparameters[:out2Crop] 
                | dailyresultsparameters[:out3Prof] | dailyresultsparameters[:out4Salt]
                | dailyresultsparameters[:out5CompWC] | dailyresultsparameters[:out6CompEC]
                | dailyresultsparameters[:out7Clim])
                setparameter!(dailyresultsparameters, :outdailyresults, true)
            end
        end
    end

    particularresultsparameters = ParametersContainer(Bool)
    filename = path*"ParticularResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            for line in eachline(file)
                if isempty(line)
                    break
                end
                outpar = strip(line)[1]
                if outpar == '1'
                    setparameter!(particularresultsparameters, :part1Mult, true)
                elseif outpar == '2'
                    setparameter!(particularresultsparameters, :part2Eval, true)
                end
            end
        end
    end


    return ComponentArray(aggregationresults=aggregationresultsparameters,
                dailyresults=dailyresultsparameters,
                paricularresults=particularresultsparameters)
end
