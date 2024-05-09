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
    end 
    
    adjust_calendar_crop!(inse)
    complete_crop_description!(inse[:crop], inse[:simulation], inse[:management])
    # Onset.Off := true;
    clim_file = inse[:string_parameters][:clim_file]
    if clim_file=="(None)" 
        # adjusting Crop.Day1 and Crop.DayN to ClimFile
        adjust_crop_year_to_climfile!(inse[:crop], clim_file, inse[:clim_record])
    else
        inse[:crop].DayN = inse[:crop].Day1 + inse[:crop].DaysToHarvest - 1
    end 

    # adjusting ClimRecord.'TO' for undefined year with 365 days
    if (clim_file != "(None)") & (inse[:clim_record].FromY == 1901) & (inse[:clim_record].NrObs==365) 
        adjust_climrecord_to!(inse[:clim_record], inse[:crop].DayN)
    end 
    # adjusting simulation period
    adjust_simperiod!(inse, projectinput)

    # 4. Irrigation
    if projectinput.Irrigation_Filename == "(None)" 
        irri_file = projectinput.Irrigation_Filename
        no_irrigation!(inse)
    else
        irri_file = projectinput.ParentDir * projectinput.Irrigation_Directory * projectinput.Irrigation_Filename
        load_irri_schedule_info!(inse, fullname)
    end 
    setparameter!(inse[:string_parameters], :irri_file, irri_file)

    # 5. Field Management
    if projectinput.Management_Filename == "(None)" 
        man_file = projectinput.Management_Filename
    else
        man_file = projectinput.ParentDir * projectinput.Management_Directory * projectinput.Management_Filename
        load_management!(inse, man_file)
        # reset canopy development to soil fertility
        daystofullcanopy, RedCGC_temp, RedCCX_temp, fertstress = time_to_max_canopy_sf(
                              inse[:crop].CCo, 
                              inse[:crop].CGC,
                              inse[:crop].CCx,
                              inse[:crop].DaysToGermination,
                              inse[:crop].DaysToFullCanopy,
                              inse[:crop].DaysToSenescence,
                              inse[:crop].DaysToFlowering,
                              inse[:crop].LengthFlowering,
                              inse[:crop].DeterminancyLinked,
                              inse[:crop].DaysToFullCanopySF, 
                              inse[:simulation].EffectStress.RedCGC,
                              inse[:simulation].EffectStress.RedCCX,
                              inse[:management].FertilityStress)
        management.FertilityStress = fertstress
        simulation.EffectStress.RedCGC = RedCGC_temp
        simulation.EffectStress.RedCCX = RedCCX_temp
        crop.DaysToFullCanopySF = daystofullcanopy
    end 
    setparameter!(inse[:string_parameters], :man_file, man_file)

    # 6. Soil Profile
    call SetProfFile(ProjectInput(NrRun)%Soil_Filename)
    if projectinput.Soil_Filename=="(External)"
        prof_file = projectinput.Soil_Filename
    elseif projectinput.Soil_Filename=="(None)"
        prof_file = projectinput.ParentDir * "DEFAULT.SOL"
    else
        # The load of profile is delayed to check if soil water profile need to be
        # reset (see 8.)
        prof_file = projectinput.ParentDir * projectinput.Soil_Directory * projectinput.Soil_Filename
    end 
    setparameter!(inse[:string_parameters], :prof_file, prof_file)


    # 7. Groundwater
    if projectinput.GroundWater_Filename=="(None)"
        groundwater_file = projectinput.GroundWater_Filename
    else
        # Loading the groundwater is done after loading the soil profile (see
        # 9.)
        groundwater_file = projectinput.ParentDir * projectinput.GroundWater_Directory * projectinput.GroundWater_Filename
    end 
    setparameter!(inse[:string_parameters], :groundwater_file, groundwater_file)

    # 8. Set simulation period
    inse[:simulation].FromDayNr = projectinput.Simulation_DayNr1
    inse[:simulation].ToDayNr = projectinput.Simulation_DayNrN
    if (inse[:crop].Day1 != inse[:simulation].FromDayNr) | (inse[:crop].DayN != inse[:simulatio].ToDayNr)
        inse[:simulation].LinkCropToSimPeriod = false
    end 

    # 9. Initial conditions
    if projectinput.SWCIni_Filename=="KeepSWC"
        # No load of soil file (which reset thickness compartments and Soil
        # water content to FC)
        swcini_file = projectinput.SWCIni_Filename
    else
        # start with load and complete profile description (see 5.) which reset
        # SWC to FC by default
        if prof_file=="(External)"
            load_profile_processing!(inse[:soil], inse[:soil_layers], inse[:compartments], inse[:simulparam])
        else
            soil, soil_layers, compartments = load_profile(prof_file, inse[:simulparam])
            inse[:soil] = soil
            inse[:soil_layers] = soil_layers
            inse[:compartments] = compartments
        end 
        complete_profile_description!(inse[:soil_layers], inse[:compartments], inse[:simulation], inse[:total_water_content]) 

        # Adjust size of compartments if required
        totdepth = 0
        for i in eachindex(inse[:compartments]) 
            totdepth = totdepth + inse[:compartments][i].Thickness
        end 
        if inse[:simulation].MultipleRunWithKeepSWX
            # Project with a sequence of simulation runs and KeepSWC
            if round(Int, inse.[:simulation].MultipleRunConstZrx*1000)>round(Int, totdepth*1000) 
                adjust_size_compartments!()
                call AdjustSizeCompartments(GetSimulation_MultipleRunConstZrx())
            end 
        else
            if round(Int, inse[:crop].RootMax*1000)>round(Int, totdepth*1000)
                if round(Int, inse[:soil].RootMax*1000)==round(Int, inse[:crop].RootMax*1000)
                    # no restrictive soil layer
                    adjust_size_compartments!()
                    call AdjustSizeCompartments(real(GetCrop_RootMax(), kind=dp))
                else
                    # restrictive soil layer
                    if round(Int, inse[:soil].RootMax*1000)>round(Int, totdepth*1000)
                        adjust_size_compartments!()
                        call AdjustSizeCompartments(real(GetSoil_RootMax(), kind=dp))
                    end 
                end 
            end 
        end 

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
    clim_file = inse[:string_parameters][:clim_file]
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
            l123 = sum_calendar_days(gdd123, thecropday1, thetbase, thetupper, tmin_tmp, tmax_tmp, inse)
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
end 

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
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
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
                            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
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
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
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
                            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
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
end 

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
    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record::RepClim)

tempprocessing.f90:362
"""
function get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record::RepClim)
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
    c1min, c1max, c2min, c2max, c3min, c3max = get_set_of_three(dayn, deci, monthi, yeari, temperature_file, temperature_record)
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
end

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
    c1min, c1max, c2min, c2max, c3min, c3max = get_set_of_three(dayn, deci, monthi, yeari, temperature_file, temperature_record::RepClim)

tempprocessing.f90:439
"""
function get_set_of_three(dayn, deci, monthi, yeari, temperature_file, temperature_record::RepClim)
    # 1 = previous decade, 2 = Actual decade, 3 = Next decade;
    open(temperature_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        if temperature_record.FromD>20
            decfile=3
        elseif temperature_record.FromD>10
            decfile=2
        else
            decfile=1
        end
        mfile = temperature_record.FromM
        if temperature_record.FromY==1901
            yfile = yeari
        else
            yfile = temperature_record.FromY
        end
        ok3 = false
        
        if temperature_record.NrObs<=2
            splitedline = split(readline(file))
            c1min = parse(Float64, popfirst!(splitedline))
            c1max = parse(Float64, popfirst!(splitedline))
            if temperature_record.NrObs==0
                c2min = c1min
                c2max = c1max #OJO in the original code says c2max = c2max but makes not much sense
                c3min = c1min
                c3max = c1max
            elseif temperature_record.NrObs==1
                decfile += 1
                if decfile>3
                    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
                end
                splitedline = split(readline(file))
                c3min = parse(Float64, popfirst!(splitedline))
                c3max = parse(Float64, popfirst!(splitedline))
                if (deci == decfile) 
                    c2min = c3min
                    c2max = c3max
                    c3min = c2min+(c2min-c1min)/4
                    c3max = c2max+(c2max-c1max)/4
                else
                    c2min = c1min
                    c2max = c1max
                    c1min = c2min + (c2min-c3min)/4
                    c1max = c2max + (c2max-c3max)/4
                end 
            end
            ok3 = true
        end
    
        if !ok3 & deci==decfile & monthi==mfile & yeari==yfile
            splitedline = split(readline(file))
            c1min = parse(Float64, popfirst!(splitedline))
            c1max = parse(Float64, popfirst!(splitedline))
            c2min = c1min
            c2max = c1max
            splitedline = split(readline(file))
            c3min = parse(Float64, popfirst!(splitedline))
            c3max = parse(Float64, popfirst!(splitedline))
            c1min = c2min + (c2min-c3min)/4
            c1max = c2max + (c2max-c3max)/4
            ok3 = true
        end 

        if !ok3 & dayn==temperature_record.ToD & monthi==temperature_record.ToM
            if temperature_record.FromY==1901 | yeari==temperature_record.ToY
                for Nri in 1:(temperature_record.NrObs-2)
                    readline(file)
                end 
                splitedline = split(readline(file))
                c1min = parse(Float64, popfirst!(splitedline))
                c1max = parse(Float64, popfirst!(splitedline))
                splitedline = split(readline(file))
                c2min = parse(Float64, popfirst!(splitedline))
                c2max = parse(Float64, popfirst!(splitedline))
                c3min = c2min+(c2min-c1min)/4
                c3max = c2max+(c2max-c1max)/4
                ok3 = true
            end 
        end 

        if !ok3 
            obsi = 1
            while !ok3
                if (decix==decfile & monthi==mfile & yeari == yfile) 
                    ok3 = true
                else
                    decfile = decfile + 1
                    if decfile>3 
                        decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
                    end
                    obsi = obsi + 1
                end
            end
            if temperature_record.FromD>20
                decfile = 3
            elseif temperature_record.FromD>10
                decfile = 2
            else
                decfile = 1
            end
            for nri in 1:(obsi-2)
                readline(file)
            end 
            splitedline = split(readline(file))
            c1min = parse(Float64, popfirst!(splitedline))
            c1max = parse(Float64, popfirst!(splitedline))
            splitedline = split(readline(file))
            c2min = parse(Float64, popfirst!(splitedline))
            c2max = parse(Float64, popfirst!(splitedline))
            splitedline = split(readline(file))
            c3min = parse(Float64, popfirst!(splitedline))
            c3max = parse(Float64, popfirst!(splitedline))
        end 
    end 

    return c1min, c1max, c2min, c2max, c3min, c3max
end 

""" 
    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)

tempprocessing.f90:293
"""
function adjust_decade_month_and_year(decfile, mfile, yfile)
    decfile = 1
    mfile = mfile + 1
    if (mfile > 12) 
        mfile = 1
        yfile = yfile + 1
    end 
    return decfile, mfile, yfile
end


"""
    mfile, yfile = adjust_month_and_year(mfile, yfile)

tempprocessing.f90:284
"""
function adjust_month_and_year(mfile, yfile)
    mfile = mfile - 12
    yfile = yfile + 1
    return mfile, yfile
end

"""
    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record::RepClim)

tempprocessing.f90:596
"""
function get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)
    c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1 = get_set_of_three_months(monthi, yeari, temperature_file, temperature_record)

    dayi = 1
    dnr = dete(dayi, monthi, yeari)
    dayn = DaysInMonth[monthi]
    if ((monthi == 2) & isleapyear(yeari)) 
        dayn = dayn + 1
    end 

    aover3min, bover2min, cmin = get_interpolation_parameters(c1min, c2min, c3min)
    aover3max, bover2max, cmax = get_interpolation_parameters(c1max, c2max, c3max)
    for dayi in 1:dayn
        t2 = t1 + 1
        tmin_dataset[dayi].DayNr = dnr+dayi-1
        tmax_dataset[dayi].DayNr = dnr+dayi-1
        tmin_dataset[dayi].Param = aover3min*(t2*t2*t2-t1*t1*t1) + bover2min*(t2*t2-t1*t1) + cmin*(t2-t1)
        tmax_dataset[dayi].Param = aover3max*(t2*t2*t2-t1*t1*t1) + bover2max*(t2*t2-t1*t1) + cmax*(t2-t1)
        t1 = t2
    end 
    for dayi in (dayn+1):31
        tmin_dataset[dayi].DayNr = dnr+dayn-1 #OJO maybe is dayi
        tmax_dataset[dayi].DayNr = dnr+dayn-1 #OJO maybe is dayi
        tmin_dataset[dayi].Param = 0
        tmax_dataset[dayi].Param = 0
    end 
    return nothing
end 

"""
    c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1 = get_set_of_three_months(monthi, yeari, temperature_file, temperature_record::RepClim)

tempprocessing.f90:645
"""
function get_set_of_three_months(monthi, yeari, temperature_file, temperature_record::RepClim)
    n1 = 30
    n2 = 30
    n3 = 30

    # 1. Prepare record
    open(temperature_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        mfile = temperature_record.FromM
        if temperature_record.FromY==1901
            yfile = yeari
        else
            yfile = temperature_record.FromY
        end
        ok3 = false

        # 2. IF 3 or less records
        if temperature_record.NrObs<=3
            c1min, c1max = read_month(readline(file))
            x1 = n1
            if temperature_record.NrObs==0
                t1 = x1
                x2 = x1 + n1
                c2min = c1min
                c2max = c1max
                x3 = x2 + n1
                c3min = c1min
                c3max = c1max
            elseif temperature_record.NrObs==1
                t1 = x1
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
                c3min, c3max = read_month(readline(file))
                if monthi==mfile 
                    c2min = c3min
                    c2max = c3max
                    x2 = x1 + n3
                    x3 = x2 + n3
                else
                    C2Min = C1Min
                    C2Max = C1Max
                    X2 = X1 + n1
                    X3 = X2 + n3
               end 
            elseif temperature_record.NrObs==2
                if monthi==mfile 
                    t1 = 0
                end 
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
                c2min, c2max = read_month(readline(file))
                x2 = x1 + n2
                if monthi==mfile 
                    t1 = x1
                end 
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
                c3min, c3max = read_month(readline(file))
                x3 = x2 + n3
                if monthi==mfile 
                    t1 = x2
                end 
            end
            ok3 = true
        end 

        # 3. If first observation
        if !ok3 & monthi==mfile & yeari==yfile
            t1 = 0
            c1min, c1max = read_month(readline(file))
            x1 = n1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2min, c2max = read_month(readline(file))
            x2 = x1 + n2
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3min, c3max = read_month(readline(file))
            x3 = x2 + n3
            ok3 = true
        end 

        # 4. If last observation
        if !ok3 & monthi==temperature_record.ToM
            if temperature_record.FromY==1901 | yeari==temperature_record.ToY
                for nri in 1:(temperature_record.NrObs-3)
                    read(fhandle, *, iostat=rc)
                    mfile = mfile + 1
                    if mfile>12 
                        mfile, yfile = adjust_month_and_year(mfile, yfile)
                    end 
                end 
                c1min, c1max = read_month(readline(file))
                x1 = n1
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
                c2min, c2max = read_month(readline(file))
                x2 = x1 + n2
                t1 = x2
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
                c3min, c3max = read_month(readline(file))
                x3 = x2 + n3
                ok3 = true
            end 
        end 

        # 5. IF not previous cases
        if !ok3
            obsi = 1
            while !ok3
                if ((monthi==mfile) & (yeari==yfile)) 
                   ok3 = true
                else
                   mfile = mfile + 1
                   if mfile>12 
                       mfile, yfile = adjust_month_and_year(mfile, yfile)
                   end 
                  obsi = obsi + 1
                end 
            end 
            mfile = temperature_record.FromM 
            for nri in 1:(obsi-2)
                readline(file)
                mfile = mfile + 1
                if (mfile > 12) then
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
            end
            c1min, c1max = read_month(readline(file))
            x1 = n1
            t1 = x1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2min, c2max = read_month(readline(file))
            x2 = x1 + n2
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3min, c3max = read_month(readline(file))
            x3 = x2 + n3
        end 
    end

    return c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1
end 

"""
    cimin, cimax = read_month(stringline)

tempprocessing.f90:837
"""
function read_month(stringline)
    ni = 30
    splitedline = split(stringline)
    cimin = parse(Int, strip(popfirst!(splitedline))) * ni
    cimax = parse(Int, strip(popfirst!(splitedline))) * ni

    return cimin, cimax
end

"""
     aover3, bover2, c = get_interpolation_parameters(c1, c2, c3)

tempprocessing.f90:854
"""
function get_interpolation_parameters(c1, c2, c3)
    # n1=n2=n3=30 --> better parabola
    aover3 = (c1-2*c2+c3)/(6*30*30*30)
    bover2 = (-6*c1+9*c2-3*c3)/(6*30*30)
    c = (11*c1-7*c2+2*c3)/(6*30)
    return aover3, bover2, c
end


"""
    nrcdays = sum_calendar_days(valgddays, firstdaycrop, tbase, tupper, tdaymin, tdaymax, inse)

tempprocessing.f90:1035
"""
function sum_calendar_days(valgddays, firstdaycrop, tbase, tupper, tdaymin, tdaymax, inse)
    temperature_file = inse[:string_parameters][:temperature_file]
    temperature_file_exists = inse[:bool_parameters][:temperature_file_exists]
    temperature_record = inse[:temperature_record]
    simulparam = inse[:simulparam]
    Tmin = inse[:array_parameters][:Tmin]
    Tmax = inse[:array_parameters][:Tmax]

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    tdaymin_loc = tdaymin
    tdaymax_loc = tdaymax

    nrcdays = 0
    if valgddays>0 
        if temperature_file=="(None)"
            # given average Tmin and Tmax
            daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
            if abs(daygdd) < eps())
                nrcdays = undef_int
            else
                nrcdays = round(Int, valgddays/daygdd)
            end 
        else
            daynri = firstdaycrop
            if full_undefined_record(temp)
                adjustdaynri = true
                daynri = set_daynr_to_yundef(daynri)
            else
                adjustdaynri = false
            end 

            if temperature_file_exists & temperature_record.ToDayNr>daynri & temperature_record.FromDayNr<=daynri
                remaininggddays = valgddays
                if temperature_record.Datatype==:Daily
                    # Tmin and Tmax arrays contain the TemperatureFilefull data
                    i = daynri - temperature_record.FromDayNr + 1
                    tdaymin_loc = Tmin[i]
                    tdaymax_loc = Tmax[i]

                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1

                    while ((remaininggddays > 0) & ((daynri < temperature_record.ToDayNr) | adjustdaynri))
                        i = i + 1
                        if i==length(Tmin) 
                            i = 1
                        end 
                        tdaymin_loc = Tmin[i]
                        tdaymax_loc = Tmax[i]

                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 

                    if RemainingGDDays>0 
                        nrcdays = undef_int
                    end 
                elseif temperature_record.Datatype==:Decadely
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
                    i = 1
                    while tmin_dataset[i].DayNr != daynri
                        i = i+1
                    end 
                    tdaymin_loc = tmin_dataset[i].Param
                    tdaymax_loc = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1
                    while (remaininggddays>0 & (daynri<temperature_record.ToDayNr | adjustdaynri))
                        if daynri>tmin_dataset[31].DayNr 
                            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
                        end
                        i = 1
                        while tmin_dataset[i].DayNr != daynri
                            i = i+1
                        end 
                        tdaymin_loc = tmin_dataset[i].Param
                        tdaymax_loc = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 
                    if remaininggddays>0 
                        nrcdays = undef_int
                    end 
                elseif  temperature_record.Datatype==:Monthly
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
                    i = 1
                    while tmin_dataset[i].DayNr != daynri
                        i = i+1
                    end 
                    tdaymin_loc = tmin_dataset[i].Param
                    tdaymax_loc = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1
                    while (remaininggddays>0 & (daynri<temperature_record.ToDayNr | adjustdaynri)
                        if daynri>tmin_dataset[31].DayNr 
                            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_file, temperature_record)
                        end
                        i = 1
                        while tmin_dataset[i].DayNr != daynri
                            i = i+1
                        end 
                        tdaymin_loc = tmin_dataset[i].Param
                        tdaymax_loc = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 
                    if remaininggddays>0 
                        nrcdays = undef_int
                    end 
                end 
            else
                nrcdays = undef_int
            end
        end
    end
    return nrcdays
end 

"""
    adjust_calendar_crop!(inse)

tempprocessing.f90:1467
"""
function adjust_calendar_crop!(inse)
    crop = inse[:crop]
    cgcisgiven = true

    if crop.ModeCycle==:GDDays
        crop.GDDaysToFullCanopy = crop.GDDaysToGermination +
                round(Int, log((0.25*crop.CCx**2/crop.CCo)/(crop.CCx-0.98*crop.CCx))/crop.GDDCGC)
        if crop.GDDaysToFullCanopy>crop.GDDaysToHarvest 
            crop.GDDaysToFullCanopy = crop.GDDaysToHarvest
        end 
        adjust_calendar_days!(inse, cgcisgiven)
    end 
    return nothing
end 


"""
    adjust_calendar_days!(inse, iscgcgiven)

tempprocessing.f90:1327
"""
function adjust_calendar_days!(inse, iscgcgiven)
    crop = inse[:crop]
    simulparam = inse[:simulparam]
    plantdaynr = crop.Day1
    infocroptype = crop.subkind
    tbase = crop.Tbase
    tupper = crop.Tupper
    notempfiletmin = simulparam.Tmin
    notempfiletmax = simulparam.Tmax
    gddl0 = crop.GDDaysToGermination
    gddl12 = crop.GDDaysToFullCanopy
    gddflor = crop.DaysToFlowering
    gddlengthflor = crop.GDDLengthFlowering
    gddl123 = crop.GDDaysToSenescence
    gddharvest = crop.GDDaysToHarvest
    gddlzmax = crop.GDDaysToMaxRooting
    gddhimax = crop.GDDaysToHIo
    gddcgc = crop.GDDCGC
    gddcdc = crop.GDDCDC
    cco = crop.CCo
    ccx = crop.CCx
    hindex = crop.HI
    thedaystoccini = crop.DaysToCCini
    thegddaystoccini = crop.GDDaysToCCini
    theplanting = crop.Planting
    d0 = crop.DaysToGermination
    d12 = crop.DaysToFullCanopy
    dflor = crop.DaysToFlowering
    lengthflor = crop.LengthFlowering
    d123 = crop.DaysToSenescence
    dharvest = crop.DaysToHarvest
    dlzmax = crop.DaysToMaxRooting
    lhimax = crop.DaysToHIo
    stlength = crop.Length
    cgc = crop.CGC
    cdc = crop.CDC
    dhidt = crop.dHIdt
    notempfiletmax = simulparam.Tmax
    notempfiletmin = simulparam.Tmin

    tmp_notempfiletmin = notempfiletmin
    tmp_notempfiletmax = notempfiletmax

    succes = true
    if thedaystoccini==0 
        # planting/sowing
        d0 = sum_calendar_days(gddl0, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, inse)
        d12 = sum_calendar_days(gddl12, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, inse)
    else
        # regrowth
        if thedaystoccini>0 
           # ccini < ccx
           extragddays = gddl12 - gddl0 - thegddaystoccini
           extradays = sum_calendar_days(extragddays, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, inse)
           d12 = d0 + thedaystoccini + extradays
        end 
    end 

    if infocroptype!=:Forage 
        d123 = sum_calendar_days(gddl123, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
        dharvest = sum_calendar_days(gddharvest, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
    end 

    dlzmax = sum_calendar_days(gddlzmax, plantdaynr, base, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
    if infocroptype==:Grain | infocroptype==:Tuber
        dflor = sum_calendar_days(gddflor, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
        if dflor!=undef_int 
            if infocroptype==subkind_grain 
                lengthflor = sum_calendar_days(gddlengthflor, (plantdaynr+dflor), tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
            else
                lengthflor = 0
            end 
            lhimax = sum_calendar_days(gddhimax, (plantdaynr+dflor), tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
            if (lengthflor==undef_int | lhimax==undef_int) 
                succes = false
            end 
        else
            lengthflor = undef_int
            lhimax = undef_int
            succes = false
        end 
    elseif infocroptype==:Vegetative | infocroptype==:Forage
        lhimax = sum_calendar_days(gddhimax, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
    end 
    if (d0==undef_int | d12 == undef_int | d123==undef_int | dharvest==undef_int | dlzmax==undef_int) 
        succes = false
    end 

    if succes 
        cgc = gddl12/d12 * gddcgc
        cdc = gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, inse)
        stlength, d123, d12, cgc = determine_length_growth_stages(cco, ccx, cdc, d0, dharvest, iscgcgiven, thedaystoccini, theplanting, d123, d12, cgc)
        if (infocroptype==:Grain | infocroptype==:Tuber) 
            dhidt = hindex/lhimax
        end 
        if (infocroptype==subkind_vegetative | infocroptype==subkind_forage) 
            if (lhimax > 0) 
                if (lhimax > dharvest) 
                    dhidt = hindex/dharvest
                else
                    dhidt = hindex/lhimax
                end 
                if (dhidt > 100) 
                    dhidt = 100 # 100 is maximum tempdhidt (see setdhidt)
                    lhimax = 0
                end 
            else
                dhidt = 100 # 100 is maximum tempdhidt (see setdhidt)
                lhimax = 0
            end 
        end 
    end 
    return nothing
end 


"""
    cdc = gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, notempfiletmin, notempfiletmax, inse)

tempprocessing.f90:1545
"""
function gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, notempfiletmin, notempfiletmax, inse)
    gddi = length_canopy_decline(ccx, gddcdc)
    if (gddl123+gddi)<=gddharvest 
        cci = 0 # full decline
    else
        # partly decline
        if gddl123<gddharvest 
            gddi = gddharvest - gddl123
        else
            gddi = 5
        end 
        # cc at time ti
        cci = ccx * (1 - 0.05 * exp(gddi*gddcdc*3.33/(ccx+2.29))-1) 
    end 
    ti = sum_calendar_days(gddi, (plantdaynr+d123), tbase, tupper, notempfiletmin, notempfiletmax, inse)
    if ti>0 
        cdc = ((ccx+2.29)/ti * log(1 + (1-cci/ccx)/0.05))/3.33
    else
        cdc = undef_int
    end 
    return cdc
end 


"""
    lcd = length_canopy_decline(ccx, cdc)

global.f90:1839
"""
function length_canopy_decline(ccx, cdc)
    lcd = 0
    if ccx>0 
        if cdc<=eps() 
            lcd = undef_int
        else
            lcd = round(Int,(((ccx+2.29)/(cdc*3.33))*log(1 + 1/0.05) + 0.50))
                         # + 0.50 to guarantee that cc is zero
        end 
    end 
    return lcd
end

"""
    stlength, length123, length12, cgcval = determine_length_growth_stages(ccoval, ccxval, cdcval, l0, totallength, cgcgiven, thedaystoccini, theplanting, length123, length12, cgcval)

global.f90:1644
"""
function determine_length_growth_stages(ccoval, ccxval, cdcval, l0, totallength, cgcgiven, thedaystoccini, theplanting, length123, length12, cgcval)
    stlength = zeros(Int, 4)
    if length123<length12 
        length123 = length12
    end 

    # 1. Initial and 2. Crop Development stage
    # CGC is given and Length12 is already adjusted to it
    # OR Length12 is given and CGC has to be determined
    if (ccoval>=ccxval | length12<=l0) 
        length12 = 0
        stlength[1] = 0
        stlength[2] = 0
        cgcval = undef_int
    else
        if !cgcgiven  # length12 is given and cgc has to be determined
            cgcval = log((0.25*ccxval/ccoval)/(1-0.98))/(length12-l0)
            # check if cgc < maximum value (0.40) and adjust length12 if required
            if cgcval>0.40 
                cgcval = 0.40
                ccxval_scaled = 0.98*ccxval
                length12 = days_to_reach_cc_with_given_cgc(ccxval_scaled , ccoval, ccxval, cgcval, l0)
                if length123<length12 
                    length123 = length12
                end 
            end 
        end 
        # find StLength[1]
        cctoreach = 0.10
        stlength[1] = days_to_reach_cc_with_given_cgc(cctoreach, ccoval, ccxval, cgcval, l0)
        # find stlength[2]
        stlength[2] = length12 - stlength[1]
    end 
    l12adj = length12

    # adjust Initial and Crop Development stage, in case crop starts as regrowth
    if theplanting==:Regrowth 
        if thedaystoccini==undef_int 
            # maximum canopy cover is already reached at start season
            l12adj = 0
            stlength[1] = 0
            stlength[2] = 0
        else
            if thedaystoccini==0 
                # start at germination
                l12adj = length12 - l0
                stlength[1] = stlength[1] - l0
            else
                # start after germination
                l12adj = length12 - (l0 + thedaystoccini)
                stlength[1] = stlength[1] - (l0 + thedaystoccini)
            end
            if stlength[1]<0 
                stlength[1] = 0
            end 
            stlength[2] = l12adj - stlength[1]
        end 
    end 

    # 3. Mid season stage
    stlength[3] = length123 - l12adj

    # 4. Late season stage
    stlength[4] = length_canopy_decline(ccxval, cdcval)

    # final adjustment
    if stlength[1]>totallength 
        stlength[1] = totallength
        stlength[2] = 0
        stlength[3] = 0
        stlength[4] = 0
    else
        if ((stlength[1]+stlength[2])>totallength) 
            stlength[2] = totallength - stlength[1]
            stlength[3] = 0
            stlength[4] = 0
        else
            if ((stlength[1]+stlength[2]+stlength[3])>totallength) 
                stlength[3] = totallength - stlength[1] - stlength[2]
                stlength[4] = 0
            elseif ((stlength[1]+stlength[2]+stlength[3]+stlength[4])>totallength) 
                stlength[4] = totallength - stlength[1] - stlength[2] - stlength[3]
            end 
        end 
    end 
    return stlength, length123, length12, cgcval 
end 

"""
    days = days_to_reach_cc_with_given_cgc(cctoreach, ccoval, ccxval, cgcval, l0)

global.f90:1809
"""
function days_to_reach_cc_with_given_cgc(cctoreach, ccoval, ccxval, cgcval, l0)
    cctoreach_local = cctoreach
    if (ccoval>cctoreach_local | ccoval>=ccxval) 
        l = 0
    else
        if cctoreach_local>(0.98*ccxval) 
            cctoreach_local = 0.98*ccxval
        end 
        if cctoreach_local<=ccxval/2) 
            l = log(cctoreach_local/ccoval)/cgcval
        else
            l = log((0.25*ccxval*ccxval/ccoval)/(ccxval-cctoreach_local))/cgcval
        end 
    end 
    return l0 + round(Int, l)
end 

"""
    adjust_crop_year_to_climfile!(crop::RepCrop, clim_file, clim_record)

global.f90:6447
"""
function adjust_crop_year_to_climfile!(crop::RepCrop, clim_file, clim_record)
    cday1 = crop.Day1
    cdayn = crop.DayN
    dayi, monthi, yeari = determine_date(cday1)
    if clim_file=="(None)" 
        yeari = 1901  # yeari = 1901 if undefined year
    else
        yeari = clim_record.FromY # yeari = 1901 if undefined year
    end 
    cday1 = determine_day_nr(dayi, monthi, yeari)

    # This function determines Crop.DayN and the string
    cdayn = cday1 + crop.DaysToHarvest - 1
    if cdayn<cday1 
        cdayn = cday1
    end

    crop.Day1 = cday1
    crop.DayN = cdayn
    return nothing
end 

"""
    adjust_climrecord_to!(clim_record::RepClim, cdayn)

global.f90:6163
"""
function adjust_climrecord_to!(clim_record::RepClim, cdayn)
    dayi, monthi, yeari = determine_date(cdayn)
    clim_record.ToD = 31
    clim_record.ToM = 12
    clim_record.ToY = yeari
    clim_record.ToDayNr = determine_day_nr(31, 12, yeari)
    return nothing
end

"""
    adjust_simperiod!(inse, projectinput::ProjectInputType)

global.f90:4692
"""
function adjust_simperiod!(inse, projectinput::ProjectInputType)
    simulation = inse[:simulation]
    crop = inse[:crop]
    clim_file = inse[:string_parameters][:clim_file]
    clim_record = inse[:clim_record]
    simulparam = inse[:simulparam]
    groundwater_file = inse[:string_parameters][:groundwater_file]


    inisimfromdaynr = simulation.FromDayNr
    if simulation.LinkCropToSimPeriod
        determine_linked_simday1!(simulation, crop, clim_record, clim_file)
        if (crop.Day1==simulation.FromDayNr) 
            simulation.ToDayNr = crop.DayN
        else
            simulation.ToDayNr = simulation.FromDayNr + 30
        end 
        if (clim_file != "(None)") 
            if (simulation.ToDayNr>clim_record.ToDayNr) 
                simulation.ToDayNr = clim_record.ToDayNr
            end 
            if (simulation.ToDayNr<clim_record.FromDayNr) 
                simulation.ToDayNr = clim_record.FromDayNr
            end 
        end 
    else 
        if (simulation.FromDayNr>crop.Day1) 
            simulation.FromDayNr = crop.Day1
        end 
        simulation.ToDayNr = crop.DayN
        if (clim_file != "(None)") & (simulation.FromDayNr<=clim_record.FromDayNr | simulation.FromDayNr>=clim_record.ToDayNr) 
            simulation.FromDayNr = clim_record.FromDayNr
            simulation.ToDayNr = simulation.FromDayNr + 30
       end 
    end 

    # adjust initial depth and quality of the groundwater when required
    if (!simulparam.ConstGwt & (inisimfromdaynr != simulation.FromDayNr)) 
        if (groundwater_file != "(None)") 
            fullfilename = projectinput.ParentDir * "/GroundWater.AqC"
        else
            fullfilename = groundwater_file
        end 
        # initialize ZiAqua and ECiAqua
        load_groundwater!(inse, fullname)
        calculate_adjusted_fc!(inse[:compartments], inse[:soil_layers], inse[:integer_parameters][:ziaqua]/100)
        if inse[:simulation].IniSWC.AtFC 
            reset_swc_to_fc!(inse[:simulation], inse[:compartments], inse[:soil_layers], inse[:integer_parameters][:ziaqua])
        end 
    end 

    return nothing
end 

"""
    determine_linked_simday1!(simulation::RepSim, crop::RepCrop, clim_record::RepClim, clim_file)

global.f90:4677
"""
function determine_linked_simday1!(simulation::RepSim, crop::RepCrop, clim_record::RepClim, clim_file)
    simday1 = crop.Day1
    if clim_file != "(None)" 
        if (simday1<clim_record.FromDayNr | simday1>clim_record.ToDayNr) 
            simulation.LinkCropToSimPeriod = false
            simday1 = clim_record.FromDayNr
        end 
    end
    simulation.FromDayNr = simday1
    return nothing
end

"""
    load_groundwater!(inse, fullname)

global.f90:5981
"""
function load_groundwater!(inse, fullname)
    simulparam = inse[:simulparam]
    atdaynr = simulation.FromDayNr

    atdaynr_local = atdaynr
    # initialize
    theend = false
    year1gwt = 1901
    daynr1 = 1
    daynr2 = 1

    if isfile(fullname)
        open(fullname, "r") do file
            readline(file)
            readline(file)

            # mode groundwater table
            i = parse(Int, strip(readline(file)))
            if i==0
                # no groundwater table
                zcm = undef_int
                ecdsm = undef_double 
                simulparam.ConstGwt = true
                theend = true
            elseif i==1
                # constant groundwater table
                simulparam.ConstGwt = true
            else
                simulparam.ConstGwt = false 
            end

            # first day of observations (only for variable groundwater table)
            if !simulparam.ConstGwt 
                dayi = parse(Int, strip(readline(file)))
                monthi = parse(Int, strip(readline(file)))
                year1gwt = parse(Int, strip(readline(file)))
                daynr1gwt = determine_day_nr(dayi, monthi, year1gwt)
            end 

            # single observation (Constant Gwt) or first observation (Variable Gwt)
            if i>0 
                # groundwater table is present
                readline(file)
                readline(file)
                readline(file)
                splitedline = split(readline(file))
                daydouble = parse(Float64, popfirst!(splitedline))
                z2 = parse(Float64, popfirst!(splitedline))
                ec2 = parse(Float64, popfirst!(splitedline))
                if (i==1 | eof(file)) 
                    # Constant groundwater table or single observation
                    Zcm = round(Int,100*z2)
                    ecdsm = ec2
                    theend = true
                else
                    daynr2 = daynr1gwt + round(Int, daydouble) - 1
                end 
            end 

            # other observations
            if !theend 
                # variable groundwater table with more than 1 observation
                # adjust AtDayNr
                dayi, monthi, yeari = determine_date(atdaynr_local)
                if (yeari==1901 & (Year1Gwt != 1901)) 
                    # Make AtDayNr defined
                    atdaynr_local = determine_day_nr(dayi, monthi, year1gwt)
                end 
                if ((yeari != 1901) & Year1Gwt==1901) 
                    # Make AtDayNr undefined
                    atdaynr_local = determine_day_nr(dayi, monthi, year1gwt)
                end 
                # get observation at AtDayNr
                if year1gwt != 1901 
                    # year is defined
                    if atdaynr_local<=daynr2 
                        zcm = round(Int,100*z2)
                        ecdsm = ec2
                    else
                        while !theend
                            daynr1 = daynr2
                            z1 = z2
                            ec1 = ec2
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z2 = parse(Float64, popfirst!(splitedline))
                            ec2 = parse(Float64, popfirst!(splitedline))
                            daynr2 = daynr1gwt + round(Int, daydouble) - 1
                            if (atdaynr_local <= daynr2) 
                                zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                                theend = true
                            end 
                            if (eof(file) & !theend)
                                zcm = round(Int,100*z2)
                                ecdsm = ec2
                                theend = true
                            end 
                        end 
                    end 
                else
                    # year is undefined
                    if (atdaynr_local <= daynr2) 
                        daynr2 = daynr2 + 365
                        atdaynr_local = atdaynr_local + 365
                        while !eof(file)
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z1 = parse(Float64, popfirst!(splitedline))
                            ec1 = parse(Float64, popfirst!(splitedline))
                            daynr1 = daynr1gwt + round(Int, daydouble) - 1
                        end 
                        zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                    else
                        daynrn = daynr2 + 365
                        zn = z2
                        ecn = ec2
                        while !theend
                            daynr1 = daynr2
                            z1 = z2
                            ec1 = ec2
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z2 = parse(Float64, popfirst!(splitedline))
                            ec2 = parse(Float64, popfirst!(splitedline))
                            daynr2 = daynr1gwt + round(Int, daydouble) - 1
                            if (atdaynr_local <= daynr2) 
                                zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                                theend = true
                            end 
                            if (eof(file) & !theend)
                                zcm, ecdsm =  find_values(atdaynr_local, daynr2, daynrn, z2, ec2, zn, ecn)
                                theend = true
                            end 
                        end 
                    end 
                end 
                # variable groundwater table with more than 1 observation
            end 
            inse[:integer_parameters][:ziaqua] = zcm
            inse[:float_parameters][:eciaqua] = ecdsm
        end 
    end

    return nothing 
end 

"""
    zcn, ecdsm = find_values(atdaynr, daynr1, daynr2, z1, ec1, z2, ec2)

global.f90:6140
"""
function find_values(atdaynr, daynr1, daynr2, z1, ec1, z2, ec2)
        zcm = round(int, 100 * (z1 + (z2-z1) * (atdaynr-daynr1)/(daynr2-daynr1)))
        ecdsm = ec1 + (ec2-ec1) * (atdaynr-daynr1)/(daynr2-daynr1)
        return zcm, ecdsm
end 


"""
    calculate_adjusted_fc!(compartadj::Vector{CompartmentIndividual}, soil_layers::Vector{SoilLayerIndividual}, depthaquifer)

global.f90:4141
"""
function calculate_adjusted_fc!(compartadj::Vector{CompartmentIndividual}, soil_layers::Vector{SoilLayerIndividual}, depthaquifer)
    depth = 0
    for compi in eachindex(compartadj)
        depth = depth + compartadj[compi].Thickness
    end 

    compi = length(compartadj)

    while compi>=1
        zi = depth - compartadj[compi].Thickness/2
        xmax = no_adjustment(soil_layers[compartadj[compi].Layer].FC)

        if (depthaquifer<0 | (depthaquifer - zi)>=xmax) 
            for ic in 1:compi
                compartadj[ic].FCadj = soil_layers[compartadj[ic].Layer].FC
            end 
            compi = 0
        else
            if (soil_layers[compartadj[compi].Layer].FC>=soil_layers[compartadj[compi].Layer].SAT)
                compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].FC
            else
                if (zi >= depthaquifer) 
                    compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].SAT
                else
                    deltav = soil_layers[compartadj[compi].Layer].SAT - soil_layers[compartadj[compi].Layer].FC
                    deltafc = (deltav/(xmax**2)) * (zi - (depthaquifer - xmax))**2
                    compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].FC + deltafc
                end 
            end 
            depth = depth - compartadj[compi].Thickness
            compi = compi - 1
        end 
    end 

    return nothing
end

"""
    nadj = no_adjustment(fcvolpr)

global.f90:4195
"""
function no_adjustment(fcvolpr)
    if fcvolpr<=10
        nadj = 1
    else
        if fcvolpr>=30 
            nadj = 2
        else
            pf = 2 + 0.3 * (fcvolpr-10)/20
            nadj = (exp(pf*log(10)))/100
        end 
    end 
    return nadj
end 


"""
    reset_swc_to_fc!(simulation::RepSim, compartments::Vector{CompartmentIndividual},
                     soil_layers::Vector{SoilLayerIndividual}, ziaqua)

global.f90:4758
"""
function reset_swc_to_fc!(simulation::RepSim, compartments::Vector{CompartmentIndividual},
                           soil_layers::Vector{SoilLayerIndividual}, ziaqua)
    simulation.IniSWC.AtDepths = false
    if ziaqua<0  # no ground water table
        simulation.IniSWC.NrLoc = length(soil_layers)
        for layeri = 1:simulation.IniSWC.NrLoc 
            simulation.IniSWC.Loc[layeri] = soil_layers[layeri].Thickness
            simulation.IniSWC.VolProc[layeri] = soil_layers[layeri].FC
            simulation.IniSWC.SaltECe[layeri] = 0 
        end 
    else
        simulation.IniSWC.NrLoc = length(compartments)
        for loci = 1:simulation.IniSWC.NrLoc 
            simulation.IniSWC.Loc[loci] = compartments[loci].Thickness
            simulation.IniSWC.VolProc[loci] = compartments[loci].FCadj
            simulation.IniSWC.SaltECe[loci] = 0 
        end 
    end 
    for compi in eachindex(compartments) 
        compartments[compi].Theta = compartments[compi].FCadj/100
        simulation.ThetaIni[compi] = compartments[compi].Theta
        for celli in 1:soil_layers[compartments[compi].Layer].SCP1
            # salinity in cells
            compartments[compi].Salt[celli] = 0
            compartments[compi].Depo[celli] = 0
        end 
    end 

    return nothing
end 

"""
    no_irrigation!(inse)

global.f90:2838
"""
function no_irrigation!(inse)
    inse[:symbol_parameters][:irrimode] = :NoIrri
    inse[:symbol_parameters][:irrimethod] = :MSprinkler
    inse[:simulation].IrriECw = 0
    inse[:symbol_parameters][:timemode] = :AllRAW
    inse[:symbol_parameters][:depthmode] = :ToFC

    for nri = 1:5
        inse[:irri_before_season][nri].DayNr = 0
        inse[:irri_before_season][nri].Param = 0
        inse[:irri_after_season][nri].DayNr = 0
        inse[:irri_after_season][nri].Param = 0
    end 
    inse[:irri_ecw].PreSeason = 0 
    inse[:irri_ecw].PostSeason = 0 

    return nothing
end 

"""
    load_irri_schedule_info!(inse, fullname)

global.f90:2860
"""
function load_irri_schedule_info!(inse, fullname)
    open(fullname, "r") do file
        readline(file)
        readline(file)

        # irrigation method
        i = parse(Int, strip(readline(file)))
        if i==1
            inse[:symbol_parameters][:irrimethod] = MSprinkler
        elseif i==2
            inse[:symbol_parameters][:irrimethod] = MBasin
        elseif i==3
            inse[:symbol_parameters][:irrimethod] = MBorder
        elseif i==4
            inse[:symbol_parameters][:irrimethod] = MFurrow 
        else
            inse[:symbol_parameters][:irrimethod] = MDrip 
        end
        # fraction of soil surface wetted
        inse[:simulparam].IrriFwInSeason = parse(Int, strip(readline(file)))

        # irrigation mode and parameters
        i = parse(Int, strip(readline(file)))
        if i==0
            inse[:symbol_parameters][:irrimode] = :NoIrri
        elseif i==1
            inse[:symbol_parameters][:irrimode] = :Manual
        elseif i==2
            inse[:symbol_parameters][:irrimode] = :Generate
        else
            inse[:symbol_parameters][:irrimode] = :Inet
        end 

        # 1. Irrigation schedule
        if i == 1
            inse[:integer_parameters][:irri_first_daynr] = parse(Int, strip(readline(file)))
        end 


        # 2. Generate
        if inse[:symbol_parameters][:irrimode] == :Generate 
            i = parse(Int, strip(readline(file)))
            if i==1
                inse[:symbol_parameters][:timemode] = :FixInt
            elseif i==2
                inse[:symbol_parameters][:timemode] = :AllDepl
            elseif i==3
                inse[:symbol_parameters][:timemode] = :AllRAW
            elseif i==4
                inse[:symbol_parameters][:timemode] = :WaterBetweenBunds
            else
                inse[:symbol_parameters][:timemode] = :AllRAW
            end
            i = parse(Int, strip(readline(file)))
            if i==1
                inse[:symbol_parameters][:depthmode] = :ToFc
            else
                inse[:symbol_parameters][:depthmode] = :FixDepth
            end 
        end 

        # 3. Net irrigation requirement
        if inse[:symbol_parameters][:irrimode] == :Inet 
            inse[:simulparam].PercRAW = parse(Int, strip(readline(file)))
        end 
    end

    return nothing
end 

"""
    load_management!(inse, fullname)

global.f90:3350
"""
function load_management!(inse, fullname)
    management = inse[:management]
    crop = inse[:crop]
    simulation = inse[:simulation]
    open(fullname, "r") do file
        readline(file)
        readline(file)
        # mulches
        management.Mulch = parse(Int, strip(readline(file)))
        management.EffectMulchInS = parse(Int, strip(readline(file)))
        # soil fertility
        management.FertilityStress = parse(Int, strip(readline(file)))
        EffectStress_temp = GetSimulation_EffectStress()
        crop_stress_parameters_soil_fertility!(simulation.EffectStress, crop.StressResponse, management.FertilityStress)
        # soil bunds
        management.BundHeight = parse(Float64, strip(readline(file)))
        simulation.SurfaceStorageIni = 0
        simulation.ECStorageIni = 0
        # surface run-off
        i = parse(Int, strip(readline(file)))
        if i==1 
            management.RunoffOn = false # prevention of surface runoff
        else
            management.RunoffOn = true # surface runoff is not prevented
        end 
        management.CNcorrection = parse(Int, strip(readline(file)))
        # weed infestation
        management.WeedRC = parse(Int, strip(readline(file)))# relative cover of weeds (%)
        management.WeedDeltaRC = parse(Int, strip(readline(file)))
        # shape factor of the CC expansion
        # function in a weed infested field
        management.WeedShape = parse(Float64, strip(readline(file)))
        management.WeedAdj = parse(Int, strip(readline(file)))
        # multiple cuttings
        read(fhandle, *) i  # Consider multiple cuttings: True or False
        i = parse(Int, strip(readline(file)))
        if i==0 
            management.Cuttings.Considered = false
        else
            management.Cuttings.Considered = true 
        end 
        # Canopy cover (%) after cutting
        management.Cuttings.CCcut = parse(Int, strip(readline(file)))
        # Next line is expected to be present in the input file, however
        # A PARAMETER THAT IS NO LONGER USED since AquaCrop version 7.1
        readline(file)
        # Considered first day when generating cuttings
        # (1 = start of growth cycle)
        management.Cuttings.Day1 = parse(Int, strip(readline(file)))
        # Considered number owhen generating cuttings
        # (-9 = total growth cycle)
        management.Cuttings.NrDays = parse(Int, strip(readline(file)))
        i = parse(Int, strip(readline(file)))
        if i==1 
            management.Cuttings.Generate = true
        else
            management.Cuttings.Generate =false 
        end
        # Time criterion for generating cuttings
        i = parse(Int, strip(readline(file)))
        if i==0
            # not applicable
            management.Cuttings.Criterion = :NA
        elseif i==1
            # interval in days
            management.Cuttings.Criterion = :IntDay
        elseif i==2
            # interval in Growing Degree Days
            management.Cuttings.Criterion = :IntGDD
        elseif i==3
            # produced dry above ground biomass (ton/ha)
            management.Cuttings.Criterion = :DryB
        elseif i==4
            # produced dry yield (ton/ha)
            management.Cuttings.Criterion = :DryY
        elseif i==5
            # produced fresh yield (ton/ha)
            management.Cuttings.Criterion = :FreshY
        end 
        # final harvest at crop maturity:
        i = parse(Int, strip(readline(file)))
        if i==1 
            management.Cuttings.HarvestEnd = true
        else
            management.Cuttings.HarvestEnd = false
        end 
        # dayNr for Day 1 of list of cuttings
        # (-9 = Day1 is start growing cycle)
        management.Cuttings.FirstDayNr = parse(Int, strip(readline(file)))
    end
    return nothing
end 

"""
global.f90:6563
"""
function adjust_size_compartments!(inse, cropzx)
    compartments = inse[:compartments]
    simulparam = inse[:simulparam]

    # 1. Save intial soil water profile (required when initial soil
    # water profile is NOT reset at start simulation - see 7.)
    # 2. Actual total depth of compartments
    prevnrcomp = length(compartments)
    prevthickcomp = Float64[]
    prevvolprcomp = Float64[]
    totdepth = 0
    for compi in eachindex(compartments)
        push!(prevthickcomp, compartments[compi].Thickness)
        push!(prevvolprcomp, compartments[compi].Theta * 100)
        totdepth += compartments[compi].Thickness
    end

    # 3. Increase number of compartments (if less than 12)
    if (length(compartments) < max_no_compartments) 
        logi = true
        while logi
            if (cropzx-totdepthc)>simulparam.CompDefThick
                push!(compartments, CompartmentIndividual(Thickness=simulparam.CompDefThick)
            else
                push!(compartments, CompartmentIndividual(Thickness=cropzx-totdepthc)
            end 
            totdepth += compartments[end].Thickness
            if (length(compartments)==max_no_compartments | (totdepthc+0.00001)>=cropzx) 
                logi = false
            end
        end 
    end 

    # 4. Adjust size of compartments (if total depth of compartments < rooting depth)
    if (totdepthc+0.00001)<cropzx
        fadd = (cropzx/0.1 - 12)/78
        totdepthc = 0
        for i in eachindex(new_compartments)
            compartments[i].Thickness = 0.1 * (1 + i*fadd)
            totdepthc += compartments[i].Thickness
        end 
        if totdepthc<cropzx 
            logi = true
            while logi
                compartments[12].Thickness += 0.05
                totdepthc += 0.05
                if totdepthc>=cropzx 
                    logi = false
                end
            end 
        else
            while (totdepthc - 0.04999999)>=cropzx
                compartments[12].Thickness -= 0.05
                totdepthc = totdepthc - 0.05
            end 
        end 
    end 
    # 5. Adjust soil water content and theta initial
    adjust_theta_initial!()
    call AdjustThetaInitial(PrevNrComp, PrevThickComp, &
                            PrevVolPrComp, PrevECdSComp)
    return nothing
end #notend

"""
global.f90:5852
"""
function adjust_theta_initial!(prevnrcomp, prevthickcomp, prevvolprcomp, prevecdscomp)
    compartments
    soil_layers

    # 1. Actual total depth of compartments
    totdepthc = 0
    for compi in eachindex(compartments)
        totdepthc += compartments[compi].Thickness
    end 

    # 2. Stretch thickness of bottom soil layer if required
    totdepthl = 0
    for layeri in eachindex(soil_layers)
        totdepthl += soil_layers[layeri].Thickness
    end 
    if totdepthc>totdepthl 
        soil_layers[end].Thickness += (totdepthc - totdepthl)
    end 

    # 3. Assign a soil layer to each soil compartment
    designate_soillayer_to_compartments!(compartments, soil_layers)

    # 4. Adjust initial Soil Water Content of soil compartments
    if (GetSimulation_ResetIniSWC()) then
        if (GetSimulation_IniSWC_AtDepths()) then
            Compartment_temp = GetCompartment()
            call TranslateIniPointsToSWProfile(GetSimulation_IniSWC_NrLoc(), &
                                               GetSimulation_IniSWC_Loc(), &
                                               GetSimulation_IniSWC_VolProc(), &
                                               GetSimulation_IniSWC_SaltECe(), &
                                               GetNrCompartments(), &
                                               Compartment_temp)
            call SetCompartment(Compartment_temp)
        else
            Compartment_temp = GetCompartment()
            call TranslateIniLayersToSWProfile(GetSimulation_IniSWC_NrLoc(), &
                                               GetSimulation_IniSWC_Loc(), &
                                               GetSimulation_IniSWC_VolProc(), &
                                               GetSimulation_IniSWC_SaltECe(), &
                                               GetNrCompartments(), &
                                               Compartment_temp)
            call SetCompartment(Compartment_temp)
        end if
    else
        Compartment_temp = GetCompartment()
        call TranslateIniLayersToSWProfile(PrevNrComp, PrevThickComp, &
                                           PrevVolPrComp, PrevECdSComp, &
                                           GetNrCompartments(), &
                                           Compartment_temp)
        call SetCompartment(Compartment_temp)
    end if

    # 5. Adjust watercontent in soil layers and determine ThetaIni
    Total = 0._dp
    do layeri = 1, GetSoil_NrSoilLayers()
        call SetSoilLayer_WaterContent(layeri, 0._dp)
    end do
    do compi = 1, GetNrCompartments()
        call SetSimulation_ThetaIni_i(compi, GetCompartment_Theta(compi))
        call SetSoilLayer_WaterContent(GetCompartment_Layer(compi), &
                         GetSoilLayer_WaterContent(GetCompartment_Layer(compi)) &
                            + GetSimulation_ThetaIni_i(compi)*100._dp*10._dp &
                                * GetCompartment_Thickness(compi))
    end do
    do layeri = 1, GetSoil_NrSoilLayers()
        Total = Total + GetSoilLayer_WaterContent(layeri)
    end do
    call SetTotalWaterContent_BeginDay(Total)

    return nothing
end #notend

"""
    translate_inipoints_to_swprofile!(inse, nrloc, locdepth, locvolpr, locecds)

global.f90:6258
"""
function translate_inipoints_to_swprofile!(inse, nrloc, locdepth, locvolpr, locecds)
    soil_layers = inse[:soil_layers]
    compartments = inse[:compartments]
    simulparam = inse[:simulparam]

    totd = 0
    for compi in eachindex(compartments)
        compartments[compi].Theta = 0
        compartments[compi].WFactor = 0 # used for salt in (10*volsat*dz * ec)
        totd += compartments[compi].thickness
    end 
    compi = 0
    depthi = 0
    addcomp = true
    th2 = locvolpr[1]
    ec2 = locecds[1]
    d2 = 0
    loci = 0
    while (compi<nrcomp) | (compi==nrcomp & addcomp==false)
        # upper and lower boundaries location
        d1 = d2
        th1 = th2
        ec1 = ec2
        if loci<nrloc 
            loci += 1
            d2 = locdepth[loci]
            th2 = locvolpr[loci]
            ec2 = locecds[loci]
        else
            d2 = totd
        end 
        # transfer water to compartment (swc in mm) and salt in (10*volsat*dz * ec)
        theend = false
        dtopcomp = d1  # depthi is the bottom depth
        thbotcomp = th1
        ecbotcomp = ec1
        while !theend
            thtopcomp = thbotcomp
            ectopcomp = ecbotcomp
            if (addcomp) then
                compi = compi + 1
                depthi = depthi + compartments[compi].Thickness
            end 
            if depthi<d2 
                thbotcomp = th1 + (th2-th1)*(depthi-d1)/(d2-d1)
                compartments[compi].Theta = compartments[compi].Theta + 10*(depthi-dtopcomp)*(thtopcomp+thbotcomp)/2
                ecbotcomp = ec1 + (ec2-ec1)*(depthi-d1)/(d2-d1)
                compartments[compi].WFactor = compartments[compi].WFactor + 10*(depthi-dtopcomp)*soil_layers[compartments[compi].Layer].SAT*(ectopcomp+ecbotcomp)/2
                addcomp = true
                dtopcomp = depthi
                if compi==nrcomp 
                    theend = true
                end 
            else
                thbotcomp = th2
                ecbotcomp = ec2
                compartments[compi].Theta = compartments[compi].Theta + 10*(d2-dtopcomp)*(thtopcomp+thbotcomp)/2
                compartments[compi].WFactor = compartments[compi].WFactor + (10*(d2-dtopcomp)*soil_layers[compartments[compi].Layer].SAT*(ectopcomp+ecbotcomp)/2
                if abs(depthi - d2)<eps()
                    addcomp = true
                else
                    addcomp = false
                end 
                theend = true
            end 
        end 
    end 

    for compi in eachindex(compartments)
        # from mm(water) to theta and final check
        compartments[compi].Theta = compartments[compi].Theta/(1000*compartments[compi].Thickness)
        if (compartments[compi].Theta>soil_layers[compartments[compi].Layer].SAT/100 
            compartments[compi].Theta = soil_layers[compartments[compi].Layer].SAT/100
        end 
        if compartments[compi].Theta<0 
            compartments[compi].Theta=0
        end 
        # from (10*VolSat*dZ * EC) to ECe and distribution in cellls
        compartments[compi].WFactor = compartments[compi].WFactor/(10*compartments[compi].Thickness*soil_layers[compartments[compi].Layer].SAT)

        determine_salt_content!(compartments[compi], soil_layers, simulparam)
    end 

    return nothing
end 

"""
    determine_salt_content!(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual}, simulparam::RepSim)

global.f90:4258
"""
function determine_salt_content!(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual}, simulparam::RepSim)
    ece = compartment.WFactor
    totsalt = ece*equiv*soil_layers[compartment.Layer].SAT*10*compartment.Thickness
    celn = active_cells(compartment, soil_layers)
    sat = soil_layers[compartment.Layer].SAT/100  # m3/m3
    ul = soil_layers[compartment.Layer].UL # m3/m3   ! Upper limit of SC salt cel
    dx = soil_layers[compartment.Layer].Dx  # m3/m3  ! Size of salts cel (expect last one)
    mm1 = dx*1000*compartment.Thickness * (1-soil_layers[compartment.Layer].GravelVol/100) # g/l ! volume [mm]=[l/m2] of cells
    mmn = (sat-ul)*1000*compartment.Thickness * (1-soil_layers[compartment.Layer].GravelVol/100) # g/l ! volume [mm]=[l/m2] of last cell
    sumdf = 0
    for i in 1:soil_layers[compartment.Layer].SCP1
        compartment.Salt[i] = 0
        compartment.Depo[i] = 0
    end 
    for i in 1:celn
        sumdf += soil_layers[compartment.Layer].SaltMobility[i]
    end 
    for i in 1:celn
        compartment.Salt[i] = totsalt * soil_layers[compartment.Layer].SaltMobility[i]/sumdf
        mm = mm1
        if i==soil_layers[compartment.Layer].SCP1 
            mm = mmn
        end
        salt_solution_deposit!(compartment, simulparam, i, mm)
    end 

    return nothing
end 

"""
    celi = active_cells(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual})

globa.f90:4241
"""
function active_cells(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual})
    if compartment.Theta<=soil_layers[compartment.Layer].UL 
        celi = 1
        while (compartment.Theta>(soil_layers[compartment.Layer].Dx * celi)
            celi = celi + 1
        end 
    else
        celi = soil_layers[compartment.Layer].SCP1
    end 
    return celi
end 

"""
    salt_solution_deposit!(compartment::CompartmentIndividual, simulparam::RepSim, i, mm)

global.f90:2572
"""
function salt_solution_deposit!(compartment::CompartmentIndividual, simulparam::RepSim, i, mm) # mm = l/m2, SaltSol/Saltdepo = g/m2
    saltsolution = compartment.Salt[i]
    saltdeposit = compartment.Depo[i]

    saltsolution = saltsolution + saltdeposit
    if saltsolution>simulparam.SaltSolub*mm 
        saltdeposit = saltsolution - simulparam.SaltSolub * mm
        saltsolution = simulparam.SaltSolub * mm
    else
        saltdeposit = 0
    end 

    compartment.Salt[i] = saltsolution
    compartment.Depo[i] = saltdeposit

    return nothing
end 
