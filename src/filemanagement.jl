"""
run.f90:7760
"""
function file_management(outputs, gvars, projectinput::ProjectInputType)
    # we create these "lvars" because we need functions that 
    # returns nothing or does not change anything
    float_parameters = ParametersContainer(Float64)
    setparameter!(float_parameters, :wpi,  0.0)
    setparameter!(float_parameters, :preirri,  0.0)
    setparameter!(float_parameters, :fracassim, 0.0)
    setparameter!(float_parameters, :ecinfilt, 0.0)
    setparameter!(float_parameters, :horizontalwaterflow, 0.0)
    setparameter!(float_parameters, :horizontalsaltflow, 0.0)
    setparameter!(float_parameters, :subdrain, 0.0)
    setparameter!(float_parameters, :infiltratedrain, 0.0)
    setparameter!(float_parameters, :infiltratedirrigation, 0.0)
    setparameter!(float_parameters, :infiltratedstorage, 0.0)

    integer_parameters = ParametersContainer(Int)
    setparameter!(integer_parameters, :targettimeval, 0)
    setparameter!(integer_parameters, :targetdepthval, 0)

    bool_parameters = ParametersContainer(Bool)
    setparameter!(bool_parameters, :harvestnow, false)

    lvars = ComponentArray(
        float_parameters = float_parameters,
        bool_parameters = bool_parameters,
        integer_parameters = integer_parameters
    )
    repeattoday = gvars[:simulation].ToDayNr

    loopi = true
    # MARK
    while loopi
        advance_one_time_step!(outputs, gvars, lvars, projectinput)
        # call ReadClimateNextDay()
        # call SetGDDVariablesNextDay()
        if (gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    return nothing
end #notend

"""
    advance_one_time_step!(outputs, gvars, lvars, projectinput::ProjectInputType)

run.f90:6747
"""
function advance_one_time_step!(outputs, gvars, lvars, projectinput::ProjectInputType)
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
            get_gwt_set!(gvars, projectinput.ParentDir, gvars[:integer_parameters][:daynri])
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
        SWCtopSoilConsidered_temp = gvars[:simulation].SWCtopSoilConsidered()
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
         Store_temp = GetTransfer_Store()
         Mobilize_temp = GetTransfer_Mobilize()
         ToMobilize_temp = GetTransfer_ToMobilize()
         Bmobilized_temp = GetTransfer_Bmobilized()
         Biomass_temp = GetSumWaBal_Biomass()
         BiomassPot_temp = GetSumWaBal_BiomassPot()
         BiomassUnlim_temp = GetSumWaBal_BiomassUnlim()
         BiomassTot_temp = GetSumWaBal_BiomassTot()
         YieldPart_temp = GetSumWaBal_YieldPart()
         TactWeedInfested_temp = GetTactWeedInfested()
         PreviousStressLevel_temp = GetPreviousStressLevel()
         StressSFadjNEW_temp = GetStressSFadjNEW()
         CCxWitheredTpotNoS_temp = GetCCxWitheredTpotNoS()
         Bin_temp = GetBin()
         Bout_temp = GetBout()
         SumKcTopStress_temp = GetSumKcTopStress()
         SumKci_temp = GetSumKci()
         WeedRCi_temp = GetWeedRCi()
         CCiActualWeedInfested_temp = GetCCiActualWeedInfested()
         HItimesBEF_temp = GetHItimesBEF()
         ScorAT1_temp = GetScorAT1()
         ScorAT2_temp = GetScorAT2()
         HItimesAT1_temp = GetHItimesAT1()
         HItimesAT2_temp = GetHItimesAT2()
         HItimesAT_temp = GetHItimesAT()
         alfaHI_temp = GetalfaHI()
         alfaHIAdj_temp = GetalfaHIAdj()
         call DetermineBiomassAndYield(gvars[:integer_parameters][:daynri], GetETo(), GetTmin(), &
               GetTmax(), GetCO2i(), GetGDDayi(), GetTact(), GetSumKcTop(), &
               GetCGCref(), GetGDDCGCref(), GetCoeffb0(), GetCoeffb1(), &
               GetCoeffb2(), GetFracBiomassPotSF(), &
               GetCoeffb0Salt(), GetCoeffb1Salt(), GetCoeffb2Salt(), &
               GetStressTot_Salt(), SumGDDadjCC, GetCCiActual(), &
               FracAssim, VirtualTimeCC, GetSumInterval(), &
               Biomass_temp, BiomassPot_temp, BiomassUnlim_temp, &
               BiomassTot_temp, YieldPart_temp, WPi, &
               HItimesBEF_temp, ScorAT1_temp, ScorAT2_temp, &
               HItimesAT1_temp, HItimesAT2_temp, HItimesAT_temp, &
               alfaHI_temp, alfaHIAdj_temp, &
               SumKcTopStress_temp, SumKci_temp, &
               WeedRCi_temp, CCiActualWeedInfested_temp, &
               TactWeedInfested_temp, StressSFadjNEW_temp, &
               PreviousStressLevel_temp, Store_temp, &
               Mobilize_temp, ToMobilize_temp, &
               Bmobilized_temp, Bin_temp, Bout_temp, TESTVALY)
         call SetTransfer_Store(Store_temp)
         call SetTransfer_Mobilize(Mobilize_temp)
         call SetTransfer_ToMobilize(ToMobilize_temp)
         call SetTransfer_Bmobilized(Bmobilized_temp)
         call SetSumWaBal_Biomass(Biomass_temp)
         call SetSumWaBal_BiomassPot(BiomassPot_temp)
         call SetSumWaBal_BiomassUnlim(BiomassUnlim_temp)
         call SetSumWaBal_BiomassTot(BiomassTot_temp)
         call SetSumWaBal_YieldPart(YieldPart_temp)
         call SetTactWeedInfested(TactWeedInfested_temp)
         call SetBin(Bin_temp)
         call SetBout(Bout_temp)
         call SetPreviousStressLevel(int(PreviousStressLevel_temp, kind=int32))
         call SetStressSFadjNEW(int(StressSFadjNEW_temp, kind=int32))
         call SetCCxWitheredTpotNoS(CCxWitheredTpotNoS_temp)
         call SetSumKcTopStress(SumKcTopStress_temp)
         call SetSumKci(SumKci_temp)
         call SetWeedRCi(WeedRCi_temp)
         call SetCCiActualWeedInfested(CCiActualWeedInfested_temp)
         call SetHItimesBEF(HItimesBEF_temp)
         call SetScorAT1(ScorAT1_temp)
         call SetScorAT2(ScorAT2_temp)
         call SetHItimesAT1(HItimesAT1_temp)
         call SetHItimesAT2(HItimesAT2_temp)
         call SetHItimesAT(HItimesAT_temp)
         call SetalfaHI(alfaHI_temp)
         call SetalfaHIAdj(alfaHIAdj_temp)
    else
         # SenStage = undef_int #GDL, 20220423, not used
         setparameter!(gvars[:float_parameters], :weedrci, undef_double)  # no crop and no weed infestation
         setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.0)  # no crop
         setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0)  # no crop
    end 

    # 12. Reset after RUN
    if (GetPreDay() .eqv. .false.) then
        call SetPreviousDayNr(gvars[:simulation].FromDayNr() - 1)
    end if
    call SetPreDay(.true.)
    if (gvars[:integer_parameters][:daynri] >= gvars[:crop].Day1()) then
        call SetCCiPrev(GetCCiActual())
        if (GetZiprev() < GetRootingDepth()) then
            call SetZiprev(GetRootingDepth())
            # IN CASE groundwater table does not affect root development
        end if
        call SetSumGDDPrev(gvars[:simulation].SumGDD())
    end if
    if (TargetTimeVal == 1) then
        call SetIrriInterval(0)
    end if

    # 13. Cuttings
    if (GetManagement_Cuttings_Considered()) then
        HarvestNow = .false.
        DayInSeason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1() + 1
        call SetSumInterval(GetSumInterval() + 1)
        call SetSumGDDcuts( GetSumGDDcuts() + GetGDDayi())
        select case (GetManagement_Cuttings_Generate())
        case (.false.)
            if (GetManagement_Cuttings_FirstDayNr() /= undef_int) then
               # adjust DayInSeason
                DayInSeason = gvars[:integer_parameters][:daynri] - &
                     GetManagement_Cuttings_FirstDayNr() + 1
            end if
            if ((DayInSeason >= GetCutInfoRecord1_FromDay()) .and. &
                (GetCutInfoRecord1_NoMoreInfo() .eqv. .false.)) then
                HarvestNow = .true.
                call GetNextHarvest()
            end if
            if (GetManagement_Cuttings_FirstDayNr() /= undef_int) then
               # reset DayInSeason
                DayInSeason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1() + 1
            end if
        case (.true.)
            if ((DayInSeason > GetCutInfoRecord1_ToDay()) .and. &
                (GetCutInfoRecord1_NoMoreInfo() .eqv. .false.)) then
                call GetNextHarvest()
            end if
            select case (GetManagement_Cuttings_Criterion())
            case (TimeCuttings_IntDay)
                if ((GetSumInterval() >= GetCutInfoRecord1_IntervalInfo()) &
                     .and. (DayInSeason >= GetCutInfoRecord1_FromDay()) &
                     .and. (DayInSeason <= GetCutInfoRecord1_ToDay())) then
                    HarvestNow = .true.
                end if
            case (TimeCuttings_IntGDD)
                if ((GetSumGDDcuts() >= GetCutInfoRecord1_IntervalGDD()) &
                     .and. (DayInSeason >= GetCutInfoRecord1_FromDay()) &
                     .and. (DayInSeason <= GetCutInfoRecord1_ToDay())) then
                    HarvestNow = .true.
                end if
            case (TimeCuttings_DryB)
                if (((GetSumWabal_Biomass() - GetBprevSum()) >= &
                      GetCutInfoRecord1_MassInfo()) &
                     .and. (DayInSeason >= GetCutInfoRecord1_FromDay()) &
                     .and. (DayInSeason <= GetCutInfoRecord1_ToDay())) then
                    HarvestNow = .true.
                end if
            case (TimeCuttings_DryY)
                if (((GetSumWabal_YieldPart() - GetYprevSum()) >= &
                      GetCutInfoRecord1_MassInfo()) &
                    .and. (DayInSeason >= GetCutInfoRecord1_FromDay()) &
                    .and. (DayInSeason <= GetCutInfoRecord1_ToDay())) then
                    HarvestNow = .true.
                end if
            case (TimeCuttings_FreshY)
                # OK if Crop.DryMatter = undef_int (not specified) HarvestNow
                # remains false
                if ((((GetSumWaBal_YieldPart() - GetYprevSum())/&
                    (gvars[:crop].DryMatter()/100._dp)) >= &
                     GetCutInfoRecord1_MassInfo()) &
                    .and. (DayInSeason >= GetCutInfoRecord1_FromDay()) &
                    .and. (DayInSeason <= GetCutInfoRecord1_ToDay())) then
                    HarvestNow = .true.
                end if
            end select
        end select
        if (HarvestNow .eqv. .true.) then
            call SetNrCut(GetNrCut() + 1)
            call SetDayLastCut(DayInSeason)
            if (GetCCiPrev() > (GetManagement_Cuttings_CCcut()/100._dp)) then
                call SetCCiPrev(GetManagement_Cuttings_CCcut()/100._dp)
                # ook nog CCwithered
                call SetCrop_CCxWithered(0._dp)  # or CCiPrev ??
                call SetCCxWitheredTpotNoS(0._dp)
                   # for calculation Maximum Biomass unlimited soil fertility
                call SetCrop_CCxAdjusted(GetCCiPrev()) # new
            end if
            # Record harvest
            if (GetPart1Mult()) then
                call RecordHarvest(GetNrCut(), DayInSeason)
            end if
            # Reset
            call SetSumInterval(0)
            call SetSumGDDcuts(0._dp)
            call SetBprevSum(GetSumWaBal_Biomass())
            call SetYprevSum(GetSumWaBal_YieldPart())
        end if
    end if

    # 14. Write results
    # 14.a Summation
    call SetSumETo( GetSumETo() + GetETo())
    call SetSumGDD( GetSumGDD() + GetGDDayi())
    # 14.b Stress totals
    if (GetCCiActual() > 0._dp) then
        # leaf expansion growth
        if (GetStressLeaf() > - 0.000001_dp) then
            call SetStressTot_Exp(((GetStressTot_NrD() - 1._dp)*GetStressTot_Exp() &
                     + GetStressLeaf())/real(GetStressTot_NrD(), kind=dp))
        end if
        # stomatal closure
        if (GetTpot() > 0._dp) then
            StressStomata = 100._dp *(1._dp - GetTact()/GetTpot())
            if (StressStomata > - 0.000001_dp) then
                call SetStressTot_Sto(((GetStressTot_NrD() - 1._dp) &
                    * GetStressTot_Sto() + StressStomata) / &
                    real(GetStressTot_NrD(), kind=dp))
            end if
        end if
    end if
    # weed stress
    if (GetWeedRCi() > - 0.000001_dp) then
        call SetStressTot_Weed(((GetStressTot_NrD() - 1._dp)*GetStressTot_Weed() &
             + GetWeedRCi())/real(GetStressTot_NrD(), kind=dp))
    end if
    # 14.c Assign crop parameters
    call SetPlotVarCrop_ActVal(GetCCiActual()/&
             GetCCxCropWeedsNoSFstress() * 100._dp)
    call SetPlotVarCrop_PotVal(100._dp * (1._dp/GetCCxCropWeedsNoSFstress()) * &
           CanopyCoverNoStressSF((VirtualTimeCC+gvars[:simulation].DelayedDays() &
             + 1), gvars[:crop].DaysToGermination(), gvars[:crop].DaysToSenescence(), &
             gvars[:crop].DaysToHarvest(), gvars[:crop].GDDaysToGermination(), &
             gvars[:crop].GDDaysToSenescence(), gvars[:crop].GDDaysToHarvest(), &
             (GetfWeedNoS()*gvars[:crop].CCo()), (GetfWeedNoS()*gvars[:crop].CCx()), &
             GetCGCref(), &
             (gvars[:crop].CDC()*(GetfWeedNoS()*gvars[:crop].CCx() + 2.29_dp)/&
             (gvars[:crop].CCx() + 2.29_dp)),&
             GetGDDCGCref(), &
             (gvars[:crop].GDDCDC()*(GetfWeedNoS()*gvars[:crop].CCx() + 2.29_dp)/&
             (gvars[:crop].CCx() + 2.29_dp)), &
             SumGDDadjCC, gvars[:crop].ModeCycle(), 0_int8, 0_int8))
    if ((VirtualTimeCC+gvars[:simulation].DelayedDays() + 1) <= &
         gvars[:crop].DaysToFullCanopySF()) then
        # not yet canopy decline with soil fertility stress
        PotValSF = 100._dp * (1._dp/GetCCxCropWeedsNoSFstress()) * &
           CanopyCoverNoStressSF((VirtualTimeCC + &
            gvars[:simulation].DelayedDays() + 1), &
            gvars[:crop].DaysToGermination(), &
            gvars[:crop].DaysToSenescence(), gvars[:crop].DaysToHarvest(), &
            gvars[:crop].GDDaysToGermination(), gvars[:crop].GDDaysToSenescence(), &
            gvars[:crop].GDDaysToHarvest(),  GetCCoTotal(), GetCCxTotal(), &
            gvars[:crop].CGC(), GetCDCTotal(), &
            gvars[:crop].GDDCGC(), GetGDDCDCTotal(), &
            SumGDDadjCC, gvars[:crop].ModeCycle(), &
            gvars[:simulation].EffectStress.RedCGC(), &
            gvars[:simulation].EffectStress.RedCCX())
    else
        call GetPotValSF((VirtualTimeCC+gvars[:simulation].DelayedDays() + 1), &
               SumGDDAdjCC, PotValSF)
    end if
    # 14.d Print ---------------------------------------
    if (GetOutputAggregate() > 0) then
        call CheckForPrint(GetTheProjectFile())
    end if
    if (GetOutDaily()) then
        call WriteDailyResults((gvars[:integer_parameters][:daynri] - gvars[:simulation].DelayedDays() &
                                - gvars[:crop].Day1()+1), WPi)
    end if
    if (GetPart2Eval() .and. (GetObservationsFile() /= '(None)')) then
        call WriteEvaluationData((gvars[:integer_parameters][:daynri]-gvars[:simulation].DelayedDays()-gvars[:crop].Day1()+1))
    end if

    # 15. Prepare Next day
    # 15.a Date
    call SetDayNri(gvars[:integer_parameters][:daynri] + 1)
    # 15.b Irrigation
    if (gvars[:integer_parameters][:daynri] == gvars[:crop].Day1()) then
        call SetIrriInterval(1)
    else
        call SetIrriInterval(GetIrriInterval() + 1)
    end if
    # 15.c Rooting depth
    # 15.bis extra line for standalone
    if (GetOutDaily()) then
        call DetermineGrowthStage(gvars[:integer_parameters][:daynri], GetCCiPrev())
    end if
    # 15.extra - reset ageing of Kc at recovery after full senescence
    if (gvars[:simulation].SumEToStress() >= 0.1_dp) then
       call SetDayLastCut(gvars[:integer_parameters][:daynri])
    end if
    return nothing
end #notend

"""
    get_z_and_ec_gwt!(gvars)

run.f90:6159
"""
function get_z_and_ec_gwt!(gvars)
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

run.f90:6262
"""
function get_irri_param!(gvars, lvars)
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
            targettimeval = gvars[:irri_info_record1]_TimeInfo

        elseif gvars[:symbol_parameters][:timemode] == :AllRAW
            targettimeval = gvars[:irri_info_record1]_TimeInfo

        elseif gvars[:symbol_parameters][:timemode] == :FixInt
            targettimeval = gvars[:irri_info_record1]_TimeInfo
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
            targettimeval = gvars[:irri_info_record1]_TimeInfo
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

run.f90:6188
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
    if (dnr < 1) then
        irri = 0
    else
        theend = false
        nri = 0
        loopi = true
        while loopi
            nri = nri + 1
            if irrievents[nri].DayNr == DNr
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

run.f90:6224
"""
function irri_manual!(gvars)
    irri_info_record1 = gvars[:irri_info_record1]

    if gvars[:integer_parameters][:irri_first_daynr] == undef_int
        dnr = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
    else
        dnr = gvars[:integer_parameters][:daynri] - gvars[:integer_parameters][:irri_first_daynr] + 1
    end 
    if irri_info_record.NoMoreInfo
        irri = 0
    else
        irri = 0
        if irri_info_record.TimeInfo == dnr
            Irri_1 = gvars[:array_parameters][:Irri_1]
            Irri_2 = gvars[:array_parameters][:Irri_2]
            Irri_3 = gvars[:array_parameters][:Irri_3]

            irri = irri_info_record.DepthInfo
            if length(Irri_1) == 0
                irri_info_record.NoMoreInfo = true
            else
                ir1 = round(Int, popfirst!(Irri_1))
                ir2 = round(Int, popfirst!(Irri_2))
                irriecw = popfirst!(Irri_3)
                gvars[:simulation].IrriECw = irriecw
                irri_info_record1.TimeInfo = ir1
                irri_info_record1.DepthInfo = ir2
                irri_info_record.NoMoreInfo = false 
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


global.f90:6371
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
                                       (cdc*(fweed*ccx+2.29)/(ccx+2.29_dp)), 
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

rootunit.f90:37
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
        zimax = actual_rooting_depth(dap, l0, lzmax, l1234, gddl0, gddlzmax,
                                sumgdd, zmin, zmax, shapefactor, typedays, gvars)
        # -- 1.3 Restore effect of restrive soil layer(s)
        gvars[:soil].RootMax = zlimit 

        # 2. increase (dZ) at time t
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

global.f90:7750
"""
function determine_root_zone_wc!(gvars, rootingdepth)
    root_zone_wc = gvars[:root_zone_wc]  
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]

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

run.f90:6348
"""
function adjust_swc_rootzone!(gvars, lvars)
    compartments = gvars[:compartments]

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

run.f90:6378
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

simul.f90:453
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
        dap = sum_calendar_days(sumgddadjcc, crop.Day1, crop.Tbase, 
                    crop.Tupper, simulparam.Tmin, simulparam.Tmax, gvars)
        dap = dap + simulation.DelayedDays # are not considered when working with GDDays
    end 
    tpotforb, epottotforb = calculate_etpot(dap, crop.DaysToGermination, crop.DaysToFullCanopy, 
                   crop.DaysToSenescence, crop.DaysToHarvest, 0, ccipot, 
                   gvars[:float_parameters][:eto],
                   crop.KcTop, crop.KcDecline, crop.CCx, 
                   CCxWitheredTpotNoS, crop.CCEffectEvapLate, co2i, gddayi, 
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
    if round(Int, 100*co2i) != round(Int, 100*co2ref)
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

global.f90:2749
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
        fco2old = (co2i/CO2Ref)/(1+(co2i-CO2Ref)*((1-fw)*0.000138&
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
            fco2adj = 1 + 0.58 * ((exp(co2rel*fshape) - 1)/&
                (exp(fshape) - 1))
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
simul.f90:528
"""
function determinebiomassandyield(dayi, eto, tminonday, tmaxonday, co2i, 
                                    gddayi, tact, sumkctop, cgcref, gddcgcref, 
                                    coeffb0, coeffb1, coeffb2, fracbiomasspotsf, 
                                    coeffb0salt, coeffb1salt, coeffb2salt, 
                                    averagesaltstress, sumgddadjcc, cctot, 
                                    fracassim, virtualtimecc, suminterval, 
                                    biomass, biomasspot, biomassunlim, 
                                    biomasstot, yieldpart, wpi, hitimesbef, 
                                    scorat1, scorat2, hitimesat1, hitimesat2, 
                                    hitimesat, alfa, alfamax, sumkctopstress, 
                                    sumkci, 
                                    weedrci, ccw, trw, stresssfadjnew, 
                                    previousstresslevel, storeassimilates, 
                                    mobilizeassimilates, assimtomobilize, 
                                    assimmobilized, bin, bout)

    integer(int32), intent(in) :: dayi
    real(dp), intent(in) :: ETo
    real(dp), intent(in) :: TminOnDay
    real(dp), intent(in) :: TmaxOnDay
    real(dp), intent(in) :: CO2i
    real(dp), intent(in) :: GDDayi
    real(dp), intent(in) :: Tact
    real(dp), intent(in) :: SumKcTop
    real(dp), intent(in) :: CGCref
    real(dp), intent(in) :: GDDCGCref
    real(dp), intent(in) :: Coeffb0
    real(dp), intent(in) :: Coeffb1
    real(dp), intent(in) :: Coeffb2
    real(dp), intent(in) :: FracBiomassPotSF
    real(dp), intent(in) :: Coeffb0Salt
    real(dp), intent(in) :: Coeffb1Salt
    real(dp), intent(in) :: Coeffb2Salt
    real(dp), intent(in) :: AverageSaltStress
    real(dp), intent(in) :: SumGDDadjCC
    real(dp), intent(in) :: CCtot
    real(dp), intent(inout) :: FracAssim
    integer(int32), intent(in) :: VirtualTimeCC
    integer(int32), intent(in) :: SumInterval
    real(dp), intent(inout) :: Biomass
    real(dp), intent(inout) :: BiomassPot
    real(dp), intent(inout) :: BiomassUnlim
    real(dp), intent(inout) :: BiomassTot
    real(dp), intent(inout) :: YieldPart
    real(dp), intent(inout) :: WPi
    real(dp), intent(inout) :: HItimesBEF
    real(dp), intent(inout) :: ScorAT1
    real(dp), intent(inout) :: ScorAT2
    real(dp), intent(inout) :: HItimesAT1
    real(dp), intent(inout) :: HItimesAT2
    real(dp), intent(inout) :: HItimesAT
    real(dp), intent(inout) :: alfa
    real(dp), intent(inout) :: alfaMax
    real(dp), intent(inout) :: SumKcTopStress
    real(dp), intent(inout) :: SumKci
    real(dp), intent(inout) :: WeedRCi
    real(dp), intent(inout) :: CCw
    real(dp), intent(inout) :: Trw
    integer(int8), intent(inout) :: StressSFadjNEW
    integer(int8), intent(inout) :: PreviousStressLevel
    logical, intent(inout) :: StoreAssimilates
    logical, intent(inout) :: MobilizeAssimilates
    real(dp), intent(inout) :: AssimToMobilize
    real(dp), intent(inout) :: AssimMobilized
    real(dp), intent(inout) :: Bin
    real(dp), intent(inout) :: Bout




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
            alfa, hifinal_temp, percentlagphase = harvest_index_day(dayi-gvars[:crop].Day1, gvars[:crop].DaysToFlowering, &
                                   gvars[:crop].HI, gvars[:crop].dHIdt, GetCCiactual, &
                                   gvars[:crop].CCxAdjusted, gvars[:crop].CCxWithered, gvars[:simulparam].PercCCxHIfinal, &
                                   gvars[:crop].Planting, hifinal_temp, crop, simulation)
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
        if round(Int, 100*co2i) /= round(Int, 100*CO2Ref)
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
            determine_root_zone_wc!(gvars, gvars[:float_parameters][:rooting_depth]
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
                pleafulact, pleafllact adjust_pleaf_to_eto(eto, crop, simulparam)
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
                pstomatulact = adjust_pstomatal_to_eto(eto, crop, simulparam)
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
            HItimesTotal = HItimesBEF * HItimesAT
            if (HItimesTotal > (1 +(gvars[:crop].DHImax/100))) then
                HItimesTotal = 1 +(gvars[:crop].DHImax/100)
            end

            # 2.9 Yield
            if (alfaMax >= alfa) then
                YieldPart = Biomass * HItimesTotal*(alfa/100)
            else
                YieldPart = Biomass * HItimesTotal*(alfaMax/100)
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
            !gvars[:crop].StressResponser.Calibrated
            # no (calibrated) soil fertility stress
            stresssfadjnew = 0
        else
            # BiomassUnlim is too small
            stresssfadjnew = gvars[:management].FertilityStress
        end
    end

    previousstresslevel = stresssfadjnew
    sumkctopstress = (1 - stresssfadjnew/100) * sumkctop


    return nothing
end

"""
    yeari = year_weighing_factor(cropfirstdaynr)
    
simul.f90:1073
"""
function year_weighing_factor(cropfirstdaynr)
    dayi, monthi, yeari = determine_date(cropfirstdaynr)
    return Yeari
end

"""
    fi = fraction_period(diflor, crop)

simul.f90:1050
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

simul.f90:1025
"""
function fraction_flowering(dayi, crop, simulation)
  if crop.LengthFlowering <= 1
      f = 1
  else
      DiFlor = dayi - (simulation.DelayedDays + crop.Day1 + crop.DaysToFlowering)
      f2 = fraction_period(diflor, crop)
      diflor = (dayi-1) - (simulation.DelayedDays + crop.Day1 + crop.DaysToFlowering)
      f1 = fraction_period(diflor, crop)
      if abs(f1-f2) < 0.0000001
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

global.f90:5530
"""
function harvest_index_day(dap, daystoflower, himax, dhidt, cci, 
                                  ccxadjusted, theccxwithered, 
                                  percccxhifinal, tempplanting, 
                                  hifinal,
                                  crop, simulation)


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
                percentlagphase = round(int, 100 * t/tswitch)
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
           (crop.subkind != :Forage)) 
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

global.f90:2278
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

global.f90:2295
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

