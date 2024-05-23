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
    adjust_compartments!(inse) #TODO check if neccesary
    # reset sumwabal and previoussum
    inse[:sumwabal] = RepSum() 
    reset_previous_sum!(inse)

    initialize_simulation_run_part1!(inse, projectinput)

    return nothing
end #not end

"""
    initialize_simulation_run_part1!(inse, projectinput)

run.f90:4754
"""
function initialize_simulation_run_part1!(inse, projectinput::ProjectInputType)
    # Part1 (before reading the climate) of the initialization of a run
    # Initializes parameters and states

    # 1. Adjustments at start
    # 1.1 Adjust soil water and salt content if water table IN soil profile
    if check_for_watertable_in_profile(inse[:compartments], inse[:integer_parameters][:ziaqua]/100)
        adjust_for_watertable!(inse)
    end 
    if !inse[:simulparam].ConstGwt
        get_gwt_set!(inse, projectinput.ParentDir, inse[:simulation].FromDayNr)
    end 

    # 1.2 Check if FromDayNr simulation needs to be adjusted
    # from previous run if Keep initial SWC
    if ((GetSWCIniFile() == 'KeepSWC') .and. &
        (GetNextSimFromDayNr() /= undef_int)) then
        # assign the adjusted DayNr defined in previous run
        if (GetNextSimFromDayNr() <= GetCrop_Day1()) then
            call SetSimulation_FromDayNr(GetNextSimFromDayNr())
        end 
    end 
    call SetNextSimFromDayNr(undef_int)

    # 2. initial settings for Crop
    call SetCrop_pActStom(GetCrop_pdef())
    call SetCrop_pSenAct(GetCrop_pSenescence())
    call SetCrop_pLeafAct(GetCrop_pLeafDefUL())
    call SetEvapoEntireSoilSurface(.true.)
    call SetSimulation_EvapLimitON(.false.)
    call SetSimulation_EvapWCsurf(0._dp)
    call SetSimulation_EvapZ(EvapZmin/100._dp)
    call SetSimulation_SumEToStress(0._dp)
    call SetCCxWitheredTpotNoS(0._dp) # for calculation Maximum Biomass
                                      # unlimited soil fertility
    call SetSimulation_DayAnaero(0_int8) # days of anaerobic conditions in
                                    # global root zone
    # germination
    if ((GetCrop_Planting() == plant_Seed) .and. &
        (GetSimulation_FromDayNr() <= GetCrop_Day1())) then
        call SetSimulation_Germinate(.false.)
    else
        call SetSimulation_Germinate(.true.)
        # since already germinated no protection required
        call SetSimulation_ProtectedSeedling(.false.)
    end 
    # delayed germination
    call SetSimulation_DelayedDays(0)

    # 3. create temperature file covering crop cycle
    if (GetTemperatureFile() /= '(None)') then
        if (GetSimulation_ToDayNr() < GetCrop_DayN()) then
            call TemperatureFileCoveringCropPeriod(GetCrop_Day1(), &
                       GetSimulation_TodayNr())
        else
            call TemperatureFileCoveringCropPeriod(GetCrop_Day1(), &
                       GetCrop_DayN())
        end 
    end 

    # 4. CO2 concentration during cropping period
    DNr1 = GetSimulation_FromDayNr()
    if (GetCrop_Day1() > GetSimulation_FromDayNr()) then
        DNr1 = GetCrop_Day1()
    end
    DNr2 = GetSimulation_ToDayNr()
    if (GetCrop_DayN() < GetSimulation_ToDayNr()) then
        DNr2 = GetCrop_DayN()
    end 
    call SetCO2i(CO2ForSimulationPeriod(DNr1, DNr2))

    # 5. seasonals stress coefficients
    bool_temp = ((GetCrop_ECemin() /= undef_int) .and. &
                 (GetCrop_ECemax() /= undef_int)) .and. &
                 (GetCrop_ECemin() < GetCrop_ECemax())
    call SetSimulation_SalinityConsidered(bool_temp)
    if (GetIrriMode() == IrriMode_Inet) then
        call SetSimulation_SalinityConsidered(.false.)
    end
    call SetStressTot_NrD(undef_int)
    call SetStressTot_Salt(0._dp)
    call SetStressTot_Temp(0._dp)
    call SetStressTot_Exp(0._dp)
    call SetStressTot_Sto(0._dp)
    call SetStressTot_Weed(0._dp)

    # 6. Soil fertility stress
    # Coefficients for soil fertility - biomass relationship
    # AND for Soil salinity - CCx/KsSto relationship
    call RelationshipsForFertilityAndSaltStress()

    # No soil fertility stress
    if (GetManagement_FertilityStress() <= 0) then
        call SetManagement_FertilityStress(0_int8)
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
    adjust_for_watertable!(inse)

run.f90:3423
"""
function adjust_for_watertable!(inse)
    compartments = inse[:compartments]
    ziaqua = inse[:integer_parameters][:ziaqua]
    soil_layers = inse[:soil_layers]
    simulparam = inse[:simulparam]

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
    get_gwt_set!(inse, parentdir, daynrin)

run.f90:3526
"""
function get_gwt_set!(inse, parentdir, daynrin)
    gwt = inse[:gwtable]
    simulation = inse[:simulation]
    # FileNameFull
    if inse[:string_parameters][:groundwater_file] != "(None)"
        filenamefull = inse[:string_parameters][:groundwater_file]
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

