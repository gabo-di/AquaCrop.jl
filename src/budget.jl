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

    # reset values since they are local variables
    setparameter!(lvars[:float_parameters], :ecinfilt, 0.0)
    setparameter!(lvars[:float_parameters], :horizontalwaterflow, 0.0)
    setparameter!(lvars[:float_parameters], :horizontalsaltflow, 0.0)
    setparameter!(lvars[:float_parameters], :subdrain, 0.0)
    setparameter!(lvars[:float_parameters], :infiltratedrain, 0.0)
    setparameter!(lvars[:float_parameters], :infiltratedirrigation, 0.0)
    setparameter!(lvars[:float_parameters], :infiltratedstorage, 0.0)

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
    if gvars[:management].BundHeight < 0.001
        setparameter!(gvars[:integer_parameters], :daysubmerged, 0)
        if gvars[:management].RunoffOn & (gvars[:float_parameters][:rain] > 0.1)
            calculate_runoff!(gvars)
        end 
    end 

    # 5. Infiltration (Rain and Irrigation)
    if (gvars[:rain_record].Datatype == :decadely) |
       (gvars[:rain_record].Datatype == :Monthly)
        calculate_effective_rainfall!(gvars, lvars)
    end 
    if (gvars[:symbol_parameters][:irrimode] == :Generate) &
       (gvars[:float_parameters][:irrigation] < eps()) &
       (targettimeval_loc != -999)
        calculate_irrigation!(gvars, lvars, targettimeval_loc, targetdepthval)
    end 
    if gvars[:management].BundHeight >= 0.01
        calculate_surfacestorage!(gvars, lvars, dayi)
    else
        calculate_extra_runoff!(gvars, lvars)
    end 
    calculate_infiltration!(gvars, lvars)

    # 6. Capillary Rise
    calculate_capillary_rise!(gvars) 

    # 7. Salt balance
    calculate_salt_content!(gvars, lvars, dayi)


    # 8. Check Germination
    if !gvars[:simulation].Germinate & (dayi >= gvars[:crop].Day1) 
        check_germination!(gvars)
    end 

    # 9. Determine effect of soil fertiltiy and soil salinity stress
    if !gvars[:bool_parameters][:nomorecrop]
        effect_soil_fertility_salinity_stress!(gvars, stresssfadjnew_loc, coeffb0salt, 
                                               coeffb1salt, coeffb2salt, 
                                               nrdaygrow, stresstotsaltprev, 
                                               virtualtimecc)
    end 


    # 10. Canopy Cover (CC)
    if !gvars[:bool_parameters][:nomorecrop]
        # determine water stresses affecting canopy cover
        determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth])
        # determine canopy cover
        if gvars[:crop].ModeCycle == :GDDays
            determine_cci_gdd!(gvars, ccxtotal, ccototal, fracassim, 
                                 mobilizationon, storageon, sumgddadjcc, 
                                 virtualtimecc, cdctotal, gddayfraction, 
                                 gddayi, gddcdctotal, gddtadj)
        else 
            determine_cci!(gvars, ccxtotal, ccototal, fracassim, 
                              mobilizationon, storageon, tadj, virtualtimecc, 
                              cdctotal, dayfraction, gddcdctotal)
        end 
    end 

    # 11. Determine Tpot and Epot
    # 11.1 Days after Planting
    if gvars[:crop].ModeCycle == :Calendardays
        dap = virtualtimecc
    else
        # growing degree days - to position correctly where in cycle
        dap = sum_calendar_days(round(Int, sumgddadjcc), gvars[:crop].Day1, 
                              gvars[:crop].Tbase, gvars[:crop].Tupper, 
                              gvars[:simulparam].Tmin, gvars[:simulparam].Tmax,
                              gvars)
        dap = dap + gvars[:simulation].DelayedDays
        # are not considered when working with GDDays
    end 

    # 11.2 Calculation
    tpot, epot = calculate_etpot(dap, gvars[:crop].DaysToGermination, 
                        gvars[:crop].DaysToFullCanopy, gvars[:crop].DaysToSenescence, 
                        gvars[:crop].DaysToHarvest, daylastcut,
                        gvars[:float_parameters][:cciactual], 
                        gvars[:float_parameters][:eto],
                        gvars[:crop].KcTop, gvars[:crop].KcDecline, 
                        gvars[:crop].CCxAdjusted, gvars[:crop].CCxWithered, 
                        gvars[:crop].CCEffectEvapLate, co2i, 
                        gddayi, gvars[:crop].GDtranspLow, gvars[:simulation],
                        gvars[:simulparam])
    setparameter!(gvars[:float_parameters], :tpot, tpot)
    setparameter!(gvars[:float_parameters], :epot, epot)
    # adjustment Epot for mulch and partial wetting in next step
    pstomatulact = adjust_pstomatal_to_eto(gvars[:float_parameters][:eto],
                                            gvars[:crop], gvars[:simulparam])
    gvars[:crop].pActStom = pstomatulact


    # 12. Evaporation
    if !gvars[:bool_parameters][:preday]
        prepare_stage2!(gvars) # Initialize Simulation.EvapstartStg2 (REW is gone)
    end 
    if (gvars[:float_parameters][:rain] > 0 ) |
        ((gvars[:float_parameters][:irrigation] > 0) & (gvars[:symbol_parameters][:irrimode] != :Inet))
        prepare_stage1!(gvars)
    end 
    adjust_epot_mulch_wetted_surface!(gvars)
    if ((gvars[:rain_record].Datatype == :Decadely) | (gvars[:rain_record].Datatype == :Monthly)) &
       (gvars[:simulparam].EffectiveRain.RootNrEvap > 0)
        # reduction soil evaporation
        epot = gvars[:float_parameters][:epot] *
               (exp((1/gvars[:simulparam].EffectiveRain.RootNrEvap)*log((gvars[:soil].REW+1)/20)))
        setparameter!(gvars[:float_parameters], :epot, epot)
    end 
    # actual evaporation
    setparameter!(gvars[:float_parameters], :eact, 0.0)
    if gvars[:float_parameters][:epot] > 0
        # surface water
        if gvars[:float_parameters][:surfacestorage] > 0
            calculate_evaporation_surface_water!(gvars)
        end 
        # stage 1 evaporation
        if (abs(gvars[:float_parameters][:epot] - gvars[:float_parameters][:eact]) > 0.0000001) &
           (gvars[:simulation].EvapWCsurf > 0)
            calculate_soil_evaporation_stage1!(gvars)
        end 
        # stage 2 evaporation
        if abs(gvars[:float_parameters][:epot] - gvars[:float_parameters][:eact]) > 0.0000001
            calculate_soil_evaporation_stage2!(gvars)
        end 
    end 
    # Reset redcution Epot for 10-day or monthly rainfall data
    if ((gvars[:rain_record].Datatype == :Decadely) | (gvars[:rain_record].Datatype == :Monthly)) &
       (gvars[:simulparam].EffectiveRain.RootNrEvap > 0)
       epot = gvars[:float_parameters][:epot] /
               (exp((1/gvars[:simulparam].EffectiveRain.RootNrEvap)*log((gvars[:soil].REW+1)/20)))
        setparameter!(gvars[:float_parameters], :epot, epot)
    end 


    # 13. Transpiration
    if !gvars[:bool_parameters][:nomorecrop] & (gvars[:float_parameters][:rooting_depth] > 0.0001)
        if (gvars[:float_parameters][:surfacestorage] > 0) &
            ((gvars[:crop].AnaeroPoint == 0) | (gvars[:integer_parameters][:daysubmerged] < gvars[:simulparam].DelayLowOxygen))
            surface_transpiration!(gvars, coeffb0salt, coeffb1salt, coeffb2salt)
        else
            calculate_transpiration!(gvars, gvars[:float_parameters][:tpot], coeffb0salt, coeffb1salt, coeffb2salt)
        end 
    end 
    if gvars[:float_parameters][:surfacestorage] < eps() 
        setparameter!(gvars[:integer_parameters], :daysubmerged, 0)
    end 
    feedback_cc!(gvars)

    # 14. Adjustment to groundwater table
    if watertableinprofile
        horizontal_inflow_gwtable!(gvars, lvars, gvars[:integer_parameters][:ziaqua]/100)
    end 

    # 15. Salt concentration
    concentrate_salts!(gvars)

    # 16. Soil water balance
    control = :end_day
    check_water_salt_balance!(gvars, lvars, dayi, control)

    return nothing
end 

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
        tpot = gvars[:float_parameters][:tpot]
        tactweedinfested = gvars[:float_parameters][:tactweedinfested]
        tact = gvars[:float_parameters][:tact]
        rain = gvars[:float_parameters][:rain]
        irrigation = gvars[:float_parameters][:irrigation]
        crwater = gvars[:float_parameters][:crwater]
        crsalt = gvars[:float_parameters][:crsalt]
        infiltrated = gvars[:float_parameters][:infiltrated]


        gvars[:total_water_content].ErrorDay = gvars[:total_water_content].BeginDay + surf0 -
                                                (gvars[:total_water_content].EndDay + drain + runoff + eact + 
                                                tact + surf1 - rain - irrigation -crwater - horizontalwaterflow)

        gvars[:total_salt_content].ErrorDay = gvars[:total_salt_content].BeginDay - gvars[:total_salt_content].EndDay +
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
            compartments[compi].Theta -= delta_theta
            drainsum = drainsum + drain_comp
            drainsum, excess = check_drain_sum(layeri, drainsum, excess, soil_layers)
        else  # drainability == .false.
            delta_theta = drainsum/(1000 * pre_thick * (1 - soil_layers[layeri].GravelVol/100))
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
        deltax = soil_layers[nrlayer].tau * (theta_sat - theta_fc) * 
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
    tau = soil_layers[nrlayer].tau
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

    cn2 = round(Int, soil.CNValue * (100 + management.CNcorrection)/100)

    if rain_record.Datatype == :Daily
        if simulparam.CNcorrection
            calculate_weighting_factors!(maxdepth, compartments)
            sumi = calculate_relative_wetness_topsoil(maxdepth, compartments, soil_layers) 
            cn1, cn3 = determine_cni_and_iii(cn2)
            cna = round(Int, cn1+(cn3-cn1)*sumi)
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
        setparameter!(gvars[:float_parameters], :runoff, term^2 / (shower + (1 - simulparam.IniAbstract/100) * s))
    end 
    if (gvars[:float_parameters][:runoff] > 0) &
       ((rain_record.Datatype == :Decadely) | (rain_record.Datatype == :Monthly))
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
    calculate_weighting_factors!(depth, compartments)

simul.f90:1819
"""
function calculate_weighting_factors!(depth, compartments)
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
        if (cumdepth >= depth) | (compi == length(compartments))
            loopi = false
        end
    end
    for i in (compi + 1):length(compartments)
        compartments[i].WFactor = 0
    end 

    return nothing
end

"""
    calculate_effective_rainfall!(gvars, lvars)

simul.f90:1986
"""
function calculate_effective_rainfall!(gvars, lvars)
    subdrain = lvars[:float_parameters][:subdrain]

    rain = gvars[:float_parameters][:rain]
    runoff = gvars[:float_parameters][:runoff]
    tpot = gvars[:float_parameters][:tpot]
    epot = gvars[:float_parameters][:epot]
    surfacestorage = gvars[:float_parameters][:surfacestorage]
    rooting_depth = gvars[:float_parameters][:rooting_depth]

    simulparam = gvars[:simulparam]
    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]
    management = gvars[:management]


    if rain > 0
        # 1. Effective Rainfall
        effecrain = (rain - runoff)
        if simulparam.EffectiveRain.Method == :Percentage
            effecrain = simulparam.EffectiveRain.PercentEffRain/100 * (rain - runoff)
        elseif simulparam.EffectiveRain.Method == :USDA
            etcropmonth = ((epot+tpot) * 30)/25.4 # inch/month
            rainmonth = ((rain-runoff) * 30)/25.4 # inch/month
            if rainmonth > 0.1
                effecrain = (0.70917*exp(0.82416*log(rainmonth))-0.11556) * 
                                (exp(0.02426*etcropmonth*log(10))) # inch/month
            else
                effecrain = rainmonth
            end 
            effecrain = effecrain*(25.4/30) # mm/day
        end 
    end 
    if effecrain < 0
        effecrain = 0
    end 
    if effecrain > (rain-runoff)
        effecrain = (rain-runoff)
    end 
    subdrain = (rain-runoff) - effecrain

    # 2. verify possibility of subdrain
    if subdrain > 0
        drainmax = soil_layers[1].InfRate
        if surfacestorage > 0
            drainmax = 0
        else
            zr = rooting_depth 
            if zr <= eps()
                zr = simulparam.EvapZmax/100
            end 
            compi = 0
            depthi = 0
            dtheta = (effecrain/zr)/1000
            loopi = true
            if loopi
                compi = compi + 1
                depthi = depthi + compartments[compi].Thickness
                resttheta = soil_layers[compartments[compi].Layer].SAT/100 - (compartments[compi].Theta + dtheta)
                if resttheta <= eps()
                    drainmax = 0
                end 
                if soil_layers[compartments[compi].Layer].InfRate < drainmax
                    drainmax = soil_layers[compartments[compi].Layer].InfRate 
                end 
                if (depthi >= zr) | (compi >= length(compartments))
                    loopi = false
                end
            end
        end 
        if subdrain > drainmax
            if management.BundHeight < 0.001
                setparameter!(gvars[:float_parameters], :runoff, runoff + subdrain - drainmax)
            end 
            subdrain = drainmax
        end 
    end 

    setparameter!(lvars[:float_parameters], :subdrain, subdrain)
    return nothing
end

"""
    calculate_irrigation!(gvars, lvars, targettimeval, targetdepthval)

simul.f90:1940
"""
function calculate_irrigation!(gvars, lvars, targettimeval, targetdepthval)

    # total root zone is considered
    determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth])
    zrwc = gvars[:root_zone_wc].Actual - gvars[:float_parameters][:epot] - gvars[:float_parameters][:tpot] +
           gvars[:float_parameters][:rain] - gvars[:float_parameters][:runoff] - lvars[:float_parameters][:subdrain] 
    if gvars[:symbol_parameters][:timemode] == :AllDep
        if (gvars[:root_zone_wc].FC - zrwc) >= targettimeval
            targettimeval = 1
        else
            targettimeval = 0
        end 
    end 
    if gvars[:symbol_parameters][:timemode] == :AllRAW
        rawi = targettimeval/100 * (gvars[:root_zone_wc].FC - gvars[:root_zone_wc].Thresh)
        if (gvars[:root_zone_wc].FC - zrwc) >= rawi
            targettimeval = 1
        else
            targettimeval = 0
        end 
    end 
    if targettimeval == 1
        if gvars[:symbol_parameters][:depthmode] == :FixDepth
            irrigation = targetdepthval
        else
            irrigation = gvars[:root_zone_wc].FC - zrwc + targetdepthval
            if irrigation < 0
                irrigation = 0.0
            end 
        end 
    else
        irrigation = 0.0
    end 
    setparameter!(gvars[:float_parameters], :irrigation, irrigation)
    return nothing
end

"""
    calculate_surfacestorage!(gvars, lvars, dayi)

simul.f90:2756
"""
function calculate_surfacestorage!(gvars, lvars, dayi)
    infiltratedrain = lvars[:float_parameters][:infiltratedrain]
    infiltratedirrigation = lvars[:float_parameters][:infiltratedirrigation]
    infiltratedstorage = lvars[:float_parameters][:infiltratedstorage]
    ecinfilt = lvars[:float_parameters][:ecinfilt]

    subdrain = lvars[:float_parameters][:subdrain]

    rain = gvars[:float_parameters][:rain]
    irrigation = gvars[:float_parameters][:irrigation]
    management = gvars[:management]
    rain_record = gvars[:rain_record]
    simulation = gvars[:simulation]
    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]
    crop = gvars[:crop]
    irri_ecw = gvars[:irri_ecw]

    surfacestorage = gvars[:float_parameters][:surfacestorage]
    runoff = gvars[:float_parameters][:runoff]
    ecstorage = gvars[:float_parameters][:ecstorage]


    infiltratedrain = 0
    infiltratedirrigation = 0
    if rain_record.Datatype == :Daily
        sumi = surfacestorage + irrigation + rain
    else
        sumi = surfacestorage + irrigation + rain - runoff - subdrain
    end 
    if sumi > 0
        # quality of irrigation water
        if dayi < crop.Day1
            ecw = irri_ecw.PreSeason
        else
            ecw = simulation.IrriECw
            if dayi > crop.DayN
                ecw = irri_ecw.PostSeason
            end 
        end 
        # quality of stored surface water
        ecstorage = (ecstorage * surfacestorage + ecw * irrigation) /sumi
        # quality of infiltrated water (rain and/or irrigation and/or stored surface water)
        ecinfilt = ecstorage
        # surface storage
        if sumi > soil_layers[compartments[1].Layer].InfRate
            infiltratedstorage = soil_layers[compartments[1].Layer].InfRate
            surfacestorage = sumi - infiltratedstorage
        else
            if rain_record.Datatype == :Daily
                infiltratedstorage = sumi
            else
                infiltratedstorage = surfacestorage + irrigation
                infiltratedrain = rain - runoff
            end 
            surfacestorage = 0.0
        end 
        # extra run-off
        if surfacestorage > (management.BundHeight*1000)
            runoff = runoff  + (surfacestorage - management.BundHeight*1000)
            surfacestorage = management.BundHeight*1000
        end 
    else
        infiltratedstorage = 0
        ecstorage = 0.0
    end 


    setparameter!(gvars[:float_parameters], :runoff, runoff)
    setparameter!(gvars[:float_parameters], :ecstorage, ecstorage)
    setparameter!(gvars[:float_parameters], :surfacestorage, surfacestorage)

    setparameter!(lvars[:float_parameters], :infiltratedrain, infiltratedrain)
    setparameter!(lvars[:float_parameters], :infiltratedirrigation, infiltratedirrigation)
    setparameter!(lvars[:float_parameters], :infiltratedstorage, infiltratedstorage)
    setparameter!(lvars[:float_parameters], :ecinfilt, ecinfilt)
    return nothing
end

"""
    calculate_extra_runoff!(gvars, lvars)

simul.f90:2720
"""
function calculate_extra_runoff!(gvars, lvars)

    infiltratedrain = lvars[:float_parameters][:infiltratedrain]
    infiltratedirrigation = lvars[:float_parameters][:infiltratedirrigation]
    infiltratedstorage = lvars[:float_parameters][:infiltratedstorage]
    subdrain = lvars[:float_parameters][:subdrain]

    rain = gvars[:float_parameters][:rain]
    irrigation = gvars[:float_parameters][:irrigation]
    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]

    runoff = gvars[:float_parameters][:runoff]

    infiltratedstorage = 0
    infiltratedrain = rain - runoff
    if infiltratedrain > 0
        fracsubdrain = subdrain/infiltratedrain
    else
        fracsubdrain = 0
    end 
    if (irrigation + infiltratedrain) > soil_layers[compartments[1].Layer].InfRate
        if irrigation > soil_layers[compartments[1].Layer].InfRate
            infiltratedirrigation = soil_layers[compartments[1].Layer].InfRate 
            runoff = rain + irrigation - infiltratedirrigation
            infiltratedrain = 0
            subdrain = 0
        else
            infiltratedirrigation = irrigation
            infiltratedrain = soil_layers[compartments[1].Layer].InfRate - infiltratedirrigation
            subdrain = fracsubdrain*infiltratedrain
            runoff = rain - infiltratedrain
        end 
    else
        infiltratedirrigation = irrigation
    end 

    
    setparameter!(gvars[:float_parameters], :runoff, runoff)

    setparameter!(lvars[:float_parameters], :infiltratedrain, infiltratedrain)
    setparameter!(lvars[:float_parameters], :infiltratedirrigation, infiltratedirrigation)
    setparameter!(lvars[:float_parameters], :infiltratedstorage, infiltratedstorage)
    setparameter!(lvars[:float_parameters], :subdrain, subdrain)
    return nothing
end

"""
    calculate_infiltration!(gvars, lvars)

simul.f90:2820
"""
function calculate_infiltration!(gvars, lvars)
    infiltratedrain = lvars[:float_parameters][:infiltratedrain]
    infiltratedirrigation = lvars[:float_parameters][:infiltratedirrigation]
    infiltratedstorage = lvars[:float_parameters][:infiltratedstorage]
    subdrain = lvars[:float_parameters][:subdrain]

    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]
    management = gvars[:management]
    simulparam = gvars[:simulparam]
    rooting_depth = gvars[:float_parameters][:rooting_depth]

    runoff = gvars[:float_parameters][:runoff]
    drain = gvars[:float_parameters][:drain]
    surfacestorage = gvars[:float_parameters][:surfacestorage]

    # calculate_infiltration
    # A -  INFILTRATION versus STORAGE in Rootzone (= EffecRain)
    if gvars[:rain_record].Datatype == :Daily
        amount_still_to_store = infiltratedrain + infiltratedirrigation + infiltratedstorage
        effecrain = 0.
    else
        amount_still_to_store = infiltratedirrigation + infiltratedstorage
        effecrain = infiltratedrain - subdrain
    end 

    # B - INFILTRATION through TOP soil surface
    if amount_still_to_store > 0
        runoffini = runoff
        compi = 0

        loopi = true
        while loopi
            compi = compi + 1
            layeri = compartments[compi].Layer

            #1. Calculate multiplication factor

            factor = calculate_factor(layeri, compi, soil_layers, compartments)

            #2. Calculate theta nul

            delta_theta_nul = amount_still_to_store /(1000 * compartments[compi].Thickness *
                              (1-soil_layers[layeri].GravelVol/100))
            delta_theta_sat = calculate_delta_theta(soil_layers[layeri].SAT/100, soil_layers[layeri].FC/100, layeri, soil_layers)

            if delta_theta_nul < delta_theta_sat
                theta_nul = calculate_theta(delta_theta_nul, soil_layers[layeri].FC/100, layeri, soil_layers)
                if theta_nul <= compartments[compi].FCadj/100
                    theta_nul = compartments[compi].FCadj/100
                    delta_theta_nul = calculate_delta_theta(theta_nul, soil_layers[layeri].FC/100, layeri, soil_layers)
                end 
                if theta_nul > soil_layers[layeri].SAT/100
                    theta_nul = soil_layers[layeri].SAT/100
                end 
            else
                theta_nul = soil_layers[layeri].SAT/100
                delta_theta_nul = delta_theta_sat
            end 

            #3. Calculate drain max

            drain_max = factor * delta_theta_nul * 1000 * compartments[compi].Thickness *
                             (1-soil_layers[layeri].GravelVol/100)
            if (compartments[compi].Fluxout + drain_max) > soil_layers[layeri].InfRate
                drain_max = soil_layers[layeri].InfRate - compartments[compi].Fluxout
            end 

            #4. Store water

            diff = theta_nul - compartments[compi].Theta
            if diff > 0
                compartments[compi].Theta += amount_still_to_store /(1000 * compartments[compi].Thickness *
                                             (1 - soil_layers[layeri].GravelVol/100))
                if compartments[compi].Theta > theta_nul
                    amount_still_to_store = (compartments[compi].Theta - theta_nul) * 1000 * compartments[compi].Thickness *
                                            (1-soil_layers[layeri].GravelVol/100)
                    compartments[compi].Theta = theta_nul
                else
                    amount_still_to_store = 0
                end 
            end 
            compartments[compi].Fluxout += amount_still_to_store 

            #5. Redistribute excess

            excess = amount_still_to_store - drain_max
            if excess < 0
                excess = 0
            end 
            amount_still_to_store = amount_still_to_store - excess

            if excess > 0
                pre_comp = compi + 1
                loopi_2 = true
                while loopi_2
                    pre_comp = pre_comp - 1
                    layeri = compartments[pre_comp].Layer
                    compartments[pre_comp].Fluxout -= excess 
                    compartments[pre_comp].Theta += excess/(1000*compartments[pre_comp].Thickness *
                                                    (1 - soil_layers[compartments[pre_comp].Layer].GravelVol/100))
                    if compartments[pre_comp].Theta > soil_layers[layeri].SAT/100
                        excess = (compartments[pre_comp].Theta - soil_layers[layeri].SAT/100) * 1000 *
                                  compartments[pre_comp].Thickness *
                                 (1-soil_layers[compartments[pre_comp].Layer].GravelVol/100)
                        compartments[pre_comp].Theta = soil_layers[layeri].SAT/100
                    else
                        excess = 0
                    end 
                    if (excess < eps()) | (pre_comp == 1)
                        loopi_2 = false
                    end
                end
                if excess > 0
                    runoff = runoff + excess
                end 
            end 

            if (amount_still_to_store <= eps()) | (compi == length(compartments)) 
                loopi = false
            end
        end
        if amount_still_to_store > 0
            drain = drain + amount_still_to_store
        end 

        #6. Adjust infiltrated water

        if runoff > runoffini
            if management.BundHeight >= 0.01
                surfacestorage += (runoff  - runoffini)
                infiltratedstorage = infiltratedstorage - (runoff-runoffini)
                if surfacestorage > management.BundHeight*1000
                    runoff = runoffini + surfacestorage - management.BundHeight*1000
                    surfacestorage = management.BundHeight*1000
                else
                    runoff = runoffini
                end 
            else
                infiltratedrain = infiltratedrain - (runoff-runoffini)
                if infiltratedrain < 0
                    infiltratedirrigation = infiltratedirrigation + infiltratedrain
                    infiltratedrain = 0
                end 
            end 

            # INFILTRATION through TOP soil surface
        end 
    end 

    # C - STORAGE in Subsoil (= SubDrain)
    if subdrain > 0
        amount_still_to_store = subdrain

        # Where to store
        zr = rooting_depth
        if zr <= 0
            zr = simulparam.EvapZmax/100
        end 
        compi = 0
        depthi = 0
        loopi_3 = true
        while loopi_3
            compi = compi + 1
            depthi = depthi + compartments[compi].Thickness
            if (depthi >= zr) | (compi >= length(compartments))
                loopi_3 = false
            end
        end
        if depthi > zr
            deltaz = (depthi - zr)
        else
            deltaz = 0
        end 

        # Store
        while (amount_still_to_store > 0) & ((compi < length(compartments)) | (deltaz > 0))
            if abs(deltaz) < eps()
                compi = compi + 1
                deltaz = compartments[compi].Thickness
            end 
            storablemm = (soil_layers[compartments[compi].Layer].SAT/100 - compartments[compi].Theta) *
                            1000 * deltaz * (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            if storablemm > amount_still_to_store
                compartments[compi].Theta += (amount_still_to_store)/(1000*compartments[compi].Thickness *
                                              (1 - soil_layers[(compartments[compi].Layer)].GravelVol/100))
                amount_still_to_store = 0
            else
                amount_still_to_store = amount_still_to_store - storablemm
                compartments[compi].Theta += storablemm/(1000 * compartments[compi].Thickness *
                                             (1 - soil_layers[compartments[compi].Layer].GravelVol/100))
            end 
            deltaz = 0
            if amount_still_to_store > soil_layers[compartments[compi].Layer].InfRate
                subdrain = subdrain - (amount_still_to_store - soil_layers[compartments[compi].Layer].InfRate)
                effecrain = effecrain + (amount_still_to_store - soil_layers[compartments[compi].Layer].InfRate) 
                amount_still_to_store = soil_layers[compartments[compi].Layer].InfRate
            end 
        end 

        # excess
        if amount_still_to_store > 0
            drain = drain + amount_still_to_store
        end 
        # STORAGE in Subsoil (= SubDrain)
    end 

    # D - STORAGE in Rootzone (= EffecRain)
    if effecrain > 0
        zr = rooting_depth
        if zr <= eps()
            zr = simulparam.EvapZmax/100
        end 
        amount_still_to_store = effecrain

        # Store
        # step 1 fill to FC (from top to bottom)
        compi = 0
        depthi = 0
        loopi_4 = true
        while loopi_4
            compi = compi + 1
            layeri = compartments[compi].Layer
            depthi = depthi + compartments[compi].Thickness
            if depthi <= zr
                deltaz = compartments[compi].Thickness
            else
                deltaz = compartments[compi].Thickness - (depthi-zr)
            end 
            storablemm = (compartments[compi].FCadj/100 - compartments[compi].Theta)*1000*deltaz *
                             (1 - soil_layers[layeri].GravelVol/100)
            if storablemm < 0
                storablemm = 0
            end 
            if storablemm > amount_still_to_store
                compartments[compi].Theta += amount_still_to_store/(1000*compartments[compi].Thickness *
                                             (1 - soil_layers[layeri].GravelVol/100))
                amount_still_to_store = 0
            elseif storablemm > 0
                compartments[compi].Theta += storablemm/(1000*compartments[compi].Thickness *
                                             (1 - soil_layers[layeri].GravelVol/100))
                amount_still_to_store = amount_still_to_store - storablemm
            end 
            if (depthi >= zr) | (compi >= length(compartments)) | (amount_still_to_store <= eps()) 
                loopi_4 = false
            end
        end

        # step 2 fill to SATURATION (from bottom to top)
        if amount_still_to_store > 0
            loopi_5 = true
            while loopi_5
                layeri = compartments[compi].Layer
                if depthi > zr
                    deltaz = compartments[compi].Thickness - (depthi-zr)
                else
                    deltaz = compartments[compi].Thickness
                end 
                storablemm = (soil_layers[layeri].SAT/100 - compartments[compi].Theta)*1000*deltaz *
                             (1 - soil_layers[layeri].GravelVol/100)
                if storablemm < 0
                    storablemm = 0
                end 
                if storablemm > amount_still_to_store
                    compartments[compi].Theta += amount_still_to_store/(1000*compartments[compi].Thickness *
                                                 (1 - soil_layers[layeri].GravelVol/100))
                    amount_still_to_store = 0
                elseif storablemm > 0
                    compartments[compi].Theta += storablemm/(1000*compartments[compi].Thickness *
                                                 (1 - soil_layers[layeri].GravelVol/100))
                    amount_still_to_store = amount_still_to_store - storablemm
                end 
                compi = compi - 1
                depthi = depthi - compartments[compi].Thickness
                if (compi == 0) | (amount_still_to_store <= eps) 
                    loopi_5 = false
                end
            end
        end 

        # excess
        if amount_still_to_store > 0
            if infiltratedrain > 0
                infiltratedrain = infiltratedrain - amount_still_to_store
            end 
            if management.BundHeight >= 0.01
                surfacestorage += amount_still_to_store
                if surfacestorage > management.BundHeight*1000
                    runoff += (surfacestorage - management.BundHeight*1000)
                    surfacestorage = management.BundHeight*1000
                end 
            else
                runoff = runoff + amount_still_to_store
            end 
        end 
        # STORAGE in Rootzone (= EffecRain)
    end 

    setparameter!(gvars[:float_parameters], :runoff, runoff)
    setparameter!(gvars[:float_parameters], :drain, drain)
    setparameter!(gvars[:float_parameters], :surfacestorage, surfacestorage)

    setparameter!(lvars[:float_parameters], :infiltratedrain, infiltratedrain)
    setparameter!(lvars[:float_parameters], :infiltratedirrigation, infiltratedirrigation)
    setparameter!(lvars[:float_parameters], :infiltratedstorage, infiltratedstorage)
    setparameter!(lvars[:float_parameters], :subdrain, subdrain)
    return nothing
end 
  
"""
    cf = calculate_factor(layeri, compi, soil_layers, compartments)

simu.f90:3212
"""
function calculate_factor(layeri, compi, soil_layers, compartments)
    delta_theta_sat = calculate_delta_theta(soil_layers[layeri].SAT/100, soil_layers[layeri].FC/100, layeri, soil_layers)
    if delta_theta_sat > 0
        cf = soil_layers[layeri].InfRate / (delta_theta_sat * 1000 * compartments[compi].Thickness *
                                 (1 - soil_layers[layeri].GravelVol/100))
    else
        cf = 1
    end 

    return cf
end

"""
    calculate_capillary_rise!(gvars) 

simul.f90:2060
"""
function calculate_capillary_rise!(gvars)
    ziaqua = gvars[:integer_parameters][:ziaqua]
    eciaqua = gvars[:float_parameters][:eciaqua]
    compartments = gvars[:compartments]
    simulparam = gvars[:simulparam]
    soil_layers = gvars[:soil_layers]


    crwater = gvars[:float_parameters][:crwater]
    crsalt = gvars[:float_parameters][:crsalt]

    zbottom = 0
    for compi in 1:length(compartments) 
        zbottom = zbottom + compartments[compi].Thickness
    end 

    # start at the bottom of the soil profile
    compi = length(compartments) 
    layeri = compartments[compi].Layer
    maxmm = max_crat_depth(soil_layers[layeri].CRa, soil_layers[layeri].CRb, soil_layers[layeri].InfRate,
                            zbottom - compartments[compi].Thickness/2, ziaqua/100)

    # check restrictions on CR from soil layers below
    ztopnextlayer = 0
    for layeri in 1:compartments[end].Layer 
        ztopnextlayer = ztopnextlayer + soil_layers[layeri].Thickness
    end 
    layeri = compartments[end].Layer
    while (ztopnextlayer < ziaqua/100) & (layeri < length(soil_layers)) 
        layeri = layeri + 1
        limitmm = max_crat_depth(soil_layers[layeri].CRa, soil_layers[layeri].CRb, soil_layers[layeri].InfRate,
                                 ztopnextlayer, ziaqua/100)
        if maxmm > limitmm
            maxmm = limitmm
        end 
        ztopnextlayer = ztopnextlayer + soil_layers[layeri].Thickness
    end 

    while (round(Int, maxmm*1000) > 0) & (compi > 0) & (round(Int, compartments[compi].Fluxout*1000) == 0)
        # Driving force
        layeri = compartments[compi].Layer
        if (compartments[compi].Theta >= soil_layers[layeri].WP/100) & (simulparam.RootNrDF > 0)
            drivingforce = 1 -
                           exp(simulparam.RootNrDF * log(compartments[compi].Theta - soil_layers[layeri].WP/100)) /
                           exp(simulparam.RootNrDF * log(compartments[compi].FCadj/100 -
                           soil_layers[layeri].WP/100))
        else
            drivingforce = 1
        end 
        # relative hydraulic conductivity
        thetathreshold = (soil_layers[layeri].WP/100 + soil_layers[layeri].FC /100)/2
        if compartments[compi].Theta < thetathreshold
            if (compartments[compi].Theta <= soil_layers[layeri].WP/100) |
               (thetathreshold <= soil_layers[layeri].WP/100)
                krel = 0
            else
                krel = (compartments[compi].Theta - soil_layers[layeri].WP/100) /
                       (thetathreshold - soil_layers[layeri].WP/100)
            end 
        else
            krel = 1
        end 

        # room available to store water
        dtheta = compartments[compi].FCadj/100 - compartments[compi].Theta
        if (dtheta > 0) & ((zbottom - compartments[compi].Thickness/2) < (ziaqua/100))
            # water stored
            dthetamax = krel * drivingforce * maxmm/(1000*compartments[compi].Thickness)
            if dtheta >= dthetamax
                compartments[compi].Theta += dthetamax
                crcomp = dthetamax*1000*compartments[compi].Thickness *
                         (1 - soil_layers[layeri].GravelVol/100)
                maxmm = 0
            else
                compartments[compi].Theta = compartments[compi].FCadj/100
                crcomp = dtheta*1000*compartments[compi].Thickness *
                         (1 - soil_layers[layeri].GravelVol/100)
                maxmm = krel * maxmm - crcomp
            end 
            crwater = crwater + crcomp
            # salt stored
            scellact = active_cells(compartments[compi], soil_layers)
            saltcri = equiv * crcomp * eciaqua # gram/m2
            compartments[compi].Salt[scellact] += saltcri
            crsalt = crsalt + saltcri
        end 
        zbottom = zbottom - compartments[compi].Thickness
        compi = compi - 1
        if compi < 1
            break
        end
        layeri = compartments[compi].Layer
        limitmm = max_crat_depth(soil_layers[layeri].CRa, soil_layers[layeri].CRb, soil_layers[layeri].InfRate, 
                                 zbottom - compartments[compi].Thickness/2, ziaqua/100)
        if maxmm > limitmm
            maxmm = limitmm
        end 
    end

    setparameter!(gvars[:float_parameters], :crwater, crwater)
    setparameter!(gvars[:float_parameters], :crsalt, crsalt)
    return nothing
end

"""
    crmax = max_crat_depth(paramcra, paramcrb, ksat, zi, depthgwt)

global.f90:2156
"""
function max_crat_depth(paramcra, paramcrb, ksat, zi, depthgwt)
    crmax = 0
    if (ksat > 0) & (depthgwt > 0) & ((depthgwt-zi) < 4)
        if zi >= depthgwt
            crmax = 99
        else
            crmax = exp((log(depthgwt - zi) - paramcrb)/paramcra)
            if crmax > 99
                crmax = 99
            end 
        end 
    end 
    return crmax
end

"""
    calculate_salt_content!(gvars, lvars, dayi)

simul.f90:2329
"""
function calculate_salt_content!(gvars, lvars, dayi)
    infiltratedrain = lvars[:float_parameters][:infiltratedrain]
    infiltratedirrigation = lvars[:float_parameters][:infiltratedirrigation]
    infiltratedstorage = lvars[:float_parameters][:infiltratedstorage]
    subdrain = lvars[:float_parameters][:subdrain]

    irri_ecw = gvars[:irri_ecw]
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    simulparam = gvars[:simulparam]
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    ecstorage = gvars[:float_parameters][:ecstorage]

    mmin = infiltratedrain + infiltratedirrigation + infiltratedstorage

    # quality of irrigation water
    if dayi < crop.Day1
        ecw = irri_ecw.PreSeason
    else
        ecw = simulation.IrriECw
        if dayi > crop.DayN
            ecw = irri_ecw.PostSeason
        end 
    end 

    # initialise salt balance
    saltin = infiltratedirrigation*ecw*equiv + infiltratedstorage*ecstorage*equiv
    setparameter!(gvars[:float_parameters], :saltinfiltr, saltin/100) # salt infiltrated in soil profile kg/ha
    saltout= 0


    for compi in 1:length(compartments) 
        # 0. Set compartment parameters
        layeri = compartments[compi].Layer
        sat = soil_layers[layeri].SAT/100  # m3/m3
        ul = soil_layers[layeri].UL # m3/m3
                                      # Upper limit of SC salt cel
        dx = soil_layers[layeri].Dx # m3/m3
                            # Size of salts cel (expect last one)

        # 1. Initial situation before drain and infiltration
        deltatheta = mmin/(1000*compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100))
        theta = compartments[compi].Theta - deltatheta + compartments[compi].Fluxout/(1000*compartments[compi].Thickness)

        # 2. Determine active SaltCels and Add IN
        theta = theta + deltatheta
        if theta <= ul
            celi = 0
            while theta > dx*celi
                celi = celi + 1
            end 
        else
            celi = soil_layers[layeri].SCP1
        end 
        if celi == 0
            celi = 1  # XXX would be best to avoid celi=0 to begin with
        end 
        if deltatheta > 0
            compartments[compi].Salt[celi] += saltin
        end 

        # 3. Mixing
        if celi > 1
            for ni in 1:(celi-1)
                mm1 = dx*1000*compartments[compi].Thickness  * (1 - soil_layers[layeri].GravelVol/100)
                if ni < soil_layers[layeri].SC
                    mm2 = mm1
                elseif theta > sat
                    mm2 = (theta-ul)*1000*compartments[compi].Thickness *
                          (1 - soil_layers[layeri].GravelVol/100)
                else
                    mm2 = (sat-ul)*1000*compartments[compi].Thickness *
                          (1 - soil_layers[layeri].GravelVol/100)
                end 
                diff = soil_layers[layeri].SaltMobility[ni]
                mixing!(compartments[compi], simulparam, mm1, mm2, diff, ni)
            end 
        end 

        # 4. Drain
        saltout = 0
        if compartments[compi].Fluxout > 0
            deltatheta = compartments[compi].Fluxout/(1000*compartments[compi].Thickness *
                         (1 - soil_layers[layeri].GravelVol/100))
            while deltatheta > 0
                if celi < soil_layers[layeri].SCP1
                    limit = (celi-1)*dx
                else
                    limit = ul
                end 
                if (theta - deltatheta) < limit
                    saltout = saltout + compartments[compi].Salt[celi] + compartments[compi].Depo[celi]
                    compartments[compi].Salt[celi] = 0
                    mm1 = (theta - limit)*1000 * compartments[compi].Thickness *
                          (1 - soil_layers[layeri].GravelVol/100)
                    if saltout > simulparam.SaltSolub * mm1
                        compartments[compi].Depo[celi] = saltout - simulparam.SaltSolub * mm1
                        saltout = simulparam.SaltSolub * mm1
                    else
                        compartments[compi].Depo[celi] = 0
                    end 
                    deltatheta = deltatheta - (theta-limit)
                    theta = limit
                    celi = celi - 1
                else
                    saltout = saltout + (compartments[compi].Salt[celi] + compartments[compi].Depo[celi]) * 
                                        (deltatheta/(theta-limit))
                    compartments[compi].Salt[celi] = compartments[compi].Salt[celi] * (1-deltatheta/(theta-limit))
                    compartments[compi].Depo[celi] = compartments[compi].Depo[celi] * (1-deltatheta/(theta-limit))
                    mm1 = deltatheta * 1000 * compartments[compi].Thickness *
                          (1 - soil_layers[layeri].GravelVol/100)
                    if saltout > simulparam.SaltSolub * mm1
                        compartments[compi].Depo[celi] += saltout - simulparam.SaltSolub * mm1
                        saltout = simulparam.SaltSolub * mm1
                    end 
                    deltatheta = 0
                    mm1 = soil_layers[layeri].Dx * 1000 * compartments[compi].Thickness *
                          (1 - soil_layers[layeri].GravelVol/100)
                    if celi == soil_layers[layeri].SCP1
                        mm1 = 2*mm1
                    end 
                    salt_solution_deposit!(compartments[compi], simulparam, celi, mm1)
                end
            end 
        end 

        mmin = compartments[compi].Fluxout
        saltin = saltout
    end 

    drain = gvars[:float_parameters][:drain]
    if drain > 0.001
        setparameter!(gvars[:float_parameters], :ecdrain, saltout/(drain*equiv)) 
    end 

    # 5. vertical salt diffusion
    celi = active_cells(compartments[1], soil_layers)
    layeri = compartments[1].Layer
    sm2 = soil_layers[layeri].SaltMobility[celi]/4
    ecsw2 = ecswcomp(compartments[1], false, gvars)
    mm2 = compartments[1].Theta * 1000 * compartments[1].Thickness *
          (1 - soil_layers[layeri].GravelVol/100)
    for compi in 2:length(compartments) 
        layeri = compartments[compi].Layer
        celim1 = celi
        sm1 = sm2
        ecsw1 = ecsw2
        mm1 = mm2
        celi = active_cells(compartments[compi], soil_layers)
        sm2 = soil_layers[layeri].SaltMobility[celi]/4
        ecsw2 = ecswcomp(compartments[compi], false, gvars) # not at fc
        mm2 = compartments[compi].Theta * 1000 * compartments[compi].Thickness *
              (1 - soil_layers[layeri].GravelVol/100)
        ecsw = (ecsw1*mm1+ecsw2*mm2)/(mm1+mm2)
        ds1 = (ecsw1 - (ecsw1+(ecsw-ecsw1)*sm1))*mm1*equiv
        ds2 = (ecsw2 - (ecsw2+(ecsw-ecsw2)*sm2))*mm2*equiv
        if abs(ds2) < abs(ds1)
            ds = abs(ds2)
        else
            ds = abs(ds1)
        end 
        if ds > 0
            if ecsw1 > ecsw
                ds = -ds
            end 
            move_salt_to!(compartments[compi-1], simulparam, soil_layers, celim1, ds)
            ds = -ds
            move_salt_to!(compartments[compi], simulparam, soil_layers, celim1, ds)
        end 
    end 

    # 6. Internal salt movement as a result of SubDrain
    # SubDrain part of non-effective rainfall (10-day & monthly input)
    if subdrain > 0
        zr = gvars[:float_parameters][:rooting_depth]
        if zr >= eps()
            zr = simulparam.EvapZmax/100 # in meter
        end 
        compi = 0
        depthi = 0
        ecsubdrain = 0

        # extract
        loopi = true
        while loopi
            compi = compi + 1
            layeri = compartments[compi].Layer
            depthi = depthi + compartments[compi].Thickness
            if depthi <= zr
                deltaz = compartments[compi].Thickness
            else
                deltaz = compartments[compi].Thickness - (depthi-zr)
            end 
            celi = active_cells(compartments[compi], soil_layers)
            if celi < soil_layers[layeri].SCP1
                mm1 = soil_layers[layeri].Dx * 1000 * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
            else
                mm1 = 2 * soil_layers[layeri].Dx * 1000 *compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
            end 
            eccel = compartments[compi].Salt[celi]/(mm1*equiv)
            ecsubdrain = (eccel*mm1*(deltaz/compartments[compi].Thickness) + ecsubdrain*subdrain) /
                         (mm1*(deltaz/compartments[compi].Thickness) + subdrain)
            compartments[compi].Salt[celi] = (1 - (deltaz/compartments[compi].Thickness)) * compartments[compi].Salt[celi] +
                                             (deltaz/compartments[compi].Thickness)*ecsubdrain*mm1*equiv
            salt_solution_deposit!(compartments[compi], simulparam, celi, mm1)
            if (depthi >= zr) | (compi >= length(compartments))
                loopi = false
            end
        end

        # dump
        drain = gvars[:float_parameters][:drain]
        ecdrain = gvars[:float_parameters][:ecdrain]
        if compi >= length(compartments)
            saltout = ecdrain*drain*equiv + ecsubdrain*subdrain*equiv
            setparameter!(gvars[:float_parameters], :ecdrain, saltout/(drain*equiv))
        else
            compi = compi + 1
            celi = active_cells(compartments[compi], soil_layers)
            layeri = compartments[compi].Layer
            if celi < soil_layers[layeri].SCP1
                mm1 = soil_layers[layeri].Dx*1000 * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
            else
                mm1 = 2 * soil_layers[layeri].Dx * 1000 * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
            end 
            compartments[compi].Salt[celi] += ecsubdrain*subdrain*equiv
            salt_solution_deposit!(compartments[compi], simulparam, celi, mm1)
        end 
    end 

    return nothing
end

"""
    mixing!(compartment::CompartmentIndividual, simulparam::RepParam, mm1, mm2, diff, ni)

simul.f90:2650
"""
function mixing!(compartment::CompartmentIndividual, simulparam::RepParam, mm1, mm2, diff, ni)
    salt_solution_deposit!(compartment, simulparam, ni, mm1)
    salt_solution_deposit!(compartment, simulparam, ni+1, mm1)

    ec1 = compartment.Salt[ni]/(mm1*equiv)
    ec2 = compartment.Salt[ni+1]/(mm2*equiv)
    ecmix = (ec1*mm1+ec2*mm2)/(mm1+mm2)
    ec1 = ec1 + (ecmix-ec1)*diff
    ec2 = ec2 + (ecmix-ec2)*diff
    compartment.Salt[ni] = ec1*mm1*equiv
    compartment.Salt[ni+1] = ec2*mm2*equiv

    salt_solution_deposit!(compartment, simulparam, ni, mm1)
    salt_solution_deposit!(compartment, simulparam, ni+1, mm1)
    return nothing
end

"""
    move_salt_to!(compx::CompartmentIndividual, simulparam::RepParam, soil_layers, celx_local, ds)

simul.f90:2675
"""
function move_salt_to!(compx::CompartmentIndividual, simulparam::RepParam, soil_layers, celx_local, ds)
    layeri = compx.Layer
    if ds >= eps()
        compx.Salt[celx_local] = compx.Salt[celx_local] + ds
        mmx = soil_layers[layeri].Dx * 1000 * compx.Thickness *
              (1 - soil_layers[layeri].GravelVol/100)
        if celx_local == soil_layers[layeri].SCP1
            mmx = 2*mmx
        end
        salt_solution_deposit!(compx, simulparam, celx_local, mmx)
    else
        celx_local = soil_layers[layeri].SCP1
        compx.Salt[celx_local] = compx.Salt[celx_local] + ds
        mmx = 2 * soil_layers[layeri].Dx * 1000 * compx.Thickness *
              (1 - soil_layers[layeri].GravelVol/100)
        salt_solution_deposit!(compx, simulparam, celx_local, mmx)
        mmx = mmx/2
        while compx.Salt[celx_local] < 0
            # index zero problem
            # TO DO: likely also happened with original Pascal code, 
            #        but Pascal code tolerates it
            if celx_local == 1
                celx_local = length(compx.Salt)
            end 
            compx.Salt[celx_local-1] = compx.Salt[celx_local-1] + compx.Salt[celx_local]
            compx.Salt[celx_local] = 0.
            celx_local = celx_local - 1
            salt_solution_deposit!(compx, simulparam, celx_local, mmx)
        end 
    end 

    return nothing
end

"""
    check_germination!(gvars)

simul.f90:1130
"""
function check_germination!(gvars)
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    root_zone_wc = gvars[:root_zone_wc]
    simulparam = gvars[:simulparam]

    # total root zone is considered
    zroot = crop.RootMin
    determine_root_zone_wc!(gvars, zroot)
    wcgermination = root_zone_wc.WP + (root_zone_wc.FC - root_zone_wc.WP) * (simulparam.TAWGermination/100)
    if root_zone_wc.Actual < wcgermination
        simulation.DelayedDays += 1
        simulation.SumGDD = 0
    else
        simulation.Germinate = true
        if crop.Planting == :Seed
            simulation.ProtectedSeedling = true
        else
            simulation.ProtectedSeedling = false 
        end 
    end 

    return nothing
end

"""
    effect_soil_fertility_salinity_stress!(gvars, stresssfadjnew, coeffb0salt, 
                                                 coeffb1salt, coeffb2salt, 
                                                 nrdaygrow, stresstotsaltprev, 
                                                 virtualtimecc)

simul.f90:3985
"""
function effect_soil_fertility_salinity_stress!(gvars, stresssfadjnew, coeffb0salt, 
                                                 coeffb1salt, coeffb2salt, 
                                                 nrdaygrow, stresstotsaltprev, 
                                                 virtualtimecc)

    if gvars[:simulation].SalinityConsidered
        determine_root_zone_salt_content!(gvars, gvars[:float_parameters][:rooting_depth])
        saltstress = (nrdaygrow*stresstotsaltprev + 100 * (1-gvars[:root_zone_salt].KsSalt)) /
                     (nrdaygrow+1)
    else
        saltstress = 0
    end 
    if (virtualtimecc < gvars[:crop].DaysToGermination) |
       (virtualtimecc > (gvars[:crop].DayN-gvars[:crop].Day1)) |
       (gvars[:simulation].Germinate == false) |
       ((stresssfadjnew == 0) & (saltstress <= 0.1))
        # no soil fertility and salinity stress
        no_effect_stress!(gvars[:simulation].EffectStress)
        gvars[:crop].DaysToFullCanopySF = gvars[:crop].DaysToFullCanopy
        if gvars[:crop].ModeCycle == :GDDays
            gvars[:crop].GDDaysToFullCanopySF = gvars[:crop].GDDaysToFullCanopy
        end 
    else
        # Soil fertility
        if stresssfadjnew == 0
            fertilityeffectstress = RepEffectStress()
            no_effect_stress!(fertilityeffectstress)
        else
            fertilityeffectstress = crop_stress_parameters_soil_fertility(gvars[:crop].StressResponse, 
                                                                            stresssfadjnew) 
        end 
        # Soil Salinity
        ccxredd = round(Int, coeffb0salt + coeffb1salt * saltstress +
                             coeffb2salt * saltstress * saltstress)
        if (ccxredd < 0) | (saltstress <= 0.1) | (gvars[:simulation].SalinityConsidered == false)
            salinityeffectstress = RepEffectStress()
            no_effect_stress!(salinityeffectstress)
        else
            if (ccxredd > 100) | (saltstress >= 99.9)
                ccxred = 100
            else
                ccxred = round(Int, ccxredd) 
            end 
            salinityeffectstress = crop_stress_parameters_soil_salinity(ccxred, 
                                                  gvars[:crop].CCsaltDistortion, 
                                                  gvars[:crop].CCo, 
                                                  gvars[:crop].CCx, 
                                                  gvars[:crop].CGC, 
                                                  gvars[:crop].GDDCGC, 
                                                  gvars[:crop].DeterminancyLinked, 
                                                  gvars[:crop].DaysToFullCanopy, 
                                                  gvars[:crop].DaysToFlowering, 
                                                  gvars[:crop].LengthFlowering, 
                                                  gvars[:crop].DaysToHarvest, 
                                                  gvars[:crop].GDDaysToFullCanopy, 
                                                  gvars[:crop].GDDaysToFlowering, 
                                                  gvars[:crop].GDDLengthFlowering, 
                                                  gvars[:crop].GDDaysToHarvest, 
                                                  gvars[:crop].ModeCycle) 
        end 
        # Assign integrated effect of the stresses
        gvars[:simulation].EffectStress.RedWP = fertilityeffectstress.RedWP
        gvars[:simulation].EffectStress.RedKsSto = salinityeffectstress.RedKsSto
        if fertilityeffectstress.RedCGC > salinityeffectstress.RedCGC
            gvars[:simulation].EffectStress.RedCGC = fertilityeffectstress.RedCGC
        else
            gvars[:simulation].EffectStress.RedCGC = salinityeffectstress.RedCGC
        end 
        if fertilityeffectstress.RedCCX > salinityeffectstress.RedCCX
            gvars[:simulation].EffectStress.RedCCX = fertilityeffectstress.RedCCX
        else
            gvars[:simulation].EffectStress.RedCCX = salinityeffectstress.RedCCX
        end 
        if fertilityeffectstress.CDecline > salinityeffectstress.CDecline
            gvars[:simulation].EffectStress.CDecline = fertilityeffectstress.CDecline
        else
            gvars[:simulation].EffectStress.CDecline = salinityeffectstress.CDecline
        end 
        # adjust time to maximum canopy cover
        l12sf, redcgc, redccx, _ = time_to_max_canopy_sf(
                               gvars[:crop].CCo, gvars[:crop].CGC, gvars[:crop].CCx, 
                               gvars[:crop].DaysToGermination, 
                               gvars[:crop].DaysToFullCanopy, 
                               gvars[:crop].DaysToSenescence, 
                               gvars[:crop].DaysToFlowering, 
                               gvars[:crop].LengthFlowering, 
                               gvars[:crop].DeterminancyLinked, 
                               gvars[:crop].DaysToFullCanopySF,
                               gvars[:simulation].EffectStress.RedCGC, 
                               gvars[:simulation].EffectStress.RedCCX, 
                               stresssfadjnew)
        gvars[:simulation].EffectStress.RedCGC = redcgc
        gvars[:simulation].EffectStress.RedCCX = redccx
        gvars[:crop].DaysToFullCanopySF = l12sf
        if gvars[:crop].ModeCycle == :GDDays
            if (abs(gvars[:management].FertilityStress) > eps()) | (abs(saltstress) > eps())
                
                gdd1234 = growing_degree_days( gvars[:crop].DaysToFullCanopySF, 
                                               gvars[:crop].Day1, 
                                               gvars[:crop].Tbase, 
                                               gvars[:crop].Tupper, 
                                               gvars,
                                               gvars[:simulparam].Tmin, 
                                               gvars[:simulparam].Tmax)
                gvars[:crop].GDDaysToFullCanopySF = gdd1234
            else
                gvars[:crop].GDDaysToFullCanopySF = gvars[:crop].GDDaysToFullCanopy
            end 
        end 
    end 

    return nothing
end

"""
    no_effect_stress!(theeffectstress::RepEffectStress)

simul.f90:4128
"""
function no_effect_stress!(theeffectstress::RepEffectStress)
    theeffectstress.RedCGC = 0
    theeffectstress.RedCCX = 0
    theeffectstress.RedWP = 0
    theeffectstress.CDecline = 0
    theeffectstress.RedKsSto = 0
    return nothing
end

"""
    determine_cci_gdd!(gvars, ccxtotal, ccototal, 
                            fracassim, mobilizationon, 
                            storageon, sumgddadjcc, virtualtimecc, 
                            cdctotal, gddayfraction, 
                            gddayi, gddcdctotal, gddtadj)

simul.f90:3234
"""
function determine_cci_gdd!(gvars, ccxtotal, ccototal, 
                            fracassim, mobilizationon, 
                            storageon, sumgddadjcc, virtualtimecc, 
                            cdctotal, gddayfraction, 
                            gddayi, gddcdctotal, gddtadj)

    stressleaf = gvars[:float_parameters][:stressleaf]
    stresssenescence = gvars[:float_parameters][:stresssenescence]
    timesenescence = gvars[:float_parameters][:timesenescence]
    nomorecrop = gvars[:bool_parameters][:nomorecrop]
    cciactual = gvars[:float_parameters][:cciactual]
    cciprev = gvars[:float_parameters][:cciprev]
    ccitopearlysen = gvars[:float_parameters][:ccitopearlysen]

    eto = gvars[:float_parameters][:eto]

    ccdormant = 0.05
    gddcdcadjusted = 0.0 #default value needed ?

    if (sumgddadjcc <= gvars[:crop].GDDaysToGermination) |
       (round(Int, sumgddadjcc) > gvars[:crop].GDDaysToHarvest)
        cciactual = 0
    else
        # growing season (once germinated)
        # 1. find some parameters
        cgcgddsf = gvars[:crop].GDDCGC * (1 - gvars[:simulation].EffectStress.RedCGC/100)
        gddcgcadjusted = cgcgddsf

        ratdgdd = 1
        if gvars[:crop].GDDaysToFullCanopySF < gvars[:crop].GDDaysToSenescence
            ratdgdd = (gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopySF) /
                      (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopySF)
        end 

        ccxsf = ccxtotal*(1 - gvars[:simulation].EffectStress.RedCCX/100)
        # maximum canopy cover than can be reached
        # (considering soil fertility/salinity, weed stress)
        if sumgddadjcc <= gvars[:crop].GDDaysToFullCanopySF
            ccxsfcd = ccxsf # no canopy decline before max canopy can be reached
        else
            # canopy decline due to soil fertility
            if sumgddadjcc < gvars[:crop].GDDaysToSenescence
                ccxsfcd = cci_no_water_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToFullCanopySF, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToFullCanopySF, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, 
                            gvars[:crop].GDDCGC, cdctotal, gddcdctotal, 
                            sumgddadjcc, ratdgdd, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX, 
                            gvars[:simulation].EffectStress.CDecline, 
                            gvars[:crop].ModeCycle, gvars[:simulation])
            else
                ccxsfcd = ccxsf - (ratdgdd * gvars[:simulation].EffectStress.CDecline/100) *
                          (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopySF)
            end 
            if ccxsfcd < 0
                ccxsfcd = 0
            end 
        end 
        stressleaf = undef_double #undef_int
        if (abs(sumgddadjcc - gvars[:crop].GDDaysToGermination) < eps()) & (gvars[:crop].DaysToCCini == 0)
            cciprev = ccototal
        end 

        # time of potential vegetative growth
        gddtfinalccx = gvars[:crop].GDDaysToSenescence # non determinant crop
        if (gvars[:crop].subkind == :Grain) & gvars[:crop].DeterminancyLinked
            # determinancy
            # reduce GDDtFinalCCx in f(determinancy of crop)
            if gvars[:crop].DaysToCCini != 0
                # regrowth
                gddtfinalccx = gvars[:crop].GDDaysToFullCanopy +
                               round(Int, gddayfraction *
                                     (gvars[:crop].GDDaysToFlowering + (gvars[:crop].GDDLengthFlowering/2) +
                                      gddtadj + gvars[:crop].GDDaysToGermination - gvars[:crop].GDDaysToFullCanopy)) # slow down
            else
                # sown or transplant
                gddtfinalccx = gvars[:crop].GDDaysToFlowering + round(Int, gvars[:crop].GDDLengthFlowering/2)
            end 
            if gddtfinalccx > gvars[:crop].GDDaysToSenescence
                gddtfinalccx = gvars[:crop].GDDaysToSenescence
            end 
        end 

        # Crop.pLeafAct and Crop.pSenAct for plotting root zone depletion in RUN
        pleafulact, pleafllact = adjust_pleaf_to_eto(eto, gvars[:crop], gvars[:simulparam])
        gvars[:crop].pLeafAct = pleafulact
        withbeta = true
        psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, gvars[:crop], gvars[:simulparam])
        gvars[:crop].pSenAct = psenact 

        # 2. Canopy can still develop (stretched to GDDtFinalCCx)
        if sumgddadjcc < gddtfinalccx
            # Canopy can stil develop (stretched to GDDtFinalCCx)
            if (cciprev <= gvars[:crop].CCoAdjusted) | (sumgddadjcc <= gddayi) |
               ((gvars[:simulation].ProtectedSeedling) & (cciprev <= (1.25 * ccototal)))
                # 2.a First day or very small CC as a result of senescence
                # (no adjustment for leaf stress)
                if gvars[:simulation].ProtectedSeedling
                    cciactual = canopy_cover_no_stress_sf(
                                 virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                 gvars[:crop].DaysToGermination, 
                                 gvars[:crop].DaysToSenescence, 
                                 gvars[:crop].DaysToHarvest, 
                                 gvars[:crop].GDDaysToGermination, 
                                 gvars[:crop].GDDaysToSenescence, 
                                 gvars[:crop].GDDaysToHarvest, 
                                 ccototal, ccxtotal, gvars[:crop].CGC, 
                                 cdctotal, gvars[:crop].GDDCGC, 
                                 gddcdcadjusted, sumgddadjcc, 
                                 gvars[:crop].ModeCycle, 
                                 gvars[:simulation].EffectStress.RedCGC, 
                                 gvars[:simulation].EffectStress.RedCCX,
                                 gvars[:simulation])
                    if cciactual > (1.25 * ccototal)
                        gvars[:simulation].ProtectedSeedling = false
                    end 
                else
                    cciactual = gvars[:crop].CCoAdjusted * exp(cgcgddsf * gddayi)
                end 
            # 2.b CC > CCo
            else
                if cciprev < 0.97999*ccxsf
                    gddcgcadjusted, stressleaf = determine_gddcgc_adjusted(cgcgddsf, pleafllact, 
                                                                            gvars[:root_zone_wc],
                                                                            gvars[:crop],
                                                                            gvars[:simulation])
                    if gddcgcadjusted > 0.00000001
                        # Crop.GDDCGC or GDDCGCadjusted > 0
                        ccxadjusted = determine_ccx_adjusted_gdd(cciprev,
                                                ccxsf, gddcgcadjusted, gddayi,
                                                sumgddadjcc, gddtfinalccx,
                                                gvars[:crop].CCoAdjusted)
                        gvars[:crop].CCxAdjusted = ccxadjusted
                        if gvars[:crop].CCxAdjusted < 0
                            cciactual = cciprev
                        elseif abs(cciprev - 0.97999*ccxsf) < 0.001
                            cciactual = canopy_cover_no_stress_sf(
                                virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                gvars[:crop].DaysToGermination, 
                                gvars[:crop].DaysToSenescence, 
                                gvars[:crop].DaysToHarvest, 
                                gvars[:crop].GDDaysToGermination, 
                                gvars[:crop].GDDaysToSenescence, 
                                gvars[:crop].GDDaysToHarvest, 
                                ccototal, ccxtotal, gvars[:crop].CGC, 
                                cdctotal, gvars[:crop].GDDCGC, gddcdcadjusted, 
                                sumgddadjcc, gvars[:crop].ModeCycle, 
                                gvars[:simulation].EffectStress.RedCGC, 
                                gvars[:simulation].EffectStress.RedCCX,
                                gvars[:simulation])
                        else
                            gddttemp = required_gdd(cciprev,
                                                    gvars[:crop].CCoAdjusted,
                                                    gvars[:crop].CCxAdjusted, 
                                                    gddcgcadjusted, gddayi, sumgddadjcc)
                            if gddttemp < 0
                                cciactual = cciprev
                            else
                                gddttemp = gddttemp + gddayi
                                cciactual = cc_at_gddtime(gddttemp, 
                                                        gvars[:crop].CCoAdjusted, 
                                                        gddcgcadjusted, 
                                                        gvars[:crop].CCxAdjusted)
                            end 
                        end 
                    else
                        # GDDCGCadjusted = 0 - too dry for leaf expansion
                        cciactual = cciprev
                        if cciactual > gvars[:crop].CCoAdjusted
                            gvars[:crop].CCoAdjusted = ccototal
                        else
                            gvars[:crop].CCoAdjusted = cciactual 
                        end 
                    end 
                else
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, cdctotal, 
                            gvars[:crop].GDDCGC, gddcdcadjusted, sumgddadjcc, 
                            gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                    gvars[:crop].CCoAdjusted = ccototal
                    stressleaf = -33 # maximum canopy is reached;
                end 
                if cciactual > ccxsfcd
                    cciactual = ccxsfcd
                    stressleaf = -33 # maximum canopy is reached;
                end 
            end 
            gvars[:crop].CCxAdjusted = cciactual

        # 3. Canopy can no longer develop
        # (Mid-season (from tFinalCCx) or Late season stage)
        else
            StressLeaf = -33 # maximum canopy is reached;
            if gvars[:crop].CCxAdjusted < 0
                gvars[:crop].CCxAdjusted = cciprev 
            end 

            if sumgddadjcc < gvars[:crop].GDDaysToSenescence # mid-season
                if gvars[:crop].CCxAdjusted > 0.97999*ccxsf
                    cciactual = canopy_cover_no_stress_sf(
                                virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                gvars[:crop].DaysToGermination, 
                                gvars[:crop].DaysToSenescence, 
                                gvars[:crop].DaysToHarvest, 
                                gvars[:crop].GDDaysToGermination, 
                                gvars[:crop].GDDaysToSenescence, 
                                gvars[:crop].GDDaysToHarvest, 
                                ccototal, ccxtotal, gvars[:crop].CGC, 
                                cdctotal, gvars[:crop].GDDCGC, 
                                gddcdcadjusted, sumgddadjcc, 
                                gvars[:crop].ModeCycle, 
                                gvars[:simulation].EffectStress.RedCGC, 
                                gvars[:simulation].EffectStress.RedCCX,
                                gvars[:simulation])
                    gvars[:crop].CCxAdjusted = cciactual 
                else
                    cciactual = canopy_cover_no_stress_sf(
                                virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                gvars[:crop].DaysToGermination, 
                                gvars[:crop].DaysToSenescence, 
                                gvars[:crop].DaysToHarvest, 
                                gvars[:crop].GDDaysToGermination, 
                                gvars[:crop].GDDaysToSenescence, 
                                gvars[:crop].GDDaysToHarvest, 
                                ccototal, 
                                gvars[:crop].CCxAdjusted/(1- gvars[:simulation].EffectStress.RedCCx/100), 
                                gvars[:crop].CGC, cdctotal, gvars[:crop].GDDCGC, 
                                gddcdcadjusted, sumgddadjcc, 
                                gvars[:crop].ModeCycle, 
                                gvars[:simulation].EffectStress.RedCGC, 
                                gvars[:simulation].EffectStress.RedCCX,
                                gvars[:simulation])
                end 
                if cciactual > ccxsfcd
                    cciactual = ccxsfcd
                end 
            # late season
            else
                stresssenescence = undef_double #undef_int # to avoid display of zero stress in late season
                if gvars[:crop].CCxAdjusted > ccxsfcd
                    gvars[:crop].CCxAdjusted = ccxsfcd
                end 
                if gvars[:crop].CCxAdjusted < 0.01
                    cciactual = 0
                else
                    # calculate CC in late season
                    # CCibis = CC which canopy declines
                    # (soil fertility/salinity stress) further in late season
                    ccibis = ccxsf - (ratdgdd*gvars[:simulation].EffectStress.CDecline/100) *
                             (exp(2 * log(sumgddadjcc - gvars[:crop].GDDaysToFullCanopySF)) /
                             (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopySF))
                    if ccibis < 0
                        cciactual = 0
                    else
                        # CCiActual = CC with natural senescence in late season
                        gddcdcadjusted = get_gddcdc_adjusted_no_stress(
                                                                    ccxtotal, 
                                                                    gddcdctotal, 
                                                                    gvars[:crop].CCxAdjusted)
                        if sumgddadjcc < (gvars[:crop].GDDaysToSenescence +
                                          length_canopy_decline(gvars[:crop].CCxAdjusted, gddcdcadjusted))
                            cciactual = gvars[:crop].CCxAdjusted * (1 - 0.05 *
                                        (exp((sumgddadjcc - gvars[:crop].GDDaysToSenescence) * 3.33 * 
                                         gddcdcadjusted/(gvars[:crop].CCxAdjusted + 2.29)) - 1))
                            # CCiActual becomes CCibis, when canopy decline is more severe
                            if ccibis < cciactual
                                cciactual = ccibis
                            end 
                        else
                            cciactual = 0
                        end 
                    end 
                end 
                # late season
            end 
            # 3. Canopy can no longer develop (Mid-season (from tFinalCCx)
            # or Late season stage)
        end 

        # 4. Canopy senescence due to water stress ?
        # not yet late season stage
        if (sumgddadjcc < gvars[:crop].GDDaysToSenescence) | (timesenescence > 0)
            # in late season with ongoing early senesence
            # (TimeSenescence in GDD)
            stresssenescence = 0
            withbeta = true
            psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, gvars[:crop], gvars[:simulparam])
            gvars[:crop].pSenAct = psenact
            ksred = 1 # effect of soil salinity
                      # on the threshold for senescence
            if gvars[:simulation].SWCtopSoilConsidered
                # top soil is relative wetter than total root zone
                if (gvars[:root_zone_wc].ZtopAct <
                    (gvars[:root_zone_wc].ZtopFC - gvars[:crop].pSenAct * ksred * (gvars[:root_zone_wc].ZtopFC - gvars[:root_zone_wc].ZtopWP))) &
                   (gvars[:simulation].ProtectedSeedling == false)
                    thesenescenceon = true
                else
                    thesenescenceon = false
                end 
            else
                if (gvars[:root_zone_wc].Actual <
                    (gvars[:root_zone_wc].FC - gvars[:crop].pSenAct * ksred * (gvars[:root_zone_wc].FC - gvars[:root_zone_wc].WP))) &
                    (gvars[:simulation].ProtectedSeedling == false)
                    thesenescenceon = true
                else
                    thesenescenceon = false
                end 
            end 

            if thesenescenceon
                # CanopySenescence
                gvars[:simulation].EvapLimitON = true
                # consider withered crop when not yet in late season
                if abs(timesenescence) < eps()
                    ccitopearlysen = cciactual # cc before canopy decline
                end 
                timesenescence = timesenescence + gddayi
                gddcdcadjusted, kssen, stresssenescence = determine_gddcdc_adjusted_water_stress(eto, timesenescence, gddcdctotal, ccxsfcd, ccxtotal,
                                                            gvars[:root_zone_wc], gvars[:crop], gvars[:simulparam], gvars[:simulation])
                if ccitopearlysen < 0.001
                    if (gvars[:simulation].SumEToStress > gvars[:crop].SumEToDelaySenescence) |
                       (abs(gvars[:crop].SumEToDelaySenescence) < eps())
                        ccisen = 0 # no crop anymore
                    else
                        if ccdormant > gvars[:crop].CCo
                            ccisen = gvars[:crop].CCo + (1 - gvars[:simulation].SumEToStress /
                                         gvars[:crop].SumEToDelaySenescence) * (ccdormant - gvars[:crop].CCo)
                        else
                            ccisen = gvars[:crop].CCo
                        end 
                    end 
                else
                    # e power too large and in any case CCisen << 0
                    if ((timesenescence*gddcdcadjusted*3.33)/(ccitopearlysen+2.29) > 100) |
                       (cciprev >= 1.05 * ccitopearlysen)
                        # Ln of negative or zero value
                        if (gvars[:simulation].SumEToStress > gvars[:crop].SumEToDelaySenescence) |
                           (abs(gvars[:crop].SumEToDelaySenescence) < eps())
                            ccisen = 0 # no crop anymore
                        else
                            if ccdormant > gvars[:crop].CCo
                                ccisen = gvars[:crop].CCo +
                                         (1 - gvars[:simulation].SumEToStress/gvars[:crop].SumEToDelaySenescence) *
                                         (ccdormant - gvars[:crop].CCo)
                            else
                                ccisen = gvars[:crop].CCo
                            end 
                        end 
                    else
                        # GDDCDC is adjusted to degree of stress
                        # time required to reach CCiprev with GDDCDCadjusted
                        gddttemp = (log(1 + (1 - cciprev/ccitopearlysen)/0.05)) /
                                   (gddcdcadjusted * 3.33/(ccitopearlysen + 2.29))
                        # add 1 day to tTemp and calculate CCiSen with CDCadjusted
                        ccisen = ccitopearlysen * (1 - 0.05 * (exp((gddttemp+gddayi) * gddcdcadjusted *
                                                   3.33 /(ccitopearlysen+2.29)) -1))
                    end 
                    if ccisen < 0
                        ccisen = 0
                    end
                    if (gvars[:crop].SumEToDelaySenescence > 0) &
                       (gvars[:simulation].SumEToStress <= gvars[:crop].SumEToDelaySenescence)
                        if (ccisen < gvars[:crop].CCo) | (ccisen < ccdormant)
                            if ccdormant > gvars[:crop].CCo
                                ccisen = gvars[:crop].CCo +
                                         (1 - gvars[:simulation].SumEToStress/gvars[:crop].SumEToDelaySenescence) *
                                         (ccdormant - gvars[:crop].CCo)
                            else
                                ccisen = gvars[:crop].CCo
                            end 
                        end 
                    end 
                end 
                if sumgddadjcc < gvars[:crop].GDDaysToSenescence
                    # before late season
                    if ccisen > ccxsfcd
                        ccisen = ccxsfcd
                    end 
                    cciactual = ccisen
                    if cciactual > cciprev
                        cciactual = cciprev # to avoid jump in cc
                    end
                    # when GDDCGCadjusted increases as a result of watering
                    gvars[:crop].CCxAdjusted = cciactual
                    if cciactual < ccototal 
                        gvars[:crop].CCoAdjusted = cciactual
                    else
                        gvars[:crop].CCoAdjusted = ccototal 
                    end
                else
                    # in late season
                    if ccisen < cciactual
                        cciactual = ccisen
                    end 
                end 

                if (round(Int, 10000*ccisen) <= (10000*ccdormant)) |
                   (round(Int, 10000*ccisen) <= round(Int, 10000*gvars[:crop].CCo))
                    gvars[:simulation].SumEToStress += eto
                end 
            else
                # no water stress, resulting in canopy senescence
                if (timesenescence > 0) & (sumgddadjcc > gvars[:crop].GDDaysToSenescence)
                    # rewatering in late season of an early declining canopy
                    ccxadjusted, gddcdcadjusted = get_new_ccx_and_gddcdc(cciprev, gddcdctotal, ccxsf, 
                                                                            sumgddadjcc, gddayi,
                                                                            gvars[:crop])
                    gvars[:crop].CCxAdjusted = ccxadjusted
                    cciactual =  canopy_cover_no_stress_sf(
                                virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                gvars[:crop].DaysToGermination, 
                                gvars[:crop].DaysToSenescence, 
                                gvars[:crop].DaysToHarvest, 
                                gvars[:crop].GDDaysToGermination, 
                                gvars[:crop].GDDaysToSenescence, 
                                gvars[:crop].GDDaysToHarvest, 
                                ccototal, 
                                gvars[:crop].CCxAdjusted/(1 - gvars[:simulation].EffectStress.RedCCx/100), 
                                gvars[:crop].CGC, cdctotal, gvars[:crop].GDDCGC, 
                                gddcdcadjusted,sumgddadjcc, 
                                gvars[:crop].ModeCycle, 
                                gvars[:simulation].EffectStress.RedCGC, 
                                gvars[:simulation].EffectStress.RedCCX,
                                gvars[:simulation])
                end 
                timesenescence = 0  # no early senescence or back to normal
                stresssenescence = 0
                gvars[:simulation].SumEToStress = 0
            end 
        end 

        # 5. Adjust Crop.CCxWithered - required for correction
        # of Transpiration of dying green canopy
        if cciactual > gvars[:crop].CCxWithered
            gvars[:crop].CCxWithered = cciactual
        end 

        # 6. correction for late-season stage for rounding off errors
        if sumgddadjcc > gvars[:crop].GDDaysToSenescence
            if cciactual > cciprev
                cciactual = cciprev
            end 
        end 

        # 7. no crop as a result of fertiltiy and/or water stress
        if round(Int, 1000*cciactual) <= 0
            nomorecrop = true
        end 
    end 

    setparameter!(gvars[:float_parameters], :stressleaf, stressleaf)
    setparameter!(gvars[:float_parameters], :stresssenescence, stresssenescence)
    setparameter!(gvars[:float_parameters], :timesenescence, timesenescence)
    setparameter!(gvars[:bool_parameters], :nomorecrop, nomorecrop)
    setparameter!(gvars[:float_parameters], :cciactual, cciactual)
    setparameter!(gvars[:float_parameters], :cciprev, cciprev)
    setparameter!(gvars[:float_parameters], :ccitopearlysen, ccitopearlysen)
    return nothing
end 

"""
    ccx, gddcdc = get_new_ccx_and_gddcdc(cciprev, gddcdc, ccx, 
                                            sumgddadjcc, gddayi,
                                            crop)

simul.f90:3967
"""
function get_new_ccx_and_gddcdc(cciprev, gddcdc, ccx, 
                                sumgddadjcc, gddayi,
                                crop)
    ccxadjusted = cciprev/(1 - 0.05*(exp((sumgddadjcc - gddayi - crop.GDDaysToSenescence) *
                                         gddcdc * 3.33/(ccx+2.29))-1))
    gddcdcadjusted = gddcdc * (ccxadjusted+2.29)/(ccx+2.29)

    return ccxadjusted, gddcdcadjusted
end

"""
    gddcdcadjusted, kssen, stresssenescence = determine_gddcdc_adjusted_water_stress(eto, timesenescence, gddcdctotal, ccxsfcd, ccxtotal,
                                                            root_zone_wc, crop, simulparam, simulation)

simul.f90:3917
"""
function determine_gddcdc_adjusted_water_stress(eto, timesenescence, gddcdctotal, ccxsfcd, ccxtotal,
                        root_zone_wc, crop, simulparam, simulation)
    psenll = 0.999 # WP
    if simulation.SWCtopSoilConsidered
        # top soil is relative wetter than total root zone
        # top soil
        wrelative = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct)/(root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)
    else
        # total root zone
        wrelative = (root_zone_wc.FC - root_zone_wc.Actual)/(root_zone_wc.FC - root_zone_wc.WP)
    end 

    withbeta = false
    psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, crop, simulparam)
    if wrelative <= psenact
        gddcdcadjusted = 0.0001 # extreme small decline
        stresssenescence = 0
        kssen = 1
    elseif wrelative >= psenll
        gddcdcadjusted = gddcdctotal * ((ccxsfcd+2.29)/(ccxtotal+2.29))# full speed
        stresssenescence = 100
        kssen = 0
    else
        kssen = ks_any(wrelative, psenact, psenll, crop.KsShapeFactorSenescence) 
        if kssen > 0.000001
            gddcdcadjusted = gddcdctotal * ((ccxsfcd+2.29)/(ccxtotal+2.29)) * (1 - exp(8*log(kssen)))
            stresssenescence = 100 * (1 - kssen)
        else
            gddcdcadjusted = 0
            stresssenescence = 0
        end 
    end 

    return gddcdcadjusted, kssen, stresssenescence
end

"""
    gddcdcadjusted = get_gddcdc_adjusted_no_stress(ccx, gddcdc, ccxadjusted)

simul.f90:3905
"""
function get_gddcdc_adjusted_no_stress(ccx, gddcdc, ccxadjusted)
    gddcdcadjusted = gddcdc * ((ccxadjusted+2.29)/(ccx+2.29))
    return gddcdcadjusted
end

"""
    ccxadjusted = determine_ccx_adjusted_gdd(cciprev, ccxsf, gddcgcadjusted, gddayi, sumgddadjcc, gddtfinalccx, cco)

simul.f90:3882
"""
function determine_ccx_adjusted_gdd(cciprev, ccxsf, gddcgcadjusted, gddayi, sumgddadjcc, gddtfinalccx, cco)
    # cco = crop.CCoAdjusted

    # 1. find time (GDDtfictive) required to reach CCiPrev
    # (CCi of previous day) with GDDCGCadjusted
    gddtfictive = required_gdd(cciprev, cco, ccxsf, gddcgcadjusted, gddayi, sumgddadjcc)

    # 2. Get CCxadjusted (reached at end of stretched crop development)
    if gddtfictive > 0
        gddtfictive = gddtfictive + (gddtfinalccx - sumgddadjcc) + gddayi
        ccxadjusted = cc_at_gddtime(gddtfictive, cco, gddcgcadjusted, ccxsf)
    else
        ccxadjusted = undef_double # this means CCiActual := CCiPrev
    end 

    return ccxadjusted
end 

"""
    cci = cc_at_gddtime(gddtfictive, ccogiven, gddcgcgiven, ccxgiven)

simul.f90:3863
"""
function cc_at_gddtime(gddtfictive, ccogiven, gddcgcgiven, ccxgiven)

    cci = ccogiven * exp(gddcgcgiven * gddtfictive)
    if cci > ccxgiven/2
        cci = ccxgiven - 0.25 * (ccxgiven/ccogiven) * ccxgiven * exp(-gddcgcgiven*gddtfictive)
    end 
    return cci
end  

"""
    requiredgdd = required_gdd(ccitofind, cco, ccx, gddcgcadjusted, gddayi, sumgddadjcc)

simul.f90:3841
"""
function required_gdd(ccitofind, cco, ccx, gddcgcadjusted, gddayi, sumgddadjcc)
    # only when sumgddadj > gddayi
    # and ccx < ccitofind
    # 1. gddcgcx to reach ccitofind on previous day (= sumgddadj - gddayi )
    if ccitofind <= ccx/2
        gddcgcx = (log(ccitofind/cco))/(sumgddadjcc-gddayi)
    else
        gddcgcx = (log((0.25*ccx*ccx/cco)/(ccx-ccitofind)))/(sumgddadjcc-gddayi)
    end 
    # 2. required gdd
    requiredgdd = (sumgddadjcc-gddayi) * gddcgcx/gddcgcadjusted

    return requiredgdd
end  

"""
    gddcgcadjusted, stressleaf = determine_gddcgc_adjusted(cgcgddsf, pleafllact, 
                                                           root_zone_wc, crop, simulation)

simul.f90:3788
"""
function  determine_gddcgc_adjusted(cgcgddsf, pleafllact, 
                                    root_zone_wc, crop, simulation)

    # determine FC and PWP
    if simulation.SWCtopSoilConsidered
        # top soil is relative wetter than total root zone
        swceffectiverootzone = root_zone_wc.ZtopAct
        wrelative = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct)/(root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)# top soil
        fceffectiverootzone = root_zone_wc.ZtopFC
        wpeffectiverootzone = root_zone_wc.ZtopWP
    else
        swceffectiverootzone = root_zone_wc.Actual
        wrelative = (root_zone_wc.FC - root_zone_wc.Actual)/(root_zone_wc.FC - root_zone_wc.WP)# total root zone
        fceffectiverootzone = root_zone_wc.FC
        wpeffectiverootzone = root_zone_wc.WP
    end 

    # Canopy stress and effect of water stress on CGCGDD
    if swceffectiverootzone >= fceffectiverootzone
        gddcgcadjusted = cgcgddsf
        stressleaf = 0
    else
        if swceffectiverootzone <= wpeffectiverootzone
            gddcgcadjusted = 0
            stressleaf = 100
        else
            if wrelative <= crop.pLeafAct
                gddcgcadjusted = cgcgddsf
                stressleaf = 0
            elseif wrelative >= pleafllact
                gddcgcadjusted = 0
                stressleaf = 100
            else
                ksleaf = ks_any(wrelative, crop.pLeafAct, pleafllact, crop.KsShapeFactorLeaf)
                gddcgcadjusted = cgcgddsf * ksleaf
                stressleaf = 100 * (1 - ksleaf)
            end 
        end 
    end 

    return gddcgcadjusted, stressleaf
end

"""
    pleafulact, pleafllact = adjust_pleaf_to_eto(etomean, crop, simulparam)

simul.f90:424
"""
function adjust_pleaf_to_eto(etomean, crop, simulparam)
    pleafllact = crop.pLeafDefLL
    pleafulact = crop.pLeafDefUL
    if crop.pMethod == :FAOCorrection
        pleafllact = crop.pLeafDefLL + simulparam.pAdjFAO * 0.04 * 
                        (5-etomean)*log10(10-9*crop.pLeafDefLL)
        if pleafllact > 1
            pleafllact = 1
        end 
        if pleafllact < 0
            pleafllact = 0
        end 
        pleafulact = crop.pLeafDefUL + simulparam.pAdjFAO * 0.04 *
                     (5-etomean)*log10(10-9*crop.pLeafDefUL)
        if pleafulact > 1
            pleafulact = 1
        end 
        if pleafulact < 0
            pleafulact = 0
        end 
    end 

    return pleafulact, pleafllact
end

"""
    psenact = adjust_psenescence_to_eto(etomean, timesenescence, withbeta, crop, simulparam)

simul.f90:1106
"""
function adjust_psenescence_to_eto(etomean, timesenescence, withbeta, crop, simulparam)
    psenact = crop.pSenescence
    if crop.pMethod == :FAOCorrection
        psenact = crop.pSenescence + simulparam.pAdjFAO * 0.04*(5-etomean) * log10(10-9*crop.pSenescence)
        if (timesenescence > 0.0001) & withbeta
            psenact = psenact * (1-simulparam.Beta/100)
        end 
        if psenact < 0
            psenact = 0
        end 
        if psenact >= 1
            psenact = 0.98 # otherwise senescence is not possible at wp
        end 
    end 

    return psenact
end

"""
    determine_cci!(gvars, ccxtotal, ccototal, fracassim, 
                            mobilizationon, storageon, tadj, virtualtimecc, 
                            cdctotal, dayfraction, 
                            gddcdctotal)

simul.f90:4611
"""
function determine_cci!(gvars, ccxtotal, ccototal, fracassim, 
                        mobilizationon, storageon, tadj, virtualtimecc, 
                        cdctotal, dayfraction, 
                        gddcdctotal)
    stressleaf = gvars[:float_parameters][:stressleaf]
    stresssenescence = gvars[:float_parameters][:stresssenescence]
    timesenescence = gvars[:float_parameters][:timesenescence]
    nomorecrop = gvars[:float_parameters][:nomorecrop]
    cciactual = gvars[:float_parameters][:cciactual]
    cciprev = gvars[:float_parameters][:cciprev]
    ccitopearlysen = gvars[:float_parameters][:ccitopearlysen]

    eto = gvars[:float_parameters][:eto]

    ccdormant = 0.05
    # DetermineCCi
    if (virtualtimecc < gvars[:crop].DaysToGermination) &
       (virtualtimecc > (gvars[:crop].DayN - gvars[:crop].Day1))
        cciactual = 0
    else
        # growing season (once germinated)
        # 1. find some parameters
        cgcsf = gvars[:crop].CGC * (1 - gvars[:simulation].EffectStress.RedCGC/100)
        cgcadjusted = cgcsf
        ccxsf = ccxtotal * (1 - gvars[:simulation].EffectStress.RedCCX/100)

        # maximum canopy cover than can be reached
        # (considering soil fertility/salinity, weed stress)
        if virtualtimecc <= gvars[:crop].DaysToFullCanopySF
            ccxsfcd = ccxsf # no correction before maximum canopy is reached
        else
            if virtualtimecc < gvars[:crop].DaysToSenescence
                ccxsfcd = cci_no_water_stress_sf(
                            virtualtimecc + gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToFullCanopySF, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToFullCanopySF, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, 
                            gvars[:crop].GDDCGC, cdctotal, gddcdctotal, 
                            gvars[:simulation].SumGDD, 1, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX, 
                            gvars[:simulation].EffectStress.CDecline, 
                            gvars[:crop].ModeCycle,
                            gvars[:simulation])
            else
                ccxsfcd = ccxsf -
                          (gvars[:simulation].EffectStress.CDecline/100) *
                          (gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopySF)
            end 
            if ccxsfcd < 0
                ccxsfcd = 0
            end 
        end 
        stressleaf = undef_double #undef_int
        if virtualtimecc == gvars[:crop].DaysToGermination
            cciprev = ccototal
        end 

        # time of potentional vegetative growth
        tfinalccx = gvars[:crop].DaysToSenescence # undeterminant crop
        if (gvars[:crop].subkind == :Grain) &
           (gvars[:crop].DeterminancyLinked)
            # determinant crop
            # reduce tFinalCC in f(determinancy of crop)
            if gvars[:crop].DaysToCCini != 0
                # regrowth  (adjust to slower time)
                tfinalccx = gvars[:crop].DaysToFullCanopy +
                            round(Int, dayfraction *
                                 ((gvars[:crop].DaysToFlowering + (gvars[:crop].LengthFlowering/2) -
                                   gvars[:simulation].DelayedDays) + tadj + gvars[:crop].DaysToGermination -
                                   gvars[:crop].DaysToFullCanopy))
            else
                # sown or transplant
                tfinalccx = gvars[:crop].DaysToFlowering + round(Int, gvars[:crop].LengthFlowering/2)
            end 
            if tfinalccx > gvars[:crop].DaysToSenescence
                tfinalccx = gvars[:crop].DaysToSenescence
            end 
        end 

        # Crop.pLeafAct and Crop.pSenAct for
        # plotting root zone depletion in RUN
        pleafulact, pleafllact = adjust_pleaf_to_eto(eto, gvars[:crop], gvars[:simulparam])
        gvars[:crop].pLeafAct = pleafulact
        withbeta = true
        psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, gvars[:crop], gvars[:simulparam])

        # 2. Canopy can still develop (stretched to tFinalCCx)
        if virtualtimecc < tfinalccx
            # Canopy can stil develop (stretched to tFinalCCx)
            if (cciprev <= gvars[:crop].CCoAdjusted) | (virtualtimecc <= 1) |
               (gvars[:simulation].ProtectedSeedling & (cciprev <= (1.25 * ccototal)))
                # 2.a first day or very small CC as a result of senescence
                # (no adjustment for leaf stress)
                if gvars[:simulation].ProtectedSeedling
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, 
                            cdctotal, gvars[:crop].GDDCGC, gddcdctotal, 
                            gvars[:simulation].SumGDD, gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                    if cciactual > (1.25 * ccototal)
                        gvars[:simulation].ProtectedSeedling = false
                    end 
                else
                    # this results in CC increase when during senescence CC
                    # becomes smaller than CCini)
                    if virtualtimecc == 1
                        cciactual = gvars[:crop].CCoAdjusted * exp(cgcsf*2)
                    else
                        cciactual = gvars[:crop].CCoAdjusted * exp(cgcsf*1)
                    end 
                end 

                # 2.b CC > CCo
            else
                if cciprev < 0.97999*ccxsf
                    cgcadjusted, stressleaf = determine_cgc_adjusted(cgcsf, pleafllact, 
                                                                        gvars[:root_zone_wc],
                                                                        gvars[:crop], 
                                                                        gvars[:simulation])
                    if cgcadjusted > 0.00000001
                        # CGCSF or CGCadjusted > 0
                        ccxadjusted = determine_ccx_adjusted_cdc(cciprev, virtualtimecc, 
                                                            cgcadjusted, ccxsf, tfinalccx, 
                                                            gvars[:crop])
                        gvars[:crop].CCxAdjusted = ccxadjusted
                        if gvars[:crop].CCxAdjusted < 0
                            cciactual = cciprev
                        elseif abs(cciprev - 0.97999*ccxsf) < 0.001
                            cciactual = canopy_cover_no_stress_sf(
                                virtualtimecc+gvars[:simulation].DelayedDays+1, 
                                gvars[:crop].DaysToGermination, 
                                gvars[:crop].DaysToSenescence, 
                                gvars[:crop].DaysToHarvest, 
                                gvars[:crop].GDDaysToGermination, 
                                gvars[:crop].GDDaysToSenescence, 
                                gvars[:crop].GDDaysToHarvest, 
                                ccototal, ccxtotal, gvars[:crop].CGC, 
                                cdctotal, gvars[:crop].GDDCGC, gddcdctotal, 
                                gvars[:simulation].SumGDD, gvars[:crop].ModeCycle, 
                                gvars[:simulation].EffectStress.RedCGC, 
                                gvars[:simulation].EffectStress.RedCCX,
                                gvars[:simulation])
                        else
                            ttemp = required_time_new(cciprev, 
                                                    gvars[:crop].CCoAdjusted, 
                                                    gvars[:crop].CCxAdjusted, 
                                                    cgcadjusted,
                                                    virtualtimecc)
                            if ttemp < 0
                                cciactual = cciprev
                            else
                                ttemp = ttemp + 1
                                cciactual = cc_at_time(
                                        ttemp, gvars[:crop].CCoAdjusted, cgcadjusted, 
                                        gvars[:crop].CCxAdjusted)
                            end 
                        end 
                    else
                        # CGCadjusted = 0 - too dry for leaf expansion
                        cciactual = cciprev
                        if cciactual > gvars[:crop].CCoAdjusted
                            gvars[:crop].CCoAdjusted = ccototal
                        else
                            gvars[:crop].CCoAdjusted = cciactual
                        end 
                    end 
                else
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, cdctotal, 
                            gvars[:crop].GDDCGC, gddcdctotal, 
                            gvars[:simulation].SumGDD, gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                    gvars[:crop].CCoAdjusted = ccototal
                    stressleaf = -33 # maximum canopy is reached;
                    # no increase anymore of CGC after cutting
                end 
                if cciactual > ccxsfcd
                    cciactual = ccxsfcd
                    stressleaf = -33 # maximum canopy is reached;
                    # no increase anymore of CGC after cutting
                end 
            end 
            gvars[:crop].CCxAdjusted = cciactual

            # 3. Canopy can no longer develop (Mid-season (from tFinalCCx) or Late season stage)
        else
            stressleaf = -33 # maximum canopy is reached;
            if gvars[:crop].CCxAdjusted < 0
                gvars[:crop].CCxAdjusted = cciprev
            end 

            if virtualtimecc < gvars[:crop].DaysToSenescence # mid-season
                if gvars[:crop].CCxAdjusted > 0.97999*ccxsf
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, ccxtotal, gvars[:crop].CGC, 
                            cdctotal, gvars[:crop].GDDCGC, gddcdctotal, 
                            gvars[:simulation].SumGDD, gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                    gvars[:crop].CCxAdjusted = cciactual
                else
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, 
                            gvars[:crop].CCxAdjusted/(1 - gvars[:simulation].EffectStress.RedCCx/100), 
                            gvars[:crop].CGC, cdctotal, gvars[:crop].GDDCGC, 
                            gddcdctotal, gvars[:simulation].SumGDD, 
                            gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                end 
                if cciactual > ccxsfcd
                    cciactual = ccxsfcd
                end 
                # late season
            else
                stresssenescence = undef_double # undef_int
                # to avoid display of zero stress in late season
                if gvars[:crop].CCxAdjusted > ccxsfcd
                    gvars[:crop].CCxAdjusted = ccxsfcd
                end 
                if gvars[:crop].CCxAdjusted < 0.01
                    cciactual = 0
                else
                    # calculate CC in late season
                    # CCibis = CC which canopy declines
                    # (soil fertility/salinity stress) further in late season
                    ccibis = ccxsf - (gvars[:simulation].EffectStress.CDecline/100) *
                             (exp(2 * log((virtualtimecc+gvars[:simulation].DelayedDays+1) -
                                  gvars[:crop].DaysToFullCanopySF))/(gvars[:crop].DaysToSenescence -
                                  gvars[:crop].DaysToFullCanopySF))
                    if ccibis < 0
                        cciactual = 0
                    else
                        # CCiActual = CC with natural senescence in late season
                        cdcadjusted = get_cdc_adjusted_no_stress_new(ccxtotal,
                                                                    cdctotal,
                                                                    gvars[:crop].CCxAdjusted)
                        if (virtualtimecc+gvars[:simulation].DelayedDays+1) < (gvars[:crop].DaysToSenescence + 
                            length_canopy_decline(gvars[:crop].CCxAdjusted, cdcadjusted))
                            cciactual = gvars[:crop].CCxAdjusted *
                                        (1 - 0.05 * (exp(((virtualtimecc+gvars[:simulation].DelayedDays+1) -
                                                          gvars[:crop].DaysToSenescence)*3.33 * cdcadjusted /
                                                         (gvars[:crop].CCxAdjusted + 2.29))- 1))
                            # CCiActual becomes CCibis, when canopy decline is more severe
                            if ccibis < cciactual
                                cciactual = ccibis
                            end 
                        else
                            cciactual = 0
                        end 
                    end 
                    # late season
                end 
                # 3. Canopy can no longer develop
                # (Mid-season (from tFinalCCx) or Late season stage)
            end 
        end 

        # 4. Canopy senescence due to water stress ?
        # not yet late season stage
        if (virtualtimecc < gvars[:crop].DaysToSenescence) |
           (timesenescence > 0)
            # in late season with ongoing early senesence
            # (TimeSenescence in days)
            stresssenescence = 0
            withbeta = true
            psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, 
                                                gvars[:crop], gvars[:simulparam])
            gvars[:crop].pSenAct = psenact
            ksred = 1  # effect of soil salinity on the
                       # threshold for senescence
            if gvars[:simulation].SWCtopSoilConsidered
                # top soil is relative wetter than total root zone
                if (gvars[:root_zone_wc].ZtopAct <
                    (gvars[:root_zone_wc].ZtopFC - gvars[:crop].pSenAct*ksred *
                    (gvars[:root_zone_wc].ZtopFC - gvars[:root_zone_wc].ZtopWP))) &
                   (! gvars[:simulation].ProtectedSeedling)
                    thesenescenceon = true
                else
                    thesenescenceon = false
                end 
            else
                if (gvars[:root_zone_wc].Actual <
                    (gvars[:root_zone_wc].FC - gvars[:crop].pSenAct*ksred *
                    (gvars[:root_zone_wc].FC - gvars[:root_zone_wc].WP))) &
                   (! gvars[:simulation].ProtectedSeedling)
                    thesenescenceon = true
                else
                    thesenescenceon = false
                end 
            end 

            if thesenescenceon
                # CanopySenescence
                gvars[:simulation].EvapLimitON = true
                # consider withered crop when not yet in late season
                if abs(timesenescence) < eps()
                    ccitopearlysen = cciactual
                    # CC before canopy decline
                end 
                timesenescence = timesenescence + 1  # add 1 day
                cdcadjusted, kssen, stresssenescence = determine_cdc_adjusted_water_stress(
                                                                eto, timesenescence, cdctotal, ccxsfcd, ccxtotal,
                                                                gvars[:root_zone_wc], gvars[:crop],
                                                                gvars[:simulparam], gvars[:simulation])
                if ccitopearlysen < 0.001
                    if (gvars[:simulation].SumEToStress > gvars[:crop].SumEToDelaySenescence) |
                       (abs(gvars[:crop].SumEToDelaySenescence) < eps())
                        ccisen = 0 # no crop anymore
                    else
                        if ccdormant > gvars[:crop].CCo
                            ccisen = gvars[:crop].CCo +
                                     (1 - gvars[:simulation].SumEToStress/gvars[:crop].SumEToDelaySenescence) *
                                     (ccdormant - gvars[:crop].CCo)
                        else
                            ccisen = gvars[:crop].CCo
                        end 
                    end 
                else
                    # e power too large and in any case CCisen << 0
                    if (timesenescence*cdctotal*3.33/(ccitopearlysen+2.29) > 100) |
                       (cciprev >= 1.05 * ccitopearlysen)
                                # Ln of negative or zero value
                        if (gvars[:simulation].SumEToStress > gvars[:crop].SumEToDelaySenescence) |
                           (abs(gvars[:crop].SumEToDelaySenescence) < eps())
                            ccisen = 0 # no crop anymore
                        else
                            if ccdormant > gvars[:crop].CCo
                                ccisen = gvars[:crop].CCo +
                                         (1 - gvars[:simulation].SumEToStress/gvars[:crop].SumEToDelaySenescence) *
                                         (ccdormant - gvars[:crop].CCo)
                            else
                                ccisen = gvars[:crop].CCo
                            end 
                        end 
                    else
                        # CDC is adjusted to degree of stress
                        # time required to reach CCiprev with CDCadjusted
                        if ccitopearlysen == 0
                            ccitopearlysen = eps()
                        end 
                        if cdcadjusted == 0
                            cdcadjusted = eps()
                        end 
                        ttemp = (log(1 + (1 - cciprev/ccitopearlysen)/0.05)) /
                                (cdcadjusted*3.33/(ccitopearlysen+2.29))
                        # add 1 day to tTemp and calculate CCiSen
                        # with CDCadjusted
                        ccisen = ccitopearlysen*(1-0.05*(exp((ttemp+1)*cdcadjusted*
                                                             3.33/(ccitopearlysen+2.29))-1))
                    end 

                    if ccisen < 0
                        ccisen = 0
                    end 
                    if (gvars[:crop].SumEToDelaySenescence > 0) &
                       (gvars[:simulation].SumEToStress <= gvars[:crop].SumEToDelaySenescence)
                        if (ccisen < gvars[:crop].CCo) | (ccisen < ccdormant)
                            if ccdormant > gvars[:crop].CCo
                                ccisen = gvars[:crop].CCo +
                                         (1 - gvars[:simulation].SumEToStress/gvars[:crop].SumEToDelaySenescence) *
                                         (ccdormant - gvars[:crop].CCo)
                            else
                                ccisen = gvars[:crop].CCo
                            end 
                        end 
                    end 
                end 
                if virtualtimecc < gvars[:crop].DaysToSenescence
                    # before late season
                    if ccisen > ccxsfcd
                        ccisen = ccxsfcd
                    end 
                    cciactual = ccisen
                    if cciactual > cciprev
                        cciactual = cciprev
                        # to avoid jump in CC
                    end 
                    # when CGCadjusted increases as a result of watering
                    gvars[:crop].CCxAdjusted = cciactual
                    if cciactual < ccototal
                        gvars[:crop].CCoAdjusted = cciactual
                    else
                        gvars[:crop].CCoAdjusted = ccototal
                    end 
                else
                    # in late season
                    if ccisen < cciactual
                        cciactual = ccisen
                    end 
                end 

                if (round(Int, 10000*ccisen) <= (10000*ccdormant)) |
                   (round(Int, 10000*ccisen) <= round(Int, 10000*gvars[:crop].CCo))
                    gvars[:simulation].SumEToStress += eto 
                end 
            else
                # no water stress, resulting in canopy senescence
                timesenescence = 0
                # No early senescence or back to normal
                stresssenescence = 0
                gvars[:simulation].SumEToStress = 0 
                if (virtualtimecc > gvars[:crop].DaysToSenescence) &
                   (cciactual > cciprev)
                    # result of a rewatering in late season of
                    # an early declining canopy
                    get_new_ccx_and_cdc
                    ccxadjusted, cdcadjusted = get_new_ccx_and_cdc(cciprev, cdctotal,
                                                                   ccxsf, virtualtimecc, 
                                                                   gvars[:crop])
                    gvars[:crop].CCxAdjusted = ccxadjusted
                    cciactual = canopy_cover_no_stress_sf(
                            virtualtimecc+gvars[:simulation].DelayedDays+1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, 
                            gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, 
                            gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest, 
                            ccototal, 
                            gvars[:crop].CCxAdjusted/(1 - gvars[:simulation].EffectStress.RedCCx/100), 
                            gvars[:crop].CGC, cdcadjusted, 
                            gvars[:crop].GDDCGC, gddcdctotal, 
                            gvars[:simulation].SumGDD, gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
                end 
            end 
        end 

        # 5. Adjust GetCrop().CCxWithered - required for correction
        # of Transpiration of dying green canopy
        if cciactual > gvars[:crop].CCxWithered
            gvars[:crop].CCxWithered = cciactual
        end 

        # 6. correction for late-season stage for rounding off errors
        if virtualtimecc > gvars[:crop].DaysToSenescence
            if cciactual > cciprev
                cciactual = cciprev
            end 
        end 

        # 7. no crop as a result of fertiltiy and/or water stress
        if round(Int, 1000*cciactual) <= 0
            nomorecrop = true
        end 
    end 

    setparameter!(gvars[:float_parameters], :stressleaf, stressleaf)
    setparameter!(gvars[:float_parameters], :stresssenescence, stresssenescence)
    setparameter!(gvars[:float_parameters], :timesenescence, timesenescence)
    setparameter!(gvars[:float_parameters], :nomorecrop, nomorecrop)
    setparameter!(gvars[:float_parameters], :cciactual, cciactual)
    setparameter!(gvars[:float_parameters], :cciprev, cciprev)
    setparameter!(gvars[:float_parameters], :ccitopearlysen, ccitopearlysen)
    return nothing
end 

"""
    ccxadjusted, cdcadjusted = get_new_ccx_and_cdc(cciprev, cdc, ccx, virtualtimecc, crop)

simul.f90:5331
"""
function get_new_ccx_and_cdc(cciprev, cdc, ccx, virtualtimecc, crop)
    ccxadjusted = cciprev/(1 - 0.05 * (exp((virtualtimecc-crop.DaysToSenescence) *
                                           cdc*3.33/(ccx+2.29))-1))
    # cdcadjusted := cdc * ccxadjusted/ccx;
    cdcadjusted = cdc * (ccxadjusted+2.29)/(ccx+2.29)
    return ccxadjusted, cdcadjusted
end 

"""
    ccxadjusted = determine_ccx_adjusted_cdc(cciprev, virtualtimecc, cgcadjusted, ccxsf, tfinalccx, crop)

simul.f90:5310
"""
function determine_ccx_adjusted_cdc(cciprev, virtualtimecc, cgcadjusted, ccxsf, tfinalccx, crop)
    # 1. find time (tfictive) required to reach cciprev
    #    (cci of previous day) with cgcadjusted
    tfictive = required_time_new(cciprev, crop.CCoAdjusted, ccxsf, cgcadjusted, virtualtimecc)

    # 2. Get CCxadjusted (reached at end of stretched crop development)
    if tfictive > 0
        tfictive = tfictive + (tfinalccx - virtualtimecc)
        ccxadjusted = cc_at_time(tfictive, crop.CCoAdjusted, cgcadjusted, ccxsf)
    else
        ccxadjusted = undef_double # this means cciactual := cciprev
    end 

    return ccxadjusted
end

"""
    t = required_time_new(ccitofind, cco, ccx, cgcadjusted, virtualtimecc)

simul.f90:5270
"""
function required_time_new(ccitofind, cco, ccx, cgcadjusted, virtualtimecc)
    # only when virtualtime > 1
    # and ccx < ccitofind
    # 1. cgcx to reach ccitofind on previous day (= virtualtime -1 )
    if ccitofind <= ccx/2
        cgcx = (log(ccitofind/cco))/virtualtimecc
    else
        cgcx = (log((0.25*ccx*ccx/cco)/(ccx-ccitofind)))/virtualtimecc
    end 
    # 2. required time
    t = virtualtimecc * cgcx/cgcadjusted
    return t
end

"""
    cdcadjusted, kssen, stresssenescence = determine_cdc_adjusted_water_stress(eto, timesenescence, cdctotal, ccxsfcd, ccxtotal,
                                                                               root_zone_wc, crop, simulparam, simulation)

simul.f90:5222
"""
function determine_cdc_adjusted_water_stress(eto, timesenescence, cdctotal, ccxsfcd, ccxtotal,
                                             root_zone_wc, crop, simulparam, simulation)
    psenll = 0.999 # WP
    if simulation.SWCtopSoilConsidered
    # top soil is relative wetter than total root zone
        wrelative = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct) /
                    (root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)# top soil
    else
        wrelative = (root_zone_wc.FC - root_zone_wc.Actual) /
                    (root_zone_wc.FC - root_zone_wc.WP) # total root zone
    end 
    withbeta = false
    psenact = adjust_psenescence_to_eto(eto, timesenescence, withbeta, crop, simulparam)
    if wrelative <= psenact
        cdcadjusted = 0.001 # extreme small decline
        stresssenescence = 0
        kssen = 1
    elseif wrelative >= psenll
        cdcadjusted = cdctotal * (ccxsfcd+2.29)/(ccxtotal+2.29)# full speed
        stresssenescence = 100
        kssen = 0
    else
        kssen = ks_any(wrelative, psenact, psenll, crop.KsShapeFactorSenescence)
        if kssen > 0.000001
            cdcadjusted = cdctotal * ((ccxsfcd+2.29)/(ccxtotal+2.29)) * (1 - exp(8*log(kssen)))
            stresssenescence = 100 * (1 - kssen)
        else
            cdcadjusted = 0
            stresssenescence = 0
        end 
    end 

    return cdcadjusted, kssen, stresssenescence
end

"""
    cgcadjusted, stressleaf = determine_cgc_adjusted(cgcsf, pleafllact, 
                                                     root_zone_wc, crop, simulation)
simul.f90:5171
"""
function determine_cgc_adjusted(cgcsf, pleafllact, 
                                root_zone_wc, crop, simulation)
    # determine FC and PWP
    if simulation.SWCtopSoilConsidered
        # top soil is relative wetter than total root zone
        swceffectiverootzone = root_zone_wc.ZtopAct
        wrelative = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct) /
                    (root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)
        fceffectiverootzone = root_zone_wc.ZtopFC
        wpeffectiverootzone = root_zone_wc.ZtopWP
    else
        # total rootzone is wetter than top soil
        swceffectiverootzone = root_zone_wc.Actual
        wrelative = (root_zone_wc.FC - root_zone_wc.Actual) /
                    (root_zone_wc.FC - root_zone_wc.WP)
        fceffectiverootzone = root_zone_wc.FC
        wpeffectiverootzone = root_zone_wc.WP
    end 

    # Canopy stress and effect of soil water stress on CGC
    if swceffectiverootzone >= fceffectiverootzone
        cgcadjusted = cgcsf
        stressleaf = 0
    elseif swceffectiverootzone <= wpeffectiverootzone
        cgcadjusted = 0.
        stressleaf = 100
    else
        if wrelative <= crop.pLeafAct
            cgcadjusted = cgcsf
            stressleaf = 0
        elseif wrelative >= pleafllact
            cgcadjusted = 0
            stressleaf = 100
        else
            ksleaf = ks_any(wrelative, crop.pLeafAct, pleafllact, crop.KsShapeFactorLeaf)
            cgcadjusted = cgcsf * ksleaf
            stressleaf = 100 * (1 - ksleaf)
        end 
    end 

    return cgcadjusted, stressleaf
end

"""
    cdcadjusted = get_cdc_adjusted_no_stress_new(ccx, cdc, ccxadjusted)

simul.f90:412
"""
function get_cdc_adjusted_no_stress_new(ccx, cdc, ccxadjusted)
    cdcadjusted = cdc * ((ccxadjusted+2.29)/(ccx+2.29))
    return cdcadjusted
end

"""
    pstomatulact = adjust_pstomatal_to_eto(meaneto, crop, simulparam)

simul.f90:1084
"""
function adjust_pstomatal_to_eto(meaneto, crop, simulparam)
    if crop.pMethod == :NoCorrection
            pstomatulact = crop.pdef
    elseif crop.pMethod == :FAOCorrection
         pstomatulact = crop.pdef + simulparam.pAdjFAO * (0.04 *(5-meaneto))*log10(10-9*crop.pdef)
    end 
    if pstomatulact > 1
        pstomatulact = 1
    end 
    if pstomatulact < 0
        pstomatulact = 0
    end 

    return pstomatulact
end

"""
    prepare_stage1!(gvars)

simul.f90:4140
"""
function prepare_stage1!(gvars)
    soil = gvars[:soil]
    simulation = gvars[:simulation]

    if gvars[:float_parameters][:surfacestorage] > 0.0000001
        simulation.EvapWCsurf = soil.REW
    else
        simulation.EvapWCsurf = gvars[:float_parameters][:rain] + 
                                gvars[:float_parameters][:irrigation] +
                                gvars[:float_parameters][:runoff] 
        if simulation.EvapWCsurf > soil.REW
            simulation.EvapWCsurf = soil.REW
        end 
    end 
    simulation.EvapStartStg2 = undef_int
    simulation.EvapZ = EvapZmin/100
    return nothing
end

"""
    wx = wc_evap_layer(zlayer, attheta, compartments, soil_layers)

simul.f90:4158
"""
function wc_evap_layer(zlayer, attheta, compartments, soil_layers)
    wx = 0
    ztot = 0
    compi = 0
    while (abs(zlayer-ztot) > 0.0001) & (compi < length(compartments))
        compi = compi + 1
        layeri = compartments[compi].Layer
        if (ztot + compartments[compi].Thickness) > zlayer
            fracz = (zlayer - ztot)/(compartments[compi].Thickness)
        else
            fracz = 1
        end 
        if attheta == :AtSat
            wx = wx + 10 * soil_layers[layeri].SAT * fracz * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
        elseif attheta == :AtFC
            wx = wx + 10 * soil_layers[layeri].FC * fracz * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
        elseif attheta == :AtWP
            wx = wx + 10 * soil_layers[layeri].WP * fracz * compartments[compi].Thickness *
                      (1 - soil_layers[layeri].GravelVol/100)
        else
            wx = wx + 1000 * compartments[compi].Theta * fracz *
                    compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100)
        end 
        ztot = ztot + fracz * compartments[compi].Thickness
    end 
    return wx
end 

"""
    prepare_stage2!(gvars)

simul.f90:4212
"""
function prepare_stage2!(gvars)
    simulation = gvars[:simulation]
    soil = gvars[:soil]
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]

    simulation.EvapZ = EvapZmin/100
    attheta = :AtSat
    wsat = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
    attheta = :AtFC
    wfc = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
    attheta = :AtAct
    wact = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)

    if (wact - (wfc-soil.REW)) <= eps()
        evapstartstg2 = 0
    else
        evapstartstg2 = round(Int, 100 * (wact - (wfc-soil.REW))/(wsat - (wfc-soil.REW)))
    end 
    simulation.EvapStartStg2 = evapstartstg2

    return nothing
end

"""
    adjust_epot_mulch_wetted_surface!(gvars)

simul.f90:4260
"""
function adjust_epot_mulch_wetted_surface!(gvars)
    dayi = gvars[:integer_parameters][:daynri]
    epottot = gvars[:float_parameters][:epot]
    surfacestorage = gvars[:float_parameters][:surfacestorage]
    rain = gvars[:float_parameters][:rain]
    irrigation = gvars[:float_parameters][:irrigation]
    management = gvars[:management]
    simulparam = gvars[:simulparam]
    crop = gvars[:crop]
    evapwcsurface = gvars[:simulation].EvapWCsurf

    # 1. Mulches (reduction of EpotTot to Epot)
    if surfacestorage <= 0.000001
        if dayi < crop.Day1 # before season
            epot = epottot * (1 - (management.EffectMulchOffS/100)*(management.SoilCoverBefore/100))
        else
            if dayi < crop.Day1+crop.DaysToHarvest # in season
                epot = epottot * (1  - (management.EffectMulchInS/100) * (management.Mulch/100))
            else
                epot = epottot * (1 - (management.EffectMulchOffS/100) * (management.SoilCoverAfter/100))
            end 
        end 
    else
        epot = epottot # flooded soil surface
    end 

    # 2a. Entire soil surface wetted ?
    if irrigation > 0
        # before season
        if (dayi < crop.Day1) & (simulparam.IrriFwOffSeason < 100)
            setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, false)
        end 
        # in season
        if (dayi >= crop.Day1) &
           (dayi < crop.Day1+crop.DaysToHarvest) &
           (simulparam.IrriFwInSeason < 100)
            setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, false)
        end 
        # after season
        if (dayi >= crop.Day1+crop.DaysToHarvest) & (simulparam.IrriFwOffSeason < 100)
            setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, false)
        end 
    end 
    if (rain > 1) | (surfacestorage > 0)
        setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true)
    end 
    if (dayi >= crop.Day1) &
       (dayi < crop.Day1+crop.DaysToHarvest) &
       (gvars[:symbol_parameters][:irrimode] == :Inet)
        setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true)
    end 

    # 2b. Correction for Wetted surface by Irrigation
        if !gvars[:bool_parameters][:evapo_entire_soil_surface]
        if (dayi >= crop.Day1) & (dayi < (crop.Day1+crop.DaysToHarvest)) 
            # in season
            evapwcsurface = evapwcsurface * (simulparam.IrriFwInSeason/100)
            epotirri = epottot * (simulparam.IrriFwInSeason/100)
        else
            # off-season
            evapwcsurface = evapwcsurface * (simulparam.IrriFwOffSeason/100)
            epotirri = epottot * (simulparam.IrriFwOffSeason/100)
        end 
        if gvars[:float_parameters][:eact] > epotirri
            epotirri = gvars[:float_parameters][:eact]  # eact refers to the previous day
        end 
        if epotirri < epot
            epot = epotirri
        end 
    end 
    
    gvars[:simulation].EvapWCsurf = evapwcsurface
    setparameter!(gvars[:float_parameters], :epot, epot)
    return nothing
end

"""
    calculate_evaporation_surface_water!(gvars)

simul.f90:4236
"""
function calculate_evaporation_surface_water!(gvars)
    if gvars[:float_parameters][:surfacestorage] > gvars[:float_parameters][:epot]
        saltsurface = gvars[:float_parameters][:surfacestorage]*gvars[:float_parameters][:ecstorage]*equiv
        setparameter!(gvars[:float_parameters], :eact, gvars[:float_parameters][:epot])
        setparameter!(gvars[:float_parameters], :surfacestorage, gvars[:float_parameters][:surfacestorage] - gvars[:float_parameters][:eact])
        # salinisation of surface storage layer
        setparameter!(gvars[:float_parameters], :ecstorage, saltsurface/(gvars[:float_parameters][:surfacestorage]*equiv))
    else
        setparameter!(gvars[:float_parameters], :eact, gvars[:float_parameters][:surfacestorage])
        setparameter!(gvars[:float_parameters], :surfacestorage, 0.0) 
        gvars[:simulation].EvapWCsurf = gvars[:soil].REW
        gvars[:simulation].EvapZ = EvapZmin/100
        if gvars[:simulation].EvapWCsurf < 0.0001
            prepare_stage2!(gvars)
        else
            gvars[:simulation].EvapStartStg2 = undef_int
        end 
    end 
    return nothing
end

"""
    calculate_soil_evaporation_stage1!(gvars)

simul.f90:4439
"""
function calculate_soil_evaporation_stage1!(gvars)
    stg1 = true
    eremaining = gvars[:float_parameters][:epot] - gvars[:float_parameters][:eact]
    if gvars[:simulation].EvapWCsurf > eremaining
        extract_water_from_evap_layer!(gvars, eremaining, EvapZmin, stg1)
    else
        extract_water_from_evap_layer!(gvars, gvars[:simulation].EvapWCsurf, EvapZmin, stg1)
    end 
    if gvars[:simulation].EvapWCsurf < 0.0000001
        prepare_stage2!(gvars)
    end 
    return nothing
end

"""
    extract_water_from_evap_layer!(gvars, evaptolose, zact, stg1)

simul.f90:4377
"""
function extract_water_from_evap_layer!(gvars, evaptolose, zact, stg1)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulation = gvars[:simulation]

    evaplost = 0
    compi = 0
    ztot = 0
    loopi = true
    while loopi
        compi = compi + 1
        layeri = compartments[compi].Layer
        if (ztot + compartments[compi].Thickness) > zact
            fracz = (zact-ztot)/compartments[compi].Thickness
        else
            fracz = 1
        end 
        wairdry = 10 *
                  soil_layers[layeri].WP/2 *
                  compartments[compi].Thickness *
                  (1 - soil_layers[layeri].GravelVol/100)
        wx = 1000 * compartments[compi].Theta *
             compartments[compi].Thickness *
             (1 - soil_layers[layeri].GravelVol/100)
        availablew = (wx-wairdry)*fracz
        stilltoextract = (evaptolose-evaplost)
        if availablew > 0
            if availablew > stilltoextract
                eact = gvars[:float_parameters][:eact]
                setparameter!(gvars[:float_parameters], :eact, eact + stilltoextract)
                evaplost = evaplost + stilltoextract
                wx = wx - stilltoextract
            else
                eact = gvars[:float_parameters][:eact]
                setparameter!(gvars[:float_parameters], :eact, eact + availablew)
                evaplost = evaplost + availablew
                wx = wx - availablew
            end 
            compartments[compi].Theta = wx/(1000 * compartments[compi].Thickness *
                                         (1 - soil_layers[layeri].GravelVol/100))
        end 
        ztot = ztot + fracz * (compartments[compi].Thickness)
        if (compi >= length(compartments)) |
           (abs(stilltoextract) < 0.0000001) |
           (ztot >= 0.999999*zact)
           loopi = false
        end
    end
    if stg1
        simulation.EvapWCsurf -= evaplost
        if abs(evaptolose-evaplost) > 0.0001
            # not enough water left in the compartment to store WCsurf
            simulation.EvapWCsurf = 0  
        end 
    end 
    return nothing
end

"""
    calculate_soil_evaporation_stage2!(gvars)

simul.f90:4458
"""
function  calculate_soil_evaporation_stage2!(gvars)
    compartments = gvars[:compartments]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    soil_layers = gvars[:soil_layers]
    soil = gvars[:soil]

    nrofstepsinday = 20
    fractionwtoexpandz = 0.4
    thetainievap = Float64[0.0 for _ in 1:11]
    scellinievap = Int[ 0 for _ in 1:11]
    # Step 1. Conditions before soil evaporation
    compi = 1
    maxsaltexdepth = compartments[compi].Thickness
    while (maxsaltexdepth < simulparam.EvapZmax) & (compi < length(compartments))
        compi = compi + 1
        thetainievap[compi-1] = compartments[compi].Theta
        scellinievap[compi-1] = active_cells(compartments[compi], soil_layers)
        maxsaltexdepth = maxsaltexdepth + compartments[compi].Thickness
    end 

    # Step 2 Soil evaporation
    stg1 = false
    eremaining = gvars[:float_parameters][:epot] - gvars[:float_parameters][:eact]
    wupper, wlower = get_limits_evap_layer(simulation.EvapStartStg2, simulation, compartments, soil_layers, soil)
    for i in 1:nrofstepsinday
        attheta = :AtAct
        wact = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
        wrel = (wact-wlower)/(wupper-wlower)
        if simulparam.EvapZmax > EvapZmin
            while (wrel < (fractionwtoexpandz * (simulparam.EvapZmax - (100*simulation.EvapZ))/(simulparam.EvapZmax-EvapZmin))) &
                  (simulation.EvapZ < simulparam.EvapZmax/100)
                simulation.EvapZ += 0.001 # add 1 mm
                wupper, wlower = get_limits_evap_layer(simulation.EvapStartStg2, simulation, compartments, soil_layers, soil)
                attheta = :AtAct
                wact = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
                wrel = (wact-wlower)/(wupper-wlower)
            end 
            kr = soil_evaporation_reduction_coefficient(wrel, simulparam.EvapDeclineFactor)
        end 
        # if abs(gvars[:float_parameters][:eto] - 5) > 0.01
        #     # correction for evaporative demand
        #     # adjustment of Kr (not considered yet)
        # end 
        elost = kr * (eremaining/nrofstepsinday)
        extract_water_from_evap_layer!(gvars, elost, simulation.EvapZ, stg1)
    end 

    # Step 3. Upward salt transport
    sx = salt_transport_factor(compartments[1].Theta, soil_layers)
    if sx > 0.01
        scell1 = active_cells(compartments[1], soil_layers)
        compi = 2
        zi = compartments[1].Thickness + compartments[2].Thickness
        while (round(Int, zi*100) <= round(Int, maxsaltexdepth*100)) &
              (compi <= length(compartments)) &
              (round(Int, thetainievap[compi-1]*100000) != round(Int, compartments[compi].Theta*100000))
            # move salt to compartment 1
            scellend = active_cells(compartments[compi], soil_layers)
            boolcell = false
            layeri = compartments[compi].Layer
            ul = soil_layers[layeri].UL
            deltax = soil_layers[layeri].Dx
            loopi = true
            while loopi
                if scellend < scellinievap[compi-1]
                    saltdisplaced = sx * compartments[compi].Salt[scellinievap[compi-1]]
                    compartments[compi].Salt[scellinievap[compi-1]] -= saltdisplaced
                    scellinievap[compi-1] = scellinievap[compi-1] - 1
                    thetainievap[compi-1] = deltax * scellinievap[compi-1]
                else
                    boolcell = true
                    if scellend == soil_layers[layeri].SCP1
                        saltdisplaced = sx * compartments[compi].Salt[scellinievap[compi]] *
                                         (thetainievap[compi-1] - compartments[compi].Theta) /
                                         (thetainievap[compi-1] - ul)
                    else
                        saltdisplaced = sx * compartments[compi].Salt[scellinievap[compi - 1]] *
                                         (thetainievap[compi-1] - compartments[compi].Theta) /
                                         (thetainievap[compi-1] - deltax*(scellend-1))
                    end 
                    compartments[compi].Salt[scellinievap[compi-1]] -= saltdisplaced
                end 
                compartments[1].Salt[scell1] -= saltdisplaced
                if boolcell
                    loopi = false
                end
            end 
            compi = compi + 1
            if compi <= length(compartments) 
                zi = zi + compartments[compi].Thickness
            end 
        end 
    end 

    return nothing
end

"""
    wupper, wlower = get_limits_evap_layer(xproc, simulation, compartments, soil_layers, soil)

simul.f90:4575
"""
function get_limits_evap_layer(xproc, simulation, compartments, soil_layers, soil)
    attheta = :AtSat
    wsat = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
    attheta = :AtFC
    wfc = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)
    wupper = (xproc/100) * (wsat - (wfc-soil.REW)) + (wfc-soil.REW)
    attheta = :AtWP
    wlower = wc_evap_layer(simulation.EvapZ, attheta, compartments, soil_layers)/2
    return wupper, wlower 
end

"""
    s = salt_transport_factor(theta, soil_layers)

simul.f90:4595
"""
function salt_transport_factor(theta, soil_layers)
    if theta <= soil_layers[1].WP/200
        s = 0
    else
        x = (theta*100 - soil_layers[1].WP/2) /
            (soil_layers[1].SAT - soil_layers[1].WP/2)
        s = exp(x*log(10)+log(x/10))
    end 
    return s
end

"""
    s = soil_evaporation_reduction_coefficient(wrel, edecline)

global.f90:2139
"""
function soil_evaporation_reduction_coefficient(wrel, edecline)
    if wrel <= 0.00001
        s = 0
    else
        if wrel >= 0.99999
            s = 1
        else
            s = (exp(edecline*wrel) - 1)/(exp(edecline) - 1)
        end 
    end 
    return s
end

"""
    surface_transpiration!(gvars, coeffb0salt, coeffb1salt, coeffb2salt)

simul.f90:1523
"""
function surface_transpiration!(gvars, coeffb0salt, coeffb1salt, coeffb2salt)
    daysubmerged = gvars[:integer_parameters][:daysubmerged]
    surfacestorage = gvars[:float_parameters][:surfacestorage]
    tact = gvars[:float_parameters][:tact]
    tpot = gvars[:float_parameters][:tpot]
    ecstorage = gvars[:float_parameters][:ecstorage]

    compartments = gvars[:compartments]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    crop = gvars[:crop]

    daysubmerged = daysubmerged + 1
    for compi in 1:length(compartments)
        compartments[compi].DayAnaero += 1 
        if compartments[compi].DayAnaero > simulparam.DelayLowOxygen
            compartments[compi].DayAnaero = simulparam.DelayLowOxygen
        end 
    end 
    if crop.AnaeroPoint > 0
        part = 1-daysubmerged/simulparam.DelayLowOxygen
    else
        part = 1
    end 
    ksreduction = ks_salinity(simulation.SalinityConsidered, crop.ECemin, crop.ECemax, ecstorage, 0)
    saltsurface = surfacestorage*ecstorage*equiv
    if surfacestorage > ksreduction*part*tpot
        surfacestorage = surfacestorage - ksreduction*part*tpot
        tact = ksreduction*part*tpot
        # salinisation of surface storage layer
        ecstorage = saltsurface/(surfacestorage*equiv)
    else
        tact = surfacestorage -0.1
        surfacestorage = 0.1 # zero give error in already updated salt balance
    end 
    if tact < ksreduction*part*tpot
        setparameter!(gvars[:integer_parameters], :daysubmerged, daysubmerged)
        setparameter!(gvars[:float_parameters], :tact, tact)
        setparameter!(gvars[:float_parameters], :surfacestorage, surfacestorage)
        setparameter!(gvars[:float_parameters], :ecstorage, ecstorage)

        tact_temp = tact   #(*protect tact from changes in the next routine*)
        calculate_transpiration!(gvars, (ksreduction*part*tpot-tact), 
                                         coeffb0salt, coeffb1salt, coeffb2salt)
        tact = tact_temp + gvars[:float_parameters][:tact]
        setparameter!(gvars[:float_parameters], :tact, tact)
    else 
        setparameter!(gvars[:integer_parameters], :daysubmerged, daysubmerged)
        setparameter!(gvars[:float_parameters], :tact, tact)
        setparameter!(gvars[:float_parameters], :surfacestorage, surfacestorage)
        setparameter!(gvars[:float_parameters], :ecstorage, ecstorage)
    end
    return nothing
end

"""
    calculate_transpiration!(gvars, tpot, coeffb0salt, coeffb1salt, coeffb2salt)

simul.f90:1156
"""
function calculate_transpiration!(gvars, tpot, coeffb0salt, coeffb1salt, coeffb2salt)
    daysubmerged = gvars[:integer_parameters][:daysubmerged]
    irrimode = gvars[:symbol_parameters][:irrimode]
    simulation = gvars[:simulation]
    soil_layers = gvars[:soil_layers]
    root_zone_wc = gvars[:root_zone_wc]
    root_zone_salt = gvars[:root_zone_salt]
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    compartments = gvars[:compartments]
    rooting_depth = gvars[:float_parameters][:rooting_depth]
    irrigation = gvars[:float_parameters][:irrigation]

    tact = 0

    if tpot > 0
        # 1. maximum transpiration in actual root zone
        if irrimode == :Inet
            # salinity stress not considered
            tpotmax = tpot
        else
            determine_root_zone_wc!(gvars, rooting_depth)

            # --- 1. Effect of water stress and ECe (total rootzone)
            wrelsalt = (root_zone_wc.FC-root_zone_wc.Actual)/ 
                       (root_zone_wc.FC-root_zone_wc.WP)

            # --- 2. effect of water stress
            pstomatllact = 1
            if simulation.SWCtopSoilConsidered == true
                # top soil is relative wetter than total root zone
                if root_zone_wc.ZtopAct < (0.999 * root_zone_wc.ZtopThresh)
                    wrel = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct)/ 
                           (root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)
                    # kssen = ks_any(wrelative, psenact, psenll, crop.KsShapeFactorSenescence) 
                    redfact = (1 - simulation.EffectStress.RedKsSto/100) * ks_any(wrel, crop.pActStom, pstomatllact, 0.0) # where (0.0) is linear
                else
                    redfact = (1 - simulation.EffectStress.RedKsSto/100)
                end 
            else
                # total root zone
                if root_zone_wc.Actual < (0.999 * root_zone_wc.Thresh)
                    wrel = (root_zone_wc.FC-root_zone_wc.Actual)/ 
                            (root_zone_wc.FC-root_zone_wc.WP)
                    redfact = (1 - simulation.EffectStress.RedKsSto/100) * ks_any(wrel, crop.pActStom, pstomatllact, 0.0) # where (0.0) is linear
                else
                    redfact = (1 - simulation.EffectStress.RedKsSto/100)
                end 
            end 

            if redfact < 0
                redfact = 0
            end 
            if redfact > 1
                redfact = 1
            end 

            # --- 3. Extra effect of ECsw (salt in total root zone is considered)
            if simulation.SalinityConsidered
                redfactecsw = adjusted_ks_sto_to_ecsw(crop.ECemin, 
                              crop.ECemax, crop.ResponseECsw, 
                              root_zone_salt.ECe, root_zone_salt.ECsw, 
                              root_zone_salt.ECswFC, wrelsalt, coeffb0salt, 
                              coeffb1salt, coeffb2salt, redfact, simulation)
            else
                redfactecsw = redfact
            end 

            # --- 4. Conclusion (adjustment of TpotMAX considering Water and Salt stress)
            tpotmax = redfactecsw * tpot

            # 1.b anaerobic conditions in root zone (total root zone is considered)
            redfact, dayanaero = determine_root_zone_anaero_conditions(root_zone_wc.SAT, 
                                              root_zone_wc.Actual, 
                                              crop.AnaeroPoint, 
                                              rooting_depth, 
                                              simulation,
                                              simulparam)
            simulation.DayAnaero = dayanaero
            tpotmax = redfact * tpotmax
        end 

        # 2. extraction of TpotMax out of the compartments
        # 2.a initial settings
        calculate_rootfraction_compartment!(compartments, rooting_depth)
        calculate_sink_values!(compartments, rooting_depth, irrimode, crop, simulation)
        compi = 0
        pre_layer = 0
        loopi = true
        theta_critical = 0
        while loopi
            compi = compi + 1
            layeri = compartments[compi].Layer
            if layeri > pre_layer
                theta_critical = calculate_theta_critical(layeri, soil_layers, crop)
                pre_layer = layeri
            end 
            # 2.b calculate alfa
            if irrimode == :Inet
                alfa = 1
            else
                # effect of water stress and ECe
                if compartments[compi].Theta >= theta_critical
                    alfa = (1 - simulation.EffectStress.RedKsSto/100)
                elseif compartments[compi].Theta > (soil_layers[layeri].WP/100)
                    if theta_critical > (soil_layers[layeri].WP/100)
                        wrel = (soil_layers[layeri].FC/100 - compartments[compi].Theta) /
                                (soil_layers[layeri].FC/100 - soil_layers[layeri].WP/100)
                        pstomatllact = 1
                        alfa = (1 - simulation.EffectStress.RedKsSto/100) *
                                ks_any(wrel, crop.pActStom, pstomatllact, crop.KsShapeFactorStomata)
                    else
                        alfa = (1 - simulation.EffectStress.RedKsSto/100)
                    end 
                else
                    alfa = 0
                end 
                # extra effect of ECsw
                if simulation.SalinityConsidered
                    wrelsalt = (soil_layers[layeri].FC/100 - compartments[compi].Theta) /
                                    (soil_layers[layeri].FC/100 - soil_layers[layeri].WP/100)
                    compiece = ececomp(compartments[compi], gvars)
                    compiecsw = ecswcomp(compartments[compi], false, gvars)
                    compiecswfc = ecswcomp(compartments[compi], true, gvars)
                    redfactecsw = adjusted_ks_sto_to_ecsw(crop.ECemin, 
                                  crop.ECemax, crop.ResponseECsw, 
                                  compiece, compiecsw, compiecswfc, wrelsalt, 
                                  coeffb0salt, coeffb1salt, coeffb2salt, alfa, simulation)
                else
                    redfactecsw = alfa
                end 
                alfa = redfactecsw
            end 
            if crop.AnaeroPoint > 0
                alfa, dayanaero = correction_anaeroby(compartments[compi], alfa, daysubmerged, simulparam, soil_layers, crop)
                compartments[compi].DayAnaero = dayanaero
            end 
            # 2.c extract water
            sinkmm = 1000 * (alfa * compartments[compi].WFactor * compartments[compi].Smax) * compartments[compi].Thickness
            wtoextract = tpotmax-tact
            if wtoextract < sinkmm
                sinkmm = wtoextract
            end 
            compartments[compi].Theta -= sinkmm/(1000*compartments[compi].Thickness* 
                                            (1 - soil_layers[layeri].GravelVol/100))
            wtoextract = wtoextract - sinkmm
            tact += sinkmm
            if (wtoextract < eps()) | (compi == length(compartments))
                loopi = false
            end
        end


        # 3. add net irrigation water requirement
        if irrimode == :Inet
            # total root zone is considered
            determine_root_zone_wc!(gvars, rooting_depth)
            inetthreshold = root_zone_wc.FC - simulparam.PercRAW/100 *(root_zone_wc.FC - root_zone_wc.Thresh)
            if root_zone_wc.Actual < inetthreshold
                pre_layer = 0
                for compi in 1:length(compartments)
                    layeri = compartments[compi].Layer
                    if layeri > pre_layer
                        theta_critical = calculate_theta_critical(layeri, soil_layers, crop)
                        inetthreshold = soil_layers[layeri].FC/100 - simulparam.PercRAW/100*(soil_layers[layeri].FC/100 - theta_critical)
                        pre_layer = layeri
                    end 
                    deltawc = compartments[compi].WFactor * (inetthreshold - compartments[compi].Theta) *
                              1000*compartments[compi].Thickness*(1 - soil_layers[layeri].GravelVol/100)
                    compartments[compi].Theta += deltawc/(1000*compartments[compi].Thickness* 
                                                (1 - soil_layers[layeri].GravelVol(layeri)/100))
                    irrigation += deltawc
                end 
            end 
        end 
    end 

    setparameter!(gvars[:float_parameters], :irrigation, irrigation)
    setparameter!(gvars[:float_parameters], :tact, tact)
    return nothing
end

"""
    redfact, dayanaero = determine_root_zone_anaero_conditions(wsat, wact, anaevol, zr, simulation, simulparam)

simul.f90:1490
note that we must do simulation.DayAnaero = dayanaero after calling this function
"""
function determine_root_zone_anaero_conditions(wsat, wact, anaevol, zr, simulation, simulparam)
    dayanaero = simulation.DayAnaero
    redfact = 1
    if (anaevol > 0) & (zr > 0)
        satvol = wsat/(10*zr)
        actvol = wact/(10*zr)
        if actvol > satvol
            actvol = satvol
        end 
        if actvol > (satvol-anaevol)
            dayanaero = dayanaero + 1
            if dayanaero > simulparam.DelayLowOxygen
                dayanaero = simulparam.DelayLowOxygen
            end 
            redfact = 1 - (1-((satvol - actvol)/anaevol)) * (dayanaero/simulparam.DelayLowOxygen)
        else
            dayanaero = 0
        end 
    else
        dayanaero = 0
    end

    return redfact, dayanaero
end

"""
    alfa, dayanaero = correction_anaeroby(compartment, alfa, daysubmerged, simulparam, soil_layers, crop)

simul.f90:1453
note that we must do compartment.DayAnaero = dayanaero after calling this function
"""
function correction_anaeroby(compartment, alfa, daysubmerged, simulparam, soil_layers, crop)

    dayanaero = compartment.DayAnaero
    if (daysubmerged >= simulparam.DelayLowOxygen) & (crop.AnaeroPoint > 0)
        alfaan = 0
    elseif compartment.Theta > (soil_layers[compartment.Layer].SAT - crop.AnaeroPoint)/100 
        dayanaero = dayanaero + 1
        if dayanaero >= simulparam.DelayLowOxygen
            ini = 0
            dayanaero = simulparam.DelayLowOxygen
        else
            ini = 1
        end 
        alfaan = (soil_layers[compartment.Layer].SAT/100 - compartment.Theta)/(crop.AnaeroPoint/100)
        if alfaan < 0
            alfaan = 0
        end 
        if simulparam.DelayLowOxygen > 1
            alfaan = (ini+(dayanaero-1)*alfaan) /(ini+dayanaero-1)
        end 
    else
        alfaan = 1
        dayanaero = 0
    end 
    if alfa > alfaan
        alfa = alfaan
    end 

    return alfa, dayanaero
end

"""
    calculate_sink_values!(compartments, rootingdepth, irrimode, crop, simulation)

simul.f90:1407
"""
function calculate_sink_values!(compartments, rootingdepth, irrimode, crop, simulation)
    if irrimode == :Inet
        sink_value = (crop.SmaxTop + crop.SmaxBot)/2
        for compi in 1:length(compartments)
            compartments[compi].Smax = sink_value
        end 
    else
        cumdepth = 0
        compi = 0
        sbotcomp = crop.SmaxTop
        loopi = true
        while loopi
            compi = compi + 1
            stopcomp = sbotcomp
            cumdepth = cumdepth + compartments[compi].Thickness
            if cumdepth <= rootingdepth
                sbotcomp = crop.SmaxBot * simulation.SCor +
                           (crop.SmaxTop - crop.SmaxBot*simulation.SCor) *
                           (rootingdepth - cumdepth)/rootingdepth
            else
                sbotcomp = crop.SmaxBot*simulation.SCor
            end 
            compartments[compi].Smax = (stopcomp + sbotcomp)/2
            if compartments[compi].Smax > 0.06
                compartments[compi].Smax = 0.06
            end 
            if (cumdepth >= rootingdepth) | (compi == length(compartments))
                loopi = false
            end
        end 
        for i in (compi + 1):length(compartments)
            compartments[i].Smax = 0
        end 
    end 
    return nothing
end

"""
    calculate_rootfraction_compartment!(compartments, rootingdepth)

simul.f90:1375
"""
function calculate_rootfraction_compartment!(compartments, rootingdepth)
    cumdepth = 0
    compi = 0
    loopi = true
    while loopi
        compi = compi + 1
        cumdepth = cumdepth + compartments[compi].Thickness
        if cumdepth <= rootingdepth
            compartments[compi].WFactor = 1
        else
            frac_value = rootingdepth - (cumdepth - compartments[compi].Thickness)
            if frac_value > 0
                compartments[compi].WFactor = frac_value/compartments[compi].Thickness
            else
                compartments[compi].WFactor = 0
            end 
        end 
        if (cumdepth >= rootingdepth) | (compi == length(compartments))
            loopi = false
        end
    end 
    for i in (compi+1):length(compartments)
        compartments[i].WFactor = 0
    end 
    return nothing
end

"""
    theta = calculate_theta_critical(layeri, soil_layers, crop)

simul.f90:1362
"""
function calculate_theta_critical(layeri, soil_layers, crop)

    theta_taw = soil_layers[layeri].FC/100 - soil_layers[layeri].WP/100
    theta_critical = soil_layers[layeri].FC/100 - theta_taw * crop.pActStom
    return theta_critical
end

"""
    ksstoout = adjusted_ks_sto_to_ecsw(ecemin, ecemax, responseecsw, ecei, 
            ecswi, ecswfci, wrel, coeffb0salt, coeffb1salt, coeffb2salt, ksstoin, simulation)

global.f90:2321
"""
function adjusted_ks_sto_to_ecsw(ecemin, ecemax, responseecsw, ecei, 
            ecswi, ecswfci, wrel, coeffb0salt, coeffb1salt, coeffb2salt, ksstoin, simulation)

        if (responseecsw > 0) & (wrel > eps()) & (simulation.SalinityConsidered == true)
        # adjustment to ecsw considered
        ecswrel = ecswi - (ecswfci - ecei) + (responseecsw-100)*wrel
        if (ecswrel > ecemin) & (ecswrel < ecemax)
            # stomatal closure at ecsw relative
            localksshapefactorsalt = 3 # convex give best ecsw response
            kssalti = ks_salinity(simulation.SalinityConsidered, ecemin, 
                                        ecemax, ecswrel, localksshapefactorsalt)
            saltstressi = (1-kssalti)*100
            stoclosure = coeffb0salt + coeffb1salt * saltstressi + coeffb2salt * saltstressi * saltstressi
            # adjusted kssto
            ksstoout = (1 - stoclosure/100)
            if ksstoout < 0
                ksstoout = 0
            end 
            if ksstoout > ksstoin
                ksstoout = ksstoin
            end 
        else
            if ecswrel >= ecemax
                ksstoout = 0 # full stress
            else
                ksstoout = ksstoin # no extra stress
            end 
        end 
    else
        ksstoout = ksstoin  # no adjustment to ecsw
    end 
    return ksstoout
end

"""
    feedback_cc!(gvars)

simul.f90:5348
"""
function feedback_cc!(gvars)
    if ((gvars[:float_parameters][:cciactual] - gvars[:float_parameters][:cciprev]) > 0.005) &
        # canopy is still developing
        (gvars[:float_parameters][:tact] < eps())
        # due to aeration stress or ETo = 0
        setparameter!(gvars[:float_parameters], :cciactual, gvars[:float_parameters][:cciprev])
        # no transpiration, no crop developmentc
    end 
    return nothing
end

"""
    horizontal_inflow_gwtable!(gvars, lvars, depthgwtmeter)

simul.f90:5360
"""
function horizontal_inflow_gwtable!(gvars, lvars, depthgwtmeter)
    horizontalsaltflow = lvars[:float_parameters][:horizontalsaltflow]
    horizontalwaterflow = lvars[:float_parameters][:horizontalwaterflow]

    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]
    eciaqua = gvars[:float_parameters][:eciaqua]

    ztot = 0
    for compi in 1:length(compartments)
        ztot = ztot + compartments[compi].Thickness
        zi = ztot - compartments[compi].Thickness/2
        layeri = compartments[compi].Layer
        if zi >= depthgwtmeter
            # soil water content is at saturation
            if compartments[compi].Theta < soil_layers[layeri].SAT/100
                deltatheta = soil_layers[layeri].SAT/100 - compartments[compi].Theta
                compartments[compi].Theta = soil_layers[layeri].SAT/100
                horizontalwaterflow = horizontalwaterflow + 1000 * deltatheta *
                                      compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/100)
            end 
            # ECe is equal to the EC of the groundwater table
            if abs(ececomp(compartments[compi], gvars) - eciaqua) > 0.0001
                saltact = 0
                for celli in 1:soil_layers[layeri].SCP1
                    saltact = saltact + (compartments[compi].Salt[celli] + compartments[compi].Depo[celli])/100 # Mg/ha
                end 
                determine_salt_content!(compartments[compi], soil_layers, simulparam)
                saltadj = 0
                for celli in 1:soil_layers[layeri].SCP1
                    saltadj = saltadj + (compartments[compi].Salt[celli] + compartments[compi].Depo[celli])/100 # Mg/ha
                end 
                horizontalsaltflow = horizontalsaltflow + (saltadj - saltact)
            end 
        end 
    end 

    setparameter!(lvars[:float_parameters], :horizontalsaltflow, horizontalsaltflow)
    setparameter!(lvars[:float_parameters], :horizontalwaterflow, horizontalwaterflow)
    return nothing
end

"""
    concentrate_salts!(gvars)

simul.f90:4343
"""
function concentrate_salts!(gvars)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]
    for compi in 1:length(compartments)
        layeri = compartments[compi].Layer
        salttot = 0.0
        celwet = active_cells(compartments[compi], soil_layers)
        if celwet < soil_layers[layeri].SCP1
            for celi in (celwet+1):soil_layers[layeri].SCP1
                salttot = salttot + compartments[compi].Salt[celi] + compartments[compi].Depo[celi]
                compartments[compi].Salt[celi] = 0
                compartments[compi].Depo[celi] = 0
            end 
        end 
        if salttot > 0
            compartments[compi].Salt[celwet] += salttot
            mm = soil_layers[layeri].Dx*1000* compartments[compi].Thickness * (1 - soil_layers[layeri].GravelVol/ 100)
            salt_solution_deposit!(compartments[compi], simulparam, celwet, mm)
        end 
    end 
    return nothing
end

"""
    cn1, cn3 = determine_cni_and_iii(cn2)

global.f90:2481
"""
function determine_cni_and_iii(cn2)
    cn1 = round(Int, 1.4*(exp(-14*log(10))) + 0.507*cn2 - 0.00374*cn2*cn2 + 0.0000867*cn2*cn2*cn2)
    cn3 = round(Int, 5.6*(exp(-14*log(10))) + 2.33*cn2 - 0.0209*cn2*cn2 + 0.000076*cn2*cn2*cn2)

    if cn1 <= 0
        cn1 = 1
    elseif cn1 > 100
        cn1 = 100
    end 
    if cn3 <= 0
        cn3 = 1
    elseif cn3 > 100
        cn3 = 100
    end 
    if cn3 < cn2
        cn3 = cn2
    end 
    return cn1, cn3
end


