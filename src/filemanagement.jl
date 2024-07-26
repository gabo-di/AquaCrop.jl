"""
run.f90:7760
"""
function file_management(outputs, gvars, projectinput::ProjectInputType)
    wpi = 0
    harvestnow = false
    repeattoday = gvars[:simulation].ToDayNr

    loopi = true
    # MARK
    while loopi
        call AdvanceOneTimeStep(WPi, HarvestNow)
        call ReadClimateNextDay()
        call SetGDDVariablesNextDay()
        if (gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    return nothing
end #notend

"""
run.f90:6747
"""
function advance_one_time_step(outputs, gvars, projectinput::ProjectInputType, wpi, harvestnow)
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
    get_irri_param!(gvars)

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
            adjust_swc_rootzone!(gvars)
        end 
    end 

    # 8. Transfer of Assimilates
    initialize_transfer_assimilates!(gvars, harvestnow)

    # 9. RUN Soil water balance and actual Canopy Cover
    StressLeaf_temp = GetStressLeaf()
    StressSenescence_temp = GetStressSenescence()
    TimeSenescence_temp = GetTimeSenescence()
    NoMoreCrop_temp = GetNoMoreCrop()
    call BUDGET_module(gvars[:integer_parameters][:daynri], TargetTimeVal, TargetDepthVal, &
           VirtualTimeCC, GetSumInterval(), GetDayLastCut(), &
           GetStressTot_NrD(), GetTadj(), GetGDDTadj(), GetGDDayi(), &
           GetCGCref(), GetGDDCGCref(), &
           GetCO2i(), GetCCxTotal(), GetCCoTotal(), GetCDCTotal(), &
           GetGDDCDCTotal(), SumGDDadjCC, &
           GetCoeffb0Salt(), GetCoeffb1Salt(), GetCoeffb2Salt(), &
           GetStressTot_Salt(), &
           GetDayFraction(), GetGDDayFraction(), FracAssim, &
           GetStressSFadjNEW(), GetTransfer_Store(), GetTransfer_Mobilize(), &
           StressLeaf_temp, StressSenescence_temp, TimeSenescence_temp, &
           NoMoreCrop_temp, TESTVAL)
    call SetStressLeaf(StressLeaf_temp)
    call SetStressSenescence(StressSenescence_temp)
    call SetTimeSenescence(TimeSenescence_temp)
    call SetNoMoreCrop(NoMoreCrop_temp)

    # consider Pre-irrigation (6.) if IrriMode = Inet
    if ((GetRootingDepth() > 0._dp) .and. (gvars[:integer_parameters][:daynri] == gvars[:crop].Day1()) &
        .and. (GetIrriMode() == IrriMode_Inet)) then
         call SetIrrigation(GetIrrigation() + PreIrri)
         call SetSumWabal_Irrigation(GetSumWaBal_Irrigation() + PreIrri)
         PreIrri = 0._dp
     end if

     # total number of days in the season
     if (GetCCiActual() > 0._dp) then
         if (GetStressTot_NrD() < 0) then
            call SetStressTot_NrD(1)
          else
            call SetStressTot_NrD(GetStressTot_NrD() + 1)
           end if
     end if

    # 10. Potential biomass
    BiomassUnlim_temp = GetSumWaBal_BiomassUnlim()
    CCxWitheredTpotNoS_temp = GetCCxWitheredTpotNoS()
    call DeterminePotentialBiomass(VirtualTimeCC, SumGDDadjCC, &
         GetCO2i(), GetGDDayi(), CCxWitheredTpotNoS_temp, BiomassUnlim_temp)
    call SetCCxWitheredTpotNoS(CCxWitheredTpotNoS_temp)
    call SetSumWaBal_BiomassUnlim(BiomassUnlim_temp)

    # 11. Biomass and yield
    if ((GetRootingDepth() > 0._dp) .and. (GetNoMoreCrop() .eqv. .false.)) then
        SWCtopSoilConsidered_temp = gvars[:simulation].SWCtopSoilConsidered()
        call DetermineRootZoneWC(GetRootingDepth(), SWCtopSoilConsidered_temp)
        call SetSimulation_SWCtopSoilConsidered(SWCtopSoilConsidered_temp)
        # temperature stress affecting crop transpiration
        if (GetCCiActual() <= 0.0000001_dp) then
             KsTr = 1._dp
        else
             KsTr = KsTemperature(0._dp, gvars[:crop].GDtranspLow(), GetGDDayi())
        end if
        call SetStressTot_Temp(((GetStressTot_NrD() - 1._dp)*GetStressTot_Temp() + &
                     100._dp*(1._dp-KsTr))/real(GetStressTot_NrD(), kind=dp))
        # soil salinity stress
         ECe_temp = GetRootZoneSalt_ECe()
         ECsw_temp = GetRootZoneSalt_ECsw()
         ECswFC_temp = GetRootZoneSalt_ECswFC()
         KsSalt_temp = GetRootZoneSalt_KsSalt()
         call DetermineRootZoneSaltContent(GetRootingDepth(), ECe_temp, &
                 ECsw_temp, ECswFC_temp, KsSalt_temp)
         call SetRootZoneSalt_ECe(ECe_temp)
         call SetRootZoneSalt_ECsw(ECsw_temp)
         call SetRootZoneSalt_ECswFC(ECswFC_temp)
         call SetRootZoneSalt_KsSalt(KsSalt_temp)
         call SetStressTot_Salt(((GetStressTot_NrD() - 1._dp)*GetStressTot_Salt()&
                + 100._dp*(1._dp-GetRootZoneSalt_KsSalt()))/&
                   real(GetStressTot_NrD(), kind=dp))
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
         call SetWeedRCi(real(undef_int, kind=dp)) # no crop and no weed infestation
         call SetCCiActualWeedInfested(0._dp) # no crop
         call SetTactWeedInfested(0._dp) # no crop
    end if

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
            gvars[:simulation].EffectStress_RedCGC(), &
            gvars[:simulation].EffectStress_RedCCX())
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
    get_irri_param!(gvars)

run.f90:6262
"""
function get_irri_param!(gvars)
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

    setparameter!(gvars[:integer_parameters], :targettimeval, targettimeval)
    setparameter!(gvars[:integer_parameters], :targetdepthval, targetdepthval)
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
    adjust_swc_rootzone!(gvars)

run.f90:6348
"""
function adjust_swc_rootzone!(gvars)
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

    # we create this "gvar" because we need a function that returns nothing or does not change anything
    setparameter!(gvars[:float_parameters], :preirri, preirri)
    return nothing
end

"""
    initialize_transfer_assimilates!(gvars, harvestnow)

run.f90:6378
"""
function initialize_transfer_assimilates!(gvars, harvestnow)
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    management = gvars[:management]
    daynri = gvars[:integer_parameters][:daynri]
    cciactual = gvars[:float_parameters][:cciactual]
    ccxtotal = gvars[:float_parameters][:ccxtotal]

    bin = gvars[:float_parameters][:bin]
    bout = gvars[:float_parameters][:bout]
    fracassim = gvars[:float_parameters][:fracassim]
    assimtomobilize = gvars[:transfer].ToMobilize
    assimmobilized = gvars[:transfer].Bmobilized
    storageon = gvars[:transfer].Store
    mobilizationon = gvars[:transfer].Mobilize

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
    setparameter!(gvars[:float_parameters], :fracassim, fracassim)
    gvars[:transfer].ToMobilize = assimtomobilize
    gvars[:transfer].Bmobilized = assimmobilized
    gvars[:transfer].Store = storageon
    gvars[:transfer].Mobilize = mobilizationon
    return nothing
end

