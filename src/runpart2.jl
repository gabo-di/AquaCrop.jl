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
    open_climfiles_and_get_data_firstday(outputs, gvars; kwargs...)
end #notend

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
            eto_dataset[nri]%DayNr = dnr+nri-1
            eto_dataset[nri]%Param = 0
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
