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
function stress_biomass_relationship(outputs, crop::RepCrop, simulparam::RepParam, co2given)
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
    # required for CalculateETpot
    simulation.DelayedDays = 0
    # to calculate SumKcTop (no stress)
    l12sf = l12
    # to calculate SumKcTop (no stress)
    gddl12sf = gddl12
    # Maximum sum Kc (no stress)
    sumkctop = seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini,
        l0, l12, l123, l1234, gddl0, gddl12, gddl123, gddl1234,
        cco, ccx, cgc, gddcgc, cdc, gddcdc, kctop, kcdeclageing,
        cceffectprocent, tbase, tupper, tdaymin, tdaymax, 
        gdtransplow, co2given, themodecycle)

    # Get PercentLagPhase (for estimate WPi during yield formation)
    if (thecroptype == :Tuber) | (thecroptype == :Grain) 
        # DaysToFlowering corresponds with Tuberformation
        daysyieldformation = round(Int, refhi/ratedhidt)
        if cropdeterm 
            HIGC = HarvestIndexGrowthCoefficient(real(RefHI, kind=dp), RatedHIdt)
            call GetDaySwitchToLinear(RefHI, RatedHIdt, HIGC, tSwitch,&
                  HIGClinear)
        else
            tswitch = roundc(Int, daysyieldformation/3)
        end 
    end 

    # 2. Biomass production for various stress levels
    do Si = 1, 8
        # various stress levels
        # stress effect
        SiPr = int(10*(Si-1), kind=int8)
        StressMatrix(Si)%StressProc = SiPr
        call CropStressParametersSoilFertility(CropSResp, SiPr, StressResponse)
        # adjusted length of Max canopy cover
        RatDGDD = 1
        if ((StressResponse%RedCCX == 0) .and. &
            (StressResponse%RedCGC == 0))then
            L12SF = L12
            GDDL12SF = GDDL12
        else
            call TimeToMaxCanopySF(CCo, CGC, CCx, L0, L12, L123, LFlor,&
                   LengthFlor, CropDeterm, L12SF, StressResponse%RedCGC,&
                   StressResponse%RedCCX, SiPr)
            if (TheModeCycle == modeCycle_GDDays) then
                TDayMin_temp = TDayMin
                TDayMax_temp = TDayMax
                GDDL12SF = GrowingDegreeDays(L12SF, CropDNr1, Tbase, Tupper,&
                                 TDayMin_temp, TDayMax_temp)
            end if
            if ((TheModeCycle == modeCycle_GDDays) .and. (GDDL12SF < GDDL123)) then
                RatDGDD = (L123-L12SF)*1._dp/(GDDL123-GDDL12SF)
            end if
        end if
        # biomass production
        BNor = Bnormalized(TheDaysToCCini, TheGDDaysToCCini,&
                L0, L12, L12SF, L123, L1234, LFlor,&
                GDDL0, GDDL12, GDDL12SF, GDDL123, GDDL1234, WPyield, &
                DaysYieldFormation, tSwitch, CCo, CCx, CGC, GDDCGC, CDC,&
                GDDCDC, KcTop, KcDeclAgeing, CCeffectProcent, WPveg, CO2Given,&
                Tbase, Tupper, TDayMin, TDayMax, GDtranspLow, RatDGDD,&
                SumKcTop, SiPr, StressResponse%RedCGC, StressResponse%RedCCX,&
                StressResponse%RedWP, StressResponse%RedKsSto, 0_int8, 0 ,&
                StressResponse%CDecline, -0.01_dp, TheModeCycle, .true.,&
                .false.)
        if (Si == 1) then
            BNor100 = BNor
            StressMatrix(1)%BioMProc = 100._dp
        else
            if (BNor100 > 0.00001_dp) then
                StressMatrix(Si)%BioMProc = 100._dp * BNor/BNor100
            else
                StressMatrix(Si)%BioMProc = 100._dp
            end if
        end if
        StressMatrix(Si)%BioMSquare =&
             StressMatrix(Si)%BioMProc *&
             StressMatrix(Si)%BioMProc
        # end stress level
    end do

    # 5. Stress - Biomass relationship
    Yavg = 0._dp
    X1avg = 0._dp
    X2avg = 0._dp
    do Si = 1, 8
        # various stress levels
        Yavg = Yavg + StressMatrix(Si)%StressProc
        X1avg = X1avg + StressMatrix(Si)%BioMProc
        X2avg = X2avg + StressMatrix(Si)%BioMSquare
    end do
    Yavg  = Yavg/8._dp
    X1avg = X1avg/8._dp
    X2avg = X2avg/8._dp
    SUMx1y  = 0._dp
    SUMx2y  = 0._dp
    SUMx1Sq = 0._dp
    SUMx2Sq = 0._dp
    SUMx1x2 = 0._dp
    do Si = 1, 8
        # various stress levels
        y     = StressMatrix(Si)%StressProc - Yavg
        x1    = StressMatrix(Si)%BioMProc - X1avg
        x2    = StressMatrix(Si)%BioMSquare - X2avg
        x1y   = x1 * y
        x2y   = x2 * y
        x1Sq  = x1 * x1
        x2Sq  = x2 * x2
        x1x2  = x1 * x2
        SUMx1y  = SUMx1y + x1y
        SUMx2y  = SUMx2y + x2y
        SUMx1Sq = SUMx1Sq + x1Sq
        SUMx2Sq = SUMx2Sq + x2Sq
        SUMx1x2 = SUMx1x2 + x1x2
    end do

    if (abs(roundc(SUMx1x2*1000._dp, mold=1)) /= 0) then
        b2 = (SUMx1y - (SUMx2y * SUMx1Sq)/SUMx1x2)/&
             (SUMx1x2 - (SUMx1Sq * SUMx2Sq)/SUMx1x2)
        b1 = (SUMx1y - b2 * SUMx1x2)/SUMx1Sq
        b0 = Yavg - b1*X1avg - b2*X2avg

        BM10 =  StressMatrix(2)%BioMProc
        BM20 =  StressMatrix(3)%BioMProc
        BM30 =  StressMatrix(4)%BioMProc
        BM40 =  StressMatrix(5)%BioMProc
        BM50 =  StressMatrix(6)%BioMProc
        BM60 =  StressMatrix(7)%BioMProc
        BM70 =  StressMatrix(8)%BioMProc
    else
        b2 = real(undef_int, kind=dp)
        b1 = real(undef_int, kind=dp)
        b0 = real(undef_int, kind=dp)
    end 
    
    return 
end #notend

"""

global.f90:5315
"""
function seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini, l0, l12, 
                                     l123, l1234, gddl0, gddl12, gddl123, 
                                     gddl1234, cco, ccx, cgc, gddcgc, cdc, 
                                     gddcdc, kctop, kcdeclageing, 
                                     cceffectprocent, tbase, tupper, tdaymin, 
                                     tdaymax, gdtransplow, co2i, themodecycle)

    simulation!!
    simulparam!!

    # 1. Open Temperature file
    loggi =  (length(outputs[:tcropsim][:tlow]) > 0) 

    # 2. Initialise global settings
    # required for CalculateETpot
    simulation.DelayedDays = 0
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
                                              0, 0)
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
                                        0, 0)
        end

        # 3.3 calculate CCxWithered
        ccxwitheredforb = cci
        if dayi >= l12 
            ccxwitheredforb = ccx
        end 

        # 3.4 Calculate Tpot + Adjust for Low temperature
        # (no transpiration)
        if cci > 0.0001
            calculate_etpot(daycc, l0, l12, l123, l1234, 0, cci, 
                           etostandard, kctop, 
                           kcdeclageing, ccx, ccxwitheredforb, 
                           cceffectprocent, co2i, 
                           gddi, gdtransplow, tpotforb, epottotforb)
        else
            tpotforb = 0
        end 

        # 3.5 Sum of Sum Of KcPot
        sumkcpot = sumkcpot + (tpotforb/etostandard)
    end 

    # 6. final sum
    return sumkcpot
end #notend

