"""
    run_simulation!(inse, projectinput::Vector{ProjectInputType})

run.f90:7779
"""
function run_simulation!(inse, projectinput::Vector{ProjectInputType})
    # maybe set outputfilesa run.f90:7786

    nrruns = inse[:simulation].NrRuns 

    for nrrun in 1:nrruns
        initialize_run_part_1!(inse, projectinput[nrrun])

    end

    return nothing
end #not end

"""
    initialize_run_part_1!(inse, projectinput::ProjectInputType)

run.f90:6590
"""
function initialize_run_part_1!(inse, projectinput::ProjectInputType)
    load_simulation_project!(inse, projectinput)
    
    return nothing
end #not end



"""
    load_simulation_project!(inse, projectinput::ProjectInputType) 

tempprocessing.f90:1932
"""
function load_simulation_project!(inse, projectinput::ProjectInputType) 
    # 0. Year of cultivation and Simulation and Cropping period
    inse[:simulation].YearSeason = projectinput.Simulation_YearSeason
    inse[:crop].Day1 = projectinput.Crop_Day1
    inse[:crop].DayN = projectinput.Crop_DayN

    # 1.1 Temperature
    if projectinput.Temperature_Filename=="(None)" | projectinput.Temperature_Filename=="(External)"
        temperature_file = projectinput.Temperature_Filename 
    else
        temperature_file = projectinput.ParentDir * projectinput.Temperature_Directory * projectinput.Temperature_Filename
        setparameter!(inse[:bool_parameters], :temperature_file_exists, isfile(temperature_file))
        if isfile(inse[:bool_parameters][:temperature_file_exists])
            read_temperature_file!(inse[:array_parameters], temperature_file)
        end
        load_clim!(inse[:temperature_record], temperature_file)
    end 
    setparameter!(inse[:string_parameters], :temperature_file, temperature_file)

    # 1.2 ETo
    if projectinput.ETo_Filename=="(None)" | projectinput.ETo_Filename=="(External)"
        eto_file = projectinput.ETo_Filename 
    else
        eto_file = projectinput.ParentDir * projectinput.ETo_Directory * projectinput.ETo_Filename
        load_clim!(inse[:eto_record], eto_file)
    end 
    setparameter!(inse[:string_parameters], :eto_file, eto_file)

    # 1.3 Rain
    if projectinput.Rain_Filename=="(None)" | projectinput.Rain_Filename=="(External)"
        rain_file = projectinput.Rain_Filename
    else
        rain_file = projectinput.ParentDir * projectinput.Rain_Directory * projectinput.Rain_Filename
        load_clim!(inse[:rain_record], rain_file)
    end 
    setparameter!(inse[:string_parameters], :rain_file, rain_file)

    # 1.4 Climate
    if projectinput.Climate_Filename != "(External)"
        set_clim_data!(inse, projectinput)
    end
    adjust_onset_search_period!(inse) # Set initial StartSearch and StopSearchDayNr


    # 3. Crop
    inse[:simulation].LinkCropToSimPeriod = true
    crop_file = projectinput.ParentDir * projectinput.Crop_Directory * projectinput.Crop_Filename
    load_crop!(inse[:crop], inse[:perennial_period], crop_file)
    # copy to CropFileSet
    if inse[:crop].ModeCycle==:GDDays
        inse[:crop_file_set].DaysFromSenescenceToEnd = inse[:crop].DaysToHarvest - inse[:crop].DaysToSenescence
        inse[:crop_file_set].DaysToHarvest = inse[:crop].DaysToHarvest
    end
    # maximum rooting depth in given soil profile
    inse[:soil].RootMax = root_max_in_soil_profile(inse[:crop].RootMax, inse[:soil_layers])

    # Adjust crop parameters of Perennials
    if inse[:crop].subkind==:Forage
        # adjust crop characteristics to the Year (Seeding/Planting or
        # Non-seesing/Planting year)
        adjust_year_perennials!(inse[:crop], inse[:simulation].YearSeason)
        # adjust length of season
        inse[:crop].DaysToHarvest = inse[:crop].DayN - inse[:crop].Day1 + 1
        adjust_crop_file_parameters!(inse)

        Crop_DaysToSenescence_temp = GetCrop_DaysToSenescence()
        Crop_DaysToHarvest_temp = GetCrop_DaysToHarvest()
        Crop_GDDaysToSenescence_temp = GetCrop_GDDaysToSenescence()
        Crop_GDDaysToHarvest_temp = GetCrop_GDDaysToHarvest()
        call AdjustCropFileParameters(GetCropFileSet(),&
              GetCrop_DaysToHarvest(), GetCrop_Day1(), &
              GetCrop_ModeCycle(), GetCrop_Tbase(), GetCrop_Tupper(),&
              Crop_DaysToSenescence_temp, Crop_DaysToHarvest_temp,&
              Crop_GDDaysToSenescence_temp, Crop_GDDaysToHarvest_temp)
        call SetCrop_DaysToSenescence(Crop_DaysToSenescence_temp)
        call SetCrop_DaysToHarvest(Crop_DaysToHarvest_temp)
        call SetCrop_GDDaysToSenescence(Crop_GDDaysToSenescence_temp)
        call SetCrop_GDDaysToHarvest(Crop_GDDaysToHarvest_temp)
    end 

    call AdjustCalendarCrop(GetCrop_Day1())
    call CompleteCropDescription
    # Onset.Off := true;
    if (GetClimFile() == '(None)') then
        Crop_Day1_temp = GetCrop_Day1()
        Crop_DayN_temp = GetCrop_DayN()
        call AdjustCropYearToClimFile(Crop_Day1_temp, Crop_DayN_temp)
        # adjusting Crop.Day1 and Crop.DayN to ClimFile
        call SetCrop_Day1(Crop_Day1_temp)
        call SetCrop_DayN(Crop_DayN_temp)
    else
        call SetCrop_DayN(GetCrop_Day1() + GetCrop_DaysToHarvest() - 1)
    end if

    # adjusting ClimRecord.'TO' for undefined year with 365 days
    if ((GetClimFile() /= '(None)') .and. (GetClimRecord_FromY() == 1901) &
        .and. (GetClimRecord_NrObs() == 365)) then
        call AdjustClimRecordTo(GetCrop_DayN())
    end if
    # adjusting simulation period
    call AdjustSimPeriod

    # 4. Irrigation
    call SetIrriFile(ProjectInput(NrRun)%Irrigation_Filename)
    if (GetIrriFile() == '(None)') then
        call SetIrriFileFull(GetIrriFile())
        call NoIrrigation
        # IrriDescription := 'Rainfed cropping';
    else
        call SetIrriFileFull(ProjectInput(NrRun)%Irrigation_Directory &
                             // GetIrriFile())
        call LoadIrriScheduleInfo(GetIrriFileFull())
    end if

    # 5. Field Management
    call SetManFile(ProjectInput(NrRun)%Management_Filename)
    if (GetManFile() == '(None)') then
        call SetManFileFull(GetManFile())
        call SetManDescription('No specific field management')
    else
        call SetManFileFull(ProjectInput(NrRun)%Management_Directory &
                            // GetManFile())
        call LoadManagement(GetManFilefull())
        # reset canopy development to soil fertility
        FertStress = GetManagement_FertilityStress()
        Crop_DaysToFullCanopySF_temp = GetCrop_DaysToFullCanopySF()
        RedCGC_temp = GetSimulation_EffectStress_RedCGC()
        RedCCX_temp = GetSimulation_EffectStress_RedCCX()
        call TimeToMaxCanopySF(GetCrop_CCo(), GetCrop_CGC(), GetCrop_CCx(),&
               GetCrop_DaysToGermination(), GetCrop_DaysToFullCanopy(),&
               GetCrop_DaysToSenescence(), GetCrop_DaysToFlowering(),&
               GetCrop_LengthFlowering(), GetCrop_DeterminancyLinked(),&
               Crop_DaysToFullCanopySF_temp, RedCGC_temp,&
               RedCCX_temp, FertStress)
        call SetCrop_DaysToFullCanopySF(Crop_DaysToFullCanopySF_temp)
        call SetManagement_FertilityStress(FertStress)
        call SetSimulation_EffectStress_RedCGC(RedCGC_temp)
        call SetSimulation_EffectStress_RedCCX(RedCCX_temp)
    end if

    # 6. Soil Profile
    call SetProfFile(ProjectInput(NrRun)%Soil_Filename)
    if (GetProfFile() == '(External)') then
        call SetProfFilefull(GetProfFile())
    elseif (GetProfFile() == '(None)') then
        call SetProfFilefull(GetPathNameSimul() // 'DEFAULT.SOL')
    else
        call SetProfFilefull(ProjectInput(NrRun)%Soil_Directory &
                             // GetProfFile())
    end if

    # The load of profile is delayed to check if soil water profile need to be
    # reset (see 8.)

    # 7. Groundwater
    call SetGroundWaterFile(ProjectInput(NrRun)%GroundWater_Filename)
    if (GetGroundWaterFile() == '(None)') then
        call SetGroundWaterFilefull(GetGroundWaterFile())
        call SetGroundWaterDescription('no shallow groundwater table')
    else
        call SetGroundWaterFilefull(ProjectInput(NrRun)%GroundWater_Directory &
                                    // GetGroundWaterFile())
        # Loading the groundwater is done after loading the soil profile (see
        # 9.)
    end if

    # 8. Set simulation period
    call SetSimulation_FromDayNr(ProjectInput(NrRun)%Simulation_DayNr1)
    call SetSimulation_ToDayNr(ProjectInput(NrRun)%Simulation_DayNrN)
    if ((GetCrop_Day1() /= GetSimulation_FromDayNr()) .or. &
        (GetCrop_DayN() /= GetSimulation_ToDayNr())) then
        call SetSimulation_LinkCropToSimPeriod(.false.)
    end if

    # 9. Initial conditions
    if (ProjectInput(NrRun)%SWCIni_Filename == 'KeepSWC') then
        # No load of soil file (which reset thickness compartments and Soil
        # water content to FC)
        call SetSWCIniFile('KeepSWC')
        call SetSWCIniDescription('Keep soil water profile of previous run')
    else
        # start with load and complete profile description (see 5.) which reset
        # SWC to FC by default
        if (GetProfFile() == '(External)') then
            call LoadProfileProcessing(ProjectInput(NrRun)%VersionNr)
        else
            call LoadProfile(GetProfFilefull())
        end if
        call CompleteProfileDescription

        # Adjust size of compartments if required
        TotDepth = 0._dp
        do i = 1, GetNrCompartments()
            TotDepth = TotDepth + GetCompartment_Thickness(i)
        end do
        if (GetSimulation_MultipleRunWithKeepSWC()) then
        # Project with a sequence of simulation runs and KeepSWC
            if (roundc(GetSimulation_MultipleRunConstZrx()*1000._dp, mold=1) > &
                roundc(TotDepth*1000._dp, mold=1)) then
                call AdjustSizeCompartments(GetSimulation_MultipleRunConstZrx())
            end if
        else
            if (roundc(GetCrop_RootMax()*1000._dp, mold=1) > &
                roundc(TotDepth*1000._dp, mold=1)) then
                if (roundc(GetSoil_RootMax()*1000._dp, mold=1) == &
                    roundc(GetCrop_RootMax()*1000._dp, mold=1)) then
                    call AdjustSizeCompartments(&
                            real(GetCrop_RootMax(), kind=dp))
                    # no restrictive soil layer
                else
                    # restrictive soil layer
                    if (roundc(GetSoil_RootMax()*1000._dp, mold=1) > &
                        roundc(TotDepth*1000._dp, mold=1)) then
                        call AdjustSizeCompartments(&
                            real(GetSoil_RootMax(), kind=dp))
                    end if
                end if
            end if
        end if

        call SetSWCIniFile(ProjectInput(NrRun)%SWCIni_Filename)
        if (GetSWCIniFile() == '(None)') then
            call SetSWCiniFileFull(GetSWCiniFile()) # no file
            call SetSWCiniDescription(&
                     'Soil water profile at Field Capacity')
        else
            call SetSWCiniFileFull(ProjectInput(NrRun)%SWCIni_Directory &
                                   // GetSWCIniFile())
            SurfaceStorage_temp = GetSurfaceStorage()
            call LoadInitialConditions(GetSWCiniFileFull(),&
                  SurfaceStorage_temp)
            call SetSurfaceStorage(SurfaceStorage_temp)
        end if

        Compartment_temp = GetCompartment()

        select case (GetSimulation_IniSWC_AtDepths())
        case (.true.)
            call TranslateIniPointsToSWProfile(&
               GetSimulation_IniSWC_NrLoc(), &
               GetSimulation_IniSWC_Loc(), GetSimulation_IniSWC_VolProc(), &
               GetSimulation_IniSWC_SaltECe(), GetNrCompartments(), &
               Compartment_temp)
        case default
            call TranslateIniLayersToSWProfile(&
               GetSimulation_IniSWC_NrLoc(),&
               GetSimulation_IniSWC_Loc(), GetSimulation_IniSWC_VolProc(), &
               GetSimulation_IniSWC_SaltECe(), GetNrCompartments(),&
               Compartment_temp)
        end select
        call SetCompartment(Compartment_temp)

        if (GetSimulation_ResetIniSWC()) then
             # to reset SWC and SALT at end of simulation run
            do i = 1, GetNrCompartments()
                 call SetSimulation_ThetaIni_i(i, GetCompartment_Theta(i))
                 call SetSimulation_ECeIni_i(i, &
                          ECeComp(GetCompartment_i(i)))
            end do
            # ADDED WHEN DESINGNING 4.0 BECAUSE BELIEVED TO HAVE FORGOTTEN -
            # CHECK LATER
            if (GetManagement_BundHeight() >= 0.01_dp) then
                 call SetSimulation_SurfaceStorageIni(GetSurfaceStorage())
                 call SetSimulation_ECStorageIni(GetECStorage())
             end 
        end 
    end 

    # 10. load the groundwater file if it exists (only possible for Version 4.0
    # and higher)
    if ((roundc(10*ProjectInput(NrRun)%VersionNr, mold=1) >= 40) .and. &
        (GetGroundWaterFile() /= '(None)')) then
          # the groundwater file is only available in Version 4.0 or higher
        ZiAqua_temp = GetZiAqua()
        ECiAqua_temp = GetECiAqua()
        call LoadGroundWater(GetGroundWaterFilefull(),&
                GetSimulation_FromDayNr(), ZiAqua_temp, ECiAqua_temp)
        call SetZiAqua(ZiAqua_temp)
        call SetECiAqua(ECiAqua_temp)
    else
        call SetZiAqua(undef_int)
        call SetECiAqua(real(undef_int, kind=dp))
        call SetSimulParam_ConstGwt(.true.)
    end 
    Compartment_temp = GetCompartment()
    call CalculateAdjustedFC((GetZiAqua()/100._dp), Compartment_temp)
    call SetCompartment(Compartment_temp)
    if (GetSimulation_IniSWC_AtFC() .and. (GetSWCIniFile() /= 'KeepSWC')) then
        call ResetSWCToFC()
    end 

    # 11. Off-season conditions
    call SetOffSeasonFile(ProjectInput(NrRun)%OffSeason_Filename)
    if (GetOffSeasonFile() == '(None)') then
        call SetOffSeasonFileFull(GetOffSeasonFile())
        call SetOffSeasonDescription('No specific off-season conditions')
    else
        call SetOffSeasonFileFull(ProjectInput(NrRun)%OffSeason_Directory &
                                  // GetOffSeasonFile())
        call LoadOffSeason(GetOffSeasonFilefull())
    end 

    # 12. Field data
    call SetObservationsFile(ProjectInput(NrRun)%Observations_Filename)
    if (GetObservationsFile() == '(None)') then
        call SetObservationsFileFull(GetObservationsFile())
        call SetObservationsDescription('No field observations')
    else
        call SetObservationsFileFull(ProjectInput(NrRun)%Observations_Directory &
                                     // GetObservationsFile())
        observations_descr = GetObservationsDescription()
        call GetFileDescription(GetObservationsFileFull(), observations_descr)
        call SetObservationsDescription(observations_descr)
    end 



    return nothing
end #not end


"""
    read_temperature_file!(array_parameters::ParametersContainer{T}, temperature_file) where T

tempprocessing.f90:307
"""
function read_temperature_file!(array_parameters::ParametersContainer{T}, temperature_file) where T
    Tmin = Float64[] 
    Tmax = Float64[]
    
    open(temperature_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        for line in eachline(file)
            splitedline = split(line)
            
            tmin = parse(Float64,popfirst!(splitedline))
            tmax = parse(Float64,popfirst!(splitedline))
            push!(Tmin, tmin)
            push!(Tmax, tmax)
        end
    end

    setparameter!(array_parameters, :Tmin, Tmin)
    setparameter!(array_parameters, :Tmax, Tmax)

    return nothing
end

"""
    load_clim!(record::RepClim, filename)

global.f90:5936
"""
function load_clim!(record::RepClim, filename)
    if isfile(filename)
        open(filename, "r") do file
            readline(file)
            Ni = parse(Int,readline(file))
            if Ni == 1
                record.Datatype = :Daily
            elseif Ni == 2
                record.Datatype = :Decadely
            else
                record.Datatype = :Monthly
            end
            record.FromD = parse(Int,readline(file))
            record.FromM = parse(Int,readline(file))
            record.FromY = parse(Int,readline(file))
            readline(file)
            readline(file)
            readline(file)
            record.NrObs = 0
            for line in eachline(file)
                record.NrObs += 1
            end
        end
        complete_climate_description!(record)
    end
    return nothing
end

"""
    complete_climate_description!(record::RepClim)

global.f90:8223
"""
function complete_climate_description!(record::RepClim)
    record.FromDayNr = determine_day_nr(record.FromD, record.FromM, record.FromY)
    if record.Datatype == :Daily
        record.ToDayNr = record.FromDayNr + record%NrObs - 1
        record.ToD, record.ToM, record.ToY = determine_date(redord.ToDayNr)
    elseif record.Datatype == :Decadely
        deci = round(Int, (record.FromD+9)/10) + record.NrObs - 1
        record.ToM = record.FromM
        record.ToY = record.FromY
        while (deci > 3)
            deci = deci - 3
            record.ToM = record.ToM + 1
            if (record.ToM > 12)
                record.ToM = 1
                record.ToY = record.ToY  + 1
            end
        end 
        record.ToD = 10
        if (deci == 2) 
            record.ToD = 20
        end 
        if (deci == 3) 
            record.ToD = DaysInMonth[record.ToM]
            if ((record.ToM == 2) & isleapyear(record.ToY)) 
                record.ToD = record.ToD + 1
            end 
        end 
        record.ToDayNr =  determine_day_nr(record.ToD, record.ToM, record.ToY)
    elseif record.Datatype == :Monthly
        record.ToY = record.FromY
        record.ToM = record.FromM + record.NrObs - 1
        while (record.ToM > 12)
            record.ToY = record.ToY + 1
            record.ToM = record.ToM - 12
        end
        record.ToD = DaysInMonth[record.ToM]
        if ((record.ToM == 2) & isleapyear(record.ToY)) 
            record.ToD = record.ToD + 1
        end 
        record.ToDayNr = determine_day_nr(record.ToD, record.ToM, record.ToY)
    end 
    return nothing
end

"""
    set_clim_data!(inse, projectinput::ProjectInputType)

global.f90:4295
"""
function set_clim_data!(inse, projectinput::ProjectInputType)
    clim_record = inse[:clim_record]
    eto_record = inse[:eto_record]
    rain_record = inse[:rain_record]
    eto_file = projectinput.ETo_Filename
    rain_file = projectinput.Rain_Filename
    temperature_file = projectinput.Temperature_Filename

    # Part A - ETo and Rain files --> ClimFile
    if ((eto_file == "(None)") & (rain_file == "(None)")) 
        clim_file = "(None)"
        clim_record.Datatype =:Daily
        clim_record.FromString = "any date"
        clim_record.ToString = "any date"
        clim_record.FromY = 1901
    else
        clim_file = "EToRainTempFile"
        if (eto_file == "(None)") 
            clim_record.FromY = rain_record.FromY
            clim_record.FromDayNr = rain_record.FromDayNr
            clim_record.ToDayNr = rain_record.ToDayNr
            clim_record.FromString = rain_record.FromString
            clim_record.ToString = rain_record.ToString
            if full_undefined_record(rain_record)
                clim_record.NrObs = 365
            end
        elseif (rain_file == "(None)") 
            clim_record.FromY = eto_record.FromY
            clim_record.FromDayNr = eto_record.FromDayNr
            clim_record.ToDayNr = eto_record.ToDayNr
            clim_record.FromString = eto_record.FromString
            clim_record.ToString = eto_record.ToString
            if full_undefined_record(eto_record)
                clim_record.NrObs = 365
            end
        else
            if full_undefined_record(eto_record) & full_undefined_record(rain_record) 
                clim_record.NrObs = 365
            end 

            if (eto_record.FromY == 1901) & (rain_record.FromY != 1901)
                eto_record.FromY = rain_record.FromY
                eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
                if (eto_record.FromDayNr < rain_record.FromDayNr) & (rain_record.FromY < rain_record.ToY)
                    eto_record.FromY = rain_record.FromY + 1
                    eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
                end
                clim_record = eto_record.FromY
                if full_undefined_record(eto_record)
                    eto_record.ToY = rain_record.ToY
                else
                    eto_record.ToY = eto_record.FromY
                end 
                eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
            end 

            if (eto_record.FromY != 1901) & (rain_record.FromY == 1901)
                rain_record.FromY = eto_record.FromY
                rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
                if (rain_record.FromDayNr < eto_record.FromDayNr) & (eto_record.FromY < eto_record.ToY)
                    rain_record.FromY = eto_record.FromY + 1
                    rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
                end
                clim_record.FromY = rain_record.FromY
                if full_undefined_record(rain_record)
                    rain_record.ToY = eto_record.ToY
                else
                    rain_record.ToY = rain_record.FromY
                end 
                rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
            end 
            # ! bepaal characteristieken van ClimRecord
            clim_record.FromY = eto_record.FromY
            clim_record.FromDayNr = eto_record.FromDayNr
            if clim_record.FromDayNr < rain_record.FromDayNr
                clim_record.FromY = rain_record.FromY
                clim_record.FromDayNr = rain_record.FromDayNr
            end
            clim_record.ToDayNr = eto_record.ToDayNr
            if clim_record.ToDayNr > rain_record.ToDayNr
                clim_record.ToDayNr = rain_record.ToDayNr
            end 
            if clim_record.ToDayNr < clim_record.FromDayNr
                clim_file = "(None)"
                clim_record.NrObs = 0
                clim_record.FromY = 1901
            end 
        end 
    end 

    # Part B - ClimFile and Temperature files --> ClimFile
    if (temperature_file != "(None)") 
        if clim_file == "(None)"
            clim_file = "EToRainTempFile"
            clim_record.FromY = temperature_record.FromY
            clim_record.FromDayNr = temperature_record.FromDayNr
            clim_record.ToDayNr = temperature_record.ToDayNr
            if full_undefined_record(temperature_record)
                clim_record.NrObs = 365
            else
                clim_record.NrObs = temperature_record.ToDayNr - temperature_record.FromDayNr + 1
            end
        else
            clim_record.FromD, clim_record.FromM, clim_record.FromY = determine_date(clim_record.FromDayNr)
            clim_record.ToD, clim_record.ToM, clim_record.ToY = determine_date(clim_record.ToDayNr)
            if (clim_record.FromY == 1901) & (full_undefined_record(temperature_record))
                clim_record.NrObs = 365
            else
                clim_record.NrObs = temperature_record.ToDayNr - temperature_record.FromDayNr + 1
            end 
            
            if (clim_record.FromY == 1901) & (temperature_record != 1901)
                clim_record.FromY = temperature_record.FromY
                clim_record.FromDayNr = determine_day_nr(clim_record.FromD, clim_record.FromM, clim_record.FromY)
                if (clim_record.FromDayNr < temperature_record.FromDayNr) & (temperature_record.FromY < temperature_record.ToY)
                    clim_record.FromY = temperature_record.FromY + 1
                    clim_record.FromDayNr = determine_day_nr(clim_record.FromD, clim_record.FromM, clim_record.FromY
                end 
                if full_undefined_record(clim_record)
                    clim_record.ToY = temperature_record.ToY
                else
                    clim_record.ToY = clim_record.FromY
                end
                clim_record.ToDayNr = determine_day_nr(clim_record.ToD, clim_record.ToM, clim_record.ToY)
            end 

            if (clim_record.FromY /= 1901) & (temperature_record == 1901)
                temperature_record.FromY = clim_record.FromY
                temperature_record.FromDayNr = determine_day_nr(temperature_record.FromD, temperature_record.FromM, temperature_record.FromY)
                if (temperature_record.FromDayNr < clim_record.FromDayNr) & (clim_record.FromY < clim_record.ToY)
                    temperature_record.FromY = clim_record.FromY + 1
                    temperature_record.FromDayNr = determine_day_nr(temperature_record.FromD, temperature_record.FromM, temperature_record.FromY
                end 
                if full_undefined_record(temperature_record)
                    temperature_record.ToY = clim_record.ToY
                else
                    temperature_record.ToY = temperature_record.FromY
                end
                temperature_record.ToDayNr = determine_day_nr(temperature_record.ToD, temperature_record.ToM, temperature_record.ToY)
            end 

            # ! bepaal nieuwe characteristieken van ClimRecord
            if clim_record.FromDayNr < temperature_record.FromDayNr
                clim_record.FromY = temperature_record.FromY
                clim_record.FromDayNr = temperature_record.FromDayNr
            end
            if clim_record.ToDayNr > temperature_record.ToDayNr
                clim_record.ToDayNr = temperature_record.ToDayNr
            end
            if clim_record.ToDayNr < clim_record.FromDayNr
                clim_file = "(None)"
                clim_record.NrObs = 0
                clim_record.FromY = 1901
            end
        end 
    end 

    setparameter!(inse[:string_parameters], :clim_file, clim_file)
    return nothing
end


"""
    logi = full_undefined_record(record::RepClim)

global.f90:2826
"""
function full_undefined_record(record::RepClim)
    fromy = record.FromY
    fromd = record.FromD
    fromm = record.FromM
    tod = record.ToD
    tom = record.ToM
    return ((fromy == 1901) & (fromd == 1) & (fromm == 1) & (tod == 31) & (tom == 12))
end


"""
    adjust_onset_search_period!(inse)

global.f90:4214
"""
function adjust_onset_search_period!(inse)
    onset = inse[:onset]
    simulation = inse[:simulation]
    clim_file = inse[:string_parameters][:clim_file]
    clim_record = inse[:clim_record]

    if clim_file=="(None)"
        onset.StartSearchDayNr = 1
        onset.StopSearchDayNr = onset.StartSearchDayNr + onset.LengthSearchPeriod + 1
    else
        onset.StartSearchDayNr = determine_day_nr(1, 1, simulation.YearStartCropCycle) # January 1st
        if onset.StartSearchDayNr < clim_record.FromDayNr
            onset.StartSearchDayNr = clim_record.FromDayNr
        end
        onset.StopSearchDayNr = onset.StartSearchDayNr + onset.LengthSearchPeriod + 1
        if onset.StopSearchDayNr > clim_record.ToDayNr
            onset.StopSearchDayNr = clim_record.ToDayNr
            onset.LengthSearchPeriod = onset.StopSearchDayNr - onset.StartSearchDayNr + 1
        end 
    end 

    return nothing
end

"""
    load_crop!(crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file)

global.f90:4799
"""
function load_crop!(crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file)
    open(crop_file, "r") do file
        readline(file)
        readline(file)

        # subkind
        xx = parse(Int, strip(readline(file)))
        if xx==1
            crop.subkind = :Vegetative
        elseif xx==2
            crop.subkind = :Grain
        elseif xx==3 
            crop.subkind = :Tuber
        elseif xx==4
            crop.subkind = :Forage
        end

        # type of planting
        xx = parse(Int, strip(readline(file)))
        if xx==1
            crop.Planting = :Seed
        elseif xx==0
            crop.Planting = :Transplat
        elseif xx==-9
            crop.Planting = :Regrowth
        else
            crop.Planting = :Seed
        end

        # mode
        xx = parse(Int, strip(readline(file)))
        if xx==0
            crop.ModeCycle = :GDDays
        else
            crop.ModeCycle = :CalendarDays
        end

        # adjustment p to ETo
        xx = parse(Int, strip(readline(file)))
        if xx==0
            crop.pMethod = :NoCorrection
        elseif xx==1
            crop.pMethod = :FAOCorrection
        end

        # temperatures controlling crop development
        crop.Tbase = parse(Float64, strip(readline(file)))
        crop.Tupper = parse(Float64, strip(readline(file)))

        # required growing degree days to complete the crop cycle
        # (is identical as to maturity)
        crop.GDDaysToHarvest = parse(Float64, strip(readline(file)))

        # water stress
        crop.pLeafDefUL = parse(Float64, strip(readline(file)))
        crop.pLeafDefLL = parse(Float64, strip(readline(file)))
        crop.KsShapeFactorLeaf = parse(Float64, strip(readline(file)))
        crop.pdef = parse(Float64, strip(readline(file)))
        crop.KsShapeFactorStomata = parse(Float64, strip(readline(file)))
        crop.pSenescence = parse(Float64, strip(readline(file)))
        crop.KsShapeFactorSenescence = parse(Float64, strip(readline(file)))
        crop.SumEToDelaySenescence = parse(Float64, strip(readline(file)))
        crop.pPollination = parse(Float64, strip(readline(file)))
        crop.AnaeroPoint = parse(Float64, strip(readline(file)))

        # soil fertility/salinity stress
        # Soil fertility stress at calibration (%)
        crop.StressResponse.Stress = parse(Int, strip(readline(file)))
        # Shape factor for the response of Canopy
        # Growth Coefficient to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCGC = parse(Float64, strip(readline(file)))
        # Shape factor for the response of Maximum
        # Canopy Cover to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCCX = parse(Float64, strip(readline(file)))
        # Shape factor for the response of Crop
        # Water Producitity to soil
        # fertility stress
        crop.StressResponse.ShapeWP = parse(Float64, strip(readline(file)))
        # Shape factor for the response of Decline
        # of Canopy Cover to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCDecline = parse(Float64, strip(readline(file)))

        readline(file)

        # continue with soil fertility/salinity stress
        if ((crop.StressResponse.ShapeCGC>24.9) & (crop.StressResponse.ShapeCCX>24.9) &
            (crop.StressResponse.ShapeWP>24.9) & (crop.StressResponse.ShapeCDecline>24.9))
            crop.StressResponse.Calibrated = false
        else
            crop.StressResponse.Calibrated = true 
        end

        # temperature stress
        # Minimum air temperature below which
        # pollination starts to fail
        # (cold stress) (degC)
        crop.Tcold = parse(Int, strip(readline(file)))
        # Maximum air temperature above which
        # pollination starts to fail
        # eat stress) (degC)
        crop.Theat = parse(Int, strip(readline(file)))
        # Minimum growing degrees required for full
        # biomass production (degC - day)
        crop.GDtranspLow = parse(Float64, strip(readline(file)))

        # salinity stress (Version 3.2 and higher)
        # upper threshold ECe
        crop.ECemin = parse(Int, strip(readline(file)))
        # lower threhsold ECe
        crop.ECemax = parse(Int, strip(readline(file)))
        readline(fhandle)

        crop.CCsaltDistortion = parse(Int, strip(readline(file)))
        crop.ResponseECsw = parse(Int, strip(readline(file)))

        # evapotranspiration
        crop.KcTop = parse(Float64, strip(readline(file)))
        crop.KcDecline = parse(Float64, strip(readline(file)))
        crop.RootMin = parse(Float64, strip(readline(file)))
        crop.RootMax = parse(Float64, strip(readline(file)))
        if crop.RootMin > crop.RootMax
            crop.RootMin = crop.RootMax
        end
        crop.RootShape = parse(Int, strip(readline(file)))
        crop.SmaxTopQuarter = parse(Float64, strip(readline(file)))
        crop.SmaxBotQuarter = parse(Float64, strip(readline(file)))
        crop.SmaxTop, crop.SmaxBot = derive_smax_top_bottom(crop)
        crop.CCEffectEvapLate = parse(Int, strip(readline(file)))

        # crop development
        crop.SizeSeedling = parse(Float64, strip(readline(file)))
        # Canopy size of individual plant
        # (re-growth) at 1st day (cm2)
        crop.SizePlant = parse(Float64, strip(readline(file)))

        crop.PlantingDens = parse(Int, strip(readline(file)))
        crop.CCo = crop.PlantingDens/10000 * crop.SizeSeedling/10000
        crop.CCini = crop.PlantingDens/10000 * crop.SizePlant/10000

        crop.CGC = parse(Float64, strip(readline(file)))

        # Number of years at which CCx declines
        # to 90 % of its value due to
        # self-thinning - for Perennials
        crop.YearCCx = parse(Int, strip(readline(file)))
        # Shape factor of the decline of CCx over
        # the years due to self-thinning
        # for Perennials
        crop.CCxRoot = parse(Float64, strip(readline(file)))

        readline(file)

        crop.CCx = parse(Float64, strip(readline(file)))
        crop.CDC = parse(Float64, strip(readline(file)))
        crop.DaysToGermination = parse(Int, strip(readline(file)))
        crop.DaysToMaxRooting = parse(Int, strip(readline(file)))
        crop.DaysToSenescence = parse(Int, strip(readline(file)))
        crop.DaysToHarvest = parse(Int, strip(readline(file)))
        crop.DaysToFlowering = parse(Int, strip(readline(file)))
        crop.LengthFlowering = parse(Int, strip(readline(file)))

        if (crop.subkind==:Vegetative) | (crop.subkind==:Forage)
            crop.DaysToFlowering = 0
            crop.LengthFlowering = 0
        end

        # Crop.DeterminancyLinked
        xx = parse(Int, strip(readline(file)))
        if xx==1
            crop.DeterminancyLinked = true
        else
            crop.DeterminancyLinked = false
        end

        # Potential excess of fruits (%) and building up HI
        if crop.subkind==:Vegetative | crop.subkind==:Forage
            readline(file)
            crop.fExcess = undef_int
        else
            crop.fExcess = parse(Int, strip(readline(file)))
        end
        crop.DaysToHIo = parse(Int, strip(readline(file)))

        # yield response to water
        crop.WP = parse(Float64, strip(readline(file)))
        crop.WPy = parse(Int, strip(readline(file)))
        # adaptation to elevated CO2 (Version 3.2 and higher)
        crop.AdaptedToCO2 = parse(Int, strip(readline(file)))
        crop.HI = parse(Int, strip(readline(file)))
        # possible increase (%) of HI due
        # to water stress before flowering
        crop.HIincrease = parse(Int, strip(readline(file)))
        # coefficient describing impact of
        # restricted vegetative growth at
        # flowering on HI
        crop.aCoeff = parse(Float64, strip(readline(file)))
        # coefficient describing impact of
        # stomatal closure at flowering on HI
        crop.bCoeff = parse(Float64, strip(readline(file)))
        # allowable maximum increase (%) of
        # specified HI
        crop.DHImax = parse(Int, strip(readline(file)))

        # growing degree days
        crop.GDDaysToGermination = parse(Int, strip(readline(file)))
        crop.GDDaysToMaxRooting = parse(Int, strip(readline(file)))
        crop.GDDaysToSenescence = parse(Int, strip(readline(file)))
        crop.GDDaysToHarvest = parse(Int, strip(readline(file)))
        crop.GDDaysToFlowering = parse(Int, strip(readline(file)))
        crop.GDDLengthFlowering = parse(Int, strip(readline(file)))
        crop.GDDCGC = parse(Float64, strip(readline(file)))
        crop.GDDCDC = parse(Float64, strip(readline(file)))
        crop.GDDaysToHIo = parse(Float64, strip(readline(file)))

        # leafy vegetable crop has an Harvest Index which builds up
        # starting from sowing
        if (crop.ModeCycle==:GDDays) & (crop.subkind==:Vegetative | crop.subkind==:Forage)
            crop.GDDaysToFlowering = 0
            crop.GDDLengthFlowering = 0
        end

        # dry matter content (%)
        # of fresh yield
        crop.DryMatter = parse(Int, strip(readline(file)))

        # Minimum rooting depth in first
        # year in meter (for regrowth)
        crop.RootMinYear1 = parse(Float64, strip(readline(file)))

        xx = parse(Int, strip(readline(file))
        if xx==1
            # crop is sown in 1 st year
            # (for perennials)
            crop.SownYear1 = true
        else
            # crop is transplanted in
            # 1st year (for regrowth)
            crop.SownYear1 = false
        end

        # transfer of assimilates
        xx = parse(Int, strip(readline(file))
        if xx==1
            # Transfer of assimilates from
            # above ground parts to root
            # system is considered
            crop.Assimilates.On = true
        else
            # Transfer of assimilates from
            # above ground parts to root
            # system is NOT considered
            crop.Assimilates.On = false 
        end
        # Number of days at end of season
        # during which assimilates are
        # stored in root system
        crop.Assimilates.Period = parse(Int, strip(readline(file)))
        # Percentage of assimilates,
        # transferred to root system
        # at last day of season
        crop.Assimilates.Stored = parse(Int, strip(readline(file)))
        # Percentage of stored
        # assimilates, transferred to above
        # ground parts in next season
        crop.Assimilates.Mobilized = parse(Int, strip(readline(file)))

        if crop.subkind==:Forage
            # data for the determination of the growing period
            # 1. Title
            readline(file)
            readline(file)
            readline(file)
            # 2. ONSET
            xx = parse(Int, strip(readline(file)))
            if xx==0
                perennial_period.GenerateOnset = false
            else
                perennial_period.GenerateOnset = true
                if xx==12
                    perennial_period.OnsetCriterion = :TMeanPeriod
                elseif xx==13
                    perennial_period.OnsetCriterion = :GDDPeriod
                else
                    perennial_period.GenerateOnset = false
                end
            end
            
            perennial_period.OnsetFirstDay = parse(Int, strip(readline(file)))
            perennial_period.OnsetFirstMonth = parse(Int, strip(readline(file)))
            perennial_period.OnsetLengthSearchPeriod = parse(Int, strip(readline(file)))
            # Mean air temperature
            # or Growing-degree days
            perennial_period.OnsetThresholdValue = parse(Float64, strip(readline(file)))
            # number of succesive days
            perennial_period.OnsetPeriodValue = parse(Int, strip(readline(file)))
            # number of occurrence
            perennial_period.OnsetOccurrence = parse(Int, strip(readline(file)))
            if perennial_period.OnsetOccurrence > 3
                perennial_period.OnsetOccurrence = 3
            end
            
            # 3. END of growing period
            xx = parse(Int, strip(readline(file)))
            if xx==0
                # end is fixed on a
                # specific day
                perennial_period.GenerateEnd = false
            else
                # end is generated by an air temperature criterion
                perennial_period.GenerateEnd = true
                if x==62
                    # Criterion: mean air temperature
                    perennial_period.EndCriterion = :TMeanPeriod
                elseif x==63
                    # Criterion: growing-degree days
                    perennial_period.EndCriterion = :GDDPeriod
                else
                    perennial_period.GenerateEnd = false
                end
            end

            perennial_period.EndLastDay = parse(Int, strip(readline(file)))
            perennial_period.EndLastMonth = parse(Int, strip(readline(file)))
            perennial_period.ExtraYears = parse(Int, strip(readline(file)))
            perennial_period.EndLengthSearchPeriod = parse(Int, strip(readline(file)))
            # Mean air temperature
            # or Growing-degree days
            perennial_period.EndThresholdValue = parse(Int, strip(readline(file)))
            # number of succesive days
            perennial_period.EndPeriodValue = parse(Int, strip(readline(file)))
            # number of occurrence
            perennial_period.EndOccurrence = parse(Int, strip(readline(file)))
            if perennial_period.EndOccurrence > 3
                perennial_period.EndOccurrence = 3
            end
        end
    end

    return nothing
end


"""
    sxtop, sxbot = derive_smax_top_bottom(crop::RepCrop)

global.f90:1944
"""
function derive_smax_top_bottom(crop::RepCrop)
    sxtopq = crop.SmaxTopQuarter
    scbotq = crop.SmaxBotQuarter
    v1 = sxtopq
    v2 = sxbotq
    if (abs(v1 - v2) < 1e-12) 
        sxtop = v1
        sxbot = v2
    else
        if (sxtopq < sxbotq) 
            v1 = sxbotq
            v2 = sxtopq
        end 
        x = 3 * v2/(v1-v2)
        if (x < 0.5) 
            v11 = (4/3.5) * v1
            v22 = 0
        else
            v11 = (x + 3.5) * v1/(x+3)
            v22 = (x - 0.5) * v2/x
        end 
        if (sxtopq > sxbotq) 
            sxtop = v11
            sxbot = v22
        else
            sxtop = v22
            sxbot = v11
        end 
    end 

    return sxtop, sxbot
end


"""
    adjust_year_perennials!(crop::RepCrop, theyearseason)

global.f90:4690
"""
function adjust_year_perennials!(crop::RepCrop, theyearseason)
    sownyear1  = crop.SownYear1
    thecyclemode = crop.ModeCycle
    zmax = crop.RootMax
    zminyear1 = crop.RootMinYear1
    thecco = crop.CCo
    thesizeseedling = crop.SizeSeedling
    thecgc = crop.CGC
    theccx = crop.CCx
    thegddcgc = crop.GDDCGC
    theplantingdens  = crop.PlantingDens
    thesizeplant = crop.SizePlant

    if (theyearseason == 1) 
        if (sown1styear == true)  ! planting
            typeofplanting = :Seed
        else
            typeofplanting = :Transplant
        end 
        zmin = zminyear1  # rooting depth
    else
        typeofplanting = :Regrowth # planting
        zmin = zmax  # rooting depth
        # plant size by regrowth
        if (round(Int, 100*thesizeplant) < round(100*thesizeseedling)) 
            thesizeplant = 10 * thesizeseedling
        end 
        if (round(Int, 100*thesizeplant) > 
            round(Int, (100*theccx*10000)/(theplantingdens/10000))) 
            # adjust size plant to maximum possible
            thesizeplant = (theccx*10000)/(theplantingdens/10000p)
        end 
    end 
    theccini = (theplantingdens/10000) * (thesizeplant/10000)
    thedaystoccini = time_to_cc_ini(typeofplanting, theplantingdens, 
                       thesizeseedling, thesizeplant, theccx, thecgc)
    if (thecyclemode == :GDDays) 
        thegddaystoccini = time_to_cc_ini(typeofplanting, theplantingdens, 
                       thesizeseedling, thesizeplant, theccx, thegddcgc)
    else
        thegddaystoccini = undef_int
    end 

    crop.Planting = typeofplanting
    crop.RootMin = zmin
    crop.SizePlant = thesizeplant
    crop.CCini = theccini
    crop.DaysToCCini = thedaystoccini  
    crop.GDDaysToCCini = thegddaystoccini

    return nothing
end

"""
    adjust_crop_file_parameters!(inse)

tempprocessing.f90:1882
"""
function adjust_crop_file_parameters!(inse)
    crop = inse[:crop]
    crop_file_set = inse[:crop_file_set]
    simulparam = inse[:simulparam]

    lseasondays = crop.DaysToHarvest
    thecropday1 = crop.Day1
    themodecycle = crop.ModeCycle
    thetbase = crop.Tbase
    thetupper = crop.Tupper


    # Adjust some crop parameters (CROP.*) as specified by the generated length
    # season (LseasonDays)
    # time to maturity
    if (themodecycle == :GDDays) 
        tmin_tmp = simulparam.Tmin 
        tmax_tmp = simulparam.Tmax 
        gdd1234 = growing_degree_days(inse, tmin_tmp, tmax_tmp) 

    else
        gdd1234 = undef_int
    end 

    # time to senescence  (reference is given in thecropfileset
    if (themodecycle == :GDDays) 
        gdd123 = gdd1234 - crop_file_set.GDDaysFromSenescenceToEnd
        if (gdd123 >= gdd1234) 
            gdd123 = gdd1234
            l123 = lseasondays
        else
            tmin_tmp = simulparam.Tmin 
            tmax_tmp = simulparam.Tmax 
            l123 = sum_calendar_days(gdd123, thecropday1, thetbase, thetupper, tmin_tmp, tmax_tmp)
        end 
    else
        l123 = lseasondays - crop_file_set.DaysFromSenescenceToEnd
        if (l123 >= lseasondays)
            l123 = lseasondays
        end
        gdd123 = undef_int
    end 
    crop.DaysToSenescence = l123
    crop.GDDaysToSenescence = gdd123
    crop.GDDaysToHarvest = gdd1234

    return nothing
end #not end

"""
    gdd1234 = growing_degree_days(inse, tdaymin, tdaymax)

tempprocessing.f90:871
"""
function growing_degree_days(inse, tdaymin, tdaymax)
    crop = inse[:crop]
    temperature_file = inse[:string_parameters][:temperature_file]
    temperature_file_exists = inse[:bool_parameters][:temperature_file_exists]
    simulparam = inse[:simulparam]
    temperature_record = inse[:temperature_record]
    Tmin = inse[:array_parameters][:Tmin]
    Tmax = inse[:array_parameters][:Tmax]

    valperiod = crop.DaysToHarvest
    firstdayperiod = crop.Day1
    tbase = crop.Tbase
    tupper = crop.Tupper

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    tdaymin_local = tdaymin
    tdaymax_local = tdaymax
    gddays = 0

    if (valperiod > 0) 
        if (temperature_file=="(None)") 
            # given average Tmin and Tmax
            daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
            gddays = round(Int, valperiod * daygdd)
        else
            # temperature file
            daynri = firstdayperiod
            if full_undefined_record(temperature_record)
                adjustdaynri = true
                daynri = set_daynr_to_yundef(daynri)
            else
                adjustdaynri = false
            end 

            if (temperature_file_exists & temperature_record.ToDayNr>daynri & temperature_record.FromDayNr<=daynri
                remainingdays = valperiod
                if temperature_record.Datatype == :Daily
                    # Tmin and Tmax arrays contain the TemperatureFilefull data
                    i = daynri - temperature_record.FromDayNr + 1
                    tdaymin_local = Tmin[i]
                    tdaymax_local = Tmax[i]

                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1

                    while ((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) | AdjustDayNri))
                        i = i + 1
                        if (i == length(Tmin)) 
                            i = 1
                        end 
                        tdaymin_local = Tmin[i]
                        tdaymax_local = Tmax[i]

                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)

                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end 

                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 
                elseif temperature_record.Datatype == :Decadely
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri)
                    i = 1
                    while (tmin_dataset[i].DayNr != daynri)
                        i = i+1
                    end 
                    tdaymin_local = tmin_dataset[i].Param
                    tdaymax_local = tmax_dataset[i].Param

                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)

                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1
                    while ((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) |  adjustdaynri))
                        if (daynri > tmin_dataset[31].DayNr)
                            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri)
                        end
                        i = 1
                        while (tmin_dataset[i].DayNr != daynri)
                            i = i+1
                        end
                        tdaymin_local = tmin_dataset[i].Param
                        tdaymax_local = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end
                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 

                elseif temperature_record.Datatype == :Monthly
                    get_monthly_temperature_dataset!(daynri, tmin_dataset, tmax_dataset)
                    i = 1
                    while (tmin_dataset[i].DayNr != daynri)
                        i = i+1
                    end
                    tdaymin_local = tmin_dataset[i].Param
                    tdaymax_local = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1
                    while((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) | adjustdaynri))
                        if (daynri > tmin_dataset[31].DayNr) 
                            get_monthly_temperature_dataset!(daynri, tmin_dataset, tmax_dataset)
                        end
                        i = 1
                        while (tmin_dataset[i].DayNr != daynri)
                            i = i+1
                        end
                        tdaymin_local = tmin_dataset[i].Param
                        tdaymax_local = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end 
                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 
                end 
            end
        end
    else
        gddays = undef_int
    end
    return round(Int, gddays)
end #not end

"""
    dgrd = degrees_day(tbase, tupper, tdaymin, tdaymax, gddselectedmethod)

global.f90:2419
"""
function degrees_day(tbase, tupper, tdaymin, tdaymax, gddselectedmethod)
    if gddselectedmethod==1
        # method 1. - no adjustemnt of tmax, tmin before calculation of taverage
        tavg = (tdaymax+tdaymin)/2
        if (tavg > tupper) then
            tavg = tupper
        end 
        if (tavg < tbase) then
            tavg = tbase
        end
    elseif gddselectedmethod==2
        # method 2. -  adjustment for tbase before calculation of taverage
        tstarmax = tdaymax
        if (tdaymax < tbase) 
            tstarmax = tbase
        end 
        if (tdaymax > tupper) 
            tstarmax = tupper
        end 
        tstarmin = tdaymin
        if (tdaymin < tbase) 
            tstarmin = tbase
        end 
        if (tdaymin > tupper) 
            tstarmin = tupper
        end 
        tavg = (tstarmax+tstarmin)/2
    else
        # method 3.
        tstarmax = tdaymax
        if (tdaymax < tbase) 
             tstarmax = tbase
        end 
        if (tdaymax > tupper) 
            tstarmax = tupper
        end 
        tstarmin = tdaymin
        if (tdaymin > tupper) 
            tstarmin = tupper
        end 
        tavg = (tstarmax+tstarmin)/2
        if (tavg < tbase) then
            tavg = tbase
        end 
    end 
    dgrd =  tavg - tbase
    return  dgrd
end 

"""
    daynri = set_daynr_to_yundef(daynri)

tempprocessing.f90:351
"""
function set_daynr_to_yundef(daynri)
    dayi, monthi, yeari = determine_date(daynri)
    yeari = 1901
    return determine_day_nr(dayi, monthi, yeari)
end


"""
    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri)

tempprocessing.f90:362
"""
function get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri)
    dayi, monthi, yeari = determine_day_nr(darnri)
    if (dayi > 20) 
        deci = 3
        dayi = 21
        dayn = DaysInMonth[monthi]
        if ((monthi == 2) & isleapyear(yeari)) 
            dayn = dayn + 1
        end 
        ni = dayn - dayi + 1
    elseif (dayi > 10) 
        deci = 2
        dayi = 11
        dayn = 20
        ni = 10
    else
        deci = 1
        dayi = 1
        dayn = 10
        ni = 10
    end 
    get_set_of_three(dayn, deci, monthi, yeari, c1min, c1max, c2min, c2max, c3min, c3max)
    dnr = determine_day_nr(dayi, monthi, yeari)

    ulmin, llmin, midmin = get_parameters(c1min, c2min, c3min)
    for nri in 1:ni
        tmin_dataset[nri].DayNr = dnr+nri-1
        if (nri <= (ni/2+0.01)) 
            tmin_dataset[nri].Param = (2*ulmin + (midmin-ulmin)*(2*nri-1)/(ni/2))/2
        else
            if (((ni == 11) | (ni == 9)) & (nri < (ni+1.01)/2)) 
                tmin_dataset[nri].Param = midmin
            else
                tmin_dataset[nri].Param = (2*midmin + (llmin-midmin)*(2*nri-(ni+1))/(ni/2))/2
            end 
        end 
    end 

    ulmax, llmax, midmax = get_parameters(c1max, c2max, c3max)
    for nri in 1:ni
        tmax_dataset[nri]%DayNr = dnr+nri-1
        if (nri <= (ni/2+0.01)) 
            tmax_dataset[nri].Param = (2*ulmax + (midmax-ulmax)*(2*nri-1)/(ni/2))/2
        else
            if (((ni == 11) | (ni == 9)) & (nri < (ni+1.01)/2)) 
                tmax_dataset[nri].Param = midmax
            else
                tmax_dataset[nri].Param = (2*midmax + (llmax-midmax)*(2*nri-(ni+1))/(ni/2))/2
            end 
        end 
    end 

    for nri = (ni+1), 31
        tmin_dataset[Nri].DayNr = dnr+ni-1
        tmin_dataset[Nri].Param = 0
        tmax_dataset[Nri].DayNr = dnr+ni-1
        tmax_dataset[Nri].Param = 0
    end 

    return nothing
end #not end

"""
    ul, ll, mid = get_parameters(c1, c2, c3)

tempprocessing.f90:580
"""
function get_parameters(c1, c2, c3)
    ul = (c1+c2)/2
    ll = (c2+c3)/2
    mid = 2*c2 - (ul+ll)/2
    # --previous decade-->/ul/....... mid ......../ll/<--next decade--
    return ul, ll, mid
end 

"""


tempprocessing.f90:439
"""
function get_set_of_three(dayn, deci, monthi, yeari, c1min, c1max, c2min, c2max, c3min, c3max)
        integer(int32), intent(in) :: DayN
        integer(int32), intent(in) :: Deci
        integer(int32), intent(in) :: Monthi
        integer(int32), intent(in) :: Yeari
        real(dp), intent(inout) :: C1Min
        real(dp), intent(inout) :: C1Max
        real(dp), intent(inout) :: C2Min
        real(dp), intent(inout) :: C2Max
        real(dp), intent(inout) :: C3Min
        real(dp), intent(inout) :: C3Max

        integer(int32) :: fhandle
        integer(int32) :: DecFile, Mfile, Yfile, Nri, Obsi, rc
        logical :: OK3
        character(len=255) :: StringREAD

        # 1 = previous decade, 2 = Actual decade, 3 = Next decade;
        open(newunit=fhandle, file=trim(GetTemperatureFilefull()), &
                     status='old', action='read', iostat=rc)
        read(fhandle, *, iostat=rc) ! description
        read(fhandle, *, iostat=rc) ! time step
        read(fhandle, *, iostat=rc) ! day
        read(fhandle, *, iostat=rc) ! month
        read(fhandle, *, iostat=rc) ! year
        read(fhandle, *, iostat=rc)
        read(fhandle, *, iostat=rc)
        read(fhandle, *, iostat=rc)

        if (GetTemperatureRecord_FromD() > 20) then
            DecFile = 3
        elseif (GetTemperatureRecord_FromD() > 10) then
            DecFile = 2
        else
            DecFile = 1
        end if
        Mfile = GetTemperatureRecord_FromM()
        if (GetTemperatureRecord_FromY() == 1901) then
            Yfile = Yeari
        else
            Yfile = GetTemperatureRecord_FromY()
        end if
        OK3 = .false.

        if (GetTemperatureRecord_NrObs() <= 2) then
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C1Min, C1Max)
            select case (GetTemperatureRecord_NrObs())
            case (0)
                C2Min = C1Min
                C2Max = C2Max
                C3Min = C1Min
                C3Max = C1Max
            case (1)
                DecFile = DecFile + 1
                if (DecFile > 3) then
                    call AdjustDecadeMONTHandYEAR(DecFile, Mfile, Yfile)
                end if
                read(fhandle, '(a)', iostat=rc) StringREAD
                call SplitStringInTwoParams(StringREAD, C3Min, C3Max)
                if (Deci == DecFile) then
                    C2Min = C3Min
                    C2Max = C3Max
                    C3Min = C2Min+(C2Min-C1Min)/4._dp
                    C3Max = C2Max+(C2Max-C1Max)/4._dp
                else
                    C2Min = C1Min
                    C2Max = C1Max
                    C1Min = C2Min + (C2Min-C3Min)/4._dp
                    C1Max = C2Max + (C2Max-C3Max)/4._dp
                end if
            end select
            OK3 = .true.
        end if

       if ((.not. OK3) .and. ((Deci == DecFile) .and. (Monthi == Mfile) &
            .and. (Yeari == Yfile))) then
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C1Min, C1Max)
            C2Min = C1Min
            C2Max = C1Max
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C3Min, C3Max)
            C1Min = C2Min + (C2Min-C3Min)/4._dp
            C1Max = C2Max + (C2Max-C3Max)/4._dp
            OK3 = .true.
        end if

        if ((.not. OK3) .and. ((DayN == GetTemperatureRecord_ToD()) &
             .and. (Monthi == GetTemperatureRecord_ToM()))) then
            if ((GetTemperatureRecord_FromY() == 1901) .or. &
                (Yeari == GetTemperatureRecord_ToY())) then
                do Nri = 1, (GetTemperatureRecord_NrObs()-2)
                     read(fhandle, *, iostat=rc)
                end do
                read(fhandle, '(a)', iostat=rc) StringREAD
                call SplitStringInTwoParams(StringREAD, C1Min, C1Max)
                read(fhandle, '(a)', iostat=rc) StringREAD
                call SplitStringInTwoParams(StringREAD, C2Min, C2Max)
                C3Min = C2Min+(C2Min-C1Min)/4._dp
                C3Max = C2Max+(C2Max-C1Max)/4._dp
                OK3 = .true.
            end if
        end if

        if (.not. OK3) then
            Obsi = 1
            do while (.not. OK3)
                if ((Deci == DecFile) .and. (Monthi == Mfile) &
                    .and. (Yeari == Yfile)) then
                    OK3 = .true.
                else
                    DecFile = DecFile + 1
                    if (DecFile > 3) then
                        call AdjustDecadeMONTHandYEAR(DecFile, Mfile, Yfile)
                    end if
                    Obsi = Obsi + 1
                end if
            end do
            if (GetTemperatureRecord_FromD() > 20) then
                DecFile = 3
            elseif (GetTemperatureRecord_FromD() > 10) then
                DecFile = 2
            else
                DecFile = 1
            end if
            do Nri = 1, (Obsi-2)
                read(fhandle, *, iostat=rc)
            end do
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C1Min, C1Max)
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C2Min, C2Max)
            read(fhandle, '(a)', iostat=rc) StringREAD
            call SplitStringInTwoParams(StringREAD, C3Min, C3Max)
        end if
        close(fhandle)
end #not end
