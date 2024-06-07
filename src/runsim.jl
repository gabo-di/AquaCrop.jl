"""
    run_simulation!(outputs, gvars, projectinput::Vector{ProjectInputType})

run.f90:7779
"""
function run_simulation!(outputs, gvars, projectinput::Vector{ProjectInputType})
    # maybe set outputfilesa run.f90:7786 OJO
    nrruns = gvars[:simulation].NrRuns 

    for nrrun in 1:nrruns
        initialize_run_part_1!(outputs, gvars, projectinput[nrrun])

    end

    return nothing
end #notend

"""
    initialize_run_part_1!(outputs, gvars, projectinput::ProjectInputType)

run.f90:6590
"""
function initialize_run_part_1!(outputs, gvars, projectinput::ProjectInputType)
    load_simulation_project!(gvars, projectinput)
    adjust_compartments!(gvars) #TODO check if neccesary
    # reset sumwabal and previoussum
    gvars[:sumwabal] = RepSum() 
    reset_previous_sum!(gvars)

    initialize_simulation_run_part1!(outputs, gvars, projectinput)

    return nothing
end #notend

"""
    initialize_simulation_run_part1!(outputs, gvars, projectinput)

run.f90:4754
"""
function initialize_simulation_run_part1!(outputs, gvars, projectinput::ProjectInputType)
    # Part1 (before reading the climate) of the initialization of a run
    # Initializes parameters and states

    # 1. Adjustments at start
    # 1.1 Adjust soil water and salt content if water table IN soil profile
    if check_for_watertable_in_profile(gvars[:compartments], gvars[:integer_parameters][:ziaqua]/100)
        adjust_for_watertable!(gvars)
    end 
    if !gvars[:simulparam].ConstGwt
        get_gwt_set!(gvars, projectinput.ParentDir, gvars[:simulation].FromDayNr)
    end 

    # 1.2 Check if FromDayNr simulation needs to be adjusted
    # from previous run if Keep initial SWC
    if (projectinput.SWCIni_Filename=="KeepSWC") & (gvars[:integer_parameters][:nextsim_from_daynr] != undef_int) 
        # assign the adjusted DayNr defined in previous run
        if gvars[:integer_parameters][:nextsim_from_daynr] <= gvars[:crop].Day1
            gvars[:simulation].FromDayNr = gvars[:integer_parameters][:nextsim_from_daynr]
        end 
    end 
    setparameter!(gvars[:integer_parameters], :nextsim_from_daynr, undef_int)

    # 2. initial settings for Crop
    gvars[:crop].pActStom = gvars[:crop].pdef
    gvars[:crop].pSenAct = gvars[:crop].pSenescence
    gvars[:crop].pLeafAct = gvars[:crop].pLeafDefUL
    setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true)
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].EvapWCsurf = 0
    gvars[:simulation].EvapZ = EvapZmin/100
    gvars[:simulation].SumEToStress = 0
    # for calculation Maximum Biomass
    # unlimited soil fertility
    setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0)
    # days of anaerobic conditions in
    # global root zone
    gvars[:simulation].DayAnaero = 0
    

    # germination
    if (gvars[:crop].Planting == :Seed) & (gvars[:simulation].FromDayNr<=gvars[:crop].Day1)
        gvars[:simulation].Germinate = false
    else
        gvars[:simulation].Germinate = true 
        gvars[:simulation].ProtectedSeedling = false
    end
    # delayed germination
    gvars[:simulation].DelayedDays = 0

    # 3. create temperature file covering crop cycle
    if gvars[:string_parameters][:temperature_file] != "(None)"
        if gvars[:simulation].ToDayNr < gvars[:crop].DayN
            temperature_file_covering_crop_period!(outputs, gvars, gvars[:crop].Day1, gvars[:simulation].ToDayNr)
        else
            temperature_file_covering_crop_period!(outputs, gvars, gvars[:crop].Day1, gvars[:crop].DayN)
        end
    end

    # 4. CO2 concentration during cropping period
    dnr1 = gvars[:simulation].FromDayNr
    if gvars[:crop].Day1 > dnr1
        dnr1 = gvars[:crop].Day1
    end
    dnr2 = gvars[:simulation].ToDayNr
    if gvars[:crop].DayN > dnr2
        dnr2 = gvars[:crop].DayN
    end
    setparameter!(gvars[:float_parameters], :co2i, 
                  co2_for_simulation_period(gvars[:string_parameters][:CO2_file], dnr1, dnr2)
                  )

    # 5. seasonals stress coefficients
    bool_temp = ((gvars[:crop].ECemin != undef_int) & (gvars[:crop].ECemax != undef_int) & (gvars[:crop].ECemin<gvars[:crop].ECemax))
    gvars[:simulation].SalinityConsidered = bool_temp
    if gvars[:symbol_parameters][:irrimode] == :Inet
        gvars[:simulation].SalinityConsidered = false
    end
    gvars[:stresstot].NrD = undef_int
    gvars[:stresstot].Salt = 0
    gvars[:stresstot].Temp = 0
    gvars[:stresstot].Exp = 0
    gvars[:stresstot].Sto = 0
    gvars[:stresstot].Weed = 0

    # 6. Soil fertility stress
    # Coefficients for soil fertility - biomass relationship
    # AND for Soil salinity - CCx/KsSto relationship
    relationships_for_fertility_and_salt_stress!(gvars)

    # No soil fertility stress
    if gvars[:management].FertilityStress <= 0 
        gvars[:management].FertilityStress = 0
    end

    # Reset soil fertility parameters to selected value in management
    EffectStress_temp = GetSimulation_EffectStress()
    call CropStressParametersSoilFertility(GetCrop_StressResponse(), &
            GetManagement_FertilityStress(), EffectStress_temp)
    call SetSimulation_EffectStress(EffectStress_temp)
    FertStress = GetManagement_FertilityStress()
    RedCGC_temp = GetSimulation_EffectStress_RedCGC()
    RedCCX_temp = GetSimulation_EffectStress_RedCCX()
    Crop_DaysToFullCanopySF_temp = GetCrop_DaysToFullCanopySF()
    call TimeToMaxCanopySF(GetCrop_CCo(), GetCrop_CGC(), GetCrop_CCx(), &
           GetCrop_DaysToGermination(), GetCrop_DaysToFullCanopy(), &
           GetCrop_DaysToSenescence(), GetCrop_DaysToFlowering(), &
           GetCrop_LengthFlowering(), GetCrop_DeterminancyLinked(), &
           Crop_DaysToFullCanopySF_temp, RedCGC_temp, RedCCX_temp, FertStress)
    call SetCrop_DaysToFullCanopySF(Crop_DaysToFullCanopySF_temp)
    call SetManagement_FertilityStress(FertStress)
    call SetSimulation_EffectStress_RedCGC(RedCGC_temp)
    call SetSimulation_EffectStress_RedCCX(RedCCX_temp)
    call SetPreviousStressLevel(int(GetManagement_FertilityStress(),kind=int32))
    call SetStressSFadjNEW(int(GetManagement_FertilityStress(),kind=int32))
    # soil fertility and GDDays
    if (GetCrop_ModeCycle() == modeCycle_GDDays) then
        if (GetManagement_FertilityStress() /= 0_int8) then
            call SetCrop_GDDaysToFullCanopySF(GrowingDegreeDays(&
                  GetCrop_DaysToFullCanopySF(), GetCrop_Day1(), &
                  GetCrop_Tbase(), GetCrop_Tupper(), GetSimulParam_Tmin(),&
                  GetSimulParam_Tmax()))
        else
            call SetCrop_GDDaysToFullCanopySF(GetCrop_GDDaysToFullCanopy())
        end 
    end

    # Maximum sum Kc (for reduction WP in season if soil fertility stress)
    call SetSumKcTop(SeasonalSumOfKcPot(GetCrop_DaysToCCini(), &
            GetCrop_GDDaysToCCini(), GetCrop_DaysToGermination(), &
            GetCrop_DaysToFullCanopy(), GetCrop_DaysToSenescence(), &
            GetCrop_DaysToHarvest(), GetCrop_GDDaysToGermination(), &
            GetCrop_GDDaysToFullCanopy(), GetCrop_GDDaysToSenescence(), &
            GetCrop_GDDaysToHarvest(), GetCrop_CCo(), GetCrop_CCx(), &
            GetCrop_CGC(), GetCrop_GDDCGC(), GetCrop_CDC(), GetCrop_GDDCDC(), &
            GetCrop_KcTop(), GetCrop_KcDecline(), real(GetCrop_CCEffectEvapLate(),kind=dp), &
            GetCrop_Tbase(), GetCrop_Tupper(), GetSimulParam_Tmin(), &
            GetSimulParam_Tmax(), GetCrop_GDtranspLow(), GetCO2i(), &
            GetCrop_ModeCycle()))
    call SetSumKcTopStress( GetSumKcTop() * GetFracBiomassPotSF())
    call SetSumKci(0._dp)

    # 7. weed infestation and self-thinning of herbaceous perennial forage crops
    # CC expansion due to weed infestation and/or CC decrease as a result of
    # self-thinning
    # 7.1 initialize
    call SetSimulation_RCadj(GetManagement_WeedRC())
    Cweed = 0_int8
    if (GetCrop_subkind() == subkind_Forage) then
        fi = MultiplierCCxSelfThinning(int(GetSimulation_YearSeason(),kind=int32), &
              int(GetCrop_YearCCx(),kind=int32), GetCrop_CCxRoot())
    else
        fi = 1._dp
    end 
    # 7.2 fweed
    if (GetManagement_WeedRC() > 0_int8) then
        call SetfWeedNoS(CCmultiplierWeed(GetManagement_WeedRC(), &
              GetCrop_CCx(), GetManagement_WeedShape()))
        call SetCCxCropWeedsNoSFstress( roundc(((100._dp*GetCrop_CCx() &
                  * GetfWeedNoS()) + 0.49),mold=1)/100._dp) # reference for plot with weed
        if (GetManagement_FertilityStress() > 0_int8) then
            fWeed = 1._dp
            if ((fi > 0._dp) .and. (GetCrop_subkind() == subkind_Forage)) then
                Cweed = 1_int8
                if (fi > 0.005_dp) then
                    # calculate the adjusted weed cover
                    call SetSimulation_RCadj(roundc(GetManagement_WeedRC() &
                         + Cweed*(1._dp-fi)*GetCrop_CCx()*&
                           (1._dp-GetSimulation_EffectStress_RedCCX()/100._dp)*&
                           GetManagement_WeedAdj()/100._dp, mold=1_int8))
                    if (GetSimulation_RCadj() < (100._dp * (1._dp- fi/(fi + (1._dp-fi)*&
                          (GetManagement_WeedAdj()/100._dp))))) then
                        call SetSimulation_RCadj(roundc(100._dp * (1._dp- fi/(fi + &
                              (1._dp-fi)*(GetManagement_WeedAdj()/100._dp))),mold=1_int8))
                    end
                    if (GetSimulation_RCadj() > 100_int8) then
                        call SetSimulation_RCadj(98_int8)
                    end 
                else
                    call SetSimulation_RCadj(100_int8)
                end 
            end 
        else
            if (GetCrop_subkind() == subkind_Forage) then
                RCadj_temp = GetSimulation_RCadj()
                fweed = CCmultiplierWeedAdjusted(GetManagement_WeedRC(), &
                          GetCrop_CCx(), GetManagement_WeedShape(), &
                          fi, GetSimulation_YearSeason(), &
                          GetManagement_WeedAdj(), &
                          RCadj_temp)
                call SetSimulation_RCadj(RCadj_temp)
            else
                fWeed = GetfWeedNoS()
            end 
        end 
    else
        call SetfWeedNoS(1._dp)
        fWeed = 1._dp
        call SetCCxCropWeedsNoSFstress(GetCrop_CCx())
    end
    # 7.3 CC total due to weed infestation
    call SetCCxTotal( fWeed * GetCrop_CCx() * (fi+Cweed*(1._dp-fi)*&
           GetManagement_WeedAdj()/100._dp))
    call SetCDCTotal( GetCrop_CDC() * (fWeed*GetCrop_CCx()*&
           (fi+Cweed*(1._dp-fi)*GetManagement_WeedAdj()/100._dp) + 2.29_dp)/ &
           (GetCrop_CCx()*(fi+Cweed*(1-fi)*GetManagement_WeedAdj()/100._dp) &
            + 2.29_dp))
    call SetGDDCDCTotal(GetCrop_GDDCDC() * (fWeed*GetCrop_CCx()*&
           (fi+Cweed*(1._dp-fi)*GetManagement_WeedAdj()/100._dp) + 2.29_dp)/ &
           (GetCrop_CCx()*(fi+Cweed*(1-fi)*GetManagement_WeedAdj()/100._dp) &
            + 2.29_dp))
    if (GetCrop_subkind() == subkind_Forage) then
        fi = MultiplierCCoSelfThinning(int(GetSimulation_YearSeason(),kind=int32), &
               int(GetCrop_YearCCx(),kind=int32), GetCrop_CCxRoot())
    else
        fi = 1._dp
    end 
    call SetCCoTotal(fWeed * GetCrop_CCo() * (fi+Cweed*(1._dp-fi)*&
            GetManagement_WeedAdj()/100._dp))

    # 8. prepare output files
    # Not applicable

    # 9. first day
    call SetStartMode(.true.)
    bool_temp = (.not. GetSimulation_ResetIniSWC())
    call SetPreDay(bool_temp)
    call SetDayNri(GetSimulation_FromDayNr())
    call DetermineDate(GetSimulation_FromDayNr(), Day1, Month1, Year1) # start simulation run
    call SetNoYear((Year1 == 1901));  # for output file
end #notend

"""
    check_for_watertable_in_profile(profilecomp::Vector{CompartmentIndividual}, depthgwtmeter)

global.f90:1540
"""
function check_for_watertable_in_profile(profilecomp::Vector{CompartmentIndividual}, depthgwtmeter)
    watertableinprofile = false
    ztot = 0
    compi = 0

    if depthgwtmeter>=eps() 
        # groundwater table is present
        while (!watertableinprofile) & (compi<length(profilecomp))
            compi = compi + 1
            ztot = ztot + profilecomp[compi].Thickness
            zi = ztot - profilecomp[compi].Thickness/2
            if zi>=depthgwtmeter 
                watertableinprofile = true
            end 
        end 
    end 

    return watertableinprofile
end 

"""
    adjust_for_watertable!(gvars)

run.f90:3423
"""
function adjust_for_watertable!(gvars)
    compartments = gvars[:compartments]
    ziaqua = gvars[:integer_parameters][:ziaqua]
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]

    ztot = 0
    for compi in eachindex(compartments)
        ztot += compartments[compi].Thickness
        zi = ztot - compartments[compi].Thickness/2
        if zi>=ziaqua/100
            # compartment at or below groundwater table
            compartments[compi].Theta = soil_layers[compartments[compi].Layer].SAT/100
            determine_salt_content!(compartments[compi], soil_layers, simulparam)
        end 
    end 

    return nothing
end 

"""
    get_gwt_set!(gvars, parentdir, daynrin)

run.f90:3526
"""
function get_gwt_set!(gvars, parentdir, daynrin)
    gwt = gvars[:gwtable]
    simulation = gvars[:simulation]
    # FileNameFull
    if gvars[:string_parameters][:groundwater_file] != "(None)"
        filenamefull = gvars[:string_parameters][:groundwater_file]
    else
        filenamefull = parentdir * "GroundWater.AqC"
    end 

    # Get DayNr1Gwt
    open(filenamefull, "r") do file
        readline(file)
        readline(file)
        readline(file)
        dayi = parse(Int,split(readline(file))[1])
        monthi = parse(Int,split(readline(file))[1])
        yeari = parse(Int,split(readline(file))[1])
        daynr1gwt = determine_day_nr(dayi, monthi, yeari)

        # Read first observation
        for i in 1:3
            readline(file)
        end 
        splitedline = split(readline(file))
        daydouble = parse(Float64, popfirst!(splitedline))
        zm = parse(Float64, popfirst!(splitedline))
        gwt.EC2 = parse(Float64, popfirst!(splitedline))
        gwt.DNr2 = daynr1gwt + round(Int, daydouble) - 1
        gwt.Z2 = round(Int, zm * 100) 
        if eof(file)
            theend = true
        else
            theend = false
        end

        # Read next observations
        if theend 
            # only one observation
            gwt.DNr1 = simulation.FromDayNr 
            gwt.Z1 = gwt.Z2
            gwt.EC1 = gwt.EC2
            gwt.DNr2 = simulation.ToDayNr 
        else
            # defined year
            if daynr1gwt>365 
                if daynrin<gwt.DNr2 
                    # DayNrIN before 1st observation
                    gwt.DNr1 = simulation.FromDayNr
                    gwt.Z1 = Gwt.Z2
                    gwt.EC1 = gwt.EC2
                else
                    # DayNrIN after or at 1st observation
                    loop1 = true
                    while loop1
                        gwt.DNr1 = gwt.DNr2
                        gwt.Z1 = gwt.Z2
                        gwt.EC1 = gwt.EC2
                        splitedline = split(readline(file))
                        daydouble = parse(Float64, popfirst!(splitedline))
                        zm = parse(Float64, popfirst!(splitedline))
                        gwt.EC2 = parse(Float64, popfirst!(splitedline))
                        gwt.DNr2 = daynr1gwt + round(Int, daydouble) - 1
                        gwt.Z2 = round(Int, zm * 100)
                        if daynrin<gwt.DNr2 
                            theend = true
                        end 
                        if theend | eof(file)
                            loop1 = false
                        end
                    end
                    if !theend 
                        # DayNrIN after last observation
                        gwt.DNr1 = gwt.DNr2
                        gwt.Z1 = gwt.Z2
                        gwt.EC1 = gwt.EC2
                        gwt.DNr2 = simulation.ToDayNr
                    end 
                end 
            end # defined year

            # undefined year
            if daynr1gwt<=365 
                dayi, monthi, yearact = determine_date(daynrin)
                if yearACT != 1901 
                    # make 1st observation defined
                    dayi, monthi, yeari = determine_date(gwt.DNr2)
                    gwt.DNr2 = determine_day_nr(dayi, monthi, yearact)
                end 
                if daynrin<gwt.DNr2 
                    # DayNrIN before 1st observation
                    loop2 = true
                    while loop2
                        splitedline = split(readline(file))
                        daydouble = parse(Float64, popfirst!(splitedline))
                        zm = parse(Float64, popfirst!(splitedline))
                        gwt.EC1 = parse(Float64, popfirst!(splitedline))
                        gwt.DNr1 = daynr1gwt + round(Int, daydouble) - 1
                        dayi, monthi, yeari = determine_date(gwt.DNr1)
                        gwt.DNr1 = determine_day_nr(dayi, monthi, yearact)
                        gwt.Z1 = round(Int, zm * 100) 
                        if eof(file)
                            loop2 = false
                        end
                    end 
                    gwt.DNr1 = gwt.DNr1 - 365
                else
                    # save 1st observation
                    dnrini = gwt.DNr2
                    zini = gwt.Z2
                    ecini = gwt.EC2
                    # DayNrIN after or at 1st observation
                    loop3 = true
                    while loop3
                        gwt.DNr1 = gwt.DNr2
                        gwt.Z1 = gwt.Z2
                        gwt.EC1 = gwt.EC2
                        splitedline = split(readline(file))
                        daydouble = parse(Float64, popfirst!(splitedline))
                        zm = parse(Float64, popfirst!(splitedline))
                        gwt.EC2 = parse(Float64, popfirst!(splitedline))
                        gwt.DNr2 = daynr1gwt + round(Int, daydouble) - 1
                        if yearACT != 1901 
                            # make observation defined
                            dayi, monthi, yeari = determine_date(gwt.DNr2)
                            gwt.DNr2 = determine_day_nr(dayi, nthi, yearact)
                        end 
                        gwt.Z2 = round(Int, zm * 100)
                        if daynrin<gwt.DNr2 
                            theend = true
                        end 
                        if theend | eof(file) 
                            loop3 = false
                        end
                    end
                    if !TheEnd 
                        # DayNrIN after last observation
                        gwt.DNr1 = gwt.DNr2
                        gwt.Z1 = gwt.Z2
                        gwt.EC1 = gwt.EC2
                        gwt.DNr2 = dnrini + 365
                        gwt.Z2 = zini
                        gwt.EC2 = ecini
                    end 
                end 
            end # undefined year
        end # more than 1 observation
    end

    return nothing
end 

"""
    temperature_file_covering_crop_period!(outputs, gvars, crop_firstday, crop_lastday)

tempprocessing.f90:1789
"""
function temperature_file_covering_crop_period!(outputs, gvars, crop_firstday, crop_lastday)
    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    if gvars[:bool_parameters][:temperature_file_exists]
        # open file and find first day of cropping period
        if gvars[:temperature_record].DataType == :Daily
            # Tmin and Tmax arrays contain the TemperatureFilefull data
            i = crop_firstday - gvars[:temperature_record].FromDayNr + 1
            tlow = gvars[:array_parameters].Tmin[i]
            thigh = gvars[:array_parameters].Tmax[i]
        
        elseif gvars[:temperature_record].DataType == :Decadely
            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, crop_firstday,
                                            gvars[:string_parameters][:temperature_file],
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != crop_firstday
                i += 1
            end
            tlow = gvars[:array_parameters].Tmin[i]
            thigh = gvars[:array_parameters].Tmax[i]

        elseif gvars[:temperature_record].DataType == :Monthly
            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, crop_firstday,
                                            gvars[:string_parameters][:temperature_file],
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != crop_firstday
                i += 1
            end
            tlow = gvars[:array_parameters].Tmin[i]
            thigh = gvars[:array_parameters].Tmax[i]
        end

        # we are not creating the TCrop.SIM for now but we use outputs variable
        add_output_in_tcropsim!(outputs, tlow, thigh)

        # next days of simulation period
        for runningday in (crop_firstday+1):crop_lastday
            if gvars[:temperature_record].DataType == :Daily
                i += 1
                if i==length(gvars[:array_parameters].Tmin) 
                    i = 1
                end 
                tlow = gvars[:array_parameters].Tmin[i]
                thigh = gvars[:array_parameters].Tmax[i]

            elseif gvars[:temperature_record].DataType == :Decadely
                if runningday>tmin_dataset[31].DayNr
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    gvars[:string_parameters][:temperature_file],
                                                    gvars[:temperature_record])
                end
                i = 1
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end 
                tlow = gvars[:array_parameters].Tmin[i]
                thigh = gvars[:array_parameters].Tmax[i]

            elseif gvars[:temperature_record].DataType == :Monthly
                if runningday>tmin_dataset[31].DayNr
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    gvars[:string_parameters][:temperature_file],
                                                    gvars[:temperature_record])
                end 
                i =1 
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end
                tlow = gvars[:array_parameters].Tmin[i]
                thigh = gvars[:array_parameters].Tmax[i]
            end

            add_output_in_tcropsim!(outputs, tlow, thigh)
        end 

    # we do not write anything yet, OJO
    # else
    #     write(*,*) 'ERROR: no valid air temperature file'
    #     return
        # fatal error if no air temperature file
    end

    return nothing
end 

"""
    co2forsimulationperiod = co2_for_simulation_period(co2_file, fromdaynr, todaynr)

global.f90:3114
"""
function co2_for_simulation_period(co2_file, fromdaynr, todaynr)
    dayi, monthi, fromyi = determine_date(fromdaynr)
    dayi, monthi, toyi = determine_date(todaynr)

    if (fromyi == 1901) | (toyi == 1901) 
        co2forsimulationperiod = CO2Ref 
    else
        open(co2_file, "r") do file
            readline(file)
            readline(file)
            readline(file)
            # from year
            splitedline = split(readline(file))
            yearb = parse(Float64, popfirst!(splitedline))
            co2b = parse(Float64, popfirst!(splitedline))
            if round(Int, yearb) >= fromyi
                co2from = co2b
                yeara = yearb
                co2a = co2b
            else
                loop_1 = true
                while loop_1
                    yeara = yearb
                    co2a = co2b
                    splitedline = split(readline(file))
                    yearb = parse(Float64, popfirst!(splitedline))
                    co2b = parse(Float64, popfirst!(splitedline))
                    if (round(Int, yearb) >= fromyi) | eof(file)
                        loop_1 == false
                    end
                end 
                if fromyi > round(Int, yearb) 
                    co2from = co2b
                else
                    co2from = co2a + (co2b-co2a)*(fromyi-round(Int, yeara))/(round(Int, yearb)-round(Int, yeara))
                end 
            end 
            # to year
            co2to = co2from
            if (toyi > fromyi) & (toyi > round(Int, yeara)) 
                if round(Int, yearb) >= toyi 
                    co2to = co2a + (co2b-co2a)*(toyi-round(Int, yeara))/(round(Int, yearb)-round(Int, yeara))
                elseif eof(file)
                    loop_2 = true
                    while loop_2
                        yeara = yearb
                        co2a = co2b
                        splitedline = split(readline(file))
                        yearb = parse(Float64, popfirst!(splitedline))
                        co2b = parse(Float64, popfirst!(splitedline))
                        if (round(Int, yearb) >= toyi) | eof(file)
                            loop_2 = false
                        end
                    end 
                    if toyi > round(Int, yearb) 
                        co2to = co2b
                    else
                        co2to = co2a + (co2b-co2a)*(toyi-round(Int, yeara))/(round(Int, yearb)-round(Int, yeara))
                    end 
                end 
            end 
        end
        co2forsimulationperiod = (co2from+co2to)/2
    end 

    return co2forsimulationperiod
end 

"""
    relationships_for_fertility_and_salt_stress!(outputs, gvars)

run.f90:3954
"""
function relationships_for_fertility_and_salt_stress!(outputs, gvars)
    crop = gvars[:crop]

    # 1. Soil fertility
    setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 1)

    # 1.a Soil fertility (Coeffb0,Coeffb1,Coeffb2 : Biomass-Soil Fertility stress)
    if crop.StressResponse.Calibrated
        stress_biomass_relationship!(outputs)
    if (GetCrop_StressResponse_Calibrated()) then
        call StressBiomassRelationship(GetCrop_DaysToCCini(), GetCrop_GDDaysToCCini(), &
                                  GetCrop_DaysToGermination(), &
                                  GetCrop_DaysToFullCanopy(), &
                                  GetCrop_DaysToSenescence(), &
                                  GetCrop_DaysToHarvest(), &
                                  GetCrop_DaysToFlowering(), &
                                  GetCrop_LengthFlowering(), &
                                  GetCrop_GDDaysToGermination(), &
                                  GetCrop_GDDaysToFullCanopy(), &
                                  GetCrop_GDDaysToSenescence(), &
                                  GetCrop_GDDaysToHarvest(), &
                                  GetCrop_WPy(), GetCrop_HI(), &
                                  GetCrop_CCo(), GetCrop_CCx(), &
                                  GetCrop_CGC(), GetCrop_GDDCGC(), &
                                  GetCrop_CDC(), GetCrop_GDDCDC(), &
                                  GetCrop_KcTop(), GetCrop_KcDecline(), &
                                  real(GetCrop_CCEffectEvapLate(), kind= dp), &
                                  GetCrop_Tbase(), &
                                  GetCrop_Tupper(), GetSimulParam_Tmin(), &
                                  GetSimulParam_Tmax(), GetCrop_GDtranspLow(), &
                                  GetCrop_WP(), GetCrop_dHIdt(), GetCO2i(), &
                                  GetCrop_Day1(), GetCrop_DeterminancyLinked(), &
                                  GetCrop_StressResponse(),GetCrop_subkind(), &
                                  GetCrop_ModeCycle(), Coeffb0_temp, Coeffb1_temp, &
                                  Coeffb2_temp, X10, X20, X30, X40, X50, X60, X70)
        call SetCoeffb0(Coeffb0_temp)
        call SetCoeffb1(Coeffb1_temp)
        call SetCoeffb2(Coeffb2_temp)
    else
        call SetCoeffb0(real(undef_int, kind=dp))
        call SetCoeffb1(real(undef_int, kind=dp))
        call SetCoeffb2(real(undef_int, kind=dp))
    end 

    # 1.b Soil fertility : FracBiomassPotSF
    if ((abs(GetManagement_FertilityStress()) > epsilon(0._dp)) .and. &
                                     GetCrop_StressResponse_Calibrated()) then
        BioLow = 100_int8
        StrLow = 0._dp
        loop: do
            BioTop = BioLow
            StrTop = StrLow
            BioLow = BioLow - 1_int8
            StrLow = GetCoeffb0() + GetCoeffb1()*BioLow + GetCoeffb2()*BioLow*BioLow
            if (((StrLow >= GetManagement_FertilityStress()) &
                         .or. (BioLow <= 0) .or. (StrLow >= 99.99_dp))) exit loop
        end do loop
        if (StrLow >= 99.99_dp) then
            StrLow = 100._dp
        end if
        if (abs(StrLow-StrTop) < 0.001_dp) then
            call SetFracBiomassPotSF(real(BioTop, kind=dp))
        else
            call SetFracBiomassPotSF(real(BioTop, kind=dp) - (GetManagement_FertilityStress() &
                                                    - StrTop)/(StrLow-StrTop))
        end if
    call SetFracBiomassPotSF(GetFracBiomassPotSF()/100._dp)
    end if

    # 2. soil salinity (Coeffb0Salt,Coeffb1Salt,Coeffb2Salt : CCx/KsSto - Salt stress)
    if (GetSimulation_SalinityConsidered() .eqv. .true.) then
        call CCxSaltStressRelationship(GetCrop_DaysToCCini(), &
                                  GetCrop_GDDaysToCCini(), &
                                  GetCrop_DaysToGermination(), &
                                  GetCrop_DaysToFullCanopy(), &
                                  GetCrop_DaysToSenescence(), &
                                  GetCrop_DaysToHarvest(), &
                                  GetCrop_DaysToFlowering(), &
                                  GetCrop_LengthFlowering(), &
                                  GetCrop_GDDaysToFlowering(), &
                                  GetCrop_GDDLengthFlowering(), &
                                  GetCrop_GDDaysToGermination(), &
                                  GetCrop_GDDaysToFullCanopy(), &
                                  GetCrop_GDDaysToSenescence(), &
                                  GetCrop_GDDaysToHarvest(), &
                                  GetCrop_WPy(), GetCrop_HI(), &
                                  GetCrop_CCo(), GetCrop_CCx(), &
                                  GetCrop_CGC(), GetCrop_GDDCGC(), &
                                  GetCrop_CDC(), GetCrop_GDDCDC(), &
                                  GetCrop_KcTop(), GetCrop_KcDecline(), &
                                  real(GetCrop_CCEffectEvapLate(), kind=dp),  &
                                  GetCrop_Tbase(), GetCrop_Tupper(), &
                                  GetSimulParam_Tmin(), GetSimulParam_Tmax(), &
                                  GetCrop_GDtranspLow(), GetCrop_WP(), &
                                  GetCrop_dHIdt(), GetCO2i(), GetCrop_Day1(), &
                                  GetCrop_DeterminancyLinked(), &
                                  GetCrop_subkind(), GetCrop_ModeCycle(), &
                                  GetCrop_CCsaltDistortion(),Coeffb0Salt_temp, &
                                  Coeffb1Salt_temp, Coeffb2Salt_temp, X10, X20, X30, &
                                  X40, X50, X60, X70, X80, X90)
        call SetCoeffb0Salt(Coeffb0Salt_temp)
        call SetCoeffb1Salt(Coeffb1Salt_temp)
        call SetCoeffb2Salt(Coeffb2Salt_temp)
    else
        call SetCoeffb0Salt(real(undef_int, kind=dp))
        call SetCoeffb1Salt(real(undef_int, kind=dp))
        call SetCoeffb2Salt(real(undef_int, kind=dp))
    end 
end #notend

"""

tempprocessing.f90:3067
"""
function stress_biomass_relationship!(outputs, gvars, co2given)
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]

    thedaystoccini = crop.DaysToCCini
    thegddaystoccini = crop.GDDaysToCCini
    l0 = crop.DaysToGermination
    l12 = crop.DaysToFullCanopy
    l123 = crop.DaysToSenescence
    l1234 = crop.DaysToHarvest
    lflor = crop.DaysToFlowering
    lengthflor = crop.LengthFlowering
    gddl0 = crop.GDDaysToGermination
    gddl12 = crop.GDDaysToFullCanopy
    gddl123 = crop.GDDaysToSenescence
    gddl1234 = crop.GDDaysToHarvest
    wpyield = crop.WPy
    refhi = crop.HI
    cco = crop.CCo
    ccx = crop.CCx
    cgc= crop.CGC
    gddcgc = crop.GDDCGC
    cdc = crop.CDC
    gddcdc = crop.GDDCDC
    kctop = crop.KcTop
    kcdeclageing = crop.KcDecline
    cceffectprocent = crop.CCEffectEvapLate
    tbase = crop.Tbase
    tupper = crop.Tupper
    tdaymin = simulparam.Tmin
    tdaymax = simulparam.Tmax
    gdtransplow = crop.GDtranspLow
    wpveg = crop.WP
    ratedhidt = crop.dHIdt
    cropdnr1 = crop.Day1
    cropdeterm = crop.DeterminancyLinked
    cropsresp = crop.StressResponse
    thecroptype = crop.subkind
    themodecycle = crop.ModeCycle
    real(dp), intent(inout) :: b0
    real(dp), intent(inout) :: b1
    real(dp), intent(inout) :: b2
    real(dp), intent(inout) :: BM10
    real(dp), intent(inout) :: BM20
    real(dp), intent(inout) :: BM30
    real(dp), intent(inout) :: BM40
    real(dp), intent(inout) :: BM50
    real(dp), intent(inout) :: BM60
    real(dp), intent(inout) :: BM70


    stress_matrix = StressIndexes[StressIndexes() for _ in 1:8]

    # 1. initialize
    # to calculate SumKcTop (no stress)
    l12sf = l12
    # to calculate SumKcTop (no stress)
    gddl12sf = gddl12
    # Maximum sum Kc (no stress)
    simulation.DelayedDays = 0 #note that we need to do this before calling seasonal_sum_of_kcpot
    sumkctop = seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini,
        l0, l12, l123, l1234, gddl0, gddl12, gddl123, gddl1234,
        cco, ccx, cgc, gddcgc, cdc, gddcdc, kctop, kcdeclageing,
        cceffectprocent, tbase, tupper, tdaymin, tdaymax, 
        gdtransplow, co2given, themodecycle, simulation, simulparam)

    # Get PercentLagPhase (for estimate WPi during yield formation)
    if (thecroptype == :Tuber) | (thecroptype == :Grain) 
        # DaysToFlowering corresponds with Tuberformation
        daysyieldformation = round(Int, refhi/ratedhidt)
        if cropdeterm 
            higc = harvest_index_growth_coefficient(refhi, ratedhidt)
            tswitch, higclinear = get_days_witch_to_linear(refhi, ratedhidt, higc)
        else
            tswitch = round(Int, daysyieldformation/3)
        end 
    end 

    # 2. Biomass production for various stress levels
    for si in 1:8
        # various stress levels
        # stress effect
        sipr = 10*(si-1)
        stress_matrix[si].StressProc = sipr
        stress_response = crop_stress_parameters_soil_fertility(cropsresp, sipr)
        # adjusted length of Max canopy cover
        ratdgdd = 1
        if (stress_response.RedCCX == 0) & (stress_response.RedCGC == 0)
            l12sf = l12
            gddl12sf = gddl12
        else
            l12sf, stress_response.RedCGC, stress_response.RedCCX, sipr = time_to_max_canopy_sf(
                                    cco, cgc, ccx, l0, l12, l123, lflor,
                                    lengthflor, cropdeterm,
                                    l12sf, stress_response.RedCGC,
                                    stress_response.RedCCX, sipr)
            if themodecycle == :GDDays 
                tdaymin_temp = tdaymin
                tdaymax_temp = tdaymax
                gddl12sf = growing_degree_days(l12sf, cropdnr1, tbase, tupper, gvars, tdaymin_temp, tdaymax_temp)
            end 
            if (themodecycle == :GDDays) & (gddl12sf < gddl123) 
                ratdgdd = (l123-l12sf)*1/(gddl123-gddl12sf)
            end 
        end 
        # biomass production
        bnor = bnormalized(thedaystoccini, thegddaystoccini,
                l0, l12, l12sf, l123, l1234, lflor,
                gddl0, gddl12, gddl12sf, gddl123, gddl1234, wpyield, 
                daysyieldformation, tswitch, cco, ccx, cgc, gddcgc, cdc,
                gddcdc, kctop, kcdeclageing, cceffectprocent, wpveg, co2given,
                tbase, tupper, tdaymin, tdaymax, gdtransplow, ratdgdd,
                sumkctop, sipr, stress_response.RedCGC, stress_response.RedCCX,
                stress_response.RedWP, stress_response.RedKsSto, 0, 0,
                stress_response.CDecline, -0.01, themodecycle, true,
                false)
        if si == 1 
            bnor100 = bnor
            stress_matrix[1].BioMProc = 100
        else
            if bnor100 > 0.00001 
                stress_matrix[si].BioMProc = 100 * bnor/bnor100
            else
                stress_matrix[si].BioMProc = 100
            end 
        end 
        stress_matrix[si].BioMSquare = stress_matrix[si].BioMProc^2
        # end stress level
    end 

    # 5. Stress - Biomass relationship
    yavg = 0
    x1avg = 0
    x2avg = 0
    for si in 1:8
        # various stress levels
        yavg += stress_matrix[si].StressProc
        x1avg += stress_matrix[si].BioMProc
        x2avg += stress_matrix[si].BioMSquare
    end do
    yavg  = yavg/8
    x1avg = x1avg/8
    x2avg = x2avg/8
    sumx1y  = 0
    sumx2y  = 0
    sumx1sq = 0
    sumx2sq = 0
    sumx1x2 = 0
    for si in 1:8
        # various stress levels
        y     = stress_matrix[si].StressProc - yavg
        x1    = stress_matrix[si].BioMProc - x1avg
        x2    = stress_matrix[si].BioMSquare - x2avg
        x1y   = x1 * y
        x2y   = x2 * y
        x1sq  = x1 * x1
        x2sq  = x2 * x2
        x1x2  = x1 * x2
        sumx1y  = sumx1y + x1y
        sumx2y  = sumx2y + x2y
        sumx1sq = sumx1sq + x1sq
        sumx2sq = sumx2sq + x2sq
        sumx1x2 = sumx1x2 + x1x2
    end 

    if abs(round(Int, sumx1x2*1000)) != 0 
        b2 = (sumx1y - (sumx2y * sumx1sq)/sumx1x2)/
             (sumx1x2 - (sumx1sq * sumx2sq)/sumx1x2)
        b1 = (sumx1y - b2 * sumx1x2)/sumx1sq
        b0 = yavg - b1*x1avg - b2*x2avg

        bm10 =  stress_matrix[2].BioMProc
        bm20 =  stress_matrix[3].BioMProc
        bm30 =  stress_matrix[4].BioMProc
        bm40 =  stress_matrix[5].BioMProc
        bm50 =  stress_matrix[6].BioMProc
        bm60 =  stress_matrix[7].BioMProc
        bm70 =  stress_matrix[8].BioMProc
    else
        b2 = real(undef_int, kind=dp)
        b1 = real(undef_int, kind=dp)
        b0 = real(undef_int, kind=dp)
    end 
    
    return 
end #notend

"""
    sumkcpot = seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini, l0, l12, 
                                     l123, l1234, gddl0, gddl12, gddl123, 
                                     gddl1234, cco, ccx, cgc, gddcgc, cdc, 
                                     gddcdc, kctop, kcdeclageing, 
                                     cceffectprocent, tbase, tupper, tdaymin, 
                                     tdaymax, gdtransplow, co2i, themodecycle,
                                     simulation, simulparam)

global.f90:5315
note that we must do simulation.DelayedDays = 0 before calling this function
"""
function seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini, l0, l12, 
                                     l123, l1234, gddl0, gddl12, gddl123, 
                                     gddl1234, cco, ccx, cgc, gddcgc, cdc, 
                                     gddcdc, kctop, kcdeclageing, 
                                     cceffectprocent, tbase, tupper, tdaymin, 
                                     tdaymax, gdtransplow, co2i, themodecycle,
                                     simulation, simulparam)
    # 1. Open Temperature file
    loggi = (length(outputs[:tcropsim][:tlow]) > 0) 

    # 2. Initialise global settings
    # required for CalculateETpot
    # simulation.DelayedDays = 0   note that this should do before calling this function
    sumkcpot = 0
    sumgddforplot = undef_int 
    sumgdd = undef_int
    sumgddfromday1 = 0
    growthon = false
    gddtadj = undef_int
    dayfraction = undef_int 
    gddayfraction = undef_int 
    # 2.bis Initialise 1st day
    if thedaystoccini != 0 
        # regrowth
        if thedaystoccini == undef_int 
            # ccx on 1st day
            tadj = l12 - l0
            if themodecycle == :GDDays 
                gddtadj = gddl12 - gddl0
                sumgdd = gddl12
            end 
            ccinitial = ccx
        else
            # cc on 1st day is < ccx
            tadj = thedaystoccini
            daycc = tadj + l0
            if themodecycle == :GDDays 
                gddtadj = thegddaystoccini
                sumgdd = gddl0 + thegddaystoccini
                sumgddforplot = sumgdd
            end 
            ccinitial = canopy_cover_no_stress_sf(daycc, l0, l123, l1234, gddl0, 
                                              gddl123, gddl1234, cco, ccx, 
                                              cgc, cdc, gddcgc, gddcdc, 
                                              sumgddforplot, themodecycle, 
                                              0, 0, simulation)
        end 
        # Time reduction for days between L12 and L123
        dayfraction = (l123-l12)/(tadj + l0 + (l123-l12))
        if themodecycle == :GDDays 
            gddayfraction = (gddl123-gddl12)/(gddtadj + gddl0 + (gddl123-gddl12))
        end 
    else
        # sowing or transplanting
        tadj = 0
        if themodecycle == :GDDays 
            gddtadj = 0
            sumgdd = 0
        end 
        ccinitial = cco
    end 

    # 3. Calculate Sum
    for dayi in 1:l1234
        # 3.1 calculate growing degrees for the day
        if loggi 
            tndayi, txdayi = read_output_from_tcropsim(outputs, dayi) 
            gddi = degrees_day(tbase, tupper, tndayi, txdayi, simulparam.GDDMethod)
        else
            gddi = degrees_day(tbase, tupper, tdaymin, tdaymax, simulparam.GDDMethod)
        end 
        if themodecycle == :GDDays 
            sumgdd = sumgdd + gddi
            sumgddfromday1 = sumgddfromday1 + gddi
        end 

        # 3.2 calculate CCi
        if growthon == false 
            # not yet canopy development
            cci = 0._dp
            daycc = dayi
            if thedaystoccini != 0 
                # regrowth on 1st day
                cci = ccinitial
                growthon = true
            else
                # wait for day of germination or recover of transplant
                if themodecycle == :CalendarDays 
                    if dayi == (l0+1) 
                        cci = ccinitial
                        growthon = true
                    end 
                else
                    if sumgdd > gddl0 
                        cci = ccinitial
                        growthon = true
                    end 
                end 
            end 
        else
            if thedaystoccini == 0 
                daycc = dayi
            else
                daycc = dayi + tadj + l0 # adjusted time scale
                if daycc > l1234 
                    daycc = l1234 # special case where l123 > l1234
                end 
                if daycc > l12 
                    if dayi <= l123 
                        daycc = l12 + round(Int, dayfraction * (dayi+tadj+l0 - l12)) # slowdown
                    else
                        daycc = dayi # switch time scale
                    end 
                end 
            end 
            if themodecycle == :GDDays 
                if thegddaystoccini == 0 
                    sumgddforplot = sumgddfromday1
                else
                    sumgddforplot = sumgdd
                    if sumgddforplot > gddl1234 
                        sumgddforplot = gddl1234 # special case
                                                 # where L123 > L1234
                    end 
                    if sumgddforplot > gddl12 
                        if sumgddfromday1 <= gddl123 
                            sumgddforplot = gddl12 + round(Int, gddayfraction * (sumgddfromday1+gddtadj+gddl0-gddl12)) # slow down
                        else
                            sumgddforplot = sumgddfromday1 # switch time scale
                        end 
                    end 
                end 
            end 
            cci = canopy_cover_no_stress_sf(daycc, l0, l123, l1234, gddl0, 
                                        gddl123, gddl1234, cco, ccx, 
                                        cgc, cdc, gddcgc, gddcdc, 
                                        sumgddforplot, themodecycle, 
                                        0, 0, simulation)
        end

        # 3.3 calculate CCxWithered
        ccxwitheredforb = cci
        if dayi >= l12 
            ccxwitheredforb = ccx
        end 

        # 3.4 Calculate Tpot + Adjust for Low temperature
        # (no transpiration)
        if cci > 0.0001
            tpotforb, epottotforb = calculate_etpot(daycc, l0, l12, l123, l1234, 0, cci, 
                           etostandard, kctop, 
                           kcdeclageing, ccx, ccxwitheredforb, 
                           cceffectprocent, co2i, 
                           gddi, gdtransplow, simulation, simulparam) 
        else
            tpotforb = 0
        end 

        # 3.5 Sum of Sum Of KcPot
        sumkcpot = sumkcpot + (tpotforb/etostandard)
    end 

    # 6. final sum
    return sumkcpot
end 

"""
    canopycovernostresssf = canopy_cover_no_stress_sf(dap, l0, l123, 
       lmaturity, gddl0, gddl123, gddlmaturity, cco, ccx,
       cgc, cdc, gddcgc, gddcdc, sumgdd, typedays, sfredcgc, sfredccx, simulation)

global.f90:1299
"""
function canopy_cover_no_stress_sf(dap, l0, l123, 
       lmaturity, gddl0, gddl123, gddlmaturity, cco, ccx,
       cgc, cdc, gddcgc, gddcdc, sumgdd, typedays, sfredcgc, sfredccx, simulation)
    if typedays == :GDDays
        canopycovernostresssf = canopy_cover_no_stress_gddays_sf(gddl0, gddl123,
            gddlmaturity, sumgdd, cco, ccx, gddcgc, gddcdc, sfredcgc, sfredccx)
    else
        canopycovernostresssf = canopy_cover_no_stress_days_sf(dap, l0, l123,
            lmaturity, cco, ccx, cgc, cdc, sfredcgc, sfredccx, simulation)
    end 
    return canopycovernostresssf
end 


"""
    cc = canopy_cover_no_stress_days_sf(dap, l0, l123,
       lmaturity, cco, ccx, cgc, cdc, sfredcgc, sfredccx, simulation)

global.f90:1333
"""
function canopy_cover_no_stress_days_sf(dap, l0, l123,
       lmaturity, cco, ccx, cgc, cdc, sfredcgc, sfredccx, simulation)
    # CanopyCoverNoStressDaysSF
    cc = 0
    t = dap - simulation.DelayedDays
    # CC refers to canopy cover at the end of the day

    if (t >= 1) & (t <= lmaturity) & (cco > eps()) 
        if t <= l0  # before germination or recovering of transplant
            cc = 0
        else
            if t < l123  # Canopy development and Mid-season stage
                cc = ccattime((t-l0), cco, ((1-sfredcgc/100)*cgc),
                              ((1-sfredccx/100)*ccx))
            else
               # Late-season stage  (t <= LMaturity)
                if ccx < 0.001 
                    cc = 0
                else
                    ccxadj = ccattime((l123-l0), cco, 
                              ((1-sfredcgc/100)*cgc),
                              ((1-sfredccx/100)*ccx))
                    cdcadj = cdc*(ccxadj+2.29)/(ccx+2.29)
                    if ccxadj < 0.001 
                        cc = 0
                    else
                        cc = ccxadj * (1 - 0.05 *
                             (exp((t-l123)*3.33*cdcadj/(ccxadj+2.29))-1))
                    end 
                end 
            end 
        end 
    end
    if cc > 1
        cc = 1
    elseif cc < eps()
        cc = 0
    end 

    return cc
end 

"""
    cc = canopy_cover_no_stress_gddays_sf(gddl0, gddl123, gddlmaturity, sumgdd, 
        cco, ccx, gddcgc, gddcdc, sfredcgc, sfredccx)

global.f90:2670
"""
function canopy_cover_no_stress_gddays_sf(gddl0, gddl123, gddlmaturity, sumgdd, 
        cco, ccx, gddcgc, gddcdc, sfredcgc, sfredccx)
    # sumgdd refers to the end of the day and delayed days are not considered
    cc = 0
    if (sumgdd > 0) & (round(Int, sumgdd) <= gddlmaturity) & (cco > 0) 
        if sumgdd <= gddl0  # before germination or recovering of transplant
            cc = 0
        else
            if sumgdd < gddl123  # canopy development and mid-season stage
                cc = ccatgdd((sumgdd-gddl0), cco, ((1-sfredcgc/100)*gddcgc), 
                  ((1-sfredccx/100)*ccx))
            else
                # late-season stage  (sumgdd <= gddlmaturity)
                if ccx < 0.001
                    cc = 0
                else
                    ccxadj = ccatgdd((gddl123-gddl0), cco, ((1-sfredcgc/100)*gddcgc), 
                      ((1-sfredccx/100)*ccx))
                    gddcdcadj = gddcdc*(ccxadj+2.29)/(ccx+2.29)
                    if (ccxadj < 0.001) 
                        cc = 0
                    else
                        cc = ccxadj * (1 - 0.05*(exp((sumgdd-gddl123)*3.33*gddcdcadj/
                          (ccxadj+2.29))-1))
                    end 
                end 
            end 
        end 
    end 
    if cc > 1
        cc = 1
    elseif cc < 0
        cc = 0
    end 
    return cc
end 

"""
    cci = ccattime(dayi, ccoin, cgcin, ccxin)

global.f90:2371
"""
function ccattime(dayi, ccoin, cgcin, ccxin)
    cci = ccoin * exp(cgcin * dayi)
    if cci > ccxin/2 
        cci = ccxin - 0.25 * (ccxin/ccoin) * ccxin * exp(-cgcin*dayi)
    end 
    return cci
end 

"""
    cci = ccatgdd(gddi, ccoin, gddcgcin, ccxin)

global.f90:2654
"""
function ccatgdd(gddi, ccoin, gddcgcin, ccxin)
    cci = ccoin * exp(gddcgcin * gddi)
    if cci > ccxin/2 
        cci = ccxin - 0.25 * (ccxin/ccoin) * ccxin * exp(-gddcgcin*gddi)
    end 
    return cci
end

"""
   tpotval, epotval = calculate_etpot(dap, l0, l12, l123, lharvest, daylastcut, cci, 
                          etoval, kcval, kcdeclineval, ccx, ccxwithered, 
                          cceffectprocent, co2i, gddayi, tempgdtransplow, 
                          simulation, simulparam)

global.f90:7888
"""
function calculate_etpot(dap, l0, l12, l123, lharvest, daylastcut, cci, 
                          etoval, kcval, kcdeclineval, ccx, ccxwithered, 
                          cceffectprocent, co2i, gddayi, tempgdtransplow, 
                          simulation, simulparam)
    # CalculateETpot
    virtualday = dap - simulation.DelayedDays
    if ((virtualday < l0) & (round(Int, 100*cci) == 0)) | (virtualday > lharvest) 
        # To handlle Forage crops: Round(100*CCi) = 0
        tpotval = 0
        epotval = simulparam.KcWetBare*etoval
    else
        # Correction for micro-advection
        cciadjusted = 1.72*cci - 1*(cci*cci) + 0.30*(cci*cci*cci)
        if cciadjusted < eps() 
            cciadjusted = 0
        elseif cciadjusted > 1 
            cciadjusted = 1
        end 

        # Correction for ageing effects - is a function of calendar days
        if (virtualday-daylastcut) > (l12+5) 
            kcval_local = kcval - (virtualday-daylastcut-(l12+5)) * (kcdeclineval/100)*ccxwithered
        else
            kcval_local = kcval
        end 

        # Correction for elevated atmospheric CO2 concentration
        if co2i > 369.41 
            kcval_local = kcval_local * (1 - 0.05 * (co2i-369.41)/(550-369.41))
        end 

        # Correction for Air temperature stress
        if (cciadjusted <= 0.0000001) | (round(Int, gddayi) < 0) 
            kstrcold = 1
        else
            kstrcold = ks_temperature(0, tempgdtransplow, gddayi)
        end 

        # First estimate of Epot and Tpot
        tpotval = cciadjusted * kstrcold * kcval_local * etoval
        epotval = simulparam.KcWetBare * (1 - cciadjusted) * etoval

        # Maximum Epot with withered canopy as a result of (early) senescence
        epotmax = simulparam.KcWetBare * etoval * 
                        (1 - ccxwithered * cceffectprocent/100)

        # Correction Epot for dying crop in late-season stage
        if (virtualday > l123) & (ccx > eps()) 
            if cci > (ccx/2) 
                # not yet full effect
                if cci > ccx 
                    multiplier = 0  # no effect
                else
                    multiplier = (ccx-cci)/(ccx/2)
                end 
            else
                multiplier = 1 # full effect
            end 
            epotval = epotval * (1 - ccx * (cceffectprocent/100) * multiplier)
            epotmin = simulparam.KcWetBare * (1._dp - 1.72_dp*ccx + 1._dp*(ccx*ccx) - 0.30_dp*(ccx*ccx*ccx)) * etoval
            if epotmin < eps() 
                epotmin = 0
            end 
            if epotval < epotmin 
                epotval = epotmin
            end 
            if epotval > epotmax 
                epotval = epotmax
            end 
        end 

        # Correction for canopy senescence before late-season stage
        if simulation.EvapLimitON 
            if epotval > epotmax 
                epotval = epotmax
            end 
        end 

        # Correction for drop in photosynthetic capacity of a dying green canopy
        if cci < ccxwithered 
            if (ccxwithered > 0.01) & (cci > 0.001) 
                tpotval = tpotval * exp(simulparam.ExpFsen * log(cci/ccxwithered))
            end 
        end 
    end 

    return tpotval, epotval
end 

"""
    m = ks_temperature(t0, t1, tin)

global.f90:1981
"""
function ks_temperature(t0, t1, tin)
    m = 1 # no correction applied (to and/or t1 is undefined, or t0=t1)
    if (round(Int, t0) != undef_int) & 
         (round(Int, t1) != undef_int) & (abs(t0-t1)>epsilon) 
        if (t0 < t1) then
            a =  1  # cold stress
        else
            a = -1 # heat stress
        end 
        if (a*tin > a*t0) & (a*tin < a*t1) 
            # within range for correction
            m = getks(t0, t1, tin)
            if m < 0 
                m = 0
            elseif m > 1 
                m = 1
            end 
        else
            if a*tin <= a*t0 
                m = 0
            end 
            if a*tin >= a*t1 
                m = 1
            end 
        end 
    end 

    return  m
end

"""
    ksi = getks(t0, t1, tin)

global.f90:2021
"""
function getks(t0, t1, tin)
    mo = 0.02
    mx = 1

    trel = (tin-t0)/(t1-t0)
    # derive rate of increase (mrate)
    mrate = (-1)*(log((mo*mx-0.98*mo)/(0.98*(mx-mo))))
    # get ks from logistic equation
    ksi = (mo*mx)/(mo+(mx-mo)*exp(-mrate*trel))
    # adjust for mo
    ksi = ksi - mo * (1 - trel)
    return ksi
end

"""
    higc = harvest_index_growth_coefficient(himax, dhidt)

global.f90:1860
"""
function harvest_index_growth_coefficient(himax, dhidt)
    hio = 1

    if himax > hio 
        t = himax/dhidt
        higc = 0.001
        higc = higc + 0.001
        hivar = (hio*himax)/(hio+(himax-hio)*exp(-higc*t))
        while (hivar <= (0.98*himax))
            higc = higc + 0.001
            hivar = (hio*himax)/(hio+(himax-hio)*exp(-higc*t))
        end 

        if hivar >= himax 
            higc = higc - 0.001
        end 
    else
        higc = undef_int
    end 
    return higc
end

"""
    tswitch, higclinear = get_days_witch_to_linear(himax, dhidt, higc)

global.f90:2988
"""
function get_days_witch_to_linear(himax, dhidt, higc)
    tmax = round(Int, himax/dhidt)
    ti = 0
    him1 = hio
    if tmax > 0 
        loopi = true
        while loopi
            ti = ti + 1
            hii = (hio*himax)/ (hio+(himax-hio)*exp(-higc*ti))
            hifinal = hii + (tmax - ti)*(hii-him1)
            him1 = hii
            if (hifinal > himax) | (ti >= tmax)  
                loopi = false
            end
        end 
        tswitch = ti - 1
    else
        tswitch = 0
    end 
    if tswitch > 0 
        hii = (hio*himax)/ (hio+(himax-hio)*exp(-higc*tswitch))
    else
        hii = 0
    end 
    higclinear = (himax-hii)/(tmax-tswitch)

    return tswitch, higclinear
end


"""
    stressout = crop_stress_parameters_soil_fertility(cropsresp::RepShapes, stresslevel)

global.f90:1231
"""
function crop_stress_parameters_soil_fertility(cropsresp::RepShapes, stresslevel)
    stressout = RepEffectStress()
    pllactual = 1

    # decline canopy growth coefficient (CGC)
    pulactual = 0
    ksi = ks_any(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCGC)
    stressout.RedCGC = round(Int, (1-ksi)*100)
    # decline maximum canopy cover (CCx)
    pulactual = 0
    ksi = ks_any(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCCX)
    stressout.RedCCX = round(Int, (1-ksi)*100)
    # decline crop water productivity (WP)
    pulactual = 0
    ksi = ks_any(stresslevel/100, pulactual, pllactual, cropsresp.ShapeWP)
    stressout.RedWP = round(Int, (1-ksi)*100)
    # decline Canopy Cover (CDecline)
    pulactual = 0
    ksi = ks_any(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCDecline)
    stressout.CDecline = 1 - ksi
    # inducing stomatal closure (KsSto) not applicable
    ksi = 1
    stressout.RedKsSto = round(Int, (1-ksi)*100)

    return stressout
end
