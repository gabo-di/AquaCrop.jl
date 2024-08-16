"""
    initialize_run_part1!(outputs, gvars, projectinput::ProjectInputType; kwargs...)

run.f90:6590
"""
function initialize_run_part1!(outputs, gvars, projectinput::ProjectInputType; kwargs...)
    load_simulation_project!(outputs, gvars, projectinput; kwargs...)
    adjust_compartments!(gvars) #TODO check if neccesary
    # reset sumwabal and previoussum
    gvars[:sumwabal] = RepSum() 
    reset_previous_sum!(gvars)

    initialize_simulation_run_part1!(outputs, gvars, projectinput)

    return nothing
end 

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
    setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.0)
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
    relationships_for_fertility_and_salt_stress!(outputs, gvars)

    # No soil fertility stress
    if gvars[:management].FertilityStress <= 0 
        gvars[:management].FertilityStress = 0
    end

    # Reset soil fertility parameters to selected value in management
    gvars[:simulation].EffectStress = crop_stress_parameters_soil_fertility(gvars[:crop].StressResponse, gvars[:management].FertilityStress)
    l12sf, redcgc, redccx, classsf = time_to_max_canopy_sf(gvars[:crop].CCo, gvars[:crop].CGC, gvars[:crop].CCx, 
        gvars[:crop].DaysToGermination, gvars[:crop].DaysToFullCanopy,
        gvars[:crop].DaysToSenescence, gvars[:crop].DaysToFlowering,
        gvars[:crop].LengthFlowering, gvars[:crop].DeterminancyLinked,
        gvars[:crop].DaysToFullCanopySF, gvars[:simulation].EffectStress.RedCGC,
        gvars[:simulation].EffectStress.RedCCX, gvars[:management].FertilityStress)
    
    gvars[:crop].DaysToFullCanopySF = l12sf
    gvars[:simulation].EffectStress.RedCGC = redcgc
    gvars[:simulation].EffectStress.RedCCX = redccx
    gvars[:management].FertilityStress = classsf

    setparameter!(gvars[:integer_parameters], :previous_stress_level, gvars[:management].FertilityStress)
    setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, gvars[:management].FertilityStress)
    # soil fertility and GDDays
    if gvars[:crop].ModeCycle == :GDDays 
        if gvars[:management].FertilityStress != 0 
            gvars[:crop].GDDaysToFullCanopySF = growing_degree_days(
                                                    gvars[:crop].DaysToFullCanopySF,
                                                    gvars[:crop].Day1,
                                                    gvars[:crop].Tbase,
                                                    gvars[:crop].Tupper,
                                                    gvars,
                                                    gvars[:simulparam].Tmin,
                                                    gvars[:simulparam].Tmax
                                                ) 
        else
            gvars[:crop].GDDaysToFullCanopySF = gvars[:crop].GDDaysToFullCanopy
        end 
    end

    # Maximum sum Kc (for reduction WP in season if soil fertility stress)
    gvars[:simulation].DelayedDays = 0 #note that we need to do this before calling seasonal_sum_of_kcpot
    sumkctop = seasonal_sum_of_kcpot(outputs, gvars[:crop].DaysToCCini,
            gvars[:crop].GDDaysToCCini, gvars[:crop].DaysToGermination,
            gvars[:crop].DaysToFullCanopy, gvars[:crop].DaysToSenescence,
            gvars[:crop].DaysToHarvest, gvars[:crop].GDDaysToGermination,
            gvars[:crop].GDDaysToFullCanopy, gvars[:crop].GDDaysToSenescence,
            gvars[:crop].GDDaysToHarvest, gvars[:crop].CCo, gvars[:crop].CCx,
            gvars[:crop].CGC, gvars[:crop].GDDCGC, gvars[:crop].CDC, gvars[:crop].GDDCDC,
            gvars[:crop].KcTop, gvars[:crop].KcDecline, gvars[:crop].CCEffectEvapLate, 
            gvars[:crop].Tbase, gvars[:crop].Tupper, gvars[:simulparam].Tmin,
            gvars[:simulparam].Tmax, gvars[:crop].GDtranspLow, gvars[:float_parameters][:co2i],
            gvars[:crop].ModeCycle, gvars[:simulation], gvars[:simulparam])
    setparameter!(gvars[:float_parameters], :sumkctop, sumkctop)
    setparameter!(gvars[:float_parameters], :sumkctop_stress, sumkctop*gvars[:float_parameters][:fracbiomasspotsf])
    setparameter!(gvars[:float_parameters], :sumkci, 0.0)

    # 7. weed infestation and self-thinning of herbaceous perennial forage crops
    # CC expansion due to weed infestation and/or CC decrease as a result of
    # self-thinning
    # 7.1 initialize
    gvars[:simulation].RCadj = gvars[:management].WeedRC
    cweed = 0
    if gvars[:crop].subkind == :Forage
        fi = multiplier_ccx_self_thinning(gvars[:simulation].YearSeason, gvars[:crop].YearCCx, gvars[:crop].CCxRoot)
    else
        fi = 1
    end 
    # 7.2 fweed
    if gvars[:management].WeedRC > 0 
        fweednos = cc_multiplier_weed(gvars[:management].WeedRC, gvars[:crop].CCx, gvars[:management].WeedShape)
        setparameter!(gvars[:float_parameters], :fweednos, fweednos)
        ccxcrop_weednosf_stress = round(Int, (100*gvars[:crop].CCx*fweednos + 0.49))/100 # reference for plot with weed
        setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, ccxcrop_weednosf_stress)
        if gvars[:management].FertilityStress > 0
            fweed = 1
            if (fi > 0) & (gvars[:crop].subkind == :Forage) 
                cweed = 1
                if fi > 0.005
                    # calculate the adjusted weed cover
                    gvars[:simulation].RCadj = round(Int, gvars[:management].WeedRC+cweed*(1-fi)*gvars[:crop].CCx*
                                                     (1-gvars[:simulation].EffectStress.RedCCX/100)*gvars[:management].WeedAdj/100)
                    if (gvars[:simulation].RCadj < (100*(1-fi/(fi+(1-fi)*(gvars[:management].WeedAdj/100))))) 
                        gvars[:simulation].RCadj = round(Int, 100*(1-fi/(fi+(1-fi)*(gvars[:management].WeedAdj/100))))
                    end
                    if gvars[:simulation].RCadj > 100
                        gvars[:simulation].RCadj = 98
                    end 
                else
                    gvars[:simulation].RCadj = 100 
                end 
            end 
        else
            if gvars[:crop].subkind == :Forage 
                fweed, rcadj = cc_multiplier_weed_adjusted(gvars[:management].WeedRC, 
                                    gvars[:crop].CCx, gvars[:management].WeedShape,
                                    fi, gvars[:simulation].YearSeason,
                                    gvars[:management].WeedAdj, gvars[:crop].subkind)
                gvars[:simulation].RCadj = rcadj
            else
                fweed = gvars[:float_parameters][:fweednos]
            end 
        end 
    else
        setparameter!(gvars[:float_parameters], :fweednos, 1.0)
        fweed = 1
        setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, gvars[:crop].CCx)
    end

    # 7.3 CC total due to weed infestation
    ccxtotal = fweed * gvars[:crop].CCx * (fi+cweed*(1-fi)*gvars[:management].WeedAdj/100)
    setparameter!(gvars[:float_parameters], :ccxtotal, ccxtotal)

    cdctotal = (gvars[:crop].CDC*(fweed*gvars[:crop].CCx*
                (fi+cweed*(1-fi)*gvars[:management].WeedAdj/100) + 2.29)/
                (gvars[:crop].CCx*(fi+cweed*(1-fi)*gvars[:management].WeedAdj/100)+2.29))
    setparameter!(gvars[:float_parameters], :cdctotal, cdctotal)

    gddcdctotal = (gvars[:crop].GDDCDC*(fweed*gvars[:crop].CCx*
                    (fi+cweed*(1-fi)*gvars[:management].WeedAdj/100) + 2.29)/
                    (gvars[:crop].CCx*(fi+cweed*(1-fi)*gvars[:management].WeedAdj/100)+2.29))
    setparameter!(gvars[:float_parameters], :gddcdctotal, gddcdctotal)

    if gvars[:crop].subkind == :Forage
        fi = multiplier_cco_self_thinning(gvars[:simulation].YearSeason, gvars[:crop].YearCCx, gvars[:crop].CCxRoot)
    else
        fi = 1
    end 
    ccototal = (fweed*gvars[:crop].CCo*(fi+cweed*(1-fi)*gvars[:management].WeedAdj/100))
    setparameter!(gvars[:float_parameters], :ccototal, ccototal)

    # 8. prepare output files
    # Not applicable

    # 9. first day
    setparameter!(gvars[:bool_parameters], :startmode, true)
    setparameter!(gvars[:bool_parameters], :preday, !gvars[:simulation].ResetIniSWC)
    setparameter!(gvars[:integer_parameters], :daynri, gvars[:simulation].FromDayNr)
    day1, month1, year1 = determine_date(gvars[:simulation].FromDayNr) # start simulation run
    setparameter!(gvars[:bool_parameters], :noyear, year1==1901) # for output file

    return nothing
end 

"""
    logi = check_for_watertable_in_profile(profilecomp::Vector{CompartmentIndividual}, depthgwtmeter)

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

function check_for_watertable_in_profile(profilecomp::Vector{AbstractParametersContainer}, depthgwtmeter)
    return check_for_watertable_in_profile(CompartmentIndividual[c for c in profilecomp], depthgwtmeter)
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
        groundwater_file = gvars[:string_parameters][:groundwater_file]
    else
        groundwater_file = parentdir * "GroundWater.AqC"
    end 

    # Get DayNr1Gwt
    open(groundwater_file, "r") do file
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
                    gwt.Z1 = gwt.Z2
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
                if yearact != 1901 
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
                        if yearact != 1901 
                            # make observation defined
                            dayi, monthi, yeari = determine_date(gwt.DNr2)
                            gwt.DNr2 = determine_day_nr(dayi, monthi, yearact)
                        end 
                        gwt.Z2 = round(Int, zm * 100)
                        if daynrin<gwt.DNr2 
                            theend = true
                        end 
                        if theend | eof(file) 
                            loop3 = false
                        end
                    end
                    if !theend 
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

    Tmin = gvars[:array_parameters][:Tmin]
    Tmax = gvars[:array_parameters][:Tmax]

    if gvars[:bool_parameters][:temperature_file_exists]
        # open file and find first day of cropping period
        if gvars[:temperature_record].Datatype == :Daily
            # Tmin and Tmax arrays contain the TemperatureFilefull data
            i = crop_firstday - gvars[:temperature_record].FromDayNr + 1
            tlow = Tmin[i]
            thigh = Tmax[i]
        
        elseif gvars[:temperature_record].Datatype == :Decadely
            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, crop_firstday,
                                            (Tmin, Tmax), 
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != crop_firstday
                i += 1
            end
            tlow = tmin_dataset[i].Param 
            thigh = tmax_dataset[i].Param 

        elseif gvars[:temperature_record].Datatype == :Monthly
            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, crop_firstday,
                                            (Tmin, Tmax), 
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != crop_firstday
                i += 1
            end
            tlow = tmin_dataset[i].Param 
            thigh = tmax_dataset[i].Param 
        end

        # we are not creating the TCrop.SIM for now but we use outputs variable
        add_output_in_tcropsim!(outputs, tlow, thigh)

        # next days of simulation period
        for runningday in (crop_firstday+1):crop_lastday
            if gvars[:temperature_record].Datatype == :Daily
                i += 1
                if i==length(gvars[:array_parameters][:Tmin]) 
                    i = 1
                end 
                tlow = Tmin[i]
                thigh = Tmax[i]

            elseif gvars[:temperature_record].Datatype == :Decadely
                if runningday>tmin_dataset[31].DayNr
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    (Tmin, Tmax), 
                                                    gvars[:temperature_record])
                end
                i = 1
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end 
                tlow = tmin_dataset[i].Param 
                thigh = tmax_dataset[i].Param 

            elseif gvars[:temperature_record].Datatype == :Monthly
                if runningday>tmin_dataset[31].DayNr
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                     (Tmin, Tmax), 
                                                     gvars[:temperature_record])
                end 
                i = 1 
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end
                tlow = tmin_dataset[i].Param 
                thigh = tmax_dataset[i].Param 
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
    elseif isfile(co2_file)
        co2from = undef_double
        co2to = undef_double
        open(co2_file, "r") do file
            readline(file)
            if !endswith(co2_file, ".csv")
                readline(file)
                readline(file)
            end
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
                        loop_1 = false
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
    # 1. Soil fertility
    setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 1.0)

    # 1.a Soil fertility (Coeffb0,Coeffb1,Coeffb2 : Biomass-Soil Fertility stress)
    if gvars[:crop].StressResponse.Calibrated
        stress_biomass_relationship!(outputs, gvars)
    else
        setparameter!(gvars[:float_parameters], :coeffb0, undef_double)
        setparameter!(gvars[:float_parameters], :coeffb1, undef_double)
        setparameter!(gvars[:float_parameters], :coeffb2, undef_double)
    end 

    # 1.b Soil fertility : FracBiomassPotSF
    if (abs(gvars[:management].FertilityStress) > eps()) & gvars[:crop].StressResponse.Calibrated 
        biolow = 100
        strlow = 0
        strtop = undef_int
        biotop = undef_int
        loopi = true
        while loopi
            biotop = biolow
            strtop = strlow
            biolow = biolow - 1
            strlow = gvars[:float_parameters][:coeffb0] + gvars[:float_parameters][:coeffb1]*biolow + gvars[:float_parameters][:coeffb2]*biolow*biolow
            if (strlow >= gvars[:management].FertilityStress) | (biolow <= 0) | (strlow >= 99.99)
                loopi = false
            end
        end
        if strlow >= 99.99 
            strlow = 100
        end 
        if abs(strlow-strtop) < 0.001 
            setparameter!(gvars[:float_parameters], :fracbiomasspotsf, biotop/100)
        else
            setparameter!(gvars[:float_parameters], :fracbiomasspotsf, (biotop - (gvars[:management].FertilityStress - strtop)/(strlow - strtop))/100)
        end 
    end 

    # 2. soil salinity (Coeffb0Salt,Coeffb1Salt,Coeffb2Salt : CCx/KsSto - Salt stress)
    if gvars[:simulation].SalinityConsidered == true
        ccx_salt_stress_relationship!(outputs, gvars)
    else
        setparameter!(gvars[:float_parameters], :coeffb0salt, undef_double)
        setparameter!(gvars[:float_parameters], :coeffb1salt, undef_double)
        setparameter!(gvars[:float_parameters], :coeffb2salt, undef_double)
    end

    return nothing
end 

"""
    stress_biomass_relationship!(outputs, gvars)

tempprocessing.f90:3067
"""
function stress_biomass_relationship!(outputs, gvars)
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    management = gvars[:management]
    co2given = gvars[:float_parameters][:co2i]

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

    stress_matrix = StressIndexesBio[StressIndexesBio() for _ in 1:8]

    # 1. initialize
    bnor100 = undef_double 
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
            tswitch, higclinear = get_day_switch_to_linear(refhi, ratedhidt, higc)
        else
            tswitch = round(Int, daysyieldformation/3)
        end 
    else
        daysyieldformation = undef_int
        tswitch = undef_int
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
        simulation.DelayedDays = 0 #note that we must do this before calling bnormalized
        bnor = bnormalized(outputs, thedaystoccini, thegddaystoccini,
                l0, l12, l12sf, l123, l1234, lflor,
                gddl0, gddl12, gddl12sf, gddl123, gddl1234, wpyield, 
                daysyieldformation, tswitch, cco, ccx, cgc, gddcgc, cdc,
                gddcdc, kctop, kcdeclageing, cceffectprocent, wpveg, co2given,
                tbase, tupper, tdaymin, tdaymax, gdtransplow, ratdgdd,
                sumkctop, sipr, stress_response.RedCGC, stress_response.RedCCX,
                stress_response.RedWP, stress_response.RedKsSto, 0, 0,
                stress_response.CDecline, -0.01, themodecycle, true,
                simulation, simulparam, management, crop)
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
    end 
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
        b2 = undef_double #real(undef_int, kind=dp)
        b1 = undef_double #real(undef_int, kind=dp)
        b0 = undef_double #real(undef_int, kind=dp)
    end 
    
    setparameter!(gvars[:float_parameters], :coeffb0, b0)
    setparameter!(gvars[:float_parameters], :coeffb1, b1)
    setparameter!(gvars[:float_parameters], :coeffb2, b2)

    return nothing
end 

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
    etostandard = 5

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
    # MARK
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
            cci = 0
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
                cc = cc_at_time((t-l0), cco, ((1-sfredcgc/100)*cgc),
                              ((1-sfredccx/100)*ccx))
            else
               # Late-season stage  (t <= LMaturity)
                if ccx < 0.001 
                    cc = 0
                else
                    ccxadj = cc_at_time((l123-l0), cco, 
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
                cc = cc_at_gdd((sumgdd-gddl0), cco, ((1-sfredcgc/100)*gddcgc), 
                  ((1-sfredccx/100)*ccx))
            else
                # late-season stage  (sumgdd <= gddlmaturity)
                if ccx < 0.001
                    cc = 0
                else
                    ccxadj = cc_at_gdd((gddl123-gddl0), cco, ((1-sfredcgc/100)*gddcgc), 
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
    cci = cc_at_gdd(gddi, ccoin, gddcgcin, ccxin)

global.f90:2654
"""
function cc_at_gdd(gddi, ccoin, gddcgcin, ccxin)
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
            epotmin = simulparam.KcWetBare * (1 - 1.72*ccx + 1*(ccx*ccx) - 0.30*(ccx*ccx*ccx)) * etoval
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
        if t0 < t1 
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
    tswitch, higclinear = get_day_switch_to_linear(himax, dhidt, higc)

global.f90:2988
"""
function get_day_switch_to_linear(himax, dhidt, higc)
    hio = 1
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
    sumbnor = bnormalized(outputs, thedaystoccini, thegddaystoccini,
            l0, l12, l12sf, l123, l1234, lflor, 
            gddl0, gddl12, gddl12sf, gddl123, gddl1234, 
            wpyield, daysyieldformation, tswitch, cco, ccx, 
            cgc, gddcgc, cdc, gddcdc, kctop, kcdeclageing, 
            cceffectprocent, wpbio, theco2, tbase, tupper, 
            tdaymin, tdaymax, gdtransplow, ratdgdd, sumkctop, 
            stressinpercent, strresredcgc, strresredccx, strresredwp, 
            strresredkssto, weedstress, deltaweedstress, strrescdecline, 
            shapefweed, themodecycle, fertilitystresson,
            simulation, simulparam, management, crop)

tempprocessing.f90:2586
note that we must do simulation.DelayedDays = 0 before calling this function
"""
function bnormalized(outputs, thedaystoccini, thegddaystoccini,
            l0, l12, l12sf, l123, l1234, lflor, 
            gddl0, gddl12, gddl12sf, gddl123, gddl1234, 
            wpyield, daysyieldformation, tswitch, cco, ccx, 
            cgc, gddcgc, cdc, gddcdc, kctop, kcdeclageing, 
            cceffectprocent, wpbio, theco2, tbase, tupper, 
            tdaymin, tdaymax, gdtransplow, ratdgdd, sumkctop, 
            stressinpercent, strresredcgc, strresredccx, strresredwp, 
            strresredkssto, weedstress, deltaweedstress, strrescdecline, 
            shapefweed, themodecycle, fertilitystresson,
            simulation, simulparam, management, crop)
    
    etostandard = 5
    k = 2

    # 1. Adjustment for weed infestation
    if weedstress > 0 
        if stressinpercent > 0  # soil fertility stress
            fweed = 1  # no expansion of canopy cover possible
        else
            fweed = cc_multiplier_weed(weedstress, ccx, shapefweed)
        end 
        ccoadj = cco*fweed
        ccxadj = ccx*fweed
        cdcadj = cdc*(fweed*ccx + 2.29)/(ccx + 2.29)
        gddcdcadj = gddcdc*(fweed*ccx + 2.29)/(ccx + 2.29)
    else
        ccoadj = cco
        ccxadj = ccx
        cdcadj = cdc
        gddcdcadj = gddcdc
    end 

    # 2. Open Temperature file
    loggi = (length(outputs[:tcropsim][:tlow]) > 0) 

    # 3. Initialize
    sumkctopsf = (1 - stressinpercent/100) * sumkctop
    # only required for soil fertility stress

    sumkci = 0
    sumbnor = 0
    sumgddforplot = undef_int
    sumgdd = undef_int
    sumgddfromday1 = 0
    growthon = false
    gddtadj = undef_int
    dayfraction = undef_int
    gddayfraction = undef_int
    ccxwitheredforb = 0

    # 4. Initialise 1st day
    if thedaystoccini != 0 
        # regrowth which starts on 1st day
        growthon = true
        if thedaystoccini == undef_int 
            # ccx on 1st day
            tadj = l12 - l0
            if themodecycle == :gddays 
                gddtadj = gddl12 - gddl0
                sumgdd = gddl12
            end 
            ccinitial = ccxadj * (1-strresredccx/100)
        else
            # cc on 1st day is < ccx
            tadj = thedaystoccini
            daycc = tadj + l0
            if themodecycle == :GDDays 
                gddtadj = thegddaystoccini
                sumgdd = gddl0 + thegddaystoccini
                sumgddforplot = sumgdd
            end 
            ccinitial = canopy_cover_no_stress_sf(daycc, l0, l123, l1234,
                            gddl0, gddl123, gddl1234, ccoadj, ccxadj, cgc, cdcadj,
                            gddcgc, gddcdcadj, sumgddforplot, themodecycle, 
                            strresredcgc, strresredccx, simulation)
        end 
        # Time reduction for days between L12 and L123
        dayfraction = (l123-l12) * 1/(tadj + l0 + (l123-l12))
        if themodecycle == :GDDays 
            gddayfraction = (gddl123-gddl12) * 1/(gddtadj + gddl0 + (gddl123-gddl12))
        end 
    else
        # growth starts after germination/recover
        tadj = 0
        if themodecycle == :GDDays 
            gddtadj = 0
            sumgdd = 0
        end 
        ccinitial = ccoadj
    end 

    # 5. Calculate Bnormalized
    # MARK
    for dayi in 1:l1234
        # 5.1 growing degrees for dayi
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

        # 5.2 green Canopy Cover (CC)
        daycc = dayi
        if growthon == false 
            # not yet canopy development
            cci = 0
            if thedaystoccini != 0 
                # regrowth
                cci = ccinitial
                growthon = true
            else
                # sowing or transplanting
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
                         daycc = l12 + round(Int, dayfraction * (dayi+tadj+l0 - l12)) # slow down
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
                        sumgddforplot = gddl1234
                        # special case where l123 > l1234
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
            cci = cci_no_water_stress_sf(daycc, l0, l12sf, l123, l1234,
                        gddl0, gddl12sf, gddl123, gddl1234,
                        ccoadj, ccxadj, cgc, gddcgc, cdcadj, gddcdcadj, 
                        sumgddforplot, ratdgdd,
                        strresredcgc, strresredccx, strrescdecline,
                        themodecycle, simulation)
        end 


        if cci > ccxwitheredforb 
            ccxwitheredforb = cci
        end
        if daycc >= l12sf 
            ccxwitheredforb = ccxadj*(1-strresredccx/100)
        end 
        ccw = cci

        if cci > 0.0001 
            # 5.3 potential transpiration of total canopy cover (crop and weed)
            tpotforb, epottotforb =  calculate_etpot(daycc, l0, l12, l123, l1234, 0, cci, 
                        etostandard, kctop, kcdeclageing,
                        ccxadj, ccxwitheredforb, cceffectprocent, theco2,
                        gddi, gdtransplow, simulation, simulparam)

            # 5.4 Sum of Kc (only required for soil fertility stress)
            sumkci = sumkci + (tpotforb/etostandard)

            # 5.5 potential transpiration of crop canopy cover (without weed)
            if weedstress > 0 
                # green canopy cover of the crop (CCw) in weed-infested field
                # (CCi is CC of crop and weeds)
                fccx = 1 # only for non perennials (no self-thinning)
                if deltaweedstress != 0 
                    deltaweedstress_local = deltaweedstress
                    weedcorrection, deltaweedstress_local = get_weed_rc(daycc, sumgddforplot, fccx,
                        weedstress, management.WeedAdj,
                        deltaweedstress_local, l12sf, l123, 
                        gddl12sf, gddl123, themodecycle)
                else
                    weedcorrection = weedstress
                end 
                ccw = cci * (1 - weedcorrection/100)
                # correction for micro-advection
                cctotstar = 1.72*cci - 1*(cci*cci) + 0.30*(cci*cci*cci)
                if cctotstar < 0
                    cctotstar = 0
                end 
                if cctotstar > 1 
                    cctotstar = 1
                end 
                if ccw > 0.0001 
                    ccwstar = ccw + (cctotstar - cci)
                else
                    ccwstar = 0
                end 
                # crop transpiration in weed-infested field
                if cctotstar <= 0.0001 
                    tpotforb = 0
                else
                    tpotforb = tpotforb * (ccwstar/cctotstar)
                end 
            end 
        else
            tpotforb = 0
        end 

        # 5.6 biomass water productivity (WP)
        wpi = wpbio # vegetative stage
        # 5.6a. vegetative versus yield formation stage
        if ((crop.subkind == :Tuber) | (crop.subkind == :Grain)) & (wpyield < 100) & (dayi > lflor) 
            # yield formation stage
            fswitch = 1
            if (daysyieldformation > 0) & (tswitch > 0) 
                fswitch = (dayi-lflor) * 1/tswitch
                if fswitch > 1
                    fswitch = 1
                end 
            end 
            wpi = wpi * (1 - (1 - wpyield/100)*fswitch)
        end 

        # 5.7 Biomass (B)
        if fertilitystresson 
            # 5.7a - reduction for soil fertiltiy
            if (strresredwp > 0) & (sumkci > 0) & (sumkctopsf > eps()) 
                if sumkci < sumkctopsf
                    if sumkci > 0 
                        wpi = wpi * (1 - (strresredwp/100) * exp(k*log(sumkci/sumkctopsf)))
                    end 
                else
                    wpi = wpi * (1 - strresredwp/100)
                end 
            end 
            # 5.7b - Biomass (B)
            sumbnor = sumbnor +  wpi * (tpotforb/etostandard)
        else
            sumbnor = sumbnor +  wpi * (1 - strresredkssto/100) * (tpotforb/etostandard) # for salinity stress
        end 
    end

    # 5. Export
    return sumbnor
end 

"""
    fweed = cc_multiplier_weed(procentweedcover, ccxcrop, fshapeweed)

global.f90:2180
"""
function cc_multiplier_weed(procentweedcover, ccxcrop, fshapeweed)
    if (procentweedcover > 0) & (ccxcrop < 0.9999) & (ccxcrop > 0.001) 
        if procentweedcover == 100 
            fweed = 1/ccxcrop
        else
            fweed = 1 - (1 - 1/ccxcrop) * (exp(fshapeweed*procentweedcover/100) - 1)/(exp(fshapeweed) - 1)
            if fweed > (1/ccxcrop) 
                fweed = 1/ccxcrop
            end 
        end 
    else
        fweed = 1
    end 

    return fweed
end

"""
    cci = cci_no_water_stress_sf(dayi, l0, l12sf, l123, l1234, gddl0,
                    gddl12sf, gddl123, gddl1234, cco, ccx, cgc, gddcgc, cdc, gddcdc, sumgdd,
                    ratdgdd, sfredcgc, sfredccx, sfcdecline, themodecycle, simulation)

global.f90:1391
"""
function cci_no_water_stress_sf(dayi, l0, l12sf, l123, l1234, gddl0,
    gddl12sf, gddl123, gddl1234, cco, ccx, cgc, gddcgc, cdc, gddcdc, sumgdd,
    ratdgdd, sfredcgc, sfredccx, sfcdecline, themodecycle, simulation)
    
    # Calculate CCi
    cci = canopy_cover_no_stress_sf(dayi, l0, l123, l1234, gddl0, gddl123,
                                gddl1234, cco, ccx, cgc, cdc, gddcgc,
                                gddcdc, sumgdd, themodecycle, sfredcgc,
                                sfredccx, simulation)

    # Consider CDecline for limited soil fertiltiy
    # IF ((Dayi > L12SF) AND (SFCDecline > 0.000001))
    if (dayi > l12sf) & (sfcdecline > 0.000001) & (l12sf < l123) 
        if dayi < l123
            if themodecycle == :CalendarDays 
                cci = cci - (sfcdecline/100) * exp(2*log(dayi-l12sf))/(l123-l12sf)
            else
                if (sumgdd > gddl12sf) & (gddl123 > gddl12sf) 
                    cci = cci - (ratdgdd*sfcdecline/100) * exp(2*log(sumgdd-gddl12sf)) / (gddl123-gddl12sf)
                end
            end 
            if cci < 0 
                cci = 0
            end 
        else
            if themodecycle == :CalendarDays 
                cci = cc_at_time((l123-l0), cco, (cgc*(1-sfredcgc/100)), ((1-sfredccx/100)*ccx))
                # ccibis is cc in late season when canopy decline continues
                ccibis = cci  - (sfcdecline/100) * (exp(2*log(dayi-l12sf)) / (l123-l12sf))
                if ccibis < 0
                    cci = 0
                else
                    cci = cci  - ((sfcdecline/100) * (l123-l12sf))
                end 
                if cci < 0.001
                    cci = 0
                else
                    # is ccx at start of late season, adjusted for canopy
                    # decline with soil fertility stress
                    ccxadj = cci
                    cdcadj = cdc * (ccxadj + 2.29)/(ccx + 2.29)
                    if dayi < (l123 + length_canopy_decline(ccxadj, cdcadj)) 
                        cci = ccxadj * (1-0.05*(exp((dayi-l123)*3.33*cdcadj/(ccxadj+2.29))-1))
                        if ccibis < cci 
                            cci = ccibis # accept smallest canopy cover
                        end
                    else
                        cci = 0
                    end
                end 
            else
                cci = cc_at_time((gddl123-gddl0), cco, (gddcgc*(1-sfredcgc/100)), ((1-sfredccx/100)*ccx))
                # ccibis is cc in late season when canopy decline continues
                if (sumgdd > gddl12sf) & (gddl123 > gddl12sf) 
                    ccibis = cci  - (ratdgdd*sfcdecline/100) * (exp(2*log(sumgdd-gddl12sf))/(gddl123-gddl12sf))
                else
                    ccibis = cci
                end
                if ccibis < 0
                    cci = 0
                else
                    cci = cci - ((ratdgdd*sfcdecline/100) * (gddl123-gddl12sf))
                end 
                if cci < 0.001
                    cci = 0
                else
                    # is ccx at start of late season, adjusted for canopy
                    # decline with soil fertility stress
                    ccxadj = cci
                    gddcdcadj = gddcdc * (ccxadj + 2.29)/(ccx + 2.29)
                    if sumgdd < (gddl123 + length_canopy_decline(ccxadj, gddcdcadj)) 
                        cci = ccxadj * (1 - 0.05*(exp((sumgdd-gddl123)*3.33*gddcdcadj/(ccxadj+2.29))-1))
                        if ccibis < cci
                            cci = ccibis # accept smallest canopy cover
                        end 
                    else
                        cci = 0
                    end 
                end 
            end 
            if cci < 0
                cci = 0
            end 
        end 
    end 

    return cci
end 

"""
    cci = cc_at_time(dayi, ccoin, cgcin, ccxin)

global.f90:2371
"""
function cc_at_time(dayi, ccoin, cgcin, ccxin)
    cci = ccoin * exp(cgcin * dayi)
    if cci > ccxin/2 
        cci = ccxin - 0.25 * (ccxin/ccoin) * ccxin * exp(-cgcin*dayi)
    end 
    return cci
end

"""
    weedrcdaycalc, tempweeddeltarc = get_weed_rc(theday, gddayi, fccx, tempweedrcinput, tempweedadj,
                            tempweeddeltarc, l12sf, templ123, gddl12sf, 
                            tempgddl123, themodecycle)

global.f90:1567
"""
function get_weed_rc(theday, gddayi, fccx, tempweedrcinput, tempweedadj,
                            tempweeddeltarc, l12sf, templ123, gddl12sf, 
                            tempgddl123, themodecycle)

    weedrcdaycalc = tempweedrcinput

    if (tempweedrcinput > 0) & (tempweeddeltarc != 0) 
        # daily RC when increase/decline of RC in season (i.e. TempWeedDeltaRC <> 0)
        # adjust the slope of increase/decline of RC in case of self-thinning (i.e. fCCx < 1)
        if (tempweeddeltarc != 0) & (fccx < 0.999) 
            # only when self-thinning and there is increase/decline of RC
            if fccx < 0.005
                tempweeddeltarc = 0
            else
                tempweeddeltarc = round(Int, tempweeddeltarc * exp(log(fccx) * (1+tempweedadj/100)))
            end 
        end 

        # calculate WeedRCDay by considering (adjusted) decline/increase of RC
        if themodecycle == :CalendarDays 
            if theday > l12sf 
                if theday >= templ123 
                    weedrcdaycalc = tempweedrcinput * (1 + tempweeddeltarc/100)
                else
                    weedrcdaycalc = tempweedrcinput * (1 + (tempweeddeltarc/100) * (theday-l12sf) / (templ123-l12sf))
                end 
            end 
        else
            if gddayi > gddl12sf 
                if gddayi > tempgddl123 
                    weedrcdaycalc = tempweedrcinput * (1 + tempweeddeltarc/100)
                else
                    weedrcdaycalc = tempweedrcinput * (1 + (tempweeddeltarc/100) * (gddayi-gddl12sf) / (tempgddl123-gddl12sf))
                end 
            end 
        end 

        # fine-tuning for over- or undershooting in case of self-thinning
        if fccx < 0.999 
            # only for self-thinning
            if (fccx < 1) & (fccx > 0) & (weedrcdaycalc > 98) 
                weedrcdaycalc = 98
            end 
            if weedrcdaycalc < 0 
                weedrcdaycalc = 0
            end 
            if fccx <= 0 
                weedrcdaycalc = 100
            end 
        end 
    end 

    return weedrcdaycalc
end

"""

    ccx_salt_stress_relationship!(outputs, gvars)

tempprocessing.f90:3277
"""
function ccx_salt_stress_relationship!(outputs, gvars)

    crop = gvars[:crop]
    simulation = gvars[:simulation]
    simulparam = gvars[:simulparam]
    management = gvars[:management]
    co2given = gvars[:float_parameters][:co2i]

    thedaystoccini = crop.DaysToCCini
    thegddaystoccini = crop.GDDaysToCCini
    l0 = crop.DaysToGermination
    l12 = crop.DaysToFullCanopy
    l123 = crop.DaysToSenescence
    l1234 = crop.DaysToHarvest
    lflor = crop.DaysToFlowering
    lengthflor = crop.LengthFlowering
    gddflor = crop.GDDaysToFlowering
    gddlengthflor = crop.GDDLengthFlowering
    gddl0 = crop.GDDaysToGermination
    gddl12 = crop.GDDaysToFullCanopy
    gddl123 = crop.GDDaysToSenescence
    gddl1234 = crop.GDDaysToHarvest
    wpyield = crop.WPy
    refhi = crop.HI
    cco = crop.CCo
    ccx = crop.CCx
    cgc = crop.CGC
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
    gdbiolow = crop.GDtranspLow
    wpveg = crop.WP
    ratedhidt = crop.dHIdt
    cropdnr1 = crop.Day1
    cropdeterm = crop.DeterminancyLinked
    thecroptype = crop.subkind
    themodecycle = crop.ModeCycle
    theccsaltdistortion = crop.CCsaltDistortion

    stress_matrix = StressIndexesSalt[StressIndexesSalt() for _ in 1:10]

    # 1. initialize
    gddl12ss = gddl12 # to calculate sumkctop (no stress)
    bnor100 = undef_double 
    # Maximum sum Kc (no stress)
    simulation.DelayedDays = 0 #note that we need to do this before calling seasonal_sum_of_kcpot
    sumkctop = seasonal_sum_of_kcpot(outputs, thedaystoccini, thegddaystoccini,
                    l0, l12, l123, l1234, gddl0, gddl12, gddl123, gddl1234,
                    cco, ccx, cgc, gddcgc, cdc, gddcdc, kctop, kcdeclageing, 
                    cceffectprocent,tbase, tupper, tdaymin, tdaymax, gdbiolow, 
                    co2given, themodecycle, simulation, simulparam)
    # Get PercentLagPhase (for estimate WPi during yield formation)
    if (thecroptype == :Tuber) | (thecroptype == :Grain) 
        # DaysToFlowering corresponds with Tuberformation
        daysyieldformation = round(Int, refhi/ratedhidt)
        if cropdeterm
            higc = harvest_index_growth_coefficient(refhi, ratedhidt)
            tswitch, higclinear = get_day_switch_to_linear(refhi, ratedhidt, higc)
        else
            tswitch = round(Int, daysyieldformation/3)
        end 
    else
        daysyieldformation = undef_int
        tswitch = undef_int
    end 

    # 2. Biomass production (or Salt stress) for various CCx reductions
    for si in 1:10
        # various CCx reduction
        # CCx reduction
        sipr = 10*(si-1)
        stress_matrix[si].CCxReduction = sipr
        # adjustment CC
        stress_response = crop_stress_parameters_soil_salinity(sipr, theccsaltdistortion, 
            cco, ccx, cgc, gddcgc, cropdeterm, l12, lflor, lengthflor, l123,
            gddl12, gddflor, gddlengthflor, gddl123, themodecycle)
        # adjusted length of Max canopy cover
        ratdgdd = 1
        if (stress_response.RedCCX == 0) & (stress_response.RedCGC == 0) 
            l12ss = l12
            gddl12ss = gddl12
        else
            cctoreach = 0.98*(1-stress_response.RedCCX/100)*ccx
            l12ss = days_to_reach_cc_with_given_cgc(cctoreach, cco, 
                 (1-stress_response.RedCCX/100)*ccx,
                 cgc*(1-stress_response.RedCGC/100), l0)
            if themodecycle == :GDDays
                tdaymax_temp = tdaymax
                tdaymin_temp = tdaymin
                gddl12ss = growing_degree_days(l12ss, cropdnr1, tbase, 
                           tupper, gvars, tdaymin_temp, tdaymax_temp)
            end 
            if (themodecycle == :GDDays) & (gddl12ss < gddl123) 
                ratdgdd = (l123-l12ss)*1/(gddl123-gddl12ss)
            end 
        end 

        # biomass production
        simulation.DelayedDays = 0 #note that we must do this before calling bnormalized
        bnor = bnormalized(outputs, thedaystoccini, thegddaystoccini,
                l0, l12, l12ss, l123, l1234, lflor,
                gddl0, gddl12, gddl12ss, gddl123, gddl1234,
                wpyield, daysyieldformation, tswitch,
                cco, ccx, cgc, gddcgc, cdc, gddcdc,
                kctop, kcdeclageing, cceffectprocent, wpveg, co2given,
                tbase, tupper, tdaymin, tdaymax, gdbiolow, ratdgdd, sumkctop,
                sipr, stress_response.RedCGC, stress_response.RedCCX,
                stress_response.RedWP, stress_response.RedKsSto, 
                0, 0, stress_response.CDecline, -0.01,
                themodecycle, false, 
                simulation, simulparam, management, crop)
        if si == 1 
            bnor100 = bnor
            biomproc = 100
            stress_matrix[1].SaltProc = 0
        else
            if bnor100 > 0.00001 
                biomproc = 100 * bnor/bnor100
                stress_matrix[si].SaltProc = 100 - biomproc
            else
                stress_matrix[si].SaltProc = 0
            end 
        end 
        stress_matrix[si].SaltSquare = stress_matrix[si].SaltProc^2
        # end stress level
    end 

    # 3. CCx - Salt stress relationship
    yavg = 0
    x1avg = 0
    x2avg = 0
    for si in 1:10
        # various CCx reduction
        yavg += stress_matrix[si].CCxReduction
        x1avg += stress_matrix[si].SaltProc
        x2avg += stress_matrix[si].SaltSquare
    end 
    yavg  = yavg/10
    x1avg = x1avg/10
    x2avg = x2avg/10
    sumx1y  = 0
    sumx2y  = 0
    sumx1sq = 0
    sumx2sq = 0
    sumx1x2 = 0
    for si in 1:10
        # various CCx reduction
        y     = stress_matrix[si].CCxReduction - yavg
        x1    = stress_matrix[si].SaltProc - x1avg
        x2    = stress_matrix[si].SaltSquare - x2avg
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
        coeffb2salt = (sumx1y - (sumx2y * sumx1sq)/sumx1x2)/(sumx1x2 - (sumx1sq * sumx2sq)/sumx1x2)
        coeffb1salt = (sumx1y - coeffb2salt * sumx1x2)/sumx1sq
        coeffb0salt = yavg - coeffb1salt*x1avg - coeffb2salt*x2avg

        salt10 =  stress_matrix[2].SaltProc
        salt20 =  stress_matrix[3].SaltProc
        salt30 =  stress_matrix[4].SaltProc
        salt40 =  stress_matrix[5].SaltProc
        salt50 =  stress_matrix[5].SaltProc
        salt60 =  stress_matrix[7].SaltProc
        salt70 =  stress_matrix[8].SaltProc
        salt80 =  stress_matrix[9].SaltProc
        salt90 =  stress_matrix[10].SaltProc
    else
        coeffb2salt = undef_double #real(undef_int, kind=dp)
        coeffb1salt = undef_double #real(undef_int, kind=dp)
        coeffb0salt = undef_double #real(undef_int, kind=dp)
    end 
    setparameter!(gvars[:float_parameters], :coeffb0salt, coeffb0salt)
    setparameter!(gvars[:float_parameters], :coeffb1salt, coeffb1salt)
    setparameter!(gvars[:float_parameters], :coeffb2salt, coeffb2salt)

    return nothing
end 

"""
    stress_response = crop_stress_parameters_soil_salinity(ccxred, ccdistortion, 
             cco, ccx, cgc, gddcgc, cropdeterm, l12, lflor, 
             lengthflor, l123, gddl12, gddlflor, gddlengthflor, 
             gddl123, themodecycle)

tempprocessing.f90:1643
"""
function crop_stress_parameters_soil_salinity(ccxred, ccdistortion, 
             cco, ccx, cgc, gddcgc, cropdeterm, l12, lflor, 
             lengthflor, l123, gddl12, gddlflor, gddlengthflor, 
             gddl123, themodecycle)
    # initialize
    stress_response = RepEffectStress()
    stress_response.RedCCX = ccxred
    stress_response.RedWP = 0
    l12double = l12
    l12ssmax = l12
    gddl12double = gddl12

    # CGC reduction
    cctoreach = 0.98 * ccx
    if (cco > cctoreach) | (cco >= ccx) | (ccxred == 0) 
        stress_response.RedCGC = 0
    else
        stress_response.RedCGC = undef_int
        # reference for no salinity stress
        if themodecycle == :CalendarDays 
            l12double = log((0.25*ccx*ccx/cco)/(ccx-cctoreach))/cgc
            if l12double <= eps() 
                stress_response.RedCGC = 0
            end 
        else
            gddl12double = log((0.25*ccx*ccx/cco)/(ccx-cctoreach))/gddcgc
            if gddl12double <= eps() 
                stress_response.RedCGC = 0
            end 
        end 
        # with salinity stress
        ccxadj = 0.90 * ccx * (1 - ccxred/100)
        cctoreach = 0.98 * ccxadj
        if (stress_response.RedCGC != 0) & ((ccxadj-cctoreach) >= 0.0001) 
            if themodecycle == :CalendarDays
                cgcadjmax = log((0.25*ccxadj*ccxadj/cco)/(ccxadj-cctoreach))/l12double
                l12ssmax = l12 + (l123 - l12)/2
                if cropdeterm & (l12ssmax > (lflor + round(Int, lengthflor/2))) 
                    l12ssmax = lflor + round(Int, lengthflor/2)
                end 
                if l12ssmax > l12double 
                    cgcadjmin = log((0.25*ccxadj*ccxadj/cco)/(ccxadj-cctoreach))/l12ssmax
                else
                    cgcadjmin = cgcadjmax
                end 
                if ccxred < 10  # smooth start required
                    cgcadj = cgcadjmax - (cgcadjmax-cgcadjmin)*(exp(ccxred*log(1.5))/exp(10*log(1.5)))*(ccdistortion/100)
                else
                    cgcadj = cgcadjmax - (cgcadjmax-cgcadjmin)*(ccdistortion/100)
                end 
                stress_response.RedCGC = round(Int, 100*(cgc-cgcadj)/cgc)
            else
                gddcgcadjmax = log((0.25*ccxadj*ccxadj/cco)/(ccxadj-cctoreach))/gddl12double
                gddl12ssmax = gddl12 + (gddl123 - gddl12)/2
                if cropdeterm & (gddl12ssmax > (gddlflor + round(Int, lengthflor/2))) 
                    gddl12ssmax = gddlflor + round(Int, gddlengthflor/2)
                end 
                if gddl12ssmax > gddl12double 
                    gddcgcadjmin = log((0.25*ccxadj*ccxadj/cco)/(ccxadj-cctoreach))/gddl12ssmax
                else
                    gddcgcadjmin = gddcgcadjmax
                end 
                if ccxred < 10  # smooth start required
                    gddcgcadj = gddcgcadjmax - (gddcgcadjmax-gddcgcadjmin)*(exp(ccxred)/exp(10))*(ccdistortion/100)
                else
                    gddcgcadj = gddcgcadjmax - (gddcgcadjmax-gddcgcadjmin)*(ccdistortion/100)
                end 
                stress_response.RedCGC = round(Int, 100*(gddcgc-gddcgcadj)/gddcgc)
           end 
        else
            stress_response.RedCGC = 0
        end 
    end 

    # Canopy decline
    if ccxred == 0 
        stress_response.CDecline = 0
    else
        ccxadj = 0.98*ccx*(1 - ccxred/100)
        l12ss = l12ssmax - (l12ssmax-l12double) * (ccdistortion/100)
        if (l123 > l12ss) & (ccdistortion > 0) 
            if ccxred < 10  # smooth start required
                ccxfinal = ccxadj - (exp(ccxred*log(1.5))/exp(10*log(1.5)))*(0.5*ccdistortion/100)*(ccxadj - cco)
            else
                ccxfinal = ccxadj - (0.5*ccdistortion/100)*(ccxadj - cco)
            end 
            if ccxfinal < cco 
                ccxfinal = cco
            end 
            stress_response.CDecline = 100*(ccxadj - ccxfinal)/(l123 - l12ss)
            if stress_response.CDecline > 1
                stress_response.CDecline = 1
            end 
            if stress_response.CDecline <= eps() 
                stress_response.CDecline = 0.001
            end 
        else
            stress_response.CDecline = 0.001 # no shift of maturity
        end 
    end 

    # Stomata closure
    stress_response.RedKsSto = ccxred

    return stress_response
end 

"""
    fccx = multiplier_ccx_self_thinning(yeari, yearx, shapefactor)

global.f90:1784
"""
function multiplier_ccx_self_thinning(yeari, yearx, shapefactor)
    fccx = 1
    if (yeari >= 2) & (yearx >= 2) & (round(Int, 100*shapefactor) != 0) 
        year0 = 1 + (yearx-1) * exp(shapefactor*log(10))
        if yeari >= year0
            fccx = 0
        else
            fccx = 0.9 + 0.1 * (1 - exp((1/shapefactor)*log((yeari-1)/(yearx-1))))
        end 
        if fccx < 0 
            fccx = 0
        end 
    end 
    return fccx
end

"""
    fweedi, rcadj = cc_multiplier_weed_adjusted(procentweedcover, ccxcrop, fshapeweed, fccx, yeari, mweedadj, cropsubkind)

global.f90:2204
"""
function cc_multiplier_weed_adjusted(procentweedcover, ccxcrop, fshapeweed, fccx, yeari, mweedadj, cropsubkind)
    fweedi = 1
    rcadj = procentweedcover
    if procentweedcover > 0 
        fweedi = cc_multiplier_weed(procentweedcover, ccxcrop, fshapeweed)
        # FOR perennials when self-thinning
        if (cropsubkind == :Forage) & (yeari > 1) & (fccx < 0.995) 
            # need for adjustment
            # step 1 - adjusment of shape factor to degree of crop replacement by weeds
            fshapeminimum = 10 - 20*( (exp(fccx*3)-1)/(exp(3)-1) + sqrt(mweedadj/100))
            if round(Int, fshapeminimum*10) == 0 
                fshapeminimum = 0.1
            end 
            fshapeweed = fshapeweed;
            if fshapeweed < fshapeminimum 
                fshapeweed = fshapeminimum
            end 

            # step 2 - Estimate of CCxTot
            # A. Total CC (crop and weeds) when self-thinning and 100% weed take over
            fweedi = cc_multiplier_weed(procentweedcover, ccxcrop, fshapeweed)
            ccxtot100 = fweedi * ccxcrop
            # B. Total CC (crop and weeds) when self-thinning and 0% weed take over
            if fccx > 0.005
                fweedi = cc_multiplier_weed(round(Int, fccx*procentweedcover), (fccx*ccxcrop), fshapeweed)
            else
                fweedi = 1
            end 
            ccxtot0 = fweedi * (fccx*ccxcrop)
            # C. total CC (crop and weeds) with specified weed take over (MWeedAdj)
            ccxtotm = ccxtot0 + (ccxtot100 - ccxtot0)* mweedadj/100
            if ccxtotm < (fccx*ccxcrop*(1-procentweedcover/100)) 
                ccxtotm = fccx*ccxcrop*(1-procentweedcover/100)
            end 
            if fccx > 0.005 
                fweedi = ccxtotm/(fccx*ccxcrop)
                fweedmax = 1/(fccx*ccxcrop)
                if round(Int, fweedi*1000) > round(Int, fweedmax*1000) 
                    fweedi = fweedmax
                end 
            end

            # step 3 - Estimate of adjusted weed cover
            rcadjd = procentweedcover + (1-fccx)*ccxcrop*mweedadj
            if fccx > 0.005
                if rcadjd < (100*(ccxtotm - fccx*ccxcrop)/ccxtotm)
                    rcadjd = 100*(ccxtotm - fccx*ccxcrop)/ccxtotm
                end 
                if rcadjd > (100 * (1- (fccx*ccxcrop*(1-procentweedcover/100)/ccxtotm))) 
                    rcadjd = 100*(1- fccx*ccxcrop*(1-procentweedcover/100)/ccxtotm)
                end 
            end 
            rcadj = round(Int, rcadjd)
            if rcadj > 100
                rcadj = 100
            end
        end 
    end 

    return fweedi, rcadj
end 

"""
    fcco = multiplier_cco_self_thinning(yeari, yearx, shapefactor)

global.f90:2588
"""
function multiplier_cco_self_thinning(yeari, yearx, shapefactor)
    fcco = 1
    if (yeari >= 1) & (yearx >= 2) & (round(Int, 100*shapefactor) != 0) 
        year0 = 1 + (yearx-1) * exp(shapefactor*log(10))
        if (yeari >= year0) | (year0 <= 1)
            fcco = 0
        else
            fcco = 1 - (yeari-1)/(year0-1)
        end 
        if fcco < 0
            fcco = 0
        end 
    end 
    return fcco
end
