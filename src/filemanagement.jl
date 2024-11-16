"""
    file_management!(outputs, gvars, nrrun; kwargs...)

run.f90:FileManagement:7807
"""
function file_management!(outputs, gvars, nrrun; kwargs...)
    # we create these "lvars" because we need functions that 
    # returns nothing or does not change anything
    lvars = initialize_lvars()
    projectinput = gvars[:projectinput][nrrun]
    repeattoday = gvars[:simulation].ToDayNr

    cont = 0
    loopi = true
    while loopi
        cont += 1
        advance_one_time_step!(outputs, gvars, lvars, projectinput.ParentDir, nrrun)
        read_climate_nextday!(outputs, gvars)
        set_gdd_variables_nextday!(gvars)
        if (gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    return nothing
end

"""
    advance_one_time_step!(outputs, gvars, lvars, parentdir, nrrun)

run.f90:AdvanceOneTimeStep:6729
"""
function advance_one_time_step!(outputs, gvars, lvars, parentdir, nrrun)
    # reset values since they are local variables
    setparameter!(lvars[:float_parameters], :preirri,  0.0)
    setparameter!(lvars[:float_parameters], :fracassim, 0.0)
    setparameter!(lvars[:integer_parameters], :targettimeval, 0)
    setparameter!(lvars[:integer_parameters], :targetdepthval, 0)

    # 1. Get ETo
    if gvars[:string_parameters][:eto_file] == "(None)"
        setparameter!(gvars[:float_parameters], :eto, 5.0)
    end 

    # 2. Get Rain
    if gvars[:string_parameters][:rain_file] == "(None)"
        setparameter!(gvars[:float_parameters], :rain, 0.0)
    end 

    # 3. Start mode
    if gvars[:bool_parameters][:startmode]
        setparameter!(gvars[:bool_parameters], :startmode, false)
    end 

    # 4. Get depth and quality of the groundwater
    if !gvars[:simulparam].ConstGwt
        if gvars[:integer_parameters][:daynri] > gvars[:gwtable].DNr2
            get_gwt_set!(gvars, parentdir, gvars[:integer_parameters][:daynri])
        end 
        get_z_and_ec_gwt!(gvars)
        if check_for_watertable_in_profile(gvars[:compartments], gvars[:integer_parameters][:ziaqua]/100)
            adjust_for_watertable!(gvars)
        end 
    end 

    # 5. Get Irrigation
    setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    get_irri_param!(gvars, lvars)

    # 6. get virtual time for CC development
    sumgddadjcc = undef_double #real(undef_int, kind=dp)
    if gvars[:crop].DaysToCCini != 0
        # regrowth
        if gvars[:integer_parameters][:daynri] >= gvars[:crop].Day1
            # time setting for canopy development
            virtualtimecc = (gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays 
                             - gvars[:crop].Day1 
                             + gvars[:integer_parameters][:tadj] + gvars[:crop].DaysToGermination)
            # adjusted time scale
            if virtualtimecc > gvars[:crop].DaysToHarvest
                virtualtimecc = gvars[:crop].DaysToHarvest
                # special case where L123 > L1234
            end 
            if virtualtimecc > gvars[:crop].DaysToFullCanopy
                if (gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays - 
                    gvars[:crop].Day1) <= gvars[:crop].DaysToSenescence
                    virtualtimecc = gvars[:crop].DaysToFullCanopy + 
                                    round(Int, gvars[:float_parameters][:dayfraction] * ((gvars[:integer_parameters][:daynri] - 
                                              gvars[:simulation].DelayedDays - 
                                              gvars[:crop].Day1) + gvars[:integer_parameters][:tadj] + 
                                              gvars[:crop].DaysToGermination - 
                                              gvars[:crop].DaysToFullCanopy)) # slow down
                else
                    virtualtimecc = gvars[:integer_parameters][:daynri] - 
                       gvars[:simulation].DelayedDays - gvars[:crop].Day1 # switch time scale
                end 
            end 
            if gvars[:crop].ModeCycle == :GDDays
                sumgddadjcc = gvars[:simulation].SumGDDfromDay1 + gvars[:integer_parameters][:gddtadj] + 
                              gvars[:crop].GDDaysToGermination
                if sumgddadjcc > gvars[:crop].GDDaysToHarvest
                    sumgddadjcc = gvars[:crop].GDDaysToHarvest
                    # special case where L123 > L1234
                end 
                if sumgddadjcc > gvars[:crop].GDDaysToFullCanopy
                    if gvars[:simulation].SumGDDfromDay1 <= gvars[:crop].GDDaysToSenescence
                        sumgddadjcc = gvars[:crop].GDDaysToFullCanopy + 
                                        round(Int, gvars[:float_parameters][:gddayfraction] *
                                                        (gvars[:simulation].SumGDDfromDay1 +
                                                         gvars[:integer_parameters][:gddtadj] + gvars[:crop].GDDaysToGermination -
                                                         gvars[:crop].GDDaysToFullCanopy)) # slow down
                    else
                        sumgddadjcc = gvars[:simulation].SumGDDfromDay1
                        # switch time scale
                    end 
                end
            end 
            # CC initial (at the end of previous day) when simulation starts
            # before regrowth,
            if (gvars[:integer_parameters][:daynri] == gvars[:crop].Day1) &
               (gvars[:integer_parameters][:daynri] > gvars[:simulation].FromDayNr)
                ratdgdd = 1
                if (gvars[:crop].ModeCycle == :GDDays) &
                   (gvars[:crop].GDDaysToFullCanopySF < gvars[:crop].GDDaysToSenescence) 
                    ratdgdd = (gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopySF) / 
                              (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopySF)
                end 
                gvars[:simulation].EffectStress = crop_stress_parameters_soil_fertility(gvars[:crop].StressResponse,
                                                             gvars[:integer_parameters][:stress_sf_adj_new]) 
                cciprev = ccini_total_from_time_to_ccini(
                        gvars[:crop].DaysToCCini, 
                        gvars[:crop].GDDaysToCCini, 
                        gvars[:crop].DaysToGermination, 
                        gvars[:crop].DaysToFullCanopy, 
                        gvars[:crop].DaysToFullCanopySF, 
                        gvars[:crop].DaysToSenescence, 
                        gvars[:crop].DaysToHarvest, 
                        gvars[:crop].GDDaysToGermination, 
                        gvars[:crop].GDDaysToFullCanopy, 
                        gvars[:crop].GDDaysToFullCanopySF, 
                        gvars[:crop].GDDaysToSenescence, 
                        gvars[:crop].GDDaysToHarvest, gvars[:crop].CCo, 
                        gvars[:crop].CCx, gvars[:crop].CGC, 
                        gvars[:crop].GDDCGC, gvars[:crop].CDC, 
                        gvars[:crop].GDDCDC, ratdgdd, 
                        gvars[:simulation].EffectStress.RedCGC, 
                        gvars[:simulation].EffectStress.RedCCX,
                        gvars[:simulation].EffectStress.CDecline, 
                        (gvars[:float_parameters][:ccxtotal]/gvars[:crop].CCx), gvars[:crop].ModeCycle, 
                        gvars[:simulation])
                setparameter!(gvars[:float_parameters], :cciprev, cciprev)
                # (CCxTotal/Crop.CCx) = fWeed
            end 
        else
            # before start crop
            virtualtimecc = gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays - 
                            gvars[:crop].Day1
            if gvars[:crop].ModeCycle == :GDDays
                sumgddadjcc = gvars[:simulation].SumGDD
            end 
        end 
    else
        # sown or transplanted
        virtualtimecc = gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays - 
                        gvars[:crop].Day1
        if gvars[:crop].ModeCycle == :GDDays
            sumgddadjcc = gvars[:simulation].SumGDD
        end 
        # CC initial (at the end of previous day) when simulation starts
        # before sowing/transplanting,
        if (gvars[:integer_parameters][:daynri] == (gvars[:crop].Day1 + gvars[:crop].DaysToGermination)) &
           (gvars[:integer_parameters][:daynri] > gvars[:simulation].FromDayNr) 
            setparameter!(gvars[:float_parameters], :cciprev, gvars[:float_parameters][:ccototal])
        end 
    end 

    # 7. Rooting depth AND Inet day 1
    if ((gvars[:crop].ModeCycle == :CalendarDays) &
        ((gvars[:integer_parameters][:daynri]-gvars[:crop].Day1+1) < gvars[:crop].DaysToHarvest)) |
       ((gvars[:crop].ModeCycle == :GDDays) &
        (gvars[:simulation].SumGDD < gvars[:crop].GDDaysToHarvest)) 
        if ((gvars[:integer_parameters][:daynri]-gvars[:simulation].DelayedDays) >= gvars[:crop].Day1) &
           ((gvars[:integer_parameters][:daynri]-gvars[:simulation].DelayedDays) <= gvars[:crop].DayN)
            # rooting depth at DAP (at Crop.Day1, DAP = 1)
            adjusted_rooting_depth!(gvars)
            setparameter!(gvars[:float_parameters], :ziprev, gvars[:float_parameters][:rooting_depth])
            # IN CASE rootzone drops below groundwate table
            if (gvars[:integer_parameters][:ziaqua] >= 0) &
               (gvars[:float_parameters][:rooting_depth] > gvars[:integer_parameters][:ziaqua]/100) &
               (gvars[:crop].AnaeroPoint > 0)
                setparameter!(gvars[:float_parameters], :rooting_depth, gvars[:integer_parameters][:ziaqua]/100)
                if gvars[:float_parameters][:rooting_depth] < gvars[:crop].RootMin
                    setparameter!(gvars[:float_parameters], :rooting_depth, gvars[:crop].RootMin)
                end 
             end 
        else
            setparameter!(gvars[:float_parameters], :rooting_depth, 0.0) 
        end 
    else
        setparameter!(gvars[:float_parameters], :rooting_depth, gvars[:float_parameters][:ziprev]) 
    end 
    if (gvars[:float_parameters][:rooting_depth] > 0) & (gvars[:integer_parameters][:daynri] == gvars[:crop].Day1)
        # initial root zone depletion day1 (for WRITE Output)
            determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth])
        if gvars[:symbol_parameters][:irrimode] == :Inet
            # required to start germination
            adjust_swc_rootzone!(gvars, lvars)
        end 
    end 

    # 8. Transfer of Assimilates
    initialize_transfer_assimilates!(gvars, lvars)

    # 9. RUN Soil water balance and actual Canopy Cover
    budget_module!(gvars, lvars, virtualtimecc, sumgddadjcc)

    # consider Pre-irrigation (6.) if IrriMode = Inet
    if (gvars[:float_parameters][:rooting_depth] > 0) & (gvars[:integer_parameters][:daynri] == gvars[:crop].Day1) &
       (gvars[:symbol_parameters][:irrimode] == :Inet)
        irrigation = gvars[:float_parameters][:irrigation]
        preirri = lvars[:float_parameters][:preirri]
        gvars[:sumwabal].Irrigation += preirri
        setparameter!(gvars[:float_parameters], :irrigation, irrigation + preirri)
        setparameter!(lvars[:float_parameters], :preirri, 0.0)
     end 

     # total number of days in the season
     if gvars[:float_parameters][:cciactual] > 0
         if gvars[:stresstot].NrD < 0
            gvars[:stresstot].NrD = 1
        else
            gvars[:stresstot].NrD += 1
        end 
     end 

    # 10. Potential biomass
    determine_potential_biomass!(gvars, virtualtimecc, sumgddadjcc)

    # 11. Biomass and yield
    if (gvars[:float_parameters][:rooting_depth] > 0) & (gvars[:bool_parameters][:nomorecrop] == false)
        determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth])
        # temperature stress affecting crop transpiration
        if gvars[:float_parameters][:cciactual] <= 0.0000001
            kstr = 1
        else
            kstr = ks_temperature(0, gvars[:crop].GDtranspLow, gvars[:float_parameters][:gddayi])
        end 
        gvars[:stresstot].Temp = ((gvars[:stresstot].NrD - 1)*gvars[:stresstot].Temp + 100*(1-kstr))/gvars[:stresstot].NrD
        # soil salinity stress
        determine_root_zone_salt_content!(gvars, gvars[:float_parameters][:rooting_depth])
        gvars[:stresstot].Salt = ((gvars[:stresstot].NrD - 1)*gvars[:stresstot].Salt +
                                 100*(1-gvars[:root_zone_salt].KsSalt))/gvars[:stresstot].NrD
         # Biomass and yield
         determine_biomass_and_yield!(gvars, lvars, sumgddadjcc, virtualtimecc) 
    else
         # SenStage = undef_int #GDL, 20220423, not used
         setparameter!(gvars[:float_parameters], :weedrci, undef_double)  # no crop and no weed infestation
         setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.0)  # no crop
         setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0)  # no crop
    end 

    # 12. Reset after RUN
    if gvars[:bool_parameters][:preday] == false
        setparameter!(gvars[:integer_parameters], :previoussdaynr, gvars[:simulation].FromDayNr - 1)
    end 
    setparameter!(gvars[:bool_parameters], :preday, true)
    if gvars[:integer_parameters][:daynri] >= gvars[:crop].Day1
        setparameter!(gvars[:float_parameters], :cciprev, gvars[:float_parameters][:cciactual])
        if gvars[:float_parameters][:ziprev] < gvars[:float_parameters][:rooting_depth] 
            setparameter!(gvars[:float_parameters], :ziprev, gvars[:float_parameters][:rooting_depth])
            # IN CASE groundwater table does not affect root development
        end 
        setparameter!(gvars[:float_parameters], :sumgddprev, gvars[:simulation].SumGDD)
    end 
    if lvars[:integer_parameters][:targettimeval] == 1
        setparameter!(gvars[:integer_parameters], :irri_interval, 0)
    end 

    # 13. Cuttings
    if gvars[:management].Cuttings.Considered
        setparameter!(lvars[:bool_parameters], :harvestnow, false)
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
        suminterval = gvars[:integer_parameters][:suminterval]
        setparameter!(gvars[:integer_parameters], :suminterval, suminterval + 1 )
        sumgddcuts = gvars[:float_parameters][:sumgddcuts]
        gddayi = gvars[:float_parameters][:gddayi]
        setparameter!(gvars[:float_parameters], :sumgddcuts, sumgddcuts + gddayi)

        if gvars[:management].Cuttings.Generate == false
            if gvars[:management].Cuttings.FirstDayNr != undef_int 
               # adjust DayInSeason
                dayinseason = gvars[:integer_parameters][:daynri] - gvars[:management].Cuttings.FirstDayNr + 1
            end 
            if (dayinseason >= gvars[:cut_info_record1].FromDay) &
                (gvars[:cut_info_record1].NoMoreInfo == false)
                setparameter!(lvars[:bool_parameters], :harvestnow, true)
                get_next_harvest!(gvars)
            end 
            if gvars[:management].Cuttings.FirstDayNr != undef_int 
               # reset DayInSeason
                dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
            end 
        else
            if (dayinseason > gvars[:cut_info_record1].ToDay) &
                (gvars[:cut_info_record1].NoMoreInfo == false)
                get_next_harvest!(gvars)
            end 
            if gvars[:management].Cuttings.Criterion == :IntDay
                if (gvars[:integer_parameters][:suminterval] >= gvars[:cut_info_record1].IntervalInfo) &
                   (dayinseason >= gvars[:cut_info_record1].FromDay) &
                   (dayinseason <= gvars[:cut_info_record1].ToDay)
                    setparameter!(lvars[:bool_parameters], :harvestnow, true)
                end 
            elseif gvars[:management].Cuttings.Criterion == :IntGDD
                if (gvars[:float_parameters][:sumgddcuts] >= gvars[:cut_info_record1].IntervalGDD) &
                   (dayinseason >= gvars[:cut_info_record1].FromDay) &
                   (dayinseason <= gvars[:cut_info_record1].ToDay)
                    setparameter!(lvars[:bool_parameters], :harvestnow, true)
                end 
            elseif gvars[:management].Cuttings.Criterion == :DryB
                if ((gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]) >= gvars[:cut_info_record1].MassInfo) &
                   (dayinseason >= gvars[:cut_info_record1].FromDay) &
                   (dayinseason <= gvars[:cut_info_record1].ToDay)
                    setparameter!(lvars[:bool_parameters], :harvestnow, true)
                end 
            elseif gvars[:management].Cuttings.Criterion == :DryY
                if ((gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]) >= gvars[:cut_info_record1].MassInfo) &
                   (dayinseason >= gvars[:cut_info_record1].FromDay) &
                   (dayinseason <= gvars[:cut_info_record1].ToDay)
                    setparameter!(lvars[:bool_parameters], :harvestnow, true)
                end 
            elseif gvars[:management].Cuttings.Criterion == :FreshY
                # OK if Crop.DryMatter = undef_int (not specified) HarvestNow
                # remains false
                if (((gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum])/
                    (gvars[:crop].DryMatter/100)) >= gvars[:cut_info_record1].MassInfo) &
                   (dayinseason >= gvars[:cut_info_record1].FromDay) &
                   (dayinseason <= gvars[:cut_info_record1].ToDay)
                    setparameter!(lvars[:bool_parameters], :harvestnow, true)
                end 
            end 
        end 
        if lvars[:bool_parameters][:harvestnow] 
            nrcut = gvars[:integer_parameters][:nrcut]

            setparameter!(gvars[:integer_parameters], :nrcut, nrcut + 1)
            setparameter!(gvars[:integer_parameters], :daylastcut, dayinseason)
            if gvars[:float_parameters][:cciprev] > (gvars[:management].Cuttings.CCcut/100)
                setparameter!(gvars[:float_parameters], :cciprev, gvars[:management].Cuttings.CCcut/100)
                # ook nog CCwithered
                gvars[:crop].CCxWithered = 0  # or CCiPrev ??
                setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.0) 
                # for calculation Maximum Biomass unlimited soil fertility
                gvars[:crop].CCxAdjusted = gvars[:float_parameters][:cciprev] # new
            end 
            # Record harvest
            if gvars[:bool_parameters][:part1Mult]
                record_harvest!(outputs, gvars, nrcut + 1, dayinseason, nrrun)
            end 
            # Reset
            setparameter!(gvars[:integer_parameters], :suminterval, 0)
            setparameter!(gvars[:float_parameters], :sumgddcuts, 0)
            setparameter!(gvars[:float_parameters], :bprevsum, gvars[:sumwabal].Biomass)
            setparameter!(gvars[:float_parameters], :yprevsum, gvars[:sumwabal].YieldPart)
        end 
    end 

    # 14. Write results
    # 14.a Summation
    sumeto = gvars[:float_parameters][:sumeto]
    eto = gvars[:float_parameters][:eto]
    setparameter!(gvars[:float_parameters], :sumeto, sumeto + eto)

    sumgdd = gvars[:float_parameters][:sumgdd]
    gddayi = gvars[:float_parameters][:gddayi]
    setparameter!(gvars[:float_parameters], :sumgdd, sumgdd + gddayi)
    # 14.b Stress totals
    if gvars[:float_parameters][:cciactual] > 0
        # leaf expansion growth
        if gvars[:float_parameters][:stressleaf] > - 0.000001
            gvars[:stresstot].Exp = ((gvars[:stresstot].NrD - 1)*gvars[:stresstot].Exp +
                                     gvars[:float_parameters][:stressleaf])/(gvars[:stresstot].NrD)
        end 
        # stomatal closure
        if gvars[:float_parameters][:tpot] > 0
            stressstomata = 100 *(1 - gvars[:float_parameters][:tact]/gvars[:float_parameters][:tpot])
            if stressstomata > - 0.000001
                gvars[:stresstot].Sto = ((gvars[:stresstot].NrD - 1) *
                                         gvars[:stresstot].Sto + stressstomata) / (gvars[:stresstot].NrD)
            end 
        end 
    end 
    # weed stress
    if gvars[:float_parameters][:weedrci] > - 0.000001
        gvars[:stresstot].Weed =  ((gvars[:stresstot].NrD - 1)*gvars[:stresstot].Weed +
                                     gvars[:float_parameters][:weedrci])/(gvars[:stresstot].NrD)
    end 
    # 14.c Assign crop parameters
    gvars[:plotvarcrop].ActVal = gvars[:float_parameters][:cciactual]/gvars[:float_parameters][:ccxcrop_weednosf_stress] * 100
    gvars[:plotvarcrop].PotVal = 100 * (1/gvars[:float_parameters][:ccxcrop_weednosf_stress]) * 
                                   canopy_cover_no_stress_sf(virtualtimecc+gvars[:simulation].DelayedDays + 1,
                                     gvars[:crop].DaysToGermination, gvars[:crop].DaysToSenescence, 
                                     gvars[:crop].DaysToHarvest, gvars[:crop].GDDaysToGermination, 
                                     gvars[:crop].GDDaysToSenescence, gvars[:crop].GDDaysToHarvest, 
                                     gvars[:float_parameters][:fweednos]*gvars[:crop].CCo, 
                                     gvars[:float_parameters][:fweednos]*gvars[:crop].CCx, 
                                     gvars[:float_parameters][:cgcref], 
                                     gvars[:crop].CDC*(gvars[:float_parameters][:fweednos]*gvars[:crop].CCx + 2.29)/(gvars[:crop].CCx + 2.29),
                                     gvars[:float_parameters][:gddcgcref], 
                                     gvars[:crop].GDDCDC*(gvars[:float_parameters][:fweednos]*gvars[:crop].CCx + 2.29)/(gvars[:crop].CCx + 2.29), 
                                     sumgddadjcc, gvars[:crop].ModeCycle, 0, 0,
                                     gvars[:simulation])
    if (virtualtimecc+gvars[:simulation].DelayedDays + 1) <= gvars[:crop].DaysToFullCanopySF
        # not yet canopy decline with soil fertility stress
        potvalsf = 100 * (1/gvars[:float_parameters][:ccxcrop_weednosf_stress]) * 
                           canopy_cover_no_stress_sf(
                            virtualtimecc + gvars[:simulation].DelayedDays + 1, 
                            gvars[:crop].DaysToGermination, 
                            gvars[:crop].DaysToSenescence, gvars[:crop].DaysToHarvest, 
                            gvars[:crop].GDDaysToGermination, gvars[:crop].GDDaysToSenescence, 
                            gvars[:crop].GDDaysToHarvest,
                            gvars[:float_parameters][:ccototal],
                            gvars[:float_parameters][:ccxtotal],
                            gvars[:crop].CGC,
                            gvars[:float_parameters][:cdctotal],
                            gvars[:crop].GDDCGC,
                            gvars[:float_parameters][:gddcdctotal],
                            sumgddadjcc, gvars[:crop].ModeCycle, 
                            gvars[:simulation].EffectStress.RedCGC, 
                            gvars[:simulation].EffectStress.RedCCX,
                            gvars[:simulation])
    else
        potvalsf = get_potvalsf(virtualtimecc+gvars[:simulation].DelayedDays + 1, sumgddadjcc, gvars)
    end 

    # 14.d Print ---------------------------------------
    if gvars[:integer_parameters][:outputaggregate] > 0
        check_for_print!(outputs, gvars)
    end 
    if gvars[:bool_parameters][:outdaily] 
        wpi = lvars[:float_parameters][:wpi]
        dap = gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays - gvars[:crop].Day1 + 1
        write_daily_results!(outputs, gvars, dap, wpi, nrrun)
    end
    if gvars[:bool_parameters][:part2Eval] & (gvars[:string_parameters][:observations_file] != "(None)")
        dap = gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays - gvars[:crop].Day1 + 1
        write_evaluation_data!(outputs, gvars, dap, nrrun)
    end 

    # 15. Prepare Next day
    # 15.a Date
    setparameter!(gvars[:integer_parameters], :daynri, gvars[:integer_parameters][:daynri] + 1)
    # 15.b Irrigation
    if gvars[:integer_parameters][:daynri] == gvars[:crop].Day1
        setparameter!(gvars[:integer_parameters], :irri_interval, 1)
    else
        setparameter!(gvars[:integer_parameters], :irri_interval, gvars[:integer_parameters][:irri_interval] + 1)
    end 
    # 15.c Rooting depth
    # 15.bis extra line for standalone
    if gvars[:bool_parameters][:outdaily]
        determine_growth_stage!(gvars, gvars[:integer_parameters][:daynri], gvars[:float_parameters][:cciprev])
    end
    # 15.extra - reset ageing of Kc at recovery after full senescence
    if gvars[:simulation].SumEToStress >= 0.1
        setparameter!(gvars[:integer_parameters], :daylastcut, gvars[:integer_parameters][:daynri])
    end 
    return nothing
end 

"""
    get_z_and_ec_gwt!(gvars)

run.f90:GetZandECgwt:6137
"""
function get_z_and_ec_gwt!(gvars)
    ziaqua = gvars[:integer_parameters][:ziaqua]
    ziin = ziaqua
    if gvars[:gwtable].DNr1 == gvars[:gwtable].DNr2
        ziaqua  = gvars[:gwtable].Z1
        eciaqua = gvars[:gwtable].EC1
    else
        ziaqua = gvars[:gwtable].Z1 + 
                 round(Int, (gvars[:integer_parameters][:daynri] - gvars[:gwtable].DNr1) * 
                            (gvars[:gwtable].Z2 - gvars[:gwtable].Z1) / 
                            (gvars[:gwtable].DNr2 - gvars[:gwtable].DNr1))
        eciaqua = gvars[:gwtable].EC1 + 
                 (gvars[:integer_parameters][:daynri] - gvars[:gwtable].DNr1) * 
                 (gvars[:gwtable].EC2 - gvars[:gwtable].EC1) /
                 (gvars[:gwtable].DNr2 - gvars[:gwtable].DNr1)
    end 
    if ziaqua != ziin
        calculate_adjusted_fc!(gvars[:compartments], gvars[:soil_layers], ziaqua/100)
    end 

    setparameter!(gvars[:integer_parameters], :ziaqua, ziaqua)
    setparameter!(gvars[:float_parameters], :eciaqua, eciaqua)
    return nothing
end

"""
    get_irri_param!(gvars, lvars)

run.f90:GetIrriParam:6240
"""
function get_irri_param!(gvars, lvars)
    irri_info_record1 = gvars[:irri_info_record1]
    irri_info_record2 = gvars[:irri_info_record2]

    targettimeval = -999
    targetdepthval = -999
    if (gvars[:integer_parameters][:daynri] < gvars[:crop].Day1) | 
       (gvars[:integer_parameters][:daynri] > gvars[:crop].DayN)
        irrigation = irri_out_season(gvars)
        setparameter!(gvars[:float_parameters], :irrigation, irrigation)
    elseif gvars[:symbol_parameters][:irrimode] == :Manual
        irri_manual!(gvars)
    end 
    if (gvars[:symbol_parameters][:irrimode] == :Generate) &
       (gvars[:integer_parameters][:daynri] >= gvars[:crop].Day1) &
       (gvars[:integer_parameters][:daynri] <= gvars[:crop].DayN)
        # read next line if required
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
        if dayinseason > gvars[:irri_info_record1].ToDay
            # read next line
            gvars[:irri_info_record1] = gvars[:irri_info_record2]

            Irri_1 = gvars[:array_parameters][:Irri_1]
            Irri_2 = gvars[:array_parameters][:Irri_2]
            Irri_3 = gvars[:array_parameters][:Irri_3]
            Irri_4 = gvars[:array_parameters][:Irri_4]
            if length(Irri_1) == 0
                irri_info_record1.ToDay = gvars[:crop].DayN - gvars[:crop].Day1 + 1
            else
                irri_info_record2.NoMoreInfo = false
                fromday = Int(popfirst!(Irri_1))
                timeinfo = Int(popfirst!(Irri_1))
                depthinfo = Int(popfirst!(Irri_1))
                irriecw = popfirst!(Irri_4)
                irri_info_record2.FromDay = fromday 
                irri_info_record2.TimeInfo = timeinfo 
                irri_info_record2.DepthInfo = depthinfo 
                gvars[:simulation].IrriECw = irriecw
                irri_info_record1.ToDay = irri_info_record2.FromDay - 1
            end 
            setparameter!(gvars[:array_parameters], :Irri_1, Irri_1)
            setparameter!(gvars[:array_parameters], :Irri_2, Irri_2)
            setparameter!(gvars[:array_parameters], :Irri_3, Irri_3)
            setparameter!(gvars[:array_parameters], :Irri_4, Irri_4)
        end 
        # get TargetValues
        targetdepthval = gvars[:irri_info_record1].DepthInfo
        if gvars[:symbol_parameters][:timemode] == :AllDepl
            targettimeval = gvars[:irri_info_record1].TimeInfo

        elseif gvars[:symbol_parameters][:timemode] == :AllRAW
            targettimeval = gvars[:irri_info_record1].TimeInfo

        elseif gvars[:symbol_parameters][:timemode] == :FixInt
            targettimeval = gvars[:irri_info_record1].TimeInfo
            if targettimeval > gvars[:integer_parameters][:irri_interval] # do not yet irrigate
                targettimeval = 0
            elseif targettimeval == gvars[:integer_parameters][:irri_interval]  # irrigate
                targettimeval = 1
            else
                # still to solve
                targettimeval = 1 # temporary solution
            end 
            if (targettimeval == 1) &
               (gvars[:symbol_parameters][:depthmode] == :FixDepth)
                setparameter!(gvars[:float_parameters], :irrigation, targetdepthval)
            end 

        elseif gvars[:symbol_parameters][:timemode] == :WaterBetweenBunds
            targettimeval = gvars[:irri_info_record1].TimeInfo
            if (gvars[:management].BundHeight >= 0.01) &
               (gvars[:symbol_parameters][:depthmode] == :FixDepth) &
               (targettimeval < (1000 * gvars[:management].BundHeight)) &
               (targettimeval >= round(Int, gvars[:float_parameters][:surfacestorage]))
                setparameter!(gvars[:float_parameters], :irrigation, targetdepthval)
            else
                setparameter!(gvars[:float_parameters], :irrigation, 0.0)
            end 
            targettimeval = -999 # no need for check in SIMUL
       end 
    end 

    setparameter!(lvars[:integer_parameters], :targettimeval, targettimeval)
    setparameter!(lvars[:integer_parameters], :targetdepthval, targetdepthval)
    return nothing
end 

"""
    irri = irri_out_season(gvars)

run.f90:IrriOutSeason:6166
"""
function irri_out_season(gvars)
    irrievents = RepDayEventInt[RepDayEventInt() for _ in 1:5]

    dnr = gvars[:integer_parameters][:daynri] - gvars[:simulation].FromDayNr + 1
    for i in 1:5
        irrievents[i] = gvars[:irri_before_season][i]
    end 
    if gvars[:integer_parameters][:daynri] > gvars[:crop].DayN
        dnr = gvars[:integer_parameters][:daynri] - gvars[:crop].DayN
        for i in 1:5
            irrievents[i] = gvars[:irri_after_season][i]
        end 
    end 
    if dnr < 1
        irri = 0
    else
        theend = false
        nri = 0
        loopi = true
        while loopi
            nri = nri + 1
            if irrievents[nri].DayNr == dnr
                irri = irrievents[nri].Param
                theend = true
            else
                irri = 0
            end 
            if (nri == 5) | (irrievents[nri].DayNr == 0) |
               (irrievents[nri].DayNr > dnr) |
               (theend)
               loopi = false
           end
        end
    end 
    return irri
end

"""
    irri_manual!(gvars)

run.f90:IrriManual:6202
"""
function irri_manual!(gvars)
    irri_info_record1 = gvars[:irri_info_record1]

    if gvars[:integer_parameters][:irri_first_daynr] == undef_int
        dnr = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
    else
        dnr = gvars[:integer_parameters][:daynri] - gvars[:integer_parameters][:irri_first_daynr] + 1
    end 
    if irri_info_record1.NoMoreInfo
        irri = 0
    else
        irri = 0
        if irri_info_record1.TimeInfo == dnr
            Irri_1 = gvars[:array_parameters][:Irri_1]
            Irri_2 = gvars[:array_parameters][:Irri_2]
            Irri_3 = gvars[:array_parameters][:Irri_3]

            irri = irri_info_record1.DepthInfo
            if length(Irri_1) == 0
                irri_info_record1.NoMoreInfo = true
            else
                ir1 = round(Int, popfirst!(Irri_1))
                ir2 = round(Int, popfirst!(Irri_2))
                irriecw = popfirst!(Irri_3)
                gvars[:simulation].IrriECw = irriecw
                irri_info_record1.TimeInfo = ir1
                irri_info_record1.DepthInfo = ir2
                irri_info_record1.NoMoreInfo = false 
            end 
            setparameter!(gvars[:array_parameters], :Irri_1, Irri_1)
            setparameter!(gvars[:array_parameters], :Irri_2, Irri_2)
            setparameter!(gvars[:array_parameters], :Irri_3, Irri_3)
        end 
    end 

    setparameter!(gvars[:float_parameters], :irrigation, irri)
    return nothing
end

"""
    ccini = ccini_total_from_time_to_ccini(tempdaystoccini, tempgddaystoccini, 
                                            l0, l12, l12sf, l123, l1234, gddl0, 
                                            gddl12, gddl12sf, gddl123, 
                                            gddl1234, cco, ccx, cgc, gddcgc, 
                                            cdc, gddcdc, ratdgdd, sfredcgc, 
                                            sfredccx, sfcdecline, fweed, 
                                            themodecycle, simulation)


global.f90:CCiniTotalFromTimeToCCini:6408
"""
function ccini_total_from_time_to_ccini(tempdaystoccini, tempgddaystoccini, 
                                            l0, l12, l12sf, l123, l1234, gddl0, 
                                            gddl12, gddl12sf, gddl123, 
                                            gddl1234, cco, ccx, cgc, gddcgc, 
                                            cdc, gddcdc, ratdgdd, sfredcgc, 
                                            sfredccx, sfcdecline, fweed, 
                                            themodecycle, simulation)

    if tempdaystoccini != 0
        # regrowth
        sumgddforccini = undef_double #real(undef_int, kind=dp)
        gddtadj = undef_int
        # find adjusted calendar and GDD time
        if tempdaystoccini == undef_int
            # CCx on 1st day
            tadj = l12 - l0
            if themodecycle == :GDDays
                gddtadj = gddl12 - gddl0
            end 
        else
            # CC on 1st day is < CCx
            tadj = tempdaystoccini
            if themodecycle == :GDDays
                gddtadj = tempgddaystoccini
            end 
        end 
        # calculate CCini with adjusted time
        daycc = l0 + tadj
        if themodecycle == :GDDays
            sumgddforccini = gddl0 + gddtadj
        end 
        tempccini = cci_no_water_stress_sf(daycc, l0, l12sf, l123, l1234, gddl0, 
                                       gddl12sf, gddl123, gddl1234, 
                                       (cco*fweed), (ccx*fweed), cgc, gddcgc, 
                                       (cdc*(fweed*ccx+2.29)/(ccx+2.29)), 
                                       (gddcdc*(fweed*ccx+2.29)/(ccx+2.29)), 
                                       sumgddforccini, ratdgdd, sfredcgc, 
                                       sfredccx, sfcdecline, themodecycle, simulation)
        # correction for fWeed is already in TempCCini (since DayCC > 0);
    else
        tempccini = (cco*fweed) # sowing or transplanting
    end 

    return tempccini
end

"""
    adjusted_rooting_depth!(gvars)

rootunit.f90:AdjustedRootingDepth:37
"""
function adjusted_rooting_depth!(gvars)
    ccact = gvars[:plotvarcrop].ActVal 
    ccpot = gvars[:plotvarcrop].PotVal 
    tpot = gvars[:float_parameters][:tpot] 
    tact = gvars[:float_parameters][:tact] 
    stressleaf = gvars[:float_parameters][:stressleaf] 
    stresssenescence = gvars[:float_parameters][:stresssenescence] 
    dap = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
    l0 = gvars[:crop].DaysToGermination
    lzmax = gvars[:crop].DaysToMaxRooting
    l1234 = gvars[:crop].DaysToHarvest
    gddl0 = gvars[:crop].GDDaysToGermination
    gddlzmax = gvars[:crop].GDDaysToMaxRooting
    gddl1234 = gvars[:crop].GDDaysToHarvest
    sumgddprev = gvars[:float_parameters][:sumgddprev]
    sumgdd = gvars[:simulation].SumGDD
    zmin = gvars[:crop].RootMin
    zmax = gvars[:crop].RootMax
    ziprev = gvars[:float_parameters][:ziprev]
    shapefactor = gvars[:crop].RootShape
    typedays = gvars[:crop].ModeCycle


    if ziprev == undef_double
        gvars[:simulation].SCor = 1
        zi = actual_rooting_depth(dap, l0, lzmax, l1234, gddl0, gddlzmax,
                                sumgdd, zmin, zmax, shapefactor, typedays, gvars)
    else
        # 1. maximum rooting depth (ZiMax) that could have been reached at
        #    time t
        # -- 1.1 Undo effect of restrictive soil layer(s)
        if round(Int, gvars[:soil].RootMax*1000) < round(Int, zmax*1000)
            zlimit = gvars[:soil].RootMax
            gvars[:soil].RootMax = zmax
        else
            zlimit = zmax
        end 

        # -- 1.2 Calculate ZiMax
        gvars[:simulation].SCor = 1
        zimax = actual_rooting_depth(dap, l0, lzmax, l1234, gddl0, gddlzmax,
                                sumgdd, zmin, zmax, shapefactor, typedays, gvars)
        # -- 1.3 Restore effect of restrive soil layer(s)
        gvars[:soil].RootMax = zlimit 

        # 2. increase (dZ) at time t
        gvars[:simulation].SCor = 1
        ziunlimm1 = actual_rooting_depth(dap-1, l0, lzmax, l1234, gddl0, gddlzmax,
                                sumgddprev, zmin, zmax, shapefactor, typedays, gvars)
        ziunlim = zimax 

        dz = ziunlim - ziunlimm1

        # 3. corrections of dZ
        # -- 3.1 correction for restrictive soil layer is already considered
        #    in ActualRootingDepth

        # -- 3.2 correction for stomatal closure
        if (tpot > 0) & (tact < tpot) & (gvars[:simulparam].KsShapeFactorRoot != undef_int)
            if gvars[:simulparam].KsShapeFactorRoot >= 0
                dz = dz * (tact/tpot)   # linear
            else
                ksshapefactorroot = gvars[:simulparam].KsShapeFactorRoot
                dz = dz * (exp((tact/tpot)*ksshapefactorroot)-1) / (exp(ksshapefactorroot)-1) # exponential
            end 
        end 

        # -- 3.2 correction for dry soil at expansion front of actual root
        #        zone
        if dz > 0.001
            # soil water depletion threshold for root deepening
            pzexp = gvars[:crop].pdef + (1 - gvars[:crop].pdef)/2
            # restrictive soil layer is considered by ActualRootingDepth
            zitest = ziprev + dz
            compi = 0
            zsoil = 0
            while (zsoil < zitest) & (compi < length(gvars[:compartments]))
                compi = compi + 1
                zsoil = zsoil + gvars[:compartments][compi].Thickness
            end 
            layer = gvars[:compartments][compi].Layer
            tawcompi = gvars[:soil_layers][layer].FC/100 - gvars[:soil_layers][layer].WP/100
            thetatreshold = gvars[:soil_layers][layer].FC/100 - pzexp * tawcompi
            if gvars[:compartments][compi].Theta < thetatreshold
                # expansion is limited due to soil water content at
                # expansion front
                if gvars[:compartments][compi].Theta <= gvars[:soil_layers][layer].WP/100 
                    dz = 0
                else
                    wrel = (gvars[:soil_layers][layer].FC/100 - gvars[:compartments][compi].Theta)/tawcompi
                    dz = dz * ks_any(wrel, pzexp, 1, gvars[:crop].KsShapeFactorStomata)
                end 
            end 
        end 

        # -- 3.3 correction for early senescence
        if (ccact <= 0) & (ccpot > 50)
            dz = 0
        end 

        # -- 3.4 correction for no germination
        if !gvars[:simulation].Germinate
            dz = 0
        end 

        # 4. actual rooting depth (Zi)
        zi = ziprev + dz

        # 5. Correction for root density if root deepening is restricted
        #    (dry soil and/or restricitive layers)
        if round(Int, zi*1000) < round(Int, zimax*1000)
            # Total extraction in restricted root zone (Zi) and max root
            # zone (ZiMax) should be identical
            gvars[:simulation].SCor = (2*(zimax/zi)*((gvars[:crop].SmaxTop+gvars[:crop].SmaxBot)/2) - 
                                                      gvars[:crop].SmaxTop)/gvars[:crop].SmaxBot
            # consider part of the restricted deepening due to water stress
            # (= less roots)
            if gvars[:sumwabal].Tpot > 0
                gvars[:simulation].SCor = gvars[:simulation].SCor * gvars[:sumwabal].Tact / gvars[:sumwabal].Tpot
                if gvars[:simulation].SCor < 1
                    gvars[:simulation].SCor = 1
                end 
            end 
        else
            gvars[:simulation].SCor = 1
        end 
    end 

    setparameter!(gvars[:float_parameters], :rooting_depth, zi)
    return nothing 
end

"""
    determine_root_zone_wc!(gvars, rootingdepth)

global.f90:DetermineRootZoneWC:7787
"""
function determine_root_zone_wc!(gvars, rootingdepth)
    root_zone_wc = gvars[:root_zone_wc]  
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]

    # calculate SWC in root zone
    cumdepth = 0
    compi = 0
    root_zone_wc.Actual = 0 
    root_zone_wc.FC = 0
    root_zone_wc.WP = 0
    root_zone_wc.SAT = 0
    root_zone_wc.Leaf = 0
    root_zone_wc.Thresh = 0
    root_zone_wc.Sen = 0

    loopi = true
    while loopi
        compi = compi + 1
        cumdepth = cumdepth + compartments[compi].Thickness
        if cumdepth <= rootingdepth
            factor = 1
        else
            frac_value = rootingdepth - (cumdepth - compartments[compi].Thickness)
            if frac_value > 0
                factor = frac_value/compartments[compi].Thickness
            else
                factor = 0
            end
        end 
        root_zone_wc.Actual = root_zone_wc.Actual + factor * 1000 * 
                              compartments[compi].Theta * compartments[compi].Thickness * 
                              (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.FC = root_zone_wc.FC + factor * 10 * 
                          soil_layers[compartments[compi].Layer].FC * compartments[compi].Thickness *
                          (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.Leaf = root_zone_wc.Leaf + factor * 10 * compartments[compi].Thickness * 
                            (soil_layers[compartments[compi].Layer].FC - crop.pLeafAct *
                             (soil_layers[compartments[compi].Layer].FC -
                              soil_layers[compartments[compi].Layer].WP)) *
                            (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.Thresh = root_zone_wc.Thresh + factor * 10 * compartments[compi].Thickness * 
                              (soil_layers[compartments[compi].Layer].FC - crop.pActStom *
                               (soil_layers[compartments[compi].Layer].FC -
                                soil_layers[compartments[compi].Layer].WP)) *
                              (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.Sen = root_zone_wc.Sen + factor * 10 * compartments[compi].Thickness * 
                           (soil_layers[compartments[compi].Layer].FC - crop.pSenAct *
                            (soil_layers[compartments[compi].Layer].FC -
                             soil_layers[compartments[compi].Layer].WP)) *
                           (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.WP = root_zone_wc.WP + factor * 10 * 
                          soil_layers[compartments[compi].Layer].WP * 
                          compartments[compi].Thickness *
                          (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        root_zone_wc.SAT = root_zone_wc.SAT+ factor * 10 * 
                           soil_layers[compartments[compi].Layer].SAT * 
                           compartments[compi].Thickness *
                           (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
        if (cumdepth >= rootingdepth) | (compi == length(compartments))
            loopi = false
        end
    end
    # calculate SWC in top soil (top soil in meter = SimulParam.ThicknessTopSWC/100)
    if (rootingdepth*100) <= simulparam.ThicknessTopSWC
        root_zone_wc.ZtopAct = root_zone_wc.Actual
        root_zone_wc.ZtopFC = root_zone_wc.FC
        root_zone_wc.ZtopWP = root_zone_wc.WP
        root_zone_wc.ZtopThresh = root_zone_wc.Thresh
    else
        cumdepth = 0
        compi = 0
        root_zone_wc.ZtopAct = 0
        root_zone_wc.ZtopFC = 0
        root_zone_wc.ZtopWP = 0
        root_zone_wc.ZtopThresh = 0
        topsoilinmeter = simulparam.ThicknessTopSWC/100
        loopi = true
        while loopi
            compi = compi + 1
            cumdepth = cumdepth + compartments[compi].Thickness
            if (cumdepth*100) <= simulparam.ThicknessTopSWC
                factor = 1
            else
                frac_value = topsoilinmeter - (cumdepth - compartments[compi].Thickness)
                if frac_value > 0
                    factor = frac_value/compartments[compi].Thickness
                else
                    factor = 0
                end 
            end 
            root_zone_wc.ZtopAct = root_zone_wc.ZtopAct + factor * 1000 *
                                   compartments[compi].Theta * compartments[compi].Thickness *
                                   (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            root_zone_wc.ZtopFC = root_zone_wc.ZtopFC + factor * 10 * 
                                  soil_layers[compartments[compi].Layer].FC * 
                                  compartments[compi].Thickness *
                                  (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            root_zone_wc.ZtopWP = root_zone_wc.ZtopWP + factor * 10 *
                                  soil_layers[compartments[compi].Layer].WP * 
                                  compartments[compi].Thickness *
                                  (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            root_zone_wc.ZtopThresh = root_zone_wc.ZtopThresh + factor * 10 *
                                      compartments[compi].Thickness *
                                      (soil_layers[compartments[compi].Layer].FC - crop.pActStom *
                                       (soil_layers[compartments[compi].Layer].FC -
                                        soil_layers[compartments[compi].Layer].WP)) *
                                      (1 - soil_layers[compartments[compi].Layer].GravelVol/100)
            if (cumdepth >= topsoilinmeter) | (compi == length(compartments))
                loopi = false
            end
        end 
    end 

    # Relative depletion in rootzone and in top soil
    if round(Int, 1000*(root_zone_wc.FC - root_zone_wc.WP)) > 0
        drrel = (root_zone_wc.FC - root_zone_wc.Actual) / 
                (root_zone_wc.FC - root_zone_wc.WP)
    else
        drrel = 0
    end 
    if round(Int, 1000*(root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)) > 0
        dztoprel = (root_zone_wc.ZtopFC - root_zone_wc.ZtopAct) / 
                   (root_zone_wc.ZtopFC - root_zone_wc.ZtopWP)
    else
        dztoprel = 0
    end 

    # Zone in soil profile considered for determining stress response
    if dztoprel < drrel
        ztopswcconsidered = true  # top soil is relative wetter than root zone
    else
        ztopswcconsidered = false
    end 

    simulation.SWCtopSoilConsidered = ztopswcconsidered
    return nothing
end

"""
    adjust_swc_rootzone!(gvars, lvars)

run.f90:AdjustSWCRootZone:6326
"""
function adjust_swc_rootzone!(gvars, lvars)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]
    crop = gvars[:crop]

    compi = 0
    sumdepth = 0
    preirri = 0
    loopi = true
    while loopi
        compi = compi + 1
        sumdepth = sumdepth + compartments[compi].Thickness
        layeri = compartments[compi].Layer
        thetapercraw = soil_layers[layeri].FC/100 - simulparam.PercRAW/100 * crop.pdef *  
                       (soil_layers[layeri].FC/100 - soil_layers[layeri].WP/100)
        if compartments[compi].Theta < thetapercraw
            preirri = preirri + (thetapercraw - compartments[compi].Theta) *
                      1000 * compartments[compi].Thickness
            compartments[compi].Theta = thetapercraw
        end 
        if (sumdepth >= gvars[:float_parameters][:rooting_depth]) |
           (compi == length(compartments))
            loopi = false
        end
    end

    setparameter!(lvars[:float_parameters], :preirri, preirri)
    return nothing
end

"""
    initialize_transfer_assimilates!(gvars, lvars)

run.f90:InitializeTransferAssimilates:6356
"""
function initialize_transfer_assimilates!(gvars, lvars)
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    management = gvars[:management]
    daynri = gvars[:integer_parameters][:daynri]
    cciactual = gvars[:float_parameters][:cciactual]
    ccxtotal = gvars[:float_parameters][:ccxtotal]

    bin = gvars[:float_parameters][:bin]
    bout = gvars[:float_parameters][:bout]
    assimtomobilize = gvars[:transfer].ToMobilize
    assimmobilized = gvars[:transfer].Bmobilized
    storageon = gvars[:transfer].Store
    mobilizationon = gvars[:transfer].Mobilize

    harvestnow = lvars[:bool_parameters][:harvestnow]
    fracassim = lvars[:float_parameters][:fracassim]

    bin = 0
    bout = 0
    fracassim = 0
    if crop.subkind == :Forage
        # only for perennial herbaceous forage crops
        fracassim = 0
        if gvars[:bool_parameters][:nomorecrop]
            storageon = false
            mobilizationon = false
        else
            # Start of storage period ?
            if (daynri - simulation.DelayedDays - crop.Day1 + 1) ==
               (crop.DaysToHarvest - crop.Assimilates.Period + 1)
                # switch storage on
                storageon = true
                # switch mobilization off
                if mobilizationon
                    assimtomobilize = assimmobilized
                end 
                mobilizationon = false
            end 
            # Fraction of assimilates transferred
            if mobilizationon
                tmob = (assimtomobilize-assimmobilized)/assimtomobilize
                if assimtomobilize > assimmobilized
                    fracassim = (exp(-5*tmob) - 1)/(exp(-5) - 1)
                    if cciactual > (0.9 * ccxtotal * (1 - simulation.EffectStress.RedCCX/100))
                        fracassim = fracassim * (ccxtotal * 
                                    (1 - simulation.EffectStress.RedCCX/100) - cciactual) / 
                                    (0.1 * ccxtotal * (1 - simulation.EffectStress.RedCCX/100))
                    end 
                    if fracassim < eps()
                        fracassim = 0
                    end 
                else
                    # everything is mobilized
                    fracassim = 0
                end 
            end 

            if storageon & (crop.Assimilates.Period > 0)
                if harvestnow
                    fracsto = 0
                else
                    if (cciactual > management.Cuttings.CCcut/100) &
                       (cciactual < (ccxtotal * (1 - simulation.EffectStress.RedCCX/100)))
                        fracsto = (cciactual - management.Cuttings.CCcut/100) /
                                  ((ccxtotal * (1 - simulation.EffectStress.RedCCX/100)) -
                                     management.Cuttings.CCcut/100)
                    else
                        fracsto = 1
                    end 
                end 
                # Use convex function
                fracassim = fracsto * crop.Assimilates.Stored/100 * 
                            (1 - ks_any(
                            (daynri - simulation.DelayedDays - crop.Day1 + 1 - 
                            (crop.DaysToHarvest - crop.Assimilates.Period)) / crop.Assimilates.Period,
                            0, 1, -5))
            end 
            if fracassim < 0
                fracassim = 0
            end 
            if fracassim > 1
                fracassim = 1
            end 
        end 
    end 

    setparameter!(gvars[:float_parameters], :bin, bin)
    setparameter!(gvars[:float_parameters], :bout, bout)
    gvars[:transfer].ToMobilize = assimtomobilize
    gvars[:transfer].Bmobilized = assimmobilized
    gvars[:transfer].Store = storageon
    gvars[:transfer].Mobilize = mobilizationon

    setparameter!(lvars[:float_parameters], :fracassim, fracassim)
    return nothing
end

"""
    determine_potential_biomass!(gvars, virtualtimecc, sumgddadjcc)

simul.f90:DeterminePotentialBiomass:454
"""
function determine_potential_biomass!(gvars, virtualtimecc, sumgddadjcc)

    co2i = gvars[:float_parameters][:co2i]
    gddayi = gvars[:float_parameters][:gddayi]
    biomassunlim = gvars[:sumwabal].BiomassUnlim
    ccxwitheredtpotnos = gvars[:float_parameters][:ccxwitheredtpotnos]

    simulation = gvars[:simulation]
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]

    # potential biomass - unlimited soil fertiltiy
    # 1. - CCi
    ccipot = canopy_cover_no_stress_sf(virtualtimecc + simulation.DelayedDays + 1, 
                                  crop.DaysToGermination, crop.DaysToSenescence, 
                                  crop.DaysToHarvest, crop.GDDaysToGermination, 
                                  crop.GDDaysToSenescence, crop.GDDaysToHarvest, 
                                  crop.CCo, crop.CCx, crop.CGC, 
                                  crop.CDC, crop.GDDCGC, crop.GDDCDC, 
                                  sumgddadjcc, crop.ModeCycle, 0, 0, simulation)
    if ccipot < 0
        ccipot = 0
    end 
    if ccipot > ccxwitheredtpotnos
        ccxwitheredtpotnos = ccipot
    end 

    # 2. - Calculation of Tpot
    if crop.ModeCycle == :CalendarDays
        dap = virtualtimecc
    else
        # growing degree days
        dap = sum_calendar_days(round(Int, sumgddadjcc), crop.Day1, crop.Tbase, 
                    crop.Tupper, simulparam.Tmin, simulparam.Tmax, gvars)
        dap = dap + simulation.DelayedDays # are not considered when working with GDDays
    end 
    tpotforb, epottotforb = calculate_etpot(dap, crop.DaysToGermination, crop.DaysToFullCanopy, 
                   crop.DaysToSenescence, crop.DaysToHarvest, 0, ccipot, 
                   gvars[:float_parameters][:eto],
                   crop.KcTop, crop.KcDecline, crop.CCx, 
                   ccxwitheredtpotnos, crop.CCEffectEvapLate, co2i, gddayi, 
                   crop.GDtranspLow, simulation, simulparam)

    # 3. - WPi for that day
    # 3a - given WPi
    wpi = crop.WP/100
    # 3b - WPi decline in reproductive stage  (works with calendar days)
    if ((crop.subkind == :Grain) | (crop.subkind == :Tuber)) &
       (crop.WPy < 100) & (crop.dHIdt > 0) & (virtualtimecc >= crop.DaysToFlowering)
        # WPi in reproductive stage
        fswitch = 1
        daysyieldformation = round(Int, crop.HI/crop.dHIdt)
        dayiafterflowering = virtualtimecc - crop.DaysToFlowering
        if (daysyieldformation > 0) & (dayiafterflowering < (daysyieldformation/3))
            fswitch = dayiafterflowering/(daysyieldformation/3)
        end 
        wpi =  wpi * (1 - (1-crop.WPy/100)*fswitch)
    end 
    # 3c - adjustment WPi for CO2
    if round(Int, 100*co2i) != round(Int, 100*CO2Ref)
        wpi = wpi * fadjusted_for_co2(co2i, crop.WP, crop.AdaptedToCO2)
    end 

    # 4. - Potential Biomass
    if gvars[:float_parameters][:eto] > 0
        biomassunlim = biomassunlim + wpi * tpotforb/gvars[:float_parameters][:eto] # ton/ha
    end 

    setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, ccxwitheredtpotnos)
    gvars[:sumwabal].BiomassUnlim = biomassunlim
    return nothing
end

"""
    fadjustedforco2 = fadjusted_for_co2(co21, wpi, percenta)

global.f90:fAdjustedForCO2:2766
"""
function fadjusted_for_co2(co2i, wpi, percenta)
    # 1. Correction for crop type: fType
    if wpi >= 40
        ftype = 0 # no correction for c4 crops
    else
        if wpi <= 20
            ftype = 1 # full correction for c3 crops
        else
            ftype = (40-wpi)/(40-20)
        end 
    end 

    # 2. crop sink strength coefficient: fsink
    fsink = percenta/100
    if fsink < 0
        fsink = 0 # based on face expirements
    end 
    if fsink > 1
        fsink = 1 # theoretical adjustment
    end 

    # 3. correction coefficient for co2: fco2old
    fco2old = undef_int
    if co2i <= 550
        # 3.1 weighing factor for co2
        if co2i <= CO2Ref
            fw = 0
        else
            if co2i >= 550
                fw = 1
            else
                fw = 1 - (550 - co2i)/(550 - CO2Ref)
            end 
        end 

        # 3.2 adjustment for co2
        fco2old = (co2i/CO2Ref)/(1+(co2i-CO2Ref)*((1-fw)*0.000138
            + fw*(0.000138*fsink + 0.001165*(1-fsink))))
    end 

    # 4. adjusted correction coefficient for co2: fco2adj
    fco2adj = undef_int
    if co2i > CO2Ref
        # 4.1 shape factor
        fshape = -4.61824 - 3.43831*fsink - 5.32587*fsink*fsink

        # 4.2 adjustment for co2
        if co2i >= 2000
            fco2adj = 1.58  # maximum is reached
        else
            co2rel = (co2i-CO2Ref)/(2000-CO2Ref)
            fco2adj = 1 + 0.58 * ((exp(co2rel*fshape) - 1)/(exp(fshape) - 1))
        end 
    end 

    # 5. selected adjusted coefficient for co2: fco2
    if co2i <= CO2Ref
        fco2 = fco2old
    else
        fco2 = fco2adj
        if (co2i <= 550) & (fco2old < fco2adj)
            fco2 = fco2old
        end 
    end 

    # 6. final adjustment
    fadjustedforco2 = 1 + ftype*(fco2-1)
    return fadjustedforco2
end

"""
    determine_biomass_and_yield!(gvars, lvars, sumgddadjcc, virtualtimecc) 

simul.f90:DetermineBiomassAndYield:529
"""
function determine_biomass_and_yield!(gvars, lvars, sumgddadjcc, virtualtimecc) 

    dayi = gvars[:integer_parameters][:daynri]
    eto = gvars[:float_parameters][:eto]
    tminonday = gvars[:float_parameters][:tmin]
    tmaxonday = gvars[:float_parameters][:tmax]
    co2i = gvars[:float_parameters][:co2i]
    gddayi = gvars[:float_parameters][:gddayi]
    tact = gvars[:float_parameters][:tact]
    sumkctop = gvars[:float_parameters][:sumkctop]
    cgcref = gvars[:float_parameters][:cgcref]
    gddcgcref = gvars[:float_parameters][:gddcgcref]
    coeffb0 = gvars[:float_parameters][:coeffb0]
    coeffb1 = gvars[:float_parameters][:coeffb1]
    coeffb2 = gvars[:float_parameters][:coeffb2]
    fracbiomasspotsf = gvars[:float_parameters][:fracbiomasspotsf]
    coeffb0salt = gvars[:float_parameters][:coeffb0salt]
    coeffb1salt = gvars[:float_parameters][:coeffb1salt]
    coeffb2salt = gvars[:float_parameters][:coeffb2salt]
    averagesaltstress = gvars[:stresstot].Salt
    cctot = gvars[:float_parameters][:cciactual]
    suminterval  = gvars[:integer_parameters][:suminterval]

    biomass = gvars[:sumwabal].Biomass
    biomasspot = gvars[:sumwabal].BiomassPot
    biomassunlim = gvars[:sumwabal].BiomassUnlim
    biomasstot = gvars[:sumwabal].BiomassTot
    yieldpart = gvars[:sumwabal].YieldPart
    hitimesbef = gvars[:float_parameters][:hi_times_bef]
    scorat1 = gvars[:float_parameters][:scor_at1]
    scorat2 = gvars[:float_parameters][:scor_at2]
    hitimesat1 = gvars[:float_parameters][:hi_times_at1]
    hitimesat2 = gvars[:float_parameters][:hi_times_at2]
    hitimesat = gvars[:float_parameters][:hi_times_at]
    alfa = gvars[:float_parameters][:alfa_hi]
    alfamax = gvars[:float_parameters][:alfa_hi_adj]
    sumkctopstress = gvars[:float_parameters][:sumkctop_stress]
    sumkci = gvars[:float_parameters][:sumkci]
    weedrci = gvars[:float_parameters][:weedrci]
    ccw = gvars[:float_parameters][:cciactualweedinfested]
    trw = gvars[:float_parameters][:tactweedinfested]
    stresssfadjnew = gvars[:integer_parameters][:stress_sf_adj_new]
    previousstresslevel = gvars[:integer_parameters][:previous_stress_level]
    storeassimilates = gvars[:transfer].Store
    mobilizeassimilates = gvars[:transfer].Mobilize
    assimtomobilize = gvars[:transfer].ToMobilize
    assimmobilized = gvars[:transfer].Bmobilized
    bin = gvars[:float_parameters][:bin]
    bout = gvars[:float_parameters][:bout]

    fracassim = lvars[:float_parameters][:fracassim]
    wpi = lvars[:float_parameters][:wpi]


    temprange = 5
    k = 2

    # 0. Reference HarvestIndex for that day (alfa in percentage) + Information on PercentLagPhase (for estimate WPi)
    if (gvars[:crop].subkind == :Tuber) | (gvars[:crop].subkind == :Grain) |
       (gvars[:crop].subkind == :Vegetative) | (gvars[:crop].subkind == :Forage)
        # DaysToFlowering corresponds with Tuberformation
        # OJO note that we do not have parenthesis in the original Fortran code then the order 
        # of boolean operators might change
        if((gvars[:crop].subkind == :Vegetative) & (gvars[:crop].Planting == :Regrowth)) |
          ((gvars[:crop].subkind == :Forage) & (gvars[:crop].Planting == :Regrowth)) 
            alfa = gvars[:crop].HI
        else
            hifinal_temp = gvars[:simulation].HIfinal
            alfa, hifinal_temp, percentlagphase = harvest_index_day(dayi-gvars[:crop].Day1, gvars[:crop].DaysToFlowering, 
                                   gvars[:crop].HI, gvars[:crop].dHIdt,
                                   gvars[:float_parameters][:cciactual], 
                                   gvars[:crop].CCxAdjusted, gvars[:crop].CCxWithered, gvars[:simulparam].PercCCxHIfinal, 
                                   gvars[:crop].Planting, hifinal_temp, gvars[:crop], gvars[:simulation])
            gvars[:simulation].HIfinal = hifinal_temp
        end
    end


    wpi = gvars[:crop].WP/100

    # 1. biomass
    if eto > 0
        # 1.1 WPi for that day
        # 1.1a - given WPi
        wpi = gvars[:crop].WP/100
        # 1.1b - adjustment WPi for reproductive stage (works with calendar days)
        if ((gvars[:crop].subkind == :Tuber) | (gvars[:crop].subkind == :Grain)) & (alfa > 0)
            # WPi switch to WP for reproductive stage
            fswitch = 1
            daysyieldformation = round(Int, gvars[:crop].HI/gvars[:crop].dHIdt)
            if daysyieldformation > 0
                if gvars[:crop].DeterminancyLinked
                    fswitch = percentlagphase/100
                else
                    dayiafterflowering = dayi - gvars[:simulation].DelayedDays - gvars[:crop].Day1 - gvars[:crop].DaysToFlowering
                    if dayiafterflowering < (daysyieldformation/3)
                        fswitch = dayiafterflowering/(daysyieldformation/3)
                    end
                end
            end
            wpi =  wpi * (1 - (1-gvars[:crop].WPy/100)*fswitch)  # switch in Lag Phase
        end


        # 1.1c - adjustment WPi for CO2
        if round(Int, 100*co2i) != round(Int, 100*CO2Ref)
            wpi = wpi * fadjusted_for_co2(co2i, gvars[:crop].WP, gvars[:crop].AdaptedToCO2)
        end


        # 1.1d - adjustment WPi for Soil Fertility
        wpsf = wpi          # no water stress, but fertility stress
        wpunlim = wpi       # no water stress, no fertiltiy stress
        if gvars[:simulation].EffectStress.RedWP > 0 # Reductions are zero if no fertility stress
            # water stress and fertility stress
            if sumkci/sumkctopstress < 1
                if eto > 0
                    sumkci = sumkci + tact/eto
                end
                if sumkci > 0
                    wpi = wpi * (1 - (gvars[:simulation].EffectStress.RedWP/100) * exp(k*log(sumkci/sumkctopstress)) )
                end
            else
                wpi = wpi * (1 - gvars[:simulation].EffectStress.RedWP/100)
            end
        elseif eto > 0
            sumkci = sumkci + tact/eto
        end


        # 1.2 actual biomass
        if (gvars[:simulation].RCadj > 0) & (round(Int, cctot*10000) > 0)
            # weed infestation
            # green canopy cover of the crop in weed-infested field
            if gvars[:management].WeedDeltaRC != 0
                if gvars[:crop].subkind == :Forage
                    fccx = multiplier_ccx_self_thinning(gvars[:simulation].YearSeason, gvars[:crop].YearCCx, gvars[:crop].CCxRoot)
                else
                    fccx = 1
                end
                wdrc_temp = gvars[:management].WeedDeltaRC
                weedrci, wdrc_temp = get_weed_rc(virtualtimecc, sumgddadjcc, fccx, 
                                                gvars[:simulation].RCadj, gvars[:management].WeedAdj, wdrc_temp, 
                                                gvars[:crop].DaysToFullCanopySF, gvars[:crop].DaysToSenescence, 
                                                gvars[:crop].GDDaysToFullCanopySF, gvars[:crop].GDDaysToSenescence, 
                                                gvars[:crop].ModeCycle)
                gvars[:management].WeedDeltaRC = wdrc_temp
            else
                weedrci = gvars[:simulation].RCadj
            end
            ccw = cctot * (1-weedrci/100)
            # correction for micro-advection
            cctotstar = 1.72*cctot - 1*(cctot*cctot) + 0.30*(cctot*cctot*cctot)
            if cctotstar < 0
                cctotstar = 0
            end
            if cctotstar > 1
                cctotstar = 1
            end
            if ccw > 0.0001
                ccwstar = ccw + (cctotstar - cctot)
            else
                ccwstar = 0
            end
            # crop transpiration in weed-infested field
            if cctotstar <= 0.0001
                trw = 0
            else
                trw = tact * (ccwstar/cctotstar)
            end
            # crop biomass in weed-infested field
            biomass = biomass + wpi *(trw/eto)  # ton/ha
        else
            weedrci = 0.0
            ccw = cctot
            trw = tact
            biomass = biomass + wpi *(tact/eto)  # ton/ha
        end

        # Transfer of assimilates
        if gvars[:crop].subkind == :Forage
            # only for perennial herbaceous forage crops
            # 1. Mobilize assimilates at start of season
            if mobilizeassimilates 
                # mass to mobilize
                bin = fracassim * wpi *(trw/eto)  # ton/ha
                if (assimmobilized + bin) > assimtomobilize
                    bin = assimtomobilize - assimmobilized
                end
                # cumulative mass mobilized
                assimmobilized = assimmobilized + bin
                # switch mobilize off when all mass is transfered
                if round(Int, 1000*assimtomobilize) <= round(Int, 1000 *assimmobilized)
                    mobilizeassimilates = false
                end
            end
            # 2. Store assimilates at end of season
            if storeassimilates 
                # mass to store
                bout = fracassim * wpi *(trw/eto)  # ton/ha
                # cumulative mass stored
                gvars[:simulation].Storage.Btotal +=  bout
            end
        end

        biomass = biomass + bin - bout  # ton/ha ! correction for transferred assimilates

        # actual total biomass (crop and weeds)
        biomasstot = biomasstot + wpi *(tact/eto)  # ton/ha  for dynamic adjustment of soil fertility stress
        biomasstot = biomasstot + bin - bout # correction for transferred assimilates

        # 1.3 potential biomass - unlimited soil fertiltiy
        biomassunlim = biomassunlim + bin - bout # correction for transferred assimilates
    end

    # 1.4 potential biomass for given soil fertility
    biomasspot =  fracbiomasspotsf * biomassunlim # ton/ha

    # 2. yield
    tmax1 = undef_int
    if (gvars[:crop].subkind == :Tuber) | (gvars[:crop].subkind == :Grain)
        # DaysToFlowering corresponds with Tuberformation
        if dayi > (gvars[:simulation].DelayedDays + gvars[:crop].Day1 + gvars[:crop].DaysToFlowering)
            # calculation starts when flowering has started

            # 2.2 determine HImultiplier at the start of flowering
            # effect of water stress before flowering (HItimesBEF)
            if hitimesbef < - 0.1
                # i.e. undefined at the start of flowering
                if biomasspot < 0.0001
                    hitimesbef = 1
                else
                    ratiobm = biomass/biomasspot
                    # not correct if weed infestation and no fertility stress
                    # for that case biomasspot might be larger (but cannot be calculated since wp is unknown)
                    if ratiobm > 1
                        ratiobm = 1
                    end
                    rbm = bm_range(gvars[:crop].HIincrease)
                    hitimesbef = hi_multiplier(ratiobm, rbm, gvars[:crop].HIincrease)
                end
                if gvars[:float_parameters][:cciactual] <= 0.01
                    if (gvars[:crop].CCxWithered > 0) &
                       (gvars[:float_parameters][:cciactual] < gvars[:crop].CCxWithered)
                        hitimesbef = 0 # no green canopy cover left at start of flowering;
                    else
                        hitimesbef = 1
                    end
                end
            end

            # 2.3 Relative water content for that day
            determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth])
            if gvars[:simulation].SWCtopSoilConsidered # top soil is relative wetter than total root zone
                wrel = (gvars[:root_zone_wc].ZtopFC - gvars[:root_zone_wc].ZtopAct)/ 
                       (gvars[:root_zone_wc].ZtopFC - gvars[:root_zone_wc].ZtopWP) # top soil
            else
                wrel = (gvars[:root_zone_wc].FC - gvars[:root_zone_wc].Actual)/ 
                       (gvars[:root_zone_wc].FC - gvars[:root_zone_wc].WP) # total root zone
            end

            # 2.4 Failure of Pollination during flowering (alfaMax in percentage)
            if gvars[:crop].subkind == :Grain # - only valid for fruit/grain crops (flowers)
                if (dayi <= (gvars[:simulation].DelayedDays + gvars[:crop].Day1 + 
                             gvars[:crop].DaysToFlowering + gvars[:crop].LengthFlowering)) & # calculation limited to flowering period
                   ((gvars[:float_parameters][:cciactual]*100) > gvars[:simulparam].PercCCxHIfinal)
                    # sufficient green canopy remains
                    # 2.4a - Fraction of flowers which are flowering on day  (fFlor)
                    fflor = fraction_flowering(dayi, gvars[:crop], gvars[:simulation])
                    # 2.4b - Ks(pollination) water stress
                    pll = 1
                    croppol_temp = gvars[:crop].pPollination
                    kspolws = ks_any(wrel, croppol_temp, pll, 0)
                    # 2.4c - Ks(pollination) cold stress
                    kspolcs = ks_temperature(gvars[:crop].Tcold-temprange, gvars[:crop].Tcold, tminonday)
                    # 2.4d - Ks(pollination) heat stress
                    kspolhs = ks_temperature(gvars[:crop].Theat+temprange, gvars[:crop].Theat, tmaxonday)
                    # 2.4e - Adjust alfa
                    kspol = kspolws
                    if kspol > kspolcs
                        kspol = kspolcs
                    end
                    if kspol > kspolhs
                        kspol = kspolhs
                    end
                    alfamax = alfamax + (kspol * (1 + gvars[:crop].fExcess/100) * fflor * gvars[:crop].HI)
                    if alfamax > gvars[:crop].HI
                        alfamax = gvars[:crop].HI
                    end
                end
            else
                alfamax = gvars[:crop].HI # for Tuber crops (no flowering)
            end

            # 2.5 determine effect of water stress affecting leaf expansion after flowering
            # from start flowering till end of determinancy
            if gvars[:crop].DeterminancyLinked
                tmax1 = round(Int, gvars[:crop].LengthFlowering/2)
            else
                tmax1 = gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFlowering
            end
            if (hitimesbef > 0.99) & # there is green canopy cover at start of flowering;
               (dayi <= (gvars[:simulation].DelayedDays + gvars[:crop].Day1 +
                         gvars[:crop].DaysToFlowering+ tmax1)) & # and not yet end period
                (tmax1 > 0) & # otherwise no effect
                (round(Int, gvars[:crop].aCoeff) != undef_int) & # otherwise no effect
                # possible precision issue in pascal code
                # added -epsilon(0) for zero-diff with pascal version output
                (gvars[:float_parameters][:cciactual] > (0.001-eps())) # and as long as green canopy cover remains (for correction to stresses)
                # determine KsLeaf
                pleafulact, pleafllact = adjust_pleaf_to_eto(eto, gvars[:crop], gvars[:simulparam])
                ksleaf = ks_any(wrel, pleafulact, pleafllact, gvars[:crop].KsShapeFactorLeaf)
                # daily correction
                dcor = (1 + (1-ksleaf)/gvars[:crop].aCoeff)
                # weighted correction
                scorat1 = scorat1 + dcor/tmax1
                daycor = dayi - (gvars[:simulation].DelayedDays + gvars[:crop].Day1 + gvars[:crop].DaysToFlowering)
                hitimesat1  = (tmax1*1/daycor) * scorat1
            end

            # 2.6 determine effect of water stress affecting stomatal closure after flowering
            # during yield formation
            if gvars[:crop].dHIdt > 99
                tmax2 = 0
            else
                tmax2 = round(Int, gvars[:crop].HI/gvars[:crop].dHIdt)
            end
            if (hitimesbef > 0.99) & # there is green canopy cover at start of flowering;
               (dayi <= (gvars[:simulation].DelayedDays + gvars[:crop].Day1 +
                         gvars[:crop].DaysToFlowering + tmax2)) & # and not yet end period
               (tmax2 > 0) & # otherwise no effect
               (round(Int, gvars[:crop].bCoeff) != undef_int) & # otherwise no effect
                # possible precision issue in pascal code
                # added -epsilon(0) for zero-diff with pascal version output
                (gvars[:float_parameters][:cciactual] > (0.001-eps())) # and as long as green canopy cover remains (for correction to stresses)
                # determine KsStomatal
                pstomatulact = adjust_pstomatal_to_eto(eto, gvars[:crop], gvars[:simulparam])
                pll = 1
                ksstomatal = ks_any(wrel, pstomatulact, pll, gvars[:crop].KsShapeFactorStomata)
                # daily correction
                if ksstomatal > 0.001
                    dcor = (exp(0.10*log(ksstomatal))) * (1-(1-ksstomatal)/gvars[:crop].bCoeff)
                else
                    dcor = 0
                end
                # weighted correction
                scorat2 = scorat2 + dcor/tmax2
                daycor = dayi - (gvars[:simulation].DelayedDays + gvars[:crop].Day1 + gvars[:crop].DaysToFlowering)
                hitimesat2  = (tmax2*1/daycor) * scorat2
            end

            # 2.7 total multiplier after flowering
            if (tmax2 == 0) & (tmax1 == 0)
                hitimesat = 1
            else
                if tmax2 == 0
                    hitimesat = hitimesat1
                else
                    if tmax1 == 0
                        hitimesat = hitimesat2
                    elseif tmax1 <= tmax2
                        hitimesat = hitimesat2 * ((tmax1*hitimesat1 + (tmax2-tmax1))/tmax2)
                        if round(Int, gvars[:crop].bCoeff) == undef_int
                            hitimesat = hitimesat1
                        end
                        if round(Int, gvars[:crop].aCoeff) == undef_int
                            hitimesat = hitimesat2
                        end
                    else
                        hitimesat = hitimesat1 * ((tmax2*hitimesat2 + (tmax1-tmax2))/tmax1)
                        if round(Int, gvars[:crop].bCoeff) == undef_int
                            hitimesat = hitimesat1
                        end
                        if round(Int, gvars[:crop].aCoeff) == undef_int
                            hitimesat = hitimesat2
                        end
                    end
                end
            end

            # 2.8 Limit HI to allowable maximum increase
            hitimestotal = hitimesbef * hitimesat
            if hitimestotal > (1 +(gvars[:crop].DHImax/100))
                hitimestotal = 1 +(gvars[:crop].DHImax/100)
            end

            # 2.9 Yield
            if alfamax >= alfa
                yieldpart = biomass * hitimestotal*(alfa/100)
            else
                yieldpart = biomass * hitimestotal*(alfamax/100)
            end
        end
    end

    # 2bis. yield leafy vegetable crops and forage crops
    if (gvars[:crop].subkind == :Vegetative) | (gvars[:crop].subkind == :Forage)
        if dayi >= (gvars[:simulation].DelayedDays + gvars[:crop].Day1 + gvars[:crop].DaysToFlowering)
            # calculation starts at crop day 1 (since days to flowering is 0)
            if round(Int, 100*eto)> 0
                # with correction for transferred assimilates
                if gvars[:simulation].RCadj > 0
                    yieldpart = yieldpart + (wpi*(trw/eto) + bin - bout) * (alfa/100)
                else
                    yieldpart = yieldpart + (wpi*(tact/eto) + bin - bout) * (alfa/100)
                end
            end
        end
    end


    # 3. Dynamic adjustment of soil fertility stress
    if (gvars[:management].FertilityStress > 0) & (biomassunlim > 0.001) & gvars[:crop].StressResponse.Calibrated
        bioadj = 100 * (fracbiomasspotsf + (fracbiomasspotsf - biomasstot/biomassunlim))
        if bioadj >= 100
            stresssfadjnew = 0
        else
            if bioadj <= eps()
                stresssfadjnew = 80
            else
                stresssfadjnew = round(Int, coeffb0 + coeffb1*bioadj + coeffb2*bioadj*bioadj) 
                if stresssfadjnew < 0
                    stresssfadjnew = gvars[:management].FertilityStress
                end
                if stresssfadjnew > 80
                    stresssfadjnew = 80
                end
            end
            if stresssfadjnew > gvars[:management].FertilityStress
                stresssfadjnew = gvars[:management].FertilityStress
            end
        end
        if (gvars[:crop].subkind == :Grain) & gvars[:crop].DeterminancyLinked &
           (dayi > (gvars[:simulation].DelayedDays + gvars[:crop].Day1 +
                    gvars[:crop].DaysToFlowering + tmax1))
            # potential vegetation period is exceeded
            if stresssfadjnew < previousstresslevel
                stresssfadjnew = previousstresslevel
            end
            if stresssfadjnew > gvars[:management].FertilityStress
                stresssfadjnew = gvars[:management].FertilityStress
            end
        end
    else
        if (gvars[:management].FertilityStress == 0) |
            !gvars[:crop].StressResponse.Calibrated
            # no (calibrated) soil fertility stress
            stresssfadjnew = 0
        else
            # BiomassUnlim is too small
            stresssfadjnew = gvars[:management].FertilityStress
        end
    end

    previousstresslevel = stresssfadjnew
    sumkctopstress = (1 - stresssfadjnew/100) * sumkctop

    gvars[:sumwabal].Biomass = biomass
    gvars[:sumwabal].BiomassPot = biomasspot
    gvars[:sumwabal].BiomassUnlim = biomassunlim
    gvars[:sumwabal].BiomassTot = biomasstot
    gvars[:sumwabal].YieldPart = yieldpart
    gvars[:transfer].Store = storeassimilates
    gvars[:transfer].Mobilize = mobilizeassimilates
    gvars[:transfer].ToMobilize = assimtomobilize
    gvars[:transfer].Bmobilized = assimmobilized
    setparameter!(gvars[:float_parameters], :hi_times_bef, hitimesbef)
    setparameter!(gvars[:float_parameters], :scor_at1, scorat1)
    setparameter!(gvars[:float_parameters], :scor_at2, scorat2)
    setparameter!(gvars[:float_parameters], :hi_times_at1, hitimesat1)
    setparameter!(gvars[:float_parameters], :hi_times_at2, hitimesat2)
    setparameter!(gvars[:float_parameters], :hi_times_at, hitimesat)
    setparameter!(gvars[:float_parameters], :alfa_hi, alfa)
    setparameter!(gvars[:float_parameters], :alfa_hi_adj, alfamax)
    setparameter!(gvars[:float_parameters], :sumkctop_stress, sumkctopstress)
    setparameter!(gvars[:float_parameters], :sumkci, sumkci)
    setparameter!(gvars[:float_parameters], :weedrci, weedrci)
    setparameter!(gvars[:float_parameters], :cciactualweedinfested, ccw)
    setparameter!(gvars[:float_parameters], :tactweedinfested, trw)
    setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, stresssfadjnew)
    setparameter!(gvars[:integer_parameters], :previous_stress_level, previousstresslevel)
    setparameter!(gvars[:float_parameters], :bin, bin)
    setparameter!(gvars[:float_parameters], :bout, bout)

    setparameter!(lvars[:float_parameters], :fracassim, fracassim)
    setparameter!(lvars[:float_parameters], :wpi, wpi)

    return nothing
end

"""
    yeari = year_weighing_factor(cropfirstdaynr)
    
simul.f90:YearWeighingFactor:1074
"""
function year_weighing_factor(cropfirstdaynr)
    dayi, monthi, yeari = determine_date(cropfirstdaynr)
    return yeari
end

"""
    fi = fraction_period(diflor, crop)

simul.f90:FractionPeriod:1051
"""
function fraction_period(diflor, crop)
    if diflor <= eps() 
        fi = 0
    else
        timeperc = 100 * (diflor * 1/crop.LengthFlowering)
        if timeperc > 100
            fi = 1
        else
            fi = 0.00558 * exp(0.63*log(timeperc)) - 0.000969 * timeperc - 0.00383
            if fi < 0
                fi = 0
            end 
        end 
    end 
    return fi
end

"""
    f = fraction_flowering(dayi, crop, simulation)

simul.f90:FractionFlowering:1026
"""
function fraction_flowering(dayi, crop, simulation)
  if crop.LengthFlowering <= 1
      f = 1
  else
      diflor = dayi - (simulation.DelayedDays + crop.Day1 + crop.DaysToFlowering)
      f2 = fraction_period(diflor, crop)
      diflor = (dayi-1) - (simulation.DelayedDays + crop.Day1 + crop.DaysToFlowering)
      f1 = fraction_period(diflor, crop)
      if abs(f1-f2) < ac_zero_threshold 
          f = 0
      else
          f = (100 * ((f1+f2)/2)/crop.LengthFlowering)
      end 
  end 
  return f
end 

"""
    hiday, hifinal, percentlagphase = harvest_index_day(dap, daystoflower, himax, dhidt, cci, 
                                  ccxadjusted, theccxwithered, 
                                  percccxhifinal, tempplanting, 
                                  hifinal,
                                  crop, simulation)

global.f90:HarvestIndexDay:5567
"""
function harvest_index_day(dap, daystoflower, himax, dhidt, cci, 
                                  ccxadjusted, theccxwithered, 
                                  percccxhifinal, tempplanting, 
                                  hifinal,
                                  crop, simulation)

    hio = 1

    dhidt_local = dhidt
    t = dap - simulation.DelayedDays - daystoflower
    # Simulation.WPyON := false;
    percentlagphase = 0
    if t <= 0
        hiday = 0
    else
        if (crop.subkind == :Vegetative) & (tempplanting == :Regrowth)
            dhidt_local = 100
        end
        if (crop.subkind == :Forage) & (tempplanting == :Regrowth)
            dhidt_local = 100
        end
        if dhidt_local > 99
            hiday = himax
            percentlagphase = 100
        else
            higc = harvest_index_growth_coefficient(himax, dhidt_local)
            tswitch, higclinear = get_day_switch_to_linear(himax, dhidt_local, higc)
            if t < tswitch
                percentlagphase = round(Int, 100 * t/tswitch)
                hiday = (hio*himax)/ (hio+(himax-hio)*exp(-higc*t))
            else
                percentlagphase = 100
                if (crop.subkind == :Tuber) | (crop.subkind == :Vegetative) | (crop.subkind == :Forage)
                    # continue with logistic equation
                    hiday = (hio*himax)/ (hio+(himax-hio)*exp(-higc*t))
                    if hiday >= 0.9799*himax
                        hiday = himax
                    end
                else
                    # switch to linear increase
                    hiday = (hio*himax)/ (hio+(himax-hio)*exp(-higc*tswitch))
                    hiday = hiday + higclinear*(t-tswitch)
                end
            end
            if hiday > himax
                hiday = himax
            end
            if hiday <= (hio + 0.4)
                hiday = 0
            end
            if (himax - hiday) < 0.4
                hiday = himax
            end
        end

        # adjust HIfinal if required for inadequate photosynthesis (unsufficient green canopy)
        tmax = round(Int, himax/dhidt_local)
        if (hifinal == himax) & (t <= tmax) & ((cci+eps()) <= (percccxhifinal/100)) &
           (theccxwithered > eps()) & (cci < theccxwithered) & (crop.subkind != :Vegetative) &
           (crop.subkind != :Forage) 
            hifinal = round(Int, hiday)
        end
        if hiday > hifinal
            hiday = hifinal
        end
    end
    return hiday, hifinal, percentlagphase
end

"""
    bmr = bm_range(hiadj)

global.f90:BMRange:2295
"""
function bm_range(hiadj)
    if hiadj <= 0
        bmr = 0
    else
        bmr = (log(hiadj)/0.0562)/100
    end 
    if bmr > 1
        bmr = 1
    end 
    return bmr
end

"""
    himultiplier = hi_multiplier(ratiobm, rangebm, hiadj)

global.f90:HImultiplier:2312
"""
function hi_multiplier(ratiobm, rangebm, hiadj)
    rini = 1 - rangebm
    rend = 1
    rmax = rini + (2/3) * (rend-rini)
    if ratiobm <= rini
        himultiplier = 1
    elseif ratiobm <= rmax 
        himultiplier = 1 + (1 + sin(pi*(1.5-(ratiobm-rini)/(rmax-rini))))*(hiadj/200)
    elseif ratiobm <= rend
        himultiplier = 1 + (1 + sin(pi*(0.5+(ratiobm-rmax)/(rend-rmax))))*(hiadj/200)
    else
        himultiplier = 1
    end 

    return himultiplier
end

"""
    potvalsf = get_potvalsf(dap, sumgddadjcc, gvars)

run.f90:GetPotValSF:6446
"""
function get_potvalsf(dap, sumgddadjcc, gvars)
    crop = gvars[:crop]
    simulation = gvars[:simulation]

    ratdgdd = 1
    if (crop.ModeCycle == :GDDays) &
       (crop.GDDaysToFullCanopySF < crop.GDDaysToSenescence)
        ratdgdd = (crop.DaysToSenescence-crop.DaysToFullCanopySF)/(crop.GDDaysToSenescence-crop.GDDaysToFullCanopySF)
    end 

    potvalsf = cci_no_water_stress_sf(dap, crop.DaysToGermination, 
                    crop.DaysToFullCanopySF, crop.DaysToSenescence, 
                    crop.DaysToHarvest, crop.GDDaysToGermination, 
                    crop.GDDaysToFullCanopySF, crop.GDDaysToSenescence, 
                    crop.GDDaysToHarvest,
                    gvars[:float_parameters][:ccototal],
                    gvars[:float_parameters][:ccxtotal], 
                    crop.CGC, crop.GDDCGC,
                    gvars[:float_parameters][:cdctotal],
                    gvars[:float_parameters][:gddcdctotal],
                    sumgddadjcc, ratdgdd, 
                    simulation.EffectStress.RedCGC, 
                    simulation.EffectStress.RedCCX, 
                    simulation.EffectStress.CDecline, crop.ModeCycle,
                    simulation)
    potvalsf = 100 * (1/gvars[:float_parameters][:ccxcrop_weednosf_stress]) * potvalsf

    return potvalsf
end

"""
    check_for_print!(outputs, gvars)

run.f90:CheckForPrint:3391
"""
function check_for_print!(outputs, gvars)
    dayn, monthn, yearn = determine_date(gvars[:integer_parameters][:daynri])

    if gvars[:integer_parameters][:outputaggregate] == 1
        # 1: daily output
        biomassday = gvars[:sumwabal].Biomass - gvars[:previoussum].Biomass
        bunlimday = gvars[:sumwabal].BiomassUnlim - gvars[:previoussum].BiomassUnlim
        saltin = gvars[:sumwabal].SaltIn - gvars[:previoussum].SaltIn
        saltout = gvars[:sumwabal].SaltOut - gvars[:previoussum].SaltOut
        crsalt = gvars[:sumwabal].CRsalt - gvars[:previoussum].CRsalt
        write_the_results!(outputs, undef_int, dayn, monthn, yearn, dayn, monthn, 
                             yearn, gvars[:float_parameters][:rain],
                             gvars[:float_parameters][:eto],
                             gvars[:float_parameters][:gddayi],
                             gvars[:float_parameters][:irrigation], 
                             gvars[:float_parameters][:infiltrated],
                             gvars[:float_parameters][:runoff],
                             gvars[:float_parameters][:drain], 
                             gvars[:float_parameters][:crwater],
                             gvars[:float_parameters][:eact], 
                             gvars[:float_parameters][:epot], 
                             gvars[:float_parameters][:tact], 
                             gvars[:float_parameters][:tactweedinfested],
                             gvars[:float_parameters][:tpot], saltin, saltout, 
                             crsalt, biomassday, bunlimday,
                             gvars[:float_parameters][:bin], 
                             gvars[:float_parameters][:bout], 
                             gvars)
        gvars[:previoussum].Biomass = gvars[:sumwabal].Biomass
        gvars[:previoussum].BiomassUnlim = gvars[:sumwabal].BiomassUnlim
        gvars[:previoussum].SaltIn = gvars[:sumwabal].SaltIn
        gvars[:previoussum].SaltOut = gvars[:sumwabal].SaltOut
        gvars[:previoussum].CRsalt = gvars[:sumwabal].CRsalt

    else
        # 2 or 3: 10-day or monthly output
        writenow = false
        dayendm = DaysInMonth[monthn]
        if isleapyear(yearn) & (monthn == 2)
            dayendm = 29
        end
        if dayn == dayendm
            writenow = true  # 10-day and month
        end
        if (gvars[:integer_parameters][:outputaggregate] == 2) & ((dayn == 10) | (dayn == 20))
            writenow = true # 10-day
        end
        if writenow
            write_intermediate_period!(outputs, gvars)
        end
    end
    return nothing
end

"""
    write_intermediate_period!(outputs, gvars)

run.f90:WriteIntermediatePeriod:6066
"""
function write_intermediate_period!(outputs, gvars)
    # determine intermediate results
    day1, month1, year1 =  determine_date(gvars[:integer_parameters][:previousdaynr]+1)
    dayn, monthn, yearn =  determine_date(gvars[:integer_parameters][:daynri])

    rper = gvars[:sumwabal].Rain - gvars[:previoussum].Rain
    etoper = gvars[:float_parameters][:sumeto] - gvars[:float_parameters][:previoussumeto]
    gddper = gvars[:float_parameters][:sumgdd] - gvars[:float_parameters][:previoussumgdd]
    irriper = gvars[:sumwabal].Irrigation - gvars[:previoussum].Irrigation
    infiltper = gvars[:sumwabal].Infiltrated - gvars[:previoussum].Infiltrated
    eper = gvars[:sumwabal].Eact - gvars[:previoussum].Eact
    exper = gvars[:sumwabal].Epot - gvars[:previoussum].Epot
    trper = gvars[:sumwabal].Tact - gvars[:previoussum].Tact
    trwper = gvars[:sumwabal].TrW - gvars[:previoussum].TrW
    trxper = gvars[:sumwabal].Tpot - gvars[:previoussum].Tpot
    drainper = gvars[:sumwabal].Drain - gvars[:previoussum].Drain
    biomassper = gvars[:sumwabal].Biomass - gvars[:previoussum].Biomass
    bunlimper = gvars[:sumwabal].BiomassUnlim - gvars[:previoussum].BiomassUnlim

    roper = gvars[:sumwabal].Runoff - gvars[:previoussum].Runoff
    crwper = gvars[:sumwabal].CRwater - gvars[:previoussum].CRwater
    salinper = gvars[:sumwabal].SaltIn - gvars[:previoussum].SaltIn
    saloutper = gvars[:sumwabal].SaltOut - gvars[:previoussum].SaltOut
    salcrper = gvars[:sumwabal].CRsalt - gvars[:previoussum].CRsalt

    bmobper = gvars[:transfer].Bmobilized - gvars[:float_parameters][:previousbmob]
    bstoper = gvars[:simulation].Storage.Btotal - gvars[:float_parameters][:previousbsto]

    write_the_results!(outputs, undef_int, day1, month1, year1, dayn, 
                         monthn, yearn, rper, etoper, gddper, irriper, infiltper, 
                         roper, drainper, crwper, eper, exper, trper, trwper, 
                         trxper, salinper, saloutper, salcrper, biomassper, 
                         bunlimper, bmobper, bstoper, gvars)

    # reset previous sums
    setparameter!(gvars[:integer_parameters], :previousdaynr, gvars[:integer_parameters][:daynri])
    gvars[:previoussum].Rain = gvars[:sumwabal].Rain
    setparameter!(gvars[:float_parameters], :previoussumeto, gvars[:float_parameters][:sumeto])
    setparameter!(gvars[:float_parameters], :previoussumgdd, gvars[:float_parameters][:sumgdd])
    gvars[:previoussum].Irrigation = gvars[:sumwabal].Irrigation
    gvars[:previoussum].Infiltrated = gvars[:sumwabal].Infiltrated
    gvars[:previoussum].Eact = gvars[:sumwabal].Eact
    gvars[:previoussum].Epot = gvars[:sumwabal].Epot
    gvars[:previoussum].Tact = gvars[:sumwabal].Tact
    gvars[:previoussum].TrW = gvars[:sumwabal].TrW
    gvars[:previoussum].Tpot = gvars[:sumwabal].Tpot
    gvars[:previoussum].Drain = gvars[:sumwabal].Drain
    gvars[:previoussum].Biomass = gvars[:sumwabal].Biomass
    gvars[:previoussum].BiomassPot = gvars[:sumwabal].BiomassPot
    gvars[:previoussum].BiomassUnlim = gvars[:sumwabal].BiomassUnlim

    gvars[:previoussum].Runoff = gvars[:sumwabal].Runoff
    gvars[:previoussum].CRwater = gvars[:sumwabal].CRwater
    gvars[:previoussum].SaltIn = gvars[:sumwabal].SaltIn
    gvars[:previoussum].SaltOut = gvars[:sumwabal].SaltOut
    gvars[:previoussum].CRsalt = gvars[:sumwabal].CRsalt

    setparameter!(gvars[:float_parameters], :previousbmob, gvars[:transfer].Bmobilized)
    setparameter!(gvars[:float_parameters], :previousbsto,  gvars[:simulation].Storage.Btotal)

    return nothing
end

"""
    read_climate_nextday!(outputs, gvars)

run.f90:ReadClimateNextDay:7330
"""
function read_climate_nextday!(outputs, gvars)
    # Read Climate next day, Get GDDays and update SumGDDays
    if gvars[:integer_parameters][:daynri] <= gvars[:simulation].ToDayNr
        i = gvars[:integer_parameters][:daynri] - gvars[:simulation].FromDayNr + 1
        if gvars[:bool_parameters][:eto_file_exists]
            eto = read_output_from_etodatasim(outputs, i)
            setparameter!(gvars[:float_parameters], :eto, eto)
        end
        if gvars[:bool_parameters][:rain_file_exists]
            rain = read_output_from_raindatasim(outputs, i)
            setparameter!(gvars[:float_parameters], :rain, rain)
        end
        if gvars[:bool_parameters][:temperature_file_exists]
            tmin, tmax = read_output_from_tempdatasim(outputs, i)
            setparameter!(gvars[:float_parameters], :tmin, tmin)
            setparameter!(gvars[:float_parameters], :tmax, tmax)
        else
            tmin = gvars[:simulparam].Tmin
            tmax = gvars[:simulparam].Tmax
            setparameter!(gvars[:float_parameters], :tmin, tmin)
            setparameter!(gvars[:float_parameters], :tmax, tmax)
        end
    end 

    return nothing
end

"""
    set_gdd_variables_nextday!(gvars)

run.f90:SetGDDVariablesNextDay:7362
"""
function set_gdd_variables_nextday!(gvars)
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    daynri = gvars[:integer_parameters][:daynri]
    gddayi = gvars[:float_parameters][:gddayi]
    if daynri <= simulation.ToDayNr
        gddayi = degrees_day(crop.Tbase, crop.Tupper, 
                                gvars[:float_parameters][:tmin],
                                gvars[:float_parameters][:tmax],
                                simulparam.GDDMethod)
        setparameter!(gvars[:float_parameters], :gddayi, gddayi) 

        if daynri >= crop.Day1
            simulation.SumGDD = simulation.SumGDD + gddayi
            simulation.SumGDDfromDay1 = simulation.SumGDDfromDay1 + gddayi
        end 
    end 
    return nothing
end

"""
    reset_gdd_variables!(gvars)
"""
function reset_gdd_variables!(gvars)
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    daynri = gvars[:integer_parameters][:daynri]
    if daynri <= simulation.ToDayNr
        gddayi = degrees_day(crop.Tbase, crop.Tupper, 
                                gvars[:float_parameters][:tmin],
                                gvars[:float_parameters][:tmax],
                                simulparam.GDDMethod)
        if daynri >= crop.Day1
            simulation.SumGDD = simulation.SumGDD - gddayi
            simulation.SumGDDfromDay1 = simulation.SumGDDfromDay1 - gddayi
        end 
    end 
    return nothing
end

"""
    write_the_results!(outputs, anumber, day1, month1, year1, dayn, monthn, 
                           yearn, rper, etoper, gddper, irriper, infiltper, 
                           roper, drainper, crwper, eper, exper, trper, trwper, 
                           trxper, salinper, saloutper, 
                           salcrper, biomassper, bunlimper, bmobper, bstoper, 
                           gvars)

run.f90:WriteTheResults:4531
"""
function write_the_results!(outputs, anumber, day1, month1, year1, dayn, monthn, 
                           yearn, rper, etoper, gddper, irriper, infiltper, 
                           roper, drainper, crwper, eper, exper, trper, trwper, 
                           trxper, salinper, saloutper, 
                           salcrper, biomassper, bunlimper, bmobper, bstoper, 
                           gvars)

    arr = Float64[]

    # copy intent(in) variables to locals
    year1_loc = year1
    yearn_loc = yearn

    # start
    if gvars[:bool_parameters][:noyear]
        year1_loc = 9999
        yearn_loc = 9999
    end 
    if anumber == undef_int # intermediate results
        push!(arr, 0) # RunNr
    else
        push!(arr, anumber) # RunNr
    end
    push!(arr, year1_loc) # Date1 year
    push!(arr, month1) # Date1 month
    push!(arr, day1) # Date1 day

    # Climatic conditions
    tempreal = round(Int, gddper*10)
    push!(arr, rper) # Rain
    push!(arr, etoper) # ETo 
    push!(arr, tempreal/10) # GD
    push!(arr, gvars[:float_parameters][:co2i]) # CO2

    # Soil water parameters
    if exper > 0
        ratioe = round(Int, 100*eper/exper)
    else
        ratioe = undef_int
    end 
    if trxper > 0
        ratiot = round(Int, 100*trper/trxper)
    else
        ratiot = undef_int
    end 
    push!(arr, irriper) # Irri
    push!(arr, infiltper) # Infilt
    push!(arr, roper) # Runoff
    push!(arr, drainper) # Drain
    push!(arr, crwper) # Upflow
    push!(arr, eper) # E
    push!(arr, ratioe) # E/Ex
    push!(arr, trper) # Tr
    push!(arr, trwper) # TrW
    push!(arr, ratiot) # Tr/Trx

    # Soil Salinity
    push!(arr, salinper) # SaltIn
    push!(arr, saloutper) # SaltOut
    push!(arr, salcrper) # SaltUp
    push!(arr, gvars[:total_salt_content].EndDay) # SaltProf

    # Seasonal stress
    push!(arr, gvars[:stresstot].NrD) # Cycle
    push!(arr, round(Int, gvars[:stresstot].Salt)) # SaltStr
    push!(arr, gvars[:management].FertilityStress) # FertStr
    push!(arr, round(Int, gvars[:stresstot].Weed)) # WeedStr
    push!(arr, round(Int, gvars[:stresstot].Temp)) # TempStr
    push!(arr, round(Int, gvars[:stresstot].Exp)) # ExpStr
    push!(arr, round(Int, gvars[:stresstot].Sto)) # StoStr

    # Biomass production
    if (biomassper > 0) & (bunlimper > 0)
        brsf = round(Int, 100*biomassper/bunlimper)
        if brsf > 100
            brsf = 100
        end 
    else
        brsf = undef_int
    end 
    push!(arr, biomassper) # BioMass
    push!(arr, brsf) # Brelative

    # Crop yield
    # Harvest Index
    if (gvars[:sumwabal].Biomass > eps()) &
       (gvars[:sumwabal].YieldPart > eps())
        hi = 100*gvars[:sumwabal].YieldPart/gvars[:sumwabal].Biomass
    else
        if gvars[:sumwabal].Biomass > eps()
            hi = 0
        else
            hi = undef_double
        end 
    end 

    if anumber != undef_int # end of simulation run
        # Water Use Efficiency yield
        if ((gvars[:sumwabal].Tact > 0) | (gvars[:sumwabal].ECropCycle > 0)) &
           (gvars[:sumwabal].YieldPart > 0) 
            wpy = (gvars[:sumwabal].YieldPart*1000) /
                  ((gvars[:sumwabal].Tact+gvars[:sumwabal].ECropCycle)*10)
        else
            wpy = 0
        end 

        # Fresh yield
        if (gvars[:crop].DryMatter ==  undef_int) |
           (gvars[:crop].DryMatter < eps())
            push!(arr, hi) # HI
            push!(arr, gvars[:sumwabal].YieldPart) # Y(dry)
            push!(arr, undef_double) # Y(fresh)
            push!(arr, wpy) # WPet
        else
            push!(arr, hi) # HI
            push!(arr, gvars[:sumwabal].YieldPart) # Y(dry)
            push!(arr, gvars[:sumwabal].YieldPart/(gvars[:crop].DryMatter/100)) # Y(fresh)
            push!(arr, wpy) # WPet
        end 

        # Transfer of assimilates
        push!(arr, gvars[:transfer].Bmobilized) # Bin
        push!(arr, gvars[:simulation].Storage.Btotal) # Bout
    else
        push!(arr, hi) # HI
        push!(arr, undef_int) # Y(dry)
        push!(arr, undef_int) # Y(fresh)
        push!(arr, undef_int) # WPet
        push!(arr, bmobper) # Bin
        push!(arr, bstoper) # Bout
    end 

    # End
    push!(arr, yearn_loc) # DateN year
    push!(arr, monthn) # DateN month
    push!(arr, dayn) # DateN day

    add_output_in_seasonout!(outputs, arr)
    return nothing
end

"""
    write_daily_results!(outputs, gvars, dap, wpi, nrrun)

run.f90:WriteDailyResults:7405
"""
function write_daily_results!(outputs, gvars, dap, wpi, nrrun)

    arr = Float64[]
    push!(arr, nrrun) # RunNr

    dap_loc = dap
    wpi_loc = wpi

    stagecode = gvars[:integer_parameters][:stagecode]
    di, mi, yi =  determine_date(gvars[:integer_parameters][:daynri])
    if gvars[:clim_record].FromY == 1901
        yi = yi - 1901 + 1
    end 
    if stagecode == 0
        dap_loc = undef_int # before or after cropping
    end 

    # 0. info day
    push!(arr, yi) # Date year
    push!(arr, mi) # Date month 
    push!(arr, di) # Date day 
    push!(arr, dap_loc) # DAP
    push!(arr, stagecode) # Stage


    # 1. Water balance
    ziaqua = gvars[:integer_parameters][:ziaqua]
    if ziaqua == undef_int
        zi = undef_double
    else
        zi = ziaqua/100
    end
    push!(arr, gvars[:total_water_content].EndDay) # WC()
    push!(arr, gvars[:float_parameters][:rain]) # Rain
    push!(arr, gvars[:float_parameters][:irrigation]) # Irri 
    push!(arr, gvars[:float_parameters][:surfacestorage]) # Surf 
    push!(arr, gvars[:float_parameters][:infiltrated]) # Infilt 
    push!(arr, gvars[:float_parameters][:runoff]) # RO 
    push!(arr, gvars[:float_parameters][:drain]) # Drain
    push!(arr, gvars[:float_parameters][:crwater]) # CR
    push!(arr, zi) # Zgwt 

    tpot = gvars[:float_parameters][:tpot]
    epot = gvars[:float_parameters][:epot]
    tact = gvars[:float_parameters][:tact]
    eact = gvars[:float_parameters][:eact]
    if tpot > 0
        ratio1 = round(Int, 100 * tact/tpot)
    else
        ratio1 = 100
    end 

    if (epot+tpot) > 0
        ratio2 = round(Int, 100 * (eact+tact)/(epot+tpot))
    else
        ratio2 = 100
    end 

    if epot > 0
        ratio3 = round(Int, 100 * eact/epot)
    else
        ratio3 = 100
    end 

    push!(arr, epot) # Ex
    push!(arr, eact) # E
    push!(arr, ratio3) # E/Ex
    push!(arr, tpot) # Trx
    push!(arr, tact) # Tr
    push!(arr, ratio1) # Tr/Trx
    push!(arr, epot + tpot) # ETx
    push!(arr, eact + tact) # ET
    push!(arr, ratio2) # ET/ETx

    # 2. Crop development and yield
    # 1. relative transpiration
    # ratio1

    # 2. Water stresses
    if gvars[:float_parameters][:stressleaf] < 0
        strexp = undef_int
    else
        strexp = round(Int, gvars[:float_parameters][:stressleaf])
    end 
    if tpot < eps()
        strsto = undef_int
    else
        strsto = round(Int, 100 * (1 - tact/tpot))
    end 

    # 3. Salinity stress
    kss = gvars[:root_zone_salt].KsSalt
    if kss < 0
        strsalt = undef_int
    else
        strsalt = round(Int, 100 * (1 - kss ))
    end 

    # 4. Air temperature stress
    cciactual = gvars[:float_parameters][:cciactual]
    if cciactual <= 0.0000001
        kstr = 1
    else
        kstr = ks_temperature(0, gvars[:crop].GDtranspLow, gvars[:float_parameters][:gddayi])
    end 

    if kstr < 1
        strtr = round(Int, (1-kstr)*100)
    else
        strtr = 0
    end 

    # 5. Relative cover of weeds
    if cciactual <= 0.0000001
        strw = undef_int
    else
        strw = round(Int, gvars[:float_parameters][:weedrci])
    end 

    # 6. WPi adjustemnt
    if gvars[:sumwabal].Biomass <= 0.000001
        wpi_loc = 0
    end 

    # 7. Harvest Index
    if (gvars[:sumwabal].Biomass > 0) &
       (gvars[:sumwabal].YieldPart > 0) 
        hi = 100 * (gvars[:sumwabal].YieldPart)/(gvars[:sumwabal].Biomass)
    else
        hi = undef_double
    end 

    # 8. Relative Biomass
    if (gvars[:sumwabal].Biomass > 0) &
       (gvars[:sumwabal].BiomassUnlim > 0)
        brel = round(Int, 100 * gvars[:sumwabal].Biomass/gvars[:sumwabal].BiomassUnlim)
        if brel > 100
            brel = 100
        end 
    else
        brel = undef_int
    end 

    # 9. Kc coefficient
    eto = gvars[:float_parameters][:eto]
    if (eto > 0) & (tpot > 0) & (strtr < 100)
        kcval = tpot/(eto*kstr)
    else
        kcval = undef_int
    end 

    # 10. Water Use Efficiency yield
    if ((gvars[:sumwabal].Tact > 0) | (gvars[:sumwabal].ECropCycle > 0)) & (gvars[:sumwabal].YieldPart > 0)
        wpy = (gvars[:sumwabal].YieldPart*1000)/((gvars[:sumwabal].Tact+gvars[:sumwabal].ECropCycle)*10)
    else
        wpy = 0
    end 

    # Fresh yield
    if (gvars[:crop].DryMatter == undef_int) |
       (gvars[:crop].DryMatter < eps())
        yf = undef_double
    else
        yf = gvars[:sumwabal].YieldPart/(gvars[:crop].DryMatter/100)
    end 

    # write
    push!(arr, gvars[:float_parameters][:gddayi]) # GD
    push!(arr, gvars[:float_parameters][:rooting_depth]) # Z
    push!(arr, strexp) # StExp
    push!(arr, strsto) # StSto
    push!(arr, round(Int, gvars[:float_parameters][:stresssenescence])) # StSen
    push!(arr, strsalt) # StSalt
    push!(arr, strw) # StWeed
    push!(arr, cciactual*100) # CC
    push!(arr, gvars[:float_parameters][:cciactualweedinfested]*100) # CCw
    push!(arr, strtr) # StTr
    push!(arr, kcval) # Kc(Tr)
    push!(arr, gvars[:float_parameters][:tactweedinfested]) # TrW
    push!(arr, 100*wpi_loc) # WP
    push!(arr, gvars[:sumwabal].Biomass) #  Biomass
    push!(arr, hi) # HI
    push!(arr, gvars[:sumwabal].YieldPart) # Y(dry)
    push!(arr, yf) # Y(fresh)
    push!(arr, brel) # Brelative
    push!(arr, wpy) # WPet
    push!(arr, gvars[:float_parameters][:bin]) # Bin
    push!(arr, gvars[:float_parameters][:bout]) # Bout


    # 3. Profile/Root zone - Soil water content
    rooting_depth = gvars[:float_parameters][:rooting_depth]
    if rooting_depth < eps()
        gvars[:root_zone_wc].Actual = undef_double
    else
        if round(Int, gvars[:soil].RootMax*1000) == round(Int, gvars[:crop].RootMax*1000)
            determine_root_zone_wc!(gvars, gvars[:crop].RootMax)
        else
            determine_root_zone_wc!(gvars, gvars[:soil].RootMax)
        end 
    end 

    push!(arr, gvars[:root_zone_wc].Actual) # Wr()

    if rooting_depth < eps() 
        gvars[:root_zone_wc].Actual = undef_double
        gvars[:root_zone_wc].FC = undef_double
        gvars[:root_zone_wc].WP = undef_double
        gvars[:root_zone_wc].SAT = undef_double
        gvars[:root_zone_wc].Thresh = undef_double
        gvars[:root_zone_wc].Leaf = undef_double
        gvars[:root_zone_wc].Sen = undef_double
    else
        determine_root_zone_wc!(gvars, rooting_depth)
    end 

    push!(arr, gvars[:root_zone_wc].Actual) # Wr
    push!(arr, gvars[:root_zone_wc].SAT) # Wr(SAT)
    push!(arr, gvars[:root_zone_wc].FC) # Wr(FC)
    push!(arr, gvars[:root_zone_wc].Leaf) # Wr(exp)
    push!(arr, gvars[:root_zone_wc].Thresh) # Wr(sto)
    push!(arr, gvars[:root_zone_wc].Sen) # Wr(sen)
    push!(arr, gvars[:root_zone_wc].WP) # Wr(PWP)

    # 4. Profile/Root zone - soil salinity
    push!(arr, gvars[:float_parameters][:saltinfiltr]) # SaltIn
    push!(arr, gvars[:float_parameters][:drain]*gvars[:float_parameters][:ecdrain]*equiv/100) # SaltOut
    push!(arr, gvars[:float_parameters][:crsalt]/100) # SaltUp
    push!(arr, gvars[:total_salt_content].EndDay) # Salt()
    if rooting_depth < eps()
        saltval = undef_int
        gvars[:root_zone_salt].ECe = undef_int 
        gvars[:root_zone_salt].ECsw = undef_int 
        gvars[:root_zone_salt].KsSalt = 1 
    else
        saltval = gvars[:root_zone_wc].SAT*gvars[:root_zone_salt].ECe*equiv/100
    end 
    push!(arr, saltval) # SaltZ
    push!(arr, gvars[:root_zone_salt].ECe) # ECe
    push!(arr, gvars[:root_zone_salt].ECsw) # ECsw
    push!(arr, round(Int, 100*(1 - gvars[:root_zone_salt].KsSalt))) # StSalt_
    push!(arr, gvars[:float_parameters][:eciaqua]) # ECgw

    # 5. Compartments - Soil water content
    for compartment in gvars[:compartments]
        push!(arr, compartment.Theta*100) # WC_i
    end

    # 6. Compartmens - Electrical conductivity of the saturated soil-paste extract
    for compartment in gvars[:compartments]
        push!(arr, ececomp(compartment, gvars)) # ECe_i
    end

    # 7. Climate input parameters
    tempreal = (gvars[:float_parameters][:tmin] + gvars[:float_parameters][:tmax])/2
    push!(arr, gvars[:float_parameters][:eto]) # ETo
    push!(arr, gvars[:float_parameters][:tmin]) # Tmin
    push!(arr, tempreal) # Tavg
    push!(arr, gvars[:float_parameters][:tmax]) # Tmax
    push!(arr, gvars[:float_parameters][:co2i]) # CO2i

    add_output_in_dayout!(outputs, arr)
    return nothing
end

"""
    record_harvest!(outputs, gvars, nrcut, dayinseason, nrrun)

run.f90:RecordHarvest:6679
"""
function record_harvest!(outputs, gvars, nrcut, dayinseason, nrrun)
    arr = Float64[]

    push!(arr, nrrun) # RunNr

    dayi, monthi, yeari_c = determine_date(gvars[:crop].Day1)
    dayi, monthi, yeari = determine_date(gvars[:integer_parameters][:daynri])
    if yeari_c == 1901
        yeari = 9999
    end

    push!(arr, nrcut) # Nr
    push!(arr, yeari) # Date year
    push!(arr, monthi) # Date month
    push!(arr, dayi) # Date day

    if nrcut == 9999
        # last line at end of season
        # maybe use missing
        dap = 0 
        interval = 0 
        biomass = 0 
        dry_yield = 0 
        fresh_yield = 0
    else
        dap = dayinseason
        interval = gvars[:integer_parameters][:suminterval]
        biomass = gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]
        dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
        if gvars[:crop].DryMatter == undef_int
            fresh_yield = 0
        else
            fresh_yield = dry_yield/(gvars[:crop].DryMatter/100)
        end
    end
    if gvars[:crop].DryMatter == undef_int
        # maybe use missing
        sumy_ = 0
    else
        sumy_ = gvars[:sumwabal].YieldPart/(gvars[:crop].DryMatter/100)
    end

    push!(arr, dap) # DAP
    push!(arr, interval) # Interval
    push!(arr, biomass) # Biomass
    push!(arr, gvars[:sumwabal].Biomass) # Sum(B)
    push!(arr, dry_yield) # Dry-Yield
    push!(arr, gvars[:sumwabal].YieldPart) # Sum(Y)
    push!(arr, fresh_yield) # Fresh-Yield
    push!(arr, sumy_) # Sum(Y)_

    add_output_in_harvestsout!(outputs, arr)
    return nothing
end

"""
    write_evaluation_data!(outputs, gvars, dap, nrrun)

run.f90:WriteEvaluationData:6476
"""
function write_evaluation_data!(outputs, gvars, dap, nrrun)
    if length(gvars[:array_parameters][:DaynrEval]) > 0
        if gvars[:integer_parameters][:daynri] == gvars[:array_parameters][:DaynrEval][1]

            DaynrEval = gvars[:array_parameters][:DaynrEval] 
            CCmeanEval = gvars[:array_parameters][:CCmeanEval]
            CCstdEval = gvars[:array_parameters][:CCstdEval]
            BmeanEval = gvars[:array_parameters][:BmeanEval]
            BstdEval = gvars[:array_parameters][:BstdEval]
            SWCmeanEval = gvars[:array_parameters][:SWCmeanEval]
            SWCstdEval = gvars[:array_parameters][:SWCstdEval]

            daynri = popfirst!(DaynrEval)
            ccmean = popfirst!(CCmeanEval)
            ccstd = popfirst!(CCstdEval)
            bmean = popfirst!(BmeanEval)
            bstd = popfirst!(BstdEval)
            swcmean = popfirst!(SWCmeanEval)
            swcstd = popfirst!(SWCstdEval)

            di, mi, yi = determine_date(daynri)
            if gvars[:clim_record].FromY == 1901
                yi = yi - 1901 + 1
            end
            dap_temp = dap
            if gvars[:integer_parameters][:stagecode] == 0
                dap_temp = undef_int
            end

            swci = swcz_soil(gvars)

            arr = Float64[]
            push!(arr, nrrun) # RunNr
            push!(arr, yi) # Date year
            push!(arr, mi) # Date month
            push!(arr, di) # Date day
            push!(arr, dap_temp) # DAP
            push!(arr, gvars[:integer_parameters][:stagecode]) # Stage
            push!(arr, gvars[:float_parameters][:cciactual]*100) # CCsim
            push!(arr, ccmean) # CCobs
            push!(arr, ccstd) # CCstd
            push!(arr, gvars[:sumwabal].Biomass) # Bsim
            push!(arr, bmean) # Bobs
            push!(arr, bstd) # Bstd
            push!(arr, swci) # SWCsim
            push!(arr, swcmean) # SWCobs
            push!(arr, swcstd) # SWCstd

            add_output_in_evaldataout!(outputs, arr)

            setparameter!(gvars[:array_parameters], :DaynrEval, DaynrEval)
            setparameter!(gvars[:array_parameters], :CCmeanEval, CCmeanEval)
            setparameter!(gvars[:array_parameters], :CCstdEval, CCstdEval)
            setparameter!(gvars[:array_parameters], :BmeanEval, BmeanEval)
            setparameter!(gvars[:array_parameters], :BstdEval, BstdEval)
            setparameter!(gvars[:array_parameters], :SWCmeanEval, SWCmeanEval)
            setparameter!(gvars[:array_parameters], :SWCstdEval, SWCstdEval)
        end
    end
    return nothing
end


"""
    swcact = swcz_soil(gvars)

run.f90:SWCZsoil:6533
"""
function swcz_soil(gvars)
    zsoil = gvars[:float_parameters][:zeval]
    compartments = gvars[:compartments]

    cumdepth = 0
    compi = 0
    swcact = 0
    loopi = true
    while loopi
        compi = compi + 1
        cumdepth = cumdepth + compartments[compi].Thickness
        if cumdepth <= zsoil
            factor = 1
        else
            frac_value = zsoil - (cumdepth - compartments[compi].Thickness)
            if frac_value > 0
                factor = frac_value/compartments[compi].Thickness
            else
                 factor = 0
            end 
        end 
        swcact = swcact + factor * 10 * compartments[compi].Theta*100 * compartments[compi].Thickness
        if (round(Int, 100*cumdepth) >= round(Int, 100*zsoil)) | 
           (compi == length(compartments))
            loopi = false
        end
    end
    return swcact
end

"""
    initialize_lvars()
"""
function initialize_lvars()
    # we create these "lvars" because we need functions that 
    # returns nothing or does not change anything
    float_parameters = ParametersContainer(Float64)
    setparameter!(float_parameters, :wpi,  0.0) #here
    setparameter!(float_parameters, :preirri,  0.0) #advance_one_time_step
    setparameter!(float_parameters, :fracassim, 0.0) #advance_one_time_step
    setparameter!(float_parameters, :ecinfilt, 0.0) #budget_module
    setparameter!(float_parameters, :horizontalwaterflow, 0.0) #budget_module
    setparameter!(float_parameters, :horizontalsaltflow, 0.0) #budget_module
    setparameter!(float_parameters, :subdrain, 0.0) #budget_module
    setparameter!(float_parameters, :infiltratedrain, 0.0) #budget_module
    setparameter!(float_parameters, :infiltratedirrigation, 0.0) #budget_module
    setparameter!(float_parameters, :infiltratedstorage, 0.0) #budget_module

    integer_parameters = ParametersContainer(Int)
    setparameter!(integer_parameters, :targettimeval, 0) #advance_one_time_step
    setparameter!(integer_parameters, :targetdepthval, 0) #advance_one_time_step

    bool_parameters = ParametersContainer(Bool)
    setparameter!(bool_parameters, :harvestnow, false) #here


    lvars = Dict{Symbol, AbstractParametersContainer}(
        :float_parameters => float_parameters,
        :bool_parameters => bool_parameters,
        :integer_parameters => integer_parameters
    )
    return lvars
end
