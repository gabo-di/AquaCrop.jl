"""
    budget_module!(gvars, lvars, virtualtimecc, sumgddadjcc)

simul.f90:5417
"""
function budget_module!(gvars, lvars, virtualtimecc, sumgddadjcc)
    dayi = gvars[:integer_parameters][:daynri]
    suminterval = gvars[:integer_parameters][:suminterval]
    daylastcut = gvars[:integer_parameters][:daylastcut]
    nrdaygrow = gvars[:stresstot].NrD
    tadj = gvars[:integer_parameters][:tadj]
    gddtadj = gvars[:integer_parameters][:gddtadj]
    gddayi = gvars[:float_parameters][:gddayi]
    cgcref = gvars[:float_parameters][:cgcref]
    gddcgcref = gvars[:float_parameters][:gddcgcref]
    co2i = gvars[:float_parameters][:co2i]
    ccxtotal = gvars[:float_parameters][:ccxtotal]
    ccototal = gvars[:float_parameters][:ccototal]
    cdctotal = gvars[:float_parameters][:cdctotal]
    gddcdctotal = gvars[:float_parameters][:gddcdctotal]
    coeffb0salt = gvars[:float_parameters][:coeffb0salt]
    coeffb1salt = gvars[:float_parameters][:coeffb1salt]
    coeffb2salt = gvars[:float_parameters][:coeffb2salt]
    stresstotsaltprev = gvars[:stresstot].Salt
    dayfraction = gvars[:float_parameters][:dayfraction]
    gddayfraction = gvars[:float_parameters][:gddayfraction]
    stresssfadjnew = gvars[:integer_parameters][:stress_sf_adj_new]
    storageon = gvars[:transfer].Store
    mobilizationon = gvars[:transfer].Mobilize

    targettimeval = lvars[:integer_parameters][:targettimeval]
    targetdepthval = lvars[:integer_parameters][:targetdepthval]
    fracassim = lvars[:float_parameters][:fracassim]

    stressleaf = gvars[:float_parameters][:stressleaf]
    stresssenescence = gvars[:float_parameters][:stresssenescence]
    timesenescence = gvars[:float_parameters][:timesenescence]
    nomorecrop = gvars[:bool_parameters][:nomorecrop]


    targettimeval_loc = targettimeval
    stresssfadjnew_loc = stresssfadjnew

    # 1. Soil water balance
    control = :begin_day
    check_water_salt_balance!(gvars, lvars, dayi, control) 


    # 2. Adjustments in presence of Groundwater table
    watertableinprofile = check_for_watertable_in_profile(gvars[:compartments], gvars[:integer_parameters][:ziaqua]/100)
    calculate_adjusted_fc!(gvars[:compartments], gvars[:soil_layers], gvars[:integer_parameters][:ziaqua]/100)  


    # 3. Drainage
    calculate_drainage!(gvars)

    # 4. Runoff
    if gvars[:management].Bundheight < 0.001
        setparameter!(gvars[:integer_parameters], :daysubmerged, 0)
        if gvars[:management].RunoffON & (gvars[:float_parameters][:rain] > 0.1)
            calculate_runoff!(gvars)
        end 
    end 

    # 5. Infiltration (Rain and Irrigation)
    if ((GetRainRecord_DataType() == datatype_decadely) &
            .or. (GetRainRecord_DataType() == datatype_monthly)) then
        call CalculateEffectiveRainfall(SubDrain)
    end if
    if (((GetIrriMode() == IrriMode_Generate) &
        .and. (GetIrrigation() < epsilon(0._dp))) &
            .and. (TargetTimeVal_loc /= -999)) then
        call Calculate_irrigation(SubDrain, TargetTimeVal_loc, TargetDepthVal)
    end if
    if (GetManagement_Bundheight() >= 0.01_dp) then
        call calculate_surfacestorage(InfiltratedRain, InfiltratedIrrigation, &
                                      InfiltratedStorage, ECinfilt, SubDrain, &
                                      dayi)
    else
        call calculate_Extra_runoff(InfiltratedRain, InfiltratedIrrigation, &
                                    InfiltratedStorage, SubDrain)
    end if
    call calculate_infiltration(InfiltratedRain, InfiltratedIrrigation, &
                                InfiltratedStorage, SubDrain)

    # 6. Capillary Rise
    CRwater_temp = GetCRwater()
    CRsalt_temp = GetCRsalt()
    call calculate_CapillaryRise(CRwater_temp, CRsalt_temp)
    call SetCRwater(CRwater_temp)
    call SetCRsalt(CRsalt_temp)

    # 7. Salt balance
    call calculate_saltcontent(InfiltratedRain, InfiltratedIrrigation, &
                               InfiltratedStorage, SubDrain, dayi)


    # 8. Check Germination
    if ((.not. GetSimulation_Germinate()) .and. (dayi >=GetCrop_Day1())) then
        call CheckGermination()
    end if

    # 9. Determine effect of soil fertiltiy and soil salinity stress
    if (.not. NoMoreCrop) then
        call EffectSoilFertilitySalinityStress(StressSFadjNEW_loc, Coeffb0Salt, &
                                               Coeffb1Salt, Coeffb2Salt, &
                                               NrDayGrow, StressTotSaltPrev, &
                                               VirtualTimeCC)
    end if


    # 10. Canopy Cover (CC)
    if (.not. NoMoreCrop) then
        # determine water stresses affecting canopy cover
        SWCtopSoilConsidered_temp = GetSimulation_SWCtopSoilConsidered()
        call DetermineRootZoneWC(GetRootingDepth(), SWCtopSoilConsidered_temp)
        call SetSimulation_SWCtopSoilConsidered(SWCtopSoilConsidered_temp)
        # determine canopy cover
        select case (GetCrop_ModeCycle())
            case(modecycle_GDDays)
            call DetermineCCiGDD(CCxTotal, CCoTotal, StressLeaf, FracAssim, &
                                 MobilizationON, StorageON, SumGDDAdjCC, &
                                 VirtualTimeCC, StressSenescence, &
                                 TimeSenescence, NoMoreCrop, CDCTotal, &
                                 GDDayFraction, &
                                 GDDayi, GDDCDCTotal, GDDTadj)
            case default
            call DetermineCCi(CCxTotal, CCoTotal, StressLeaf, FracAssim, &
                              MobilizationON, StorageON, Tadj, VirtualTimeCC, &
                              StressSenescence, TimeSenescence, NoMoreCrop, &
                              CDCTotal, &
                              DayFraction, GDDCDCTotal, TESTVAL)
        end select
    end if

    # 11. Determine Tpot and Epot
    # 11.1 Days after Planting
    if (GetCrop_ModeCycle() == modecycle_Calendardays) then
        DAP = VirtualTimeCC
    else
        # growing degree days - to position correctly where in cycle
        DAP = SumCalendarDays(roundc(SumGDDadjCC, mold=1), GetCrop_Day1(), &
                              GetCrop_Tbase(), GetCrop_Tupper(), &
                              GetSimulParam_Tmin(), GetSimulParam_Tmax())
        DAP = DAP + GetSimulation_DelayedDays()
            # are not considered when working with GDDays
    end if

    # 11.2 Calculation
    Tpot_temp = GetTpot()
    call CalculateETpot(DAP, GetCrop_DaysToGermination(), &
                        GetCrop_DaysToFullCanopy(), GetCrop_DaysToSenescence(), &
                        GetCrop_DaysToHarvest(), DayLastCut, GetCCiActual(), &
                        GetETo(), GetCrop_KcTop(), GetCrop_KcDecline(), &
                        GetCrop_CCxAdjusted(), GetCrop_CCxWithered(), &
                        real(GetCrop_CCEffectEvapLate(), kind=dp), CO2i, &
                        GDDayi, GetCrop_GDtranspLow(), Tpot_temp, EpotTot)
    call SetTpot(Tpot_temp)
    call SetEpot(EpotTot)
        # adjustment Epot for mulch and partial wetting in next step
    Crop_pActStom_temp = GetCrop_pActStom()
    call AdjustpStomatalToETo(GetETo(), Crop_pActStom_temp)
    call SetCrop_pActStom(Crop_pActStom_temp)

    # 12. Evaporation
    if (.not. GetPreDay()) then
        call PrepareStage2()
            # Initialize Simulation.EvapstartStg2 (REW is gone)
    end if
    if ((GetRain() > 0._dp) &
        .or. ((GetIrrigation() > 0._dp) &
            .and. (GetIrriMode() /= IrriMode_Inet))) then
        call PrepareStage1()
    end if
    EvapWCsurf_temp = GetSimulation_EvapWCsurf()
    Epot_temp = GetEpot()
    call AdjustEpotMulchWettedSurface(dayi, EpotTot, Epot_temp, EvapWCsurf_temp)
    call SetEpot(Epot_temp)
    call SetSimulation_EvapWCsurf(EvapWCsurf_temp)
    if (((GetRainRecord_DataType() == datatype_Decadely) &
            .or. (GetRainRecord_DataType() == datatype_Monthly)) &
        .and. (GetSimulParam_EffectiveRain_RootNrEvap() > 0)) then
        # reduction soil evaporation
        call SetEpot(GetEpot() &
                    * (exp((1._dp/GetSimulParam_EffectiveRain_RootNrEvap())&
                            *log((GetSoil_REW()+1._dp)/20._dp))))
    end if
    # actual evaporation
    call SetEact(0._dp)
    if (GetEpot() > 0._dp) then
        # surface water
        if (GetSurfaceStorage() > 0._dp) then
            call CalculateEvaporationSurfaceWater
        end if
        # stage 1 evaporation
        if ((abs(GetEpot() - GetEact()) > 0.0000001_dp) &
            .and. (GetSimulation_EvapWCsurf() > 0._dp)) then
            call CalculateSoilEvaporationStage1()
        end if
        # stage 2 evaporation
        if (abs(GetEpot() - GetEact()) > 0.0000001_dp) then
            call CalculateSoilEvaporationStage2()
        end if
    end if
    # Reset redcution Epot for 10-day or monthly rainfall data
    if (((GetRainRecord_DataType() == datatype_Decadely) &
            .or. (GetRainRecord_DataType() == datatype_Monthly)) &
        .and. (GetSimulParam_EffectiveRain_RootNrEvap() > 0._dp)) then
        call SetEpot(GetEpot()&
                    /(exp((1._dp/GetSimulParam_EffectiveRain_RootNrEvap()) &
                           *log((GetSoil_REW()+1._dp)/20._dp))))
    end if


    # 13. Transpiration
    if ((.not. NoMoreCrop) .and. (GetRootingDepth() > 0.0001_dp)) then
        if ((GetSurfaceStorage() > 0._dp) &
            .and. ((GetCrop_AnaeroPoint() == 0) &
                  .or. (GetDaySubmerged() < GetSimulParam_DelayLowOxygen()))) then
            call surface_transpiration(Coeffb0Salt, Coeffb1Salt, Coeffb2Salt)
        else
            call calculate_transpiration(GetTpot(), Coeffb0Salt, Coeffb1Salt, &
                                         Coeffb2Salt)
        end if
    end if
    if (GetSurfaceStorage() < epsilon(0._dp)) then
        call SetDaySubmerged(0)
    end if
    call FeedbackCC()

    # 14. Adjustment to groundwater table
    if (WaterTableInProfile) then
        call HorizontalInflowGWTable(GetZiAqua()/100._dp, HorizontalSaltFlow, &
                                     HorizontalWaterFlow)
    end if

    # 15. Salt concentration
    call ConcentrateSalts()

    # 16. Soil water balance
    control = :end_day
    check_water_salt_balance!(gvars, lvars, dayi, control)

    setparameter!(gvars[:float_parameters], :stressleaf, stressleaf)
    setparameter!(gvars[:float_parameters], :stresssenescence, stresssenescence)
    setparameter!(gvars[:float_parameters], :timesenescence, timesenescence)
    setparameter!(gvars[:bool_parameters], :nomorecrop, nomorecrop)
    return nothing
end #notend

"""
    check_water_salt_balance!(gvars, lvars, dayi, control)

simul.f90:2191
"""
function check_water_salt_balance!(gvars, lvars, dayi, control)
    infiltratedrain = lvars[:float_parameters][:infiltratedrain]
    infiltratedirrigation = lvars[:float_parameters][:infiltratedirrigation]
    infiltratedstorage = lvars[:float_parameters][:infiltratedstorage]

    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    surf0 = gvars[:float_parameters][:surf0]
    ecdrain = gvars[:float_parameters][:ecdrain]

    ecinfilt = lvars[:float_parameters][:ecinfilt]
    horizontalwaterflow = lvars[:float_parameters][:horizontalwaterflow]
    horizontalsaltflow = lvars[:float_parameters][:horizontalsaltflow]
    subdrain = lvars[:float_parameters][:subdrain]


    if control == :begin_day
        gvars[:total_water_content].BeginDay = 0 # mm
        gvars[:total_salt_content].BeginDay = 0  # Mg/ha
        surf0 = gvars[:float_parameters][:surfacestorage] # mm
        for compi in 1:length(compartments)
            gvars[:total_water_content].BeginDay += compartments[compi].Theta * 1000 * compartments[compi].Thickness * 
                                                    ( 1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            compartments[compi].Fluxout = 0
            for celli in 1:soil_layers[compartments[compi].Layer].SCP1  
                gvars[:total_salt_content].BeginDay += (compartments[compi].Salt[celli] + compartments[compi].Depo[celli])/100 # Mg/ha
            end 
        end 
        setparameter!(gvars[:float_parameters], :drain, 0.0)
        setparameter!(gvars[:float_parameters], :runoff, 0.0)
        # Eact is set to 0 at the beginning of the evaporation process
        setparameter!(gvars[:float_parameters], :tact, 0.0)
        setparameter!(gvars[:float_parameters], :infiltrated, 0.0)
        ecinfilt = 0
        subdrain = 0
        ecdrain = 0
        horizontalwaterflow = 0
        horizontalsaltflow = 0
        setparameter!(gvars[:float_parameters], :crwater, 0.0)
        setparameter!(gvars[:float_parameters], :crsalt, 0.0)

    elseif control == :end_day
        setparameter!(gvars[:float_parameters], :infiltrated, infiltratedrain + infiltratedirrigation + infiltratedstorage)
        for layeri in 1:length(soil_layers)
            soil_layers[layeri].WaterContent = 0
        end 
        gvars[:total_water_content].EndDay = 0 # mm
        gvars[:total_salt_content].EndDay = 0  # Mg/ha
        surf1 = gvars[:float_parameters][:surfacestorage] # mm

        # quality of irrigation water
        if dayi < gvars[:crop].Day1
            ecw = gvars[:irri_ecw].PreSeason
        else
            ecw = gvars[:simulation].IrriECw
            if dayi > gvars[:crop].DayN
                ecw = gvars[:irri_ecw].PostSeason
            end 
        end 

        for compi in 1:length(compartments)
            gvars[:total_water_content].EndDay += compartments[compi].Theta * 1000 * compartments[compi].Thickness * 
                                                    ( 1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            # OJO, maybe we need compartment.Thickness instead of two times compartments.Theta
            soil_layers[compartments[compi].Layer].WaterContent += compartments[compi].Theta * 1000 * compartments[compi].Theta * 
                                                    ( 1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            for celli in 1:soil_layers[compartments[compi].Layer].SCP1  
                gvars[:total_salt_content].EndDay += (compartments[compi].Salt[celli] + compartments[compi].Depo[celli])/100 # Mg/ha
            end 
        end 

        drain = gvars[:float_parameters][:drain]
        runoff = gvars[:float_parameters][:runoff]
        eact = gvars[:float_parameters][:eact]
        epot = gvars[:float_parameters][:epot]
        tact = gvars[:float_parameters][:tact]
        rain = gvars[:float_parameters][:rain]
        irrigation = gvars[:float_parameters][:irrigation]
        crwater = gvars[:float_parameters][:crwater]
        crsalt = gvars[:float_parameters][:crsalt]
        infiltrated = gvars[:float_parameters][:infiltrated]


        gvars[:total_water_content].ErrorDay = gvars[:total_water_content].BeginDay + surf0 -
                                                (gvars[:total_water_content].EndDay + drain + runoff + eact + 
                                                tact + surf1 - rain - irrigation -crwater - horizontalwaterflow)

        gvars[:total_salt_content].ErrorDay = gvars[:total_salt_content].ErrorDay - gvars[:total_salt_content].EndDay +
                                              infiltratedirrigation * ecw * equiv /100 + 
                                              infiltratedstorage * ecinfilt * equiv/100 -
                                              drain * ecdrain *equiv/100 + 
                                              crsalt/100 + horizontalsaltflow
        
        gvars[:sumwabal].Epot += epot
        gvars[:sumwabal].Tpot += tpot 
        gvars[:sumwabal].Rain += rain 
        gvars[:sumwabal].Irrigation  += irrigation 
        gvars[:sumwabal].Infiltrated += infiltrated 
        gvars[:sumwabal].Runoff += runoff 
        gvars[:sumwabal].Drain += drain
        gvars[:sumwabal].Eact += eact
        gvars[:sumwabal].Tact += tact 
        gvars[:sumwabal].TrW += tactweedinfested 
        gvars[:sumwabal].CRwater += crwater

        if ((dayi - gvars[:simulation].DelayedDays) >= gvars[:crop].Day1) &
           ((dayi - gvars[:simulation].DelayedDays) <= gvars[:crop].DayN)
            # in growing cycle
            if gvars[:sumwabal].Biomass > 0
                # biomass was already produced (i.e. CC present)
                # and still canopy cover
                if gvars[:float_parameters][:cciactual] > 0
                    gvars[:sumwabal].ECropCycle += eact
                end 
            else
                gvars[:sumwabal].ECropCycle += eact # before germination
            end 
        end 
        gvars[:sumwabal].CRsalt += crsalt/100
        gvars[:sumwabal].SaltIn += (infiltratedirrigation * ecw + infiltratedstorage * ecinfilt)*equiv/100
        gvars[:sumwabal].SaltOut += drain * ecdrain * equiv/100
    end 

    setparameter!(gvars[:float_parameters], :surf0, surf0)
    setparameter!(gvars[:float_parameters], :ecdrain, ecdrain)

    
    setparameter!(lvars[:float_parameters], :ecinfilt, ecinfilt)
    setparameter!(lvars[:float_parameters], :horizontalwaterflow, horizontalwaterflow)
    setparameter!(lvars[:float_parameters], :horizontalsaltflow, horizontalsaltflow)
    setparameter!(lvars[:float_parameters], :subdrain, subdrain)
    return nothing
end 

"""
    calculate_drainage!(gvars)

simul.f90:1627
"""
function calculate_drainage!(gvars)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]

    drainsum = 0
    for compi in 1:length(compartments)
        # 1. Calculate drainage of compartment
        # ====================================
        layeri = compartments[compi].Layer
        if compartments[compi].Theta > compartments[compi].FCadj
            delta_theta = calculate_delta_theta(compartments[compi].Theta, compartments[compi].FCadj/100, layeri, soil_layers)
        else
            delta_theta = 0
        end 
        drain_comp = delta_theta * 1000 * compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100)


        # 2. Check drainability
        # =====================
        excess = 0
        pre_thick = 0
        for i in 1:(compi-1)
            pre_thick = pre_thick + compartments[i].Thickness
        end 
        drainmax = delta_theta * 1000 * pre_thick * (1 - soil_layers[layeri].GravelVol/100)
        if drainsum <= drainmax
            drainability = true
        else
            drainability = false
        end 

        # 3. Drain compartment
        # ====================
        if drainability
            call SetCompartment_theta(compi, &
                     compartments[compi].theta(compi)-delta_theta)
            drainsum = drainsum + drain_comp
            drainsum, excess = check_drain_sum(layeri, drainsum, excess, soil_layers)
        else  # drainability == .false.
            delta_theta = drainsum/(1000 * pre_thicki * (1 - soil_layers[layeri].GravelVol/100))
            theta_x = calculate_theta(delta_theta, compartments[compi].FCadj/100, layeri, soil_layers)

            if theta_x <= soil_layers[layeri].SAT/100
                compartments[compi].Theta += drainsum/(1000*compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100))
                if compartments[compi].Theta > theta_x
                    drainsum = (compartments[compi].Theta - theta_x) * 1000 * compartments[compi].Thickness *
                               (1 - soil_layers[layeri].GravelVol/100)
                    delta_theta = calculate_delta_theta(theta_x, compartments[compi].FCadj/100, layeri, soil_layers)
                    drainsum = drainsum + delta_theta * 1000 * compartments[compi].Thickness *
                                          (1 - soil_layers[layeri].GravelVol/100)
                    drainsum, excess =  check_drain_sum(layeri, drainsum, excess, soil_layers)
                    compartments[compi].Theta = theta_x - delta_theta
                elseif compartments[compi].Theta > compartments[compi].FCadj/100
                    delta_theta = calculate_delta_theta(compartments[compi].Theta, compartments[compi].FCadj/100, layeri, soil_layers)
                    compartments[compi].Theta -= delta_theta
                    drainsum = delta_theta * 1000 * compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100)
                    drainsum, excess =  check_drain_sum(layeri, drainsum, excess, soil_layers)
                else
                    drainsum = 0
                end 
            end # theta_x <= SoilLayer[layeri].SAT/100

            if theta_x > soil_layers[layeri].SAT/100
                compartments[compi].Theta += drainsum / (1000 * compartments[compi].Thickness *
                                                         (1 - soil_layers[layeri].GravelVol/100))
                if compartments[compi].Theta <= soil_layers[layeri].SAT/100
                    if compartments[compi].Theta > compartments[compi].FCadj/100
                        delta_theta = calculate_delta_theta(compartments[compi].Theta, compartments[compi].FCadj/100, layeri, soil_layers)
                        compartments[compi].Theta -= delta_theta
                        drainsum = delta_theta * 1000 * compartments[compi].Thickness *
                                    (1 - soil_layers[layeri].GravelVol/100)
                        drainsum, excess =  check_drain_sum(layeri, drainsum, excess, soil_layers)
                    else
                        drainsum = 0
                    end 
                end 

                if compartments[compi].Theta > soil_layers[layeri].SAT/100
                    excess = (compartments[compi].Theta - (soil_layers[layeri].SAT/100)) *
                              1000 * compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100)
                    delta_theta = calculate_delta_theta(compartments[compi].Theta, compartments[compi].FCadj/100, layeri, soil_layers)
                    compartments[compi].Theta = soil_layers[layeri].SAT/100 - delta_theta
                    drain_comp = delta_theta * 1000 * compartments[compi].Thickness * 
                                 (1 - soil_layers[layeri].GravelVol/100)
                    drainmax = delta_theta * 1000 * pre_thick * (1 - soil_layers[layeri].GravelVol/100)
                    if drainmax > excess
                        drainmax = excess
                    end 
                    excess = excess - drainmax
                    drainsum = drainmax + drain_comp
                    drainsum, excess = check_drain_sum(layeri, drainsum, excess, soil_layers)
                end 
            end  # theta_x > SoilLayer[layeri].SAT/100
        end  # drainability = false

        compartments[compi].Fluxout = drainsum

        # 4. Redistribute excess
        # ======================
        if excess > 0
            pre_nr = compi + 1
            loopi = true
            while loopi
                pre_nr = pre_nr - 1
                layeri = compartments[pre_nr].Layer
                if pre_nr < compi
                    compartments[pre_nr].Fluxout -= excess 
                end 
                compartments[pre_nr].Theta += excess / (1000 * compartments[pre_nr].Thickness * 
                                                        (1-soil_layers[compartments[pre_nr].Layer].GravelVol/100))
                if compartments[pre_nr].Theta > soil_layers[layeri].SAT/100
                    excess = (compartments[pre_nr].Theta - soil_layers[layeri].SAT/100) *
                              1000 * compartments[pre_nr].Thickness *
                              (1-soil_layers[compartments[pre_nr].Layer].GravelVol/100)
                    compartments[pre_nr].Theta = soil_layers[layeri].SAT/100
                else
                    excess = 0
                end 
                if (abs(excess) < eps()) | (pre_nr == 1)
                    loopi = false
                end
            end
            # redistribute excess
        end 

    #Do-loop
    end 
    setparameter!(gvars[:float_parameters], :drain, drainsum)

    return nothing
end 

"""
    drainsum, excess = check_drain_sum(layeri, drainsum, excess, soil_layers)

simul.f90:1806
"""
function check_drain_sum(layeri, drainsum, excess, soil_layers)
    if drainsum > soil_layers[layeri].InfRate
        excess = excess + drainsum - soil_layers[layeri].InfRate 
        drainsum = soil_layers[layeri].InfRate 
    end 
    return drainsum, excess
end 

"""
    deltax = calculate_delta_theta(theta_in, thetaadjfc, nrlayer, soil_layers)

simul.f90:1570
"""
function calculate_delta_theta(theta_in, thetaadjfc, nrlayer, soil_layers)
    theta = theta_in
    theta_sat = soil_layers[nrlayer].SAT / 100
    theta_fc = soil_layers[nrlayer].FC / 100
    if theta > theta_sat
        theta = theta_sat
    end 
    if theta <= thetaadjfc/100
        deltax = 0
    else
        DeltaX = soil_layers[nrlayer].Tau * (theta_sat - theta_fc) * 
                 (exp(theta - theta_fc) - 1) / (exp(theta_sat - theta_fc) - 1)
        if (theta - deltax) < thetaadjfc
            deltax = theta - thetaadjfc
        end 
    end 
    return deltax
end

"""
    thetax = calculate_theta(delta_theta, thetaadjfc, nrlayer, soil_layers)

simul.f90:1598
"""
function calculate_theta(delta_theta, thetaadjfc, nrlayer, soil_layers)
    theta_sat = soil_layers[nrlayer].SAT / 100
    theta_fc = soil_layers[nrlayer].FC / 100
    tau = soil_layers[nrlayer].Tau
    if delta_theta <= eps()
        thetax = thetaadjfc
    elseif tau > 0
        thetax = theta_fc + log(1 + delta_theta * (exp(theta_sat - theta_fc) - 1) /
                                (tau * (theta_sat - theta_fc)))
        if thetax < thetaadjfc
            thetax = thetaadjfc
        end 
    else
        # to stop draining
        thetax = theta_sat + 0.1
    end 
    return thetax
end

"""
    calculate_runoff!(gvars)

simul.f90:1852
"""
function calculate_runoff!(gvars)
    simulparam = gvars[:simulparam]
    rain_record = gvars[:rain_record]
    soil = gvars[:soil]
    management = gvars[:management]
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]

    rain = gvars[:float_parameters][:rain]

    maxdepth = simulparam.RunoffDepth

    CN2 = round(Int, soil.CNvalue * (100 + management.CNcorrection)/100)

    if rain_record.DataType == :Daily
        if simulparam.CNcorrection
            calculate_weighting_factors!(maxdepth, compartments)
            sumi = calculate_relative_wetness_topsoil(maxdepth, compartments, soil_layers) 

            call determinecniandiii(cn2, cn1, cn3)
            cna = round(int, cn1+(cn3-cn1)*sumi)
        else
            cna = cn2 
        end 
        shower = rain
    else
        cna = cn2
        shower = rain * 10 / simulparam.EffectiveRain.ShowersInDecade
    end 
    s = 254 * (100/cna - 1)
    term = shower - simulparam.IniAbstract/100 * s
    if term <= eps()
        setparameter!(gvars[:float_parameters], :runoff, 0.0)
    else
        setparameter!(gvars[:float_parameters], :runoff, term**2 / (shower + (1 - simulparam.IniAbstract/100) * s))
    end 
    if (gvars[:float_parameters][:runoff] > 0) &
       ((rain_record.DataType == :Decadely) | (rain_record.DataType == :Monthly))
        if gvars[:float_parameters][:runoff] >= shower
            setparameter!(gvars[:float_parameters], :runoff, rain)
        else
            runoff = gvars[:float_parameters][:runoff] * simulparam.EffectiveRain.ShowersInDecade/10.14
            setparameter!(gvars[:float_parameters], :runoff, runoff)
            if gvars[:float_parameters][:runoff] > rain
                setparameter!(gvars[:float_parameters], :runoff, rain)
            end 
        end 
    end 

    return nothing
end

"""
    sumi = calculate_relative_wetness_topsoil(maxdepth, compartments, soil_layers) 

simul.f90:1901
"""
function calculate_relative_wetness_topsoil(maxdepth, compartments, soil_layers)
    sumi = 0
    compi = 0
    cumdepth = 0

    loopi = true
    while loopi
        compi = compi + 1
        layeri = compartments[compi].Layer
        cumdepth = cumdepth + compartments[compi].Thickness
        if compartments[compi].Theta < soil_layers[layeri].WP/100
            theta = soil_layers[layeri].WP/100 
        else
            theta =compartments[compi].Theta 
        end 
        sumi += compartments[compi].WFactor * (theta - soil_layers[layeri].WP/100) /
                 (soil_layers[layeri].FC/100 - soil_layers[layeri].WP/100)
        if (cumdepth >= maxdepth) | (compi == length(compartments))
            loopi = false
        end
    end

    if sumi < 0
        sumi = 0
    end 
    if sumi > 1
        sumi = 1
    end 

    return sumi
end

"""
    calculate_weighting_factors(depth, compartments)

simulf90:1819
"""
function calculate_weighting_factors(depth, compartments)
    cumdepth = 0
    xx = 0
    compi = 0
    loopi = true
    while loopi
        compi = compi + 1
        cumdepth = cumdepth + compartments[compi].Thickness
        if cumdepth > depth
            cumdepth = depth
        end 
        wx = 1.016 * (1 - exp(-4.16 * cumdepth/depth))
        compartments[compi].WFactor = wx - xx
        if compartments[compi].WFactor > 1
            compartments[compi].WFactor = 1
        end 
        if compartments[compi].WFactor < 0
            compartments[compi].WFactor = 0
        end 
        xx = wx
        if (cumdepth >= depth) | (compi == length(compartments)
            loopi = false
        end
    end
    for i in (compi + 1):length(compartments)
        compartments[i].WFactor = 0
    end 

    return nothing
end

