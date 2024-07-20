"""
    initialize_climate!(outputs, gvars; kwargs...)

run.f90:5006
"""
function initialize_climate!(outputs, gvars; kwargs...)
    # Creates the Climate SIM files and reads climate of first day
    # but in julia we save that things in outputs variable

    # 10. Climate
    # create climate files
    create_daily_climfiles!(outputs, gvars; kwargs...)
    # climatic data for first day
    open_climfiles_and_get_data_firstday!(outputs, gvars; kwargs...)
end 

"""
    create_daily_climfiles(outputs, gvars; kwargs...)

run.f90:5592
"""
function create_daily_climfiles!(outputs, gvars; kwargs...)
    simulation = gvars[:simulation]
    eto_record = gvars[:eto_record]
    rain_record = gvars[:rain_record]
    temperature_record = gvars[:temperature_record]

    Tmin = gvars[:array_parameters][:Tmin]
    Tmax = gvars[:array_parameters][:Tmax]
    ETo = gvars[:array_parameters][:ETo]
    Rain = gvars[:array_parameters][:Rain]

    fromsimday = simulation.FromDayNr
    tosimday = simulation.ToDayNr

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    eto_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    rain_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    # note that we setparameter in the next function

    # 1. ETo file
    if gvars[:bool_parameters][:eto_file_exists]
        if eto_record.DataType == :Daily
            i = fromsimday - eto_record.FromDayNr + 1
            eto = ETo[i]

        elseif eto_record.DataType == :Decadely
            get_decade_eto_dataset!(eto_dataset, fromsimday, ETo, eto_record)
            i = 1
            while eto_dataset[i].DayNr != fromsimday
                i = i+1
            end
            eto = eto_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :eto, eto)

        elseif eto_record.DataType == :Monthly
            get_monthly_eto_dataset!(eto_dataset, fromsimday, ETo, eto_record)
            i = 1
            while eto_dataset[i].DayNr != fromsimday
                i = i+1
            end
            eto = eto_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :eto, eto)

        end 

        # we do no create EToData.SIM but we use outputs variable
        add_output_in_etodatasim!(outputs, eto)

        # next days of simulation period
        for runningday in (fromsimday + 1):tosimday
            if eto_record.DataType == :Daily
                i += 1
                if i==length(ETo)
                    i = 1
                end
                eto = ETo[i]

            elseif eto_record.DataType == :Decadely
                if runningday>eto_dataset[31].DayNr
                    get_decade_eto_dataset!(eto_dataset, runningday,
                                            ETo, 
                                            eto_record) 
                end
                i = 1
                while eto_dataset[1].DayNr != runningday
                    i += 1
                end 
                eto = eto_dataset[i].Param 

            elseif eto_record.DataType == :Monthly
                if runningday>eto_dataset[31].DayNr
                    get_monthly_eto_dataset!(eto_dataset, runningday,
                                             ETo,
                                             eto_record) 
                end 
                i = 1 
                while eto_dataset[1].DayNr != runningday
                    i += 1
                end
                eto = eto_dataset[i].Param 
            end
            add_output_in_etodatasim!(outputs, eto)
        end
    end 

    # 2. Rain File
    if gvars[:bool_parameters][:rain_file_exists]
        if rain_record.DataType == :Daily
            i = fromsimday - rain_record.FromDayNr + 1
            rain = Rain[i]

        elseif rain_record.DataType == :Decadely
            get_decade_rain_dataset!(rain_dataset, fromsimday, ETo, rain_record)
            i = 1
            while rain_dataset[i].DayNr != fromsimday
                i = i+1
            end
            rain = rain_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :rain, rain)

        elseif rain_record.DataType == :Monthly
            get_monthly_rain_dataset!(rain_dataset, fromsimday, Rain, rain_record)
            i = 1
            while rain_dataset[i].DayNr != fromsimday
                i = i+1
            end
            rain = rain_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :rain, rain)

        end 

        # we do no create RainData.SIM but we use outputs variable
        add_output_in_raindatasim!(outputs, rain)

        # next days of simulation period
        for runningday in (fromsimday + 1):tosimday
            if rain_record.DataType == :Daily
                i += 1
                if i==length(Rain)
                    i = 1
                end
                rain = Rain[i]

            elseif rain_record.DataType == :Decadely
                if runningday>rain_dataset[31].DayNr
                    get_decade_rain_dataset!(rain_dataset, runningday,
                                            Rain, 
                                            rain_record) 
                end
                i = 1
                while rain_dataset[1].DayNr != runningday
                    i += 1
                end 
                rain = rain_dataset[i].Param 

            elseif rain_record.DataType == :Monthly
                if runningday>rain_dataset[31].DayNr
                    get_monthly_rain_dataset!(rain_dataset, runningday,
                                             Rain,
                                             rain_record) 
                end 
                i = 1 
                while rain_dataset[1].DayNr != runningday
                    i += 1
                end
                rain = rain_dataset[i].Param 
            end
            add_output_in_raindatasim!(outputs, rain)
        end
    end 

    # 3. Temperature file
    if gvars[:bool_parameters][:temperature_file_exists]
        if temperature_record.DataType == :Daily
            i = fromsimday - temperature_record.FromDayNr + 1
            tlow = Tmin[i]
            thigh = Tmax[i]
            # setparameter!(gvars[:float_parameters], :tmin, tlow)
            # setparameter!(gvars[:float_parameters], :tmax, thigh)

        elseif temperature_record.DataType == :Decadely
            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, fromsimday,
                                            (Tmin, Tmax), 
                                            temperature_record)
            i = 1
            while tmin_dataset[i].DayNr != fromsimday
                i = i+1
            end
            tlow = tmin_dataset[i].Param 
            thigh = tmax_dataset[i].Param 
            # setparameter!(gvars[:float_parameters], :tmin, tlow)
            # setparameter!(gvars[:float_parameters], :tmax, thigh)

        elseif temperature_record.DataType == :Monthly
            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, fromsimday,
                                            (Tmin, Tmax), 
                                            temperature_record)
            i = 1
            while tmin_dataset[1].DayNr != fromsimday 
                i += 1
            end
            tlow = tmin_dataset[i].Param 
            thigh = tmax_dataset[i].Param 
            # setparameter!(gvars[:float_parameters], :tmin, tlow)
            # setparameter!(gvars[:float_parameters], :tmax, thigh)
        end 

        # we do no create TempData.SIM but we use outputs variable
        add_output_in_tempdatasim!(outputs, tlow, thigh)

        # next days of simulation period
        for runningday in (fromsimday + 1):tosimday
            if temperature_record.DataType == :Daily
                i += 1
                if i==length(Tmin)
                    i = 1
                end
                tlow = Tmin[i]
                thigh = Tmax[i]

            elseif temperature_record.DataType == :Decadely
                if runningday>tmin_dataset[31].DayNr
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    (Tmin, Tmax), 
                                                    temperature_record)
                end
                i = 1
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end 
                tlow = tmin_dataset[i].Param 
                thigh = tmax_dataset[i].Param 

            elseif temperature_record.DataType == :Monthly
                if runningday>tmin_dataset[31].DayNr
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                     (Tmin, Tmax), 
                                                     temperature_record)
                end 
                i = 1 
                while tmin_dataset[1].DayNr != runningday
                    i += 1
                end
                tlow = tmin_dataset[i].Param 
                thigh = tmax_dataset[i].Param 
            end
            add_output_in_tempdatasim!(outputs, tlow, thigh)
        end
    end 

    return nothing
end 


"""
    get_decade_eto_dataset!(eto_dataset, daynri, eto_array, eto_record::RepClim)

climprocessing.f90:325
"""
function get_decade_eto_dataset!(eto_dataset, daynri, eto_array, eto_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)
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
    c1, c2, c3 = get_set_of_three_eto(dayn, deci, monthi, yeari, eto_array, eto_record)
    dnr = determine_day_nr(dayi, monthi, yeari)

    if abs(c2) < eps() 
        for nri in 1:ni
            eto_dataset[nri].DayNr = dnr+nri-1
            eto_dataset[nri].Param = 0
        end 
    else
        ul, ll, mid = get_parameters(c1, c2, c3)
        for nri in 1:ni
            eto_dataset[nri].DayNr = dnr+nri-1
            if (nri <= (ni/2+0.01)) 
                eto_dataset[nri].Param = (2*ul + (mid-ul)*(2*nri-1)/(ni/2))/2
            else
                if ((ni == 11) | (ni == 9)) & (nri < (ni+1.01)/2) 
                    eto_dataset[nri].Param = mid
                else
                    eto_dataset[nri].Param = (2*mid + (ll-mid)*(2*nri-(ni+1))/(ni/2))/2
                end 
            end 
            if eto_dataset[nri].Param<0
                eto_dataset[nri].Param = 0
            end
        end 
    end 

    for nri in (ni+1):31
        eto_dataset[nri].DayNr = dnr+ni-1
        eto_dataset[nri].Param = 0
    end 

    return nothing
end 

"""
    c1, c2, c3 = get_set_of_three_eto(dayn, deci, monthi, yeari, eto_array, eto_record::RepClim)

climprocessing.f90:393
"""
function get_set_of_three_eto(dayn, deci, monthi, yeari, eto_array, eto_record::RepClim)
    # 1 = previous decade, 2 = Actual decade, 3 = Next decade;
    if eto_record.FromD>20
        decfile=3
    elseif eto_record.FromD>10
        decfile=2
    else
        decfile=1
    end
    mfile = eto_record.FromM
    if eto_record.FromY==1901
        yfile = yeari
    else
        yfile = eto_record.FromY
    end
    ok3 = false

    cont = 1
    if eto_record.NrObs <= 2
        c1 = eto_array[cont]
        cont += 1
        # OJO for some reason this ==1 and ==2 are different for temperature get_set_of_three
        if eto_record.NrObs==1
            c2 = c1
            c3 = c1
        elseif eto_record.NrObs==2
            decfile += 1
            if decfile>3
                decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
            end
            c1 = eto_array[cont]
            cont += 1
            if (deci == decfile) 
                c2 = c3
                c3 = c2+(c2-c1)/4
            else
                c2 = c1
                c1 = c2 + (c2-c3)/4
            end 
        end
        ok3 = true
    end

    if (!ok3) & (deci==decfile) & (monthi==mfile) & (yeari==yfile)
        c1 = eto_array[cont]
        cont += 1
        c2 = c1
        c3 = eto_array[cont]
        cont += 1
        c1 = c2 + (c2-c3)/4
        ok3 = true
    end

    if (!ok3) & (dayn==eto_record.ToD) & (monthi==eto_record.ToM)
        if (eto_record.FromY==1901) | (yeari==eto_record.ToY)
            for Nri in 1:(eto_record.NrObs-2)
                cont += 1
            end 
            c1 = eto_array[cont]
            cont += 1
            c2 = eto_array[cont]
            cont += 1
            c3 = c2+(c2-c1)/4
            ok3 = true
        end 
    end 

    if !ok3 
        obsi = 1
        while !ok3
            if (deci==decfile) & (monthi==mfile) & (yeari == yfile) 
                ok3 = true
            else
                decfile = decfile + 1
                if decfile>3 
                    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
                end
                obsi = obsi + 1
            end
        end
        if eto_record.FromD>20
            decfile = 3
        elseif eto_record.FromD>10
            decfile = 2
        else
            decfile = 1
        end
        for nri in 1:(obsi-2)
            cont += 1
        end 
        c1 = eto_array[cont]
        cont += 1
        c2 = eto_array[cont]
        cont += 1
        c3 = eto_array[cont]
        cont += 1
    end 

    return c1, c2, c3
end

"""
    get_monthly_eto_dataset!(eto_dataset, daynri, eto_array, eto_record::RepClim)

climprocessing.f90:87
"""
function get_monthly_eto_dataset!(eto_dataset, daynri, eto_array, eto_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)
    c1, c2, c3, x1, x2, x3, t1 = get_set_of_three_months_eto(monthi, yeari, eto_array, eto_record)

    dayi = 1
    dnr = determine_day_nr(dayi, monthi, yeari)
    dayn = DaysInMonth[monthi]
    if ((monthi == 2) & isleapyear(yeari)) 
        dayn = dayn + 1
    end 

    aover3, bover2, c = get_interpolation_parameters(c1min, c2min, c3min)
    for dayi in 1:dayn
        t2 = t1 + 1
        eto_dataset[dayi].DayNr = dnr+dayi-1
        eto_dataset[dayi].Param = aover3*(t2*t2*t2-t1*t1*t1) + bover2*(t2*t2-t1*t1) + c*(t2-t1)
        if eto_dataset[dayi].Param<0
            eto_dataset[dayi].Param=0
        end
        t1 = t2
    end 
    for dayi in (dayn+1):31
        eto_dataset[dayi].DayNr = dnr+dayn-1 #OJO maybe is dayi
        eto_dataset[dayi].Param = 0
    end 

    return nothing
end  

"""
    c1, c2, c3, x1, x2, x3, t1 = get_set_of_three_months_eto(monthi, yeari, eto_array, eto_record)

climprocessing.f90:128
"""
function get_set_of_three_months_eto(monthi, yeari, eto_array, eto_record)
    ni = 30

    # 1. Prepare record
    mfile = eto_record.FromM
    if eto_record.FromY==1901
        yfile = yeari
    else
        yfile = eto_record.FromY
    end
    ok3 = false

    cont = 1
    # 2. IF 3 or less records
    if eto_record.NrObs <= 3
        c1 = eto_array[cont]
        cont += 1
        c1 = c1 * ni
        x1 = ni
        # OJO for some reason this ==1 ==2 and ==3 are different for temperature get_set_of_three_months
        if eto_record.NrObs==1
            t1 = x1
            x2 = x1 + ni
            c2 = c1
            x3 = x2 + ni
            c3 = c1
        elseif eto_record.NrObs==2
            t1 = x1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3 = eto_array[cont]
            cont += 1
            c3 = c3 * ni
            if monthi==mfile 
                c2 = c3
                x2 = x1 + ni
                x3 = x2 + ni
            else
                c2 = c1
                x2 = x1 + ni
                x3 = x2 + ni
            end 
        elseif eto_record.NrObs==3
            if monthi==mfile 
                t1 = 0
            end 
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c2 = eto_array[cont]
            cont += 1
            c2 = c2 * ni
            x2 = x1 + ni
            if monthi==mfile 
                t1 = x1
            end 
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3 = eto_array[cont]
            cont += 1
            c3 = c3 * ni
            x3 = x2 + ni
            if monthi == mfile 
                t1 = x2
            end 
        end
        ok3 = true
    end 

    # 3. If first observation
    if (!ok3) & (monthi==mfile) & (yeari==yfile)
        t1 = 0
        c1 = eto_array[cont]
        cont += 1
        c1 = c1 * ni
        x1 = ni
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c2 = eto_array[cont]
        cont += 1
        c2 = c2 * ni
        x2 = x1 + ni
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c3 = eto_array[cont]
        cont += 1
        c3 = c3 * ni
        x3 = x2 + ni
        ok3 = true
    end 

    # 4. If last observation
    if (!ok3) & (monthi==eto_record.ToM)
        if (eto_record.FromY==1901) | (yeari==eto_record.ToY)
            for nri in 1:(eto_record.NrObs-3)
                cont += 1
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
            end 
            c1 = eto_array[cont]
            cont += 1
            c1 = c1 * ni
            x1 = ni
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2 = eto_array[cont]
            cont += 1
            c2 = c2 * ni
            x2 = x1 + ni
            t1 = x2
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3 = eto_array[cont]
            cont += 1
            c3 = c3 * ni
            x3 = x2 + ni
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
        mfile = eto_record.FromM 
        for nri in 1:(obsi-2)
            cont += 1
            mfile = mfile + 1
            if (mfile > 12) 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
        end
        c1 = eto_array[cont]
        cont += 1
        c1 = c1 * ni
        x1 = ni
        t1 = x1
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c2 = eto_array[cont]
        cont += 1
        c2 = c2 * ni
        x2 = x1 + ni
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end
        c3 = eto_array[cont]
        cont += 1
        c3 = c3 * ni
        x3 = x2 + ni
    end 

    return c1, c2, c3, x1, x2, x3, t1
end

"""
    get_decade_rain_dataset!(rain_dataset, daynri, rain_array, rain_record::RepClim)

climprocessing.f90:515
"""
function get_decade_rain_dataset!(rain_dataset, daynri, rain_array, rain_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)

    # 0. Set Monthly Parameters

    # 1. Which decade ?
    if (dayi > 20) 
        deci = 3
        dayi = 21
        ni = DaysInMonth[monthi] - dayi + 1
        if ((monthi == 2) & isleapyear(yeari)) 
            ni = ni + 1
        end 
    elseif (dayi > 10) 
        deci = 2
        dayi = 11
        ni = 10
    else
        deci = 1
        dayi = 1
        ni = 10
    end 

    # 2. Load datafile
    if rain_record.FromD > 20 
        decfile = 3
    elseif rain_record.FromD > 10 
        decfile = 2
    else
        decfile = 1
    end 
    mfile = rain_record.FromM
    if rain_record.FromY == 1901 
        yfile = yeari
    else
        yfile = rain_record.FromY
    end 

    cont = 1
    # 3. Find decade
    okrain = false
    c = 999
    while !okrain
        if ((deci == decfile) & (monthi == mfile) & (yeari == yfile)) 
            c = rain_array[cont]
            cont += 1
            okrain = true
        else
            cont += 1
            decfile = decfile + 1
            if decfile > 3 
                decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
            end 
        end 
    end 

    # 4. Process data
    dnr = determine_day_nr(dayi, monthi, yeari)
    for nri in 1:ni
        rain_dataset[nri].DayNr = dnr+nri-1
        rain_dataset[nri].Param = c/ni
    end 
    for Nri in (ni+1):31
        rain_dataset[nri].DayNr = dnr+ni-1
        rain_dataset[nri].Param = 0
    end 
    return nothing
end

"""
    get_monthly_rain_dataset!(rain_dataset, daynri, rain_array, rain_record::RepClim)

climprocessing.f90:604
"""
function get_monthly_rain_dataset!(rain_dataset, daynri, rain_array, rain_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)

    # Set Monthly Parameters

    c1, c2, c3 = get_set_of_three_months_rain(monthi, yeari, rain_array, rain_record)

    dayi = 1
    dnr = determine_day_nr(dayi, monthi, yeari)
    dayn = DaysInMonth[monthi]
    if ((monthi == 2) & isleapyear(yeari)) 
        dayn = dayn + 1
    end 
    if c2 > eps() 
        raindec1 = (5*c1 + 26*c2 - 4*c3)/(27*3) # mm/dec
        raindec2 = (-c1 + 29*c2 - c3)/(27*3)
        raindec3 = (-4*c1 + 26*c2 + 5*c3)/(27*3)
        for dayi in 1:10
            rain_dataset[dayi].DayNr = dnr+dayi-1
            rain_dataset[dayi].Param = raindec1/10
            if rain_dataset[dayi].Param < eps() 
                rain_dataset[dayi].Param = 0
            end 
        end 
        for dayi in 11:20
            rain_dataset[dayi].DayNr = dnr+dayi-1
            rain_dataset[dayi].Param = raindec2/10
            if rain_dataset[dayi].Param < eps() 
                rain_dataset[dayi].Param = 0
            end 
        end 
        for dayi in 21:dayn
            rain_dataset[dayi].DayNr = dnr+dayi-1
            rain_dataset[dayi].Param = raindec3/(dayn-21+1)
            if rain_dataset[dayi].Param < eps() 
                rain_dataset[dayi].Param = 0
            end 
        end 
    else
        for dayi in 1:dayn
            rain_dataset[dayi].DayNr = dnr+dayi-1
            rain_dataset[dayi].Param = 0
        end 
    end 

    for dayi in (dayn+1):31
        rain_dataset[dayi].DayNr = dnr+dayn-1
        rain_dataset[dayi].Param = 0
    end 

    return nothing
end

"""
    c1, c2, c3 = get_set_of_three_months_rain(monthi, yeari, rain_array, rain_record)

climprocessing.f90:665
"""
function get_set_of_three_months_rain(monthi, yeari, rain_array, rain_record)
    # 1. Prepare record
    mfile = rain_record.FromM
    if rain_record.FromY==1901
        yfile = yeari
    else
        yfile = rain_record.FromY
    end
    ok3 = false

    cont = 1
    # 2. IF 2 or less records
    if rain_record.NrObs <= 2
        c1 = rain_array[cont]
        cont += 1
        if rain_record.NrObs==1
            c2 = c1
            c3 = c1
        elseif eto_record.NrObs==2
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3 = rain_array[cont]
            cont += 1
            if monthi==mfile 
                c2 = c3
            else
                c2 = c1
            end 
        end
        ok3 = true
    end

    # 3. If first observation
    if (!ok3) & (monthi==mfile) & (yeari==yfile)
        c1 = rain_array[cont]
        cont += 1
        c2 = c1
        c3 = rain_array[cont]
        cont += 1
        ok3 = true
    end

    # 4. If last observation
    if (!ok3) & (monthi==rain_record.ToM)
        if (rain_record.FromY==1901) | (yeari==rain_record.ToY)
            for nri in 1:(rain_record.NrObs-2)
                cont += 1
            end 
            c1 = rain_array[cont]
            cont += 1
            c2 = rain_array[cont]
            cont += 1
            c3 = c2
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
        mfile = rain_record.FromM 
        for nri in 1:(obsi-2)
            cont += 1
            mfile = mfile + 1
            if (mfile > 12) 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
        end
        c1 = eto_array[cont]
        cont += 1
        c2 = eto_array[cont]
        cont += 1
        c3 = eto_array[cont]
        cont += 1
    end 

    return c1, c2, c3
end

"""
    open_climfiles_and_get_data_firstday!(outputs, gvars; kwargs...)

run.f90:5962
"""
function open_climfiles_and_get_data_firstday!(outputs, gvars; kwargs...)
    firstdaynr = gvars[:integer_parameters][:daynri]
    simulation = gvars[:simulation]
    simulparam = gvars[:simulparam]

    # ETo file
    if gvars[:bool_parameters][:eto_file_exists]
        if firstdaynr == simulation.FromDayNr
            i = 1
            eto = read_output_from_etodatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :eto, eto)
        else
            i = firstdaynr - simulation.FromDayNr + 1
            eto = read_output_from_etodatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :eto, eto)
        end 
    end 
    # Rain file
    if gvars[:bool_parameters][:rain_file_exists]
        if firstdaynr == simulation.FromDayNr
            i = 1
            rain = read_output_from_raindatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :rain, rain)
        else
            i = firstdaynr - simulation.FromDayNr + 1
            rain = read_output_from_raindatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :rain, rain)
        end 
    end 
    # Temperature file
    if gvars[:bool_parameters][:temperature_file_exists]
        if firstdaynr == simulation.FromDayNr
            i = 1
            tlow, thigh = read_output_from_tempdatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :tmin, tlow)
            setparameter!(gvars[:float_parameters], :tmax, thigh)
        else
            i = firstdaynr - simulation.FromDayNr + 1
            tlow, thigh = read_output_from_tempdatasim(outputs, i) 
            setparameter!(gvars[:float_parameters], :tmin, tlow)
            setparameter!(gvars[:float_parameters], :tmax, thigh)
        end 
    else
        setparameter!(gvars[:float_parameters], :tmin, simulparam.Tmin)
        setparameter!(gvars[:float_parameters], :tmax, simulparam.Tmax)
    end 
    return nothing
end

"""
    initialize_run_part2!(outputs, gvars, projectinput::ProjectInputType; kwargs...)

run.f90:6672
"""
function initialize_run_part2!(outputs, gvars, projectinput::ProjectInputType; kwargs...)
    # Part2 (after reading the climate) of the run initialization
    # Calls InitializeSimulationRunPart2
    # Initializes write out for the run
    integer(int8), intent(in) :: NrRun
    integer(intEnum), intent(in) :: TheProjectType

    call InitializeSimulationRunPart2()

    if (GetOutDaily()) then
        call WriteTitleDailyResults(TheProjectType, NrRun)
    end 

    if (GetPart1Mult()) then
        call WriteTitlePart1MultResults(TheProjectType, NrRun)
    end 

    if (GetPart2Eval() .and. (GetObservationsFile() /= '(None)')) then
        call CreateEvalData(NrRun)
    end 
end #notend

"""
    initialize_simulation_run_part2!(outputs, gvars, projectinput::ProjectInputType; kwargs...)

run.f90:5018
"""
function initialize_simulation_run_part2!(outputs, gvars, projectinput::ProjectInputType; kwargs...)
    # Part2 (after reading the climate) of the initialization of a run
    # Initializes parameters and states

    # Sum of GDD before start of simulation
    gvars[:simulation].SumGDD = 0
    gvars[:simulation].SumGDDfromDay1 = 0
    if (gvars[:crop].ModeCycle==:GDDays) & 
        (gvars[:crop].Day1<gvars[:integer_parameters][:daynri])
        get_sumgdd_before_simulation!(gvars)
    end
    setparameter!(gvars[:float_parameters], :sumgddprev, gvars[:simulation].SumGDDfromDay1)

    # Sum of GDD at end of first day
    gddayi = degrees_day(gvars[:crop].Tbase, gvars[:crop].Tupper,
                gvars[:float_parameters][:tmin], gvars[:float_parameters][:tmax],
                gvars[:simulparam].GDDMethod)
    setparameter!(gvars[:float_parameters], :gddayi, gddayi)
    if gvars[:integer_parameters][:daynri] >= gvars[:crop].Day1 
        if gvars[:integer_parameters][:daynri] == gvars[:crop].Day1 
            gvars[:simulation].SumGDD += gddayi
        end
        gvars[:simulation].SumGDDfromDay1 += gddayi
    end
    # Reset cummulative sums of ETo and GDD for Run output
    setparameter!(gvars[:float_parameters], :sumeto, 0.0)
    setparameter!(gvars[:float_parameters], :sumgdd, 0.0)

    # 11. Irrigation
    setparameter!(gvars[:integer_parameters], :irri_interval, 1)
    # In Versions < 3.2 - Irrigation water
    # quality is not yet recorded on file
    setparameter!(gvars[:bool_parameters], :global_irri_ecw, true)
    open_irrigation_file!(gvars, projectinput.ParentDir)

    # 12. Adjusted time when starting as regrowth
    if gvars[:crop].DaysToCCini != 0
        # regrowth
        setparameter!(gvars[:integer_parameters], :gddtadj, undef_int)
        setparameter!(gvars[:float_parameters], :gddayfraction, undef_double)
        if gvars[:crop].DaysToCCini == undef_int
            tadj = gvars[:crop].DaysToFullCanopy - gvars[:crop].DaysToGermination 
            setparameter!(gvars[:integer_parameters], :tadj, tadj)
        else
            tadj = gvars[:crop].DaysToCCini
            setparameter!(gvars[:integer_parameters], :tadj, tadj)
        end
        dayfraction = (gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopy)/
                      (tadj + gvars[:crop].DaysToGermination +
                       gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopy)
        setparameter!(gvars[:float_parameters], :dayfraction, dayfraction)
        if gvars[:crop].ModeCycle == :GDDays
            if gvars[:crop].GDDaysToCCini == undef_int
                gddtadj = gvars[:crop].GDDaysToFullCanopy - gvars[:crop].GDDaysToGermination
                setparameter!(gvars[:integer_parameters], :gddtadj, gddtadj)
            else
                gddtadj = gvars[:crop].GDDaysToCCini
                setparameter!(gvars[:integer_parameters], :gddtadj, gddtadj)
            end
            gddayfraction = (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopy)/
                          (gddtadj + gvars[:crop].GDDaysToGermination +
                           gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopy)
            setparameter!(gvars[:float_parameters], :gddayfraction, gddayfraction)
        end
    else
        # sowing or transplanting
        setparameter!(gvars[:integer_parameters], :tadj, 0)
        setparameter!(gvars[:float_parameters], :dayfraction, undef_double)
        setparameter!(gvars[:integer_parameters], :gddtadj, 0)
        setparameter!(gvars[:float_parameters], :gddayfraction, undef_double)
    end 

    # 13. Initial canopy cover
    # 13.1 default value
    # 13.1a RatDGDD for simulation of CanopyCoverNoStressSF (CCi with decline)
    RatDGDD = 1._dp
    if (GetCrop_ModeCycle() == modeCycle_GDDays) then
        if (GetCrop_GDDaysToFullCanopySF() < GetCrop_GDDaysToSenescence()) then
            RatDGDD = (GetCrop_DaysToSenescence() - &
                       GetCrop_DaysToFullCanopySF()) / &
                      real(GetCrop_GDDaysToSenescence() -&
                           GetCrop_GDDaysToFullCanopySF(), kind=dp)
        end if
    end if
    # 13.1b DayCC for initial canopy cover
    Dayi = GetDayNri() - GetCrop_Day1()
    if (GetCrop_DaysToCCini() == 0) then
        # sowing or transplant
        DayCC = Dayi
        call SetDayFraction(real(undef_int, kind=dp))
    else
        # adjust time (calendar days) for regrowth
        DayCC = Dayi + GetTadj() + GetCrop_DaysToGermination() # adjusted time scale
        if (DayCC > GetCrop_DaysToHarvest()) then
            DayCC = GetCrop_DaysToHarvest() # special case where L123 > L1234
        end if
        if (DayCC > GetCrop_DaysToFullCanopy()) then
            if (Dayi <= GetCrop_DaysToSenescence()) then
                DayCC = GetCrop_DaysToFullCanopy()  + &
                         roundc(GetDayFraction() * &
                         (Dayi+GetTadj()+GetCrop_DaysToGermination() -&
                         GetCrop_DaysToFullCanopy()),mold=1) # slow down
            else
                DayCC = Dayi # switch time scale
            end if
        end if
    end if
    # 13.1c SumGDDayCC for initial canopy cover
    SumGDDforDayCC = undef_int
    if (GetCrop_ModeCycle() == modeCycle_GDDays) then
        if (GetCrop_GDDaysToCCini() == 0) then
            SumGDDforDayCC = GetSimulation_SumGDDfromDay1() - GetGDDayi()
        else
            # adjust time (Growing Degree Days) for regrowth
            SumGDDforDayCC = GetSimulation_SumGDDfromDay1() - GetGDDayi() + &
                             GetGDDTadj() + GetCrop_GDDaysToGermination()
            if (SumGDDforDayCC > GetCrop_GDDaysToHarvest()) then
                SumGDDforDayCC = GetCrop_GDDaysToHarvest()
                # special case where L123 > L1234
            end if
            if (SumGDDforDayCC > GetCrop_GDDaysToFullCanopy()) then
                if (GetSimulation_SumGDDfromDay1() <= &
                    GetCrop_GDDaysToFullCanopy()) then
                    SumGDDforDayCC = GetCrop_GDDaysToFullCanopy() + &
                      roundc(GetGDDayFraction() * &
                       (GetSimulation_SumGDDfromDay1()+GetGDDTadj()+ &
                       GetCrop_GDDaysToGermination()- &
                       GetCrop_GDDaysToFullCanopy()),mold=1)
                    # slow down
                else
                    SumGDDforDayCC = GetSimulation_SumGDDfromDay1() - &
                                      GetGDDayi()
                    # switch time scale
                end if
            end if
        end if
    end if
    # 13.1d CCi at start of day (is CCi at end of previous day)
    if (GetDayNri() <= GetCrop_Day1()) then
        if (GetCrop_DaysToCCini() /= 0) then
            # regrowth which starts on 1st day
            if (GetDayNri() == GetCrop_Day1()) then
                call SetCCiPrev(CCiNoWaterStressSF(DayCC, &
                   GetCrop_DaysToGermination(), &
                   GetCrop_DaysToFullCanopySF(), &
                   GetCrop_DaysToSenescence(), GetCrop_DaysToHarvest(), &
                   GetCrop_GDDaysToGermination(), &
                   GetCrop_GDDaysToFullCanopySF(), &
                   GetCrop_GDDaysToSenescence(), GetCrop_GDDaysToHarvest(), &
                   GetCCoTotal(), GetCCxTotal(), GetCrop_CGC(), &
                   GetCrop_GDDCGC(), GetCDCTotal(), GetGDDCDCTotal(), &
                   SumGDDforDayCC, RatDGDD, &
                   GetSimulation_EffectStress_RedCGC(), &
                   GetSimulation_EffectStress_RedCCX(), &
                   GetSimulation_EffectStress_CDecline(), GetCrop_ModeCycle()))
            else
                call SetCCiPrev(0._dp)
            end if
        else
            # sowing or transplanting
            call SetCCiPrev(0._dp)
            if (GetDayNri() == (GetCrop_Day1()+GetCrop_DaysToGermination())) then
                call SetCCiPrev(GetCCoTotal())
            end if
        end if
    else
        if (GetDayNri() > GetCrop_DayN()) then
            call SetCCiPrev(0._dp)  # after cropping period
        else
            call SetCCiPrev(CCiNoWaterStressSF(DayCC, &
                GetCrop_DaysToGermination(), &
                GetCrop_DaysToFullCanopySF(), GetCrop_DaysToSenescence(), &
                GetCrop_DaysToHarvest(), GetCrop_GDDaysToGermination(), &
                GetCrop_GDDaysToFullCanopySF(), GetCrop_GDDaysToSenescence(), &
                GetCrop_GDDaysToHarvest(), GetCCoTotal(), GetCCxTotal(), &
                GetCrop_CGC(), GetCrop_GDDCGC(), GetCDCTotal(),&
                GetGDDCDCTotal(), SumGDDforDayCC, RatDGDD, &
                GetSimulation_EffectStress_RedCGC(), &
                GetSimulation_EffectStress_RedCCX(), &
                GetSimulation_EffectStress_CDecline(), GetCrop_ModeCycle()))
        end if
    end if
    # 13.2 specified CCini (%)
    if ((GetSimulation_CCini() > 0._dp) .and. &
        (roundc(10000._dp*GetCCiPrev(), mold=1) > 0) .and. &
        (roundc(GetSimulation_CCini(), mold=1) /= &
            roundc(100._dp*GetCCiPrev(),mold=1))) then
        # 13.2a Minimum CC
        CCiniMin = 100._dp * (GetCrop_SizeSeedling()/10000._dp)*&
                    (GetCrop_PlantingDens()/10000._dp)
        if (CCiniMin - roundc(CCiniMin*100._dp, mold=1)/100._dp >= 0.00001) then
            CCiniMin = roundc(CCiniMin*100._dp + 1._dp, mold=1)/100._dp
        else
            CCiniMin = roundc(CCiniMin*100._dp, mold=1)/100._dp
        end if
        # 13.2b Maximum CC
        CCiniMax = 100._dp * GetCCiPrev()
        CCiniMax = roundc(CCiniMax*100._dp, mold=1)/100._dp
        # 13.2c accept specified CCini
        if ((GetSimulation_CCini() >= CCiniMin) .and. &
            (GetSimulation_CCini() <= CCiniMax)) then
            call SetCCiPrev(GetSimulation_CCini()/100._dp)
        end if
    end if
    # 13.3
    call SetCrop_CCxAdjusted(GetCCxTotal())
    call SetCrop_CCoAdjusted(GetCCoTotal())
    call SetTimeSenescence(0._dp)
    call SetCrop_CCxWithered(0._dp)
    call SetNoMoreCrop(.false.)
    call SetCCiActual(GetCCiPrev())

    # 14. Biomass and re-setting of GlobalZero
    if (roundc(1000._dp*GetSimulation_Bini(), mold=1) > 0) then
        # overwrite settings in GlobalZero (in Global)
        call SetSumWaBal_Biomass(GetSimulation_Bini())
        call SetSumWaBal_BiomassPot(GetSimulation_Bini())
        call SetSumWaBal_BiomassUnlim(GetSimulation_Bini())
        call SetSumWaBal_BiomassTot(GetSimulation_Bini())
    end if

    # 15. Transfer of assimilates
    if ((GetCrop_subkind() == subkind_Forage)&
        # only valid for perennial herbaceous forage crops
        .and. (trim(GetCropFileFull()) == &
               trim(GetSimulation_Storage_CropString()))&
        # only for the same crop
        .and. (GetSimulation_YearSeason() > 1) &
        # mobilization not possible in season 1
        .and. (GetSimulation_YearSeason() == &
               (GetSimulation_Storage_Season() + 1))) then
            # season next to season in which storage took place
            # mobilization of assimilates
            if (GetSimulation_YearSeason() == 2) then
                call SetTransfer_ToMobilize(GetSimulation_Storage_Btotal() *& 
                    0.2 * GetCrop_Assimilates_Mobilized()/100._dp)
            else
                call SetTransfer_ToMobilize(GetSimulation_Storage_Btotal() *&
                    GetCrop_Assimilates_Mobilized()/100._dp)
            endif
            if (roundc(1000._dp * GetTransfer_ToMobilize(),&
                   mold=1) > 0) then # minimum 1 kg
                 call SetTransfer_Mobilize(.true.)
            else
                 call SetTransfer_Mobilize(.false.)
            end if
    else
        call SetSimulation_Storage_CropString(GetCropFileFull())
        # no mobilization of assimilates
        call SetTransfer_ToMobilize(0._dp)
        call SetTransfer_Mobilize(.false.)
    end if
    # Storage is off and zero at start of season
    call SetSimulation_Storage_Season(GetSimulation_YearSeason())
    call SetSimulation_Storage_Btotal(0._dp)
    call SetTransfer_Store(.false.)
    # Nothing yet mobilized at start of season
    call SetTransfer_Bmobilized(0._dp)

    # 16. Initial rooting depth
    # 16.1 default value
    if (GetDayNri() <= GetCrop_Day1()) then
        call SetZiprev(real(undef_int, kind=dp))
    else
        if (GetDayNri() > GetCrop_DayN()) then
            call SetZiprev(real(undef_int, kind=dp))
        else
            call SetZiprev( ActualRootingDepth(GetDayNri()-GetCrop_Day1(),&
                  GetCrop_DaysToGermination(),&
                  GetCrop_DaysToMaxRooting(),&
                  GetCrop_DaysToHarvest(),&
                  GetCrop_GDDaysToGermination(),&
                  GetCrop_GDDaysToMaxRooting(),&
                  GetSumGDDPrev(),&
                  GetCrop_RootMin(),&
                  GetCrop_RootMax(),&
                  GetCrop_RootShape(),&
                  GetCrop_ModeCycle()) )
        end if
    end if
    # 16.2 specified or default Zrini (m)
    if ((GetSimulation_Zrini() > 0._dp) .and. &
        (GetZiprev() > 0._dp) .and. &
        (GetSimulation_Zrini() <= GetZiprev())) then
        if ((GetSimulation_Zrini() >= GetCrop_RootMin()) .and. &
            (GetSimulation_Zrini() <= GetCrop_RootMax())) then
            call SetZiprev( GetSimulation_Zrini())
        else
            if (GetSimulation_Zrini() < GetCrop_RootMin()) then
                call SetZiprev( GetCrop_RootMin())
            else
                call SetZiprev( GetCrop_RootMax())
            end if
        end if
        if ((roundc(GetSoil_RootMax()*1000._dp, mold=1) < &
             roundc(GetCrop_RootMax()*1000._dp, mold=1)) &
            .and. (GetZiprev() > GetSoil_RootMax())) then
            call SetZiprev(real(GetSoil_RootMax(), kind=dp))
        end if
        call SetRootingDepth(GetZiprev())
        # NOT NEEDED since RootingDepth is calculated in the RUN by considering
        # Ziprev
    else
        call SetRootingDepth(ActualRootingDepth(GetDayNri()-GetCrop_Day1()+1, &
              GetCrop_DaysToGermination(), &
              GetCrop_DaysToMaxRooting(),&
              GetCrop_DaysToHarvest(),&
              GetCrop_GDDaysToGermination(),&
              GetCrop_GDDaysToMaxRooting(),&
              GetSumGDDPrev(),&
              GetCrop_RootMin(),&
              GetCrop_RootMax(),&
              GetCrop_RootShape(),&
              GetCrop_ModeCycle()))
    end if

    # 17. Multiple cuttings
    call SetNrCut(0)
    call SetSumInterval(0)
    call SetSumGDDcuts(0._dp)
    call SetBprevSum(0._dp)
    call SetYprevSum(0._dp)
    call SetCutInfoRecord1_IntervalInfo(0)
    call SetCutInfoRecord2_IntervalInfo(0)
    call SetCutInfoRecord1_MassInfo(0._dp)
    call SetCutInfoRecord2_MassInfo(0._dp)
    call SetDayLastCut(0)
    call SetCGCref( GetCrop_CGC())
    call SetGDDCGCref(GetCrop_GDDCGC())
    if (GetManagement_Cuttings_Considered()) then
        call OpenHarvestInfo()
    end if

    # 18. Tab sheets

    # 19. Labels, Plots and displays
    if (GetManagement_BundHeight() < 0.01_dp) then
        call SetSurfaceStorage(0._dp)
        call SetECStorage(0._dp)
    end if
    if (GetRootingDepth() > 0._dp) then
        # salinity in root zone
        ECe_temp = GetRootZoneSalt_ECe()
        ECsw_temp = GetRootZoneSalt_ECsw()
        ECswFC_temp = GetRootZoneSalt_ECswFC()
        KsSalt_temp = GetRootZoneSalt_KsSalt()
        call DetermineRootZoneSaltContent(GetRootingDepth(), ECe_temp,&
               ECsw_temp, ECswFC_temp, KsSalt_temp)
        call SetRootZoneSalt_ECe(ECe_temp)
        call SetRootZoneSalt_ECsw(ECsw_temp)
        call SetRootZoneSalt_ECswFC(ECswFC_temp)
        call SetRootZoneSalt_KsSalt(KsSalt_temp)
        call SetStressTot_Salt(((GetStressTot_NrD() - 1._dp)*GetStressTot_Salt() + &
              100._dp*(1._dp-GetRootZoneSalt_KsSalt()))/real(GetStressTot_NrD(), kind=dp))
    end if
    # Harvest Index
    call SetSimulation_HIfinal(GetCrop_HI())
    call SetHItimesBEF(real(undef_int, kind=dp))
    call SetHItimesAT1(1._dp)
    call SetHItimesAT2(1._dp)
    call SetHItimesAT(1._dp)
    call SetalfaHI(real(undef_int, kind=dp))
    call SetalfaHIAdj(0._dp)
    if (GetSimulation_FromDayNr() <= (GetSimulation_DelayedDays() + &
        GetCrop_Day1() + GetCrop_DaysToFlowering())) then
        # not yet flowering
        call SetScorAT1(0._dp)
        call SetScorAT2(0._dp)
    else
        # water stress affecting leaf expansion
        # NOTE: time to reach end determinancy  is tHImax (i.e. flowering/2 or
        # senescence)
        if (GetCrop_DeterminancyLinked()) then
            tHImax = roundc(GetCrop_LengthFlowering()/2._dp, mold=1)
        else
            tHImax = (GetCrop_DaysToSenescence() - GetCrop_DaysToFlowering())
        end if
        if ((GetSimulation_FromDayNr() <= (GetSimulation_DelayedDays() + &
            GetCrop_Day1() + GetCrop_DaysToFlowering() + tHImax)) & # not yet end period
            .and. (tHImax > 0)) then
            # not yet end determinancy
            call SetScorAT1(1._dp/tHImax)
            call SetScorAT1(GetScorAT1() * (GetSimulation_FromDayNr() - &
                  (GetSimulation_DelayedDays() + GetCrop_Day1() + &
                   GetCrop_DaysToFlowering())))
            if (GetScorAT1() > 1._dp) then
                call SetScorAT1(1._dp)
            end if
        else
            call SetScorAT1(1._dp)  # after period of effect
        end if
        # water stress affecting stomatal closure
        # period of effect is yield formation
        if (GetCrop_dHIdt() > 99._dp) then
            tHImax = 0
        else
            tHImax = roundc(GetCrop_HI()/GetCrop_dHIdt(), mold=1)
        end if
        if ((GetSimulation_FromDayNr() <= (GetSimulation_DelayedDays() + &
             GetCrop_Day1() + GetCrop_DaysToFlowering() + tHImax)) & # not yet end period
             .and. (tHImax > 0)) then
            # not yet end yield formation
            call SetScorAT2(1._dp/real(tHImax, kind=dp))
            call SetScorAT2(GetScorAT2() * (GetSimulation_FromDayNr() - &
                  (GetSimulation_DelayedDays() + GetCrop_Day1() + &
                   GetCrop_DaysToFlowering())))
            if (GetScorAT2() > 1._dp) then
                call SetScorAT2(1._dp)
            end if
        else
            call SetScorAT2(1._dp)  # after period of effect
        end if
    end if

    if (GetOutDaily()) then
        call DetermineGrowthStage(GetDayNri(), GetCCiPrev())
    end if

    # 20. Settings for start
    call SetStartMode(.true.)
    call SetStressLeaf(real(undef_int, kind=dp))
    call SetStressSenescence(real(undef_int, kind=dp))
end #notend

"""
    get_sumgdd_before_simulation!(gvars)

run.f90:3798
"""
function get_sumgdd_before_simulation!(gvars)
    daynri = gvars[:integer_parameters][:daynri]

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    Tmin = gvars[:array_parameters][:Tmin]
    Tmax = gvars[:array_parameters][:Tmax]
    tmin = gvars[:float_parameters][:tmin]
    tmax = gvars[:float_parameters][:tmax]
    
    if gvars[:bool_parameters][:temperature_file_exists]
        # open file and find first day of cropping period
        if gvars[:temperature_record].Datatype == :Daily
            # days before first day of simulation (= DayNri)
            for i in gvars[:temperature_record].FromDayNr:(daynri - 1)
                if i < gvars[:crop].Day
                    continue
                else
                    tmin = Tmin[i]
                    tmax = Tmax[i]
                    gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                                                    gvars[:crop].Tupper,
                                                    tmin, tmax,
                                                    gvars[:simulparam].GDDMethod)
                end 
            end 

        elseif gvars[:temperature_record].Datatype == :Decadely
            # first day of cropping
            dayx = gvars[:crop].Day1
            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, dayx,
                                            (Tmin, Tmax), 
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != dayx 
                i += 1
            end
            tmin = tmin_dataset[i].Param 
            tmax = tmax_dataset[i].Param 
            gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                                            gvars[:crop].Tupper,
                                            tmin, tmax,
                                            gvars[:simulparam].GDDMethod)

            # next days
            while dayx < daynri
                dayx = dayx + 1
                if dayx>tmin_dataset[31].DayNr
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    (Tmin, Tmax), 
                                                    gvars[:temperature_record])
                    i = 0
                end 
                i = i+1
                tmin = tmin_dataset[i].Param 
                tmax = tmax_dataset[i].Param 
                gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                                                gvars[:crop].Tupper,
                                                tmin, tmax,
                                                gvars[:simulparam].GDDMethod)
            end 

        elseif gvars[:temperature_record].Datatype == :Monthly
            # first day of cropping
            dayx = gvars[:crop].Day1
            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, dayx,
                                            (Tmin, Tmax), 
                                            gvars[:temperature_record])
            i = 1
            while tmin_dataset[1].DayNr != crop_firstday
                i += 1
            end
            tmin = tmin_dataset[i].Param 
            tmax = tmax_dataset[i].Param 
            gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                                            gvars[:crop].Tupper,
                                            tmin, tmax,
                                            gvars[:simulparam].GDDMethod)

            # next days
            while dayx < daynri
                dayx = dayx + 1
                if dayx>tmin_dataset[31].DayNr
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, runningday,
                                                    (Tmin, Tmax), 
                                                    gvars[:temperature_record])
                    i = 0
                end 
                i = i+1
                tmin = tmin_dataset[i].Param 
                tmax = tmax_dataset[i].Param 
                gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                                                gvars[:crop].Tupper,
                                                tmin, tmax,
                                                gvars[:simulparam].GDDMethod)
            end 
        end
    end 

    if gvars[:string_parameters][:temperature_file]=="(None)"
        dgrd =  degrees_day(gvars[:crop].Tbase, gvars[:crop].Tupper,
                            gvars.[:simulparam].Tmin, gvars[:simulparam].Tmax,
                            gvars[:simulparam].GDDMethod)
        sumgdd  = (daynri - gvars[:crop].Day1 + 1) * dgrd
        if sumgdd < 0 
            gvars[:simulation].SumGDD = 0
        else
            gvars[:simulation].SumGDD = sumgdd
        end 
        
        sumgddfromday1 = (daynri - gvars[:crop].Day1) * dgrd 
        if sumgddfromday1 < 0 
            gvars[:simulation].SumGDD = 0
        else
            gvars[:simulation].SumGDDfromDay1 = sumgddfromday1
        end 

    else
        sumgdd = gvars[:simulation].SumGDD
        dgrd =  degrees_day(gvars[:crop].Tbase, gvars[:crop].Tupper,
                            tmin, tmax, 
                            gvars[:simulparam].GDDMethod)
        sumgddfromday1 = sumgdd - degrees_day
        gvars[:simulation].SumGDDfromDay1 = sumgddfromday1
        setparameter!(gvars[:float_parameters], :tmin, tmin)
        setparameter!(gvars[:float_parameters], :tmax, tmax)
    end 

    return nothing
end 

"""
    open_irrigation_file!(gvars, path)

run.f90:4436
"""
function open_irrigation_file!(gvars, path)
    irri_info_record1 = gvars[:irri_info_record1]
    irri_info_record2 = gvars[:irri_info_record2]
    irrimode = gvars[:symbol_parameters][:irrimode]

    if (irrimode == :Manual) | (irrimode == :Generate) 
        if gvars[:string_parameters][:irri_file] != "(None)"
            totalname = gvars[:string_parameters][:irri_file]
        else
            totalname = joinpath( path, "IrriSchedule.AqC")
        end 
        open(totalname, "r") do file
            readline(file)
            readline(file)
            readline(file)
            setparameter!(gvars[:bool_parameters], :global_irri_ecw, false)
            for i in 1:6
                readline(file)
            end
            if irrimode == :Manual
                if gvars[:integer_parameters][:irri_first_daynr] == undef_int
                    dnr = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
                else
                    dnr = gvars[:integer_parameters][:daynri] - gvars[:integer_parameters][:irri_first_daynr] + 1
                end
                loopi = true
                while loopi
                    splitedline = split(readline(file))
                    if eof(file)
                        irri_info_record1.NoMoreInfo = true
                    else
                        irri_info_record1.NoMoreInfo = false
                        if gvars[:bool_parameters][:global_irri_ecw]
                            ir1 = parse(Int, popfirst!(splitedline))
                            ir2 = parse(Int, popfirst!(splitedline))
                        else
                            ir1 = parse(Int, popfirst!(splitedline))
                            ir2 = parse(Int, popfirst!(splitedline))
                            irriecw = parse(Float64, popfirst!(splitedline))
                            gvars[:simulation].IrriECw = irriecw
                        end
                        irri_info_record1.TimeInfo = ir1
                        irri_info_record1.DepthInfo = ir2
                    end
                    if irri_info_record1.NoMoreInfo | (irri_info_record1.TimeInfo>dnr)
                        loopi = false
                    end
                end
            elseif irrimode == :Generate
                readline(file)
                readline(file)
                irri_info_record1.NoMoreInfo = false
                splitedline = split(readline(file))
                fromday = parse(Int, popfirst!(splitedline))
                timeinfo = parse(Int, popfirst!(splitedline))
                depthinfo = parse(Int, popfirst!(splitedline))
                irriecw = parse(Float64, popfirst!(splitedline))
                irri_info_record1.FromDay = fromday 
                irri_info_record1.TimeInfo = timeinfo 
                irri_info_record1.DepthInfo = depthinfo 
                gvars[:simulation].IrriECw = irriecw

                splitedline = split(readline(file))
                if eof(file)
                    irri_info_record1.ToDay = gvars[:crop].DayN - gvars[:crop].Day1 + 1
                else
                    irri_info_record2.NoMoreInfo = false
                    if gvars[:bool_parameters][:global_irri_ecw]
                        fromday = parse(Int, popfirst!(splitedline))
                        timeinfo = parse(Int, popfirst!(splitedline))
                        depthinfo = parse(Int, popfirst!(splitedline))
                        irri_info_record2.FromDay = fromday 
                        irri_info_record2.TimeInfo = timeinfo 
                        irri_info_record2.DepthInfo = depthinfo 
                    else
                        fromday = parse(Int, popfirst!(splitedline))
                        timeinfo = parse(Int, popfirst!(splitedline))
                        depthinfo = parse(Int, popfirst!(splitedline))
                        irriecw = parse(Float64, popfirst!(splitedline))
                        irri_info_record2.FromDay = fromday 
                        irri_info_record2.TimeInfo = timeinfo 
                        irri_info_record2.DepthInfo = depthinfo 
                        gvars[:simulation].IrriECw = irriecw
                    end 
                    irri_info_record1.ToDay = irri_info_record2.FromDay - 1
                end
            end
        end 
    end 
    return nothing
end 
