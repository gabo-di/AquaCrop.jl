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
        if eto_record.Datatype == :Daily
            i = fromsimday - eto_record.FromDayNr + 1
            eto = ETo[i]

        elseif eto_record.Datatype == :Decadely
            get_decade_eto_dataset!(eto_dataset, fromsimday, ETo, eto_record)
            i = 1
            while eto_dataset[i].DayNr != fromsimday
                i = i + 1
            end
            eto = eto_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :eto, eto)

        elseif eto_record.Datatype == :Monthly
            get_monthly_eto_dataset!(eto_dataset, fromsimday, ETo, eto_record)
            i = 1
            while eto_dataset[i].DayNr != fromsimday
                i = i + 1
            end
            eto = eto_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :eto, eto)

        end

        # we do no create EToData.SIM but we use outputs variable
        add_output_in_etodatasim!(outputs, eto)

        # next days of simulation period
        for runningday in (fromsimday+1):tosimday
            if eto_record.Datatype == :Daily
                i += 1
                if i == length(ETo)
                    i = 1
                end
                eto = ETo[i]

            elseif eto_record.Datatype == :Decadely
                if runningday > eto_dataset[31].DayNr
                    get_decade_eto_dataset!(eto_dataset, runningday,
                        ETo,
                        eto_record)
                end
                i = 1
                while eto_dataset[1].DayNr != runningday
                    i += 1
                end
                eto = eto_dataset[i].Param

            elseif eto_record.Datatype == :Monthly
                if runningday > eto_dataset[31].DayNr
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
        if rain_record.Datatype == :Daily
            i = fromsimday - rain_record.FromDayNr + 1
            rain = Rain[i]

        elseif rain_record.Datatype == :Decadely
            get_decade_rain_dataset!(rain_dataset, fromsimday, ETo, rain_record)
            i = 1
            while rain_dataset[i].DayNr != fromsimday
                i = i + 1
            end
            rain = rain_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :rain, rain)

        elseif rain_record.Datatype == :Monthly
            get_monthly_rain_dataset!(rain_dataset, fromsimday, Rain, rain_record)
            i = 1
            while rain_dataset[i].DayNr != fromsimday
                i = i + 1
            end
            rain = rain_dataset[i].Param
            # setparameter!(gvars[:float_parameters], :rain, rain)

        end

        # we do no create RainData.SIM but we use outputs variable
        add_output_in_raindatasim!(outputs, rain)

        # next days of simulation period
        for runningday in (fromsimday+1):tosimday
            if rain_record.Datatype == :Daily
                i += 1
                if i == length(Rain)
                    i = 1
                end
                rain = Rain[i]

            elseif rain_record.Datatype == :Decadely
                if runningday > rain_dataset[31].DayNr
                    get_decade_rain_dataset!(rain_dataset, runningday,
                        Rain,
                        rain_record)
                end
                i = 1
                while rain_dataset[1].DayNr != runningday
                    i += 1
                end
                rain = rain_dataset[i].Param

            elseif rain_record.Datatype == :Monthly
                if runningday > rain_dataset[31].DayNr
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
        if temperature_record.Datatype == :Daily
            i = fromsimday - temperature_record.FromDayNr + 1
            tlow = Tmin[i]
            thigh = Tmax[i]
            # setparameter!(gvars[:float_parameters], :tmin, tlow)
            # setparameter!(gvars[:float_parameters], :tmax, thigh)

        elseif temperature_record.Datatype == :Decadely
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

        elseif temperature_record.Datatype == :Monthly
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
            if temperature_record.Datatype == :Daily
                i += 1
                if i==length(Tmin)
                    i = 1
                end
                tlow = Tmin[i]
                thigh = Tmax[i]

            elseif temperature_record.Datatype == :Decadely
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

            elseif temperature_record.Datatype == :Monthly
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
            eto_dataset[nri].DayNr = dnr + nri - 1
            eto_dataset[nri].Param = 0
        end
    else
        ul, ll, mid = get_parameters(c1, c2, c3)
        for nri in 1:ni
            eto_dataset[nri].DayNr = dnr + nri - 1
            if (nri <= (ni / 2 + 0.01))
                eto_dataset[nri].Param = (2 * ul + (mid - ul) * (2 * nri - 1) / (ni / 2)) / 2
            else
                if ((ni == 11) | (ni == 9)) & (nri < (ni + 1.01) / 2)
                    eto_dataset[nri].Param = mid
                else
                    eto_dataset[nri].Param = (2 * mid + (ll - mid) * (2 * nri - (ni + 1)) / (ni / 2)) / 2
                end
            end
            if eto_dataset[nri].Param < 0
                eto_dataset[nri].Param = 0
            end
        end
    end

    for nri in (ni+1):31
        eto_dataset[nri].DayNr = dnr + ni - 1
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
    if eto_record.FromD > 20
        decfile = 3
    elseif eto_record.FromD > 10
        decfile = 2
    else
        decfile = 1
    end
    mfile = eto_record.FromM
    if eto_record.FromY == 1901
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
        if eto_record.NrObs == 1
            c2 = c1
            c3 = c1
        elseif eto_record.NrObs == 2
            decfile += 1
            if decfile > 3
                decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
            end
            c1 = eto_array[cont]
            cont += 1
            if (deci == decfile)
                c2 = c3
                c3 = c2 + (c2 - c1) / 4
            else
                c2 = c1
                c1 = c2 + (c2 - c3) / 4
            end
        end
        ok3 = true
    end

    if (!ok3) & (deci == decfile) & (monthi == mfile) & (yeari == yfile)
        c1 = eto_array[cont]
        cont += 1
        c2 = c1
        c3 = eto_array[cont]
        cont += 1
        c1 = c2 + (c2 - c3) / 4
        ok3 = true
    end

    if (!ok3) & (dayn == eto_record.ToD) & (monthi == eto_record.ToM)
        if (eto_record.FromY == 1901) | (yeari == eto_record.ToY)
            for Nri in 1:(eto_record.NrObs-2)
                cont += 1
            end
            c1 = eto_array[cont]
            cont += 1
            c2 = eto_array[cont]
            cont += 1
            c3 = c2 + (c2 - c1) / 4
            ok3 = true
        end
    end

    if !ok3
        obsi = 1
        while !ok3
            if (deci == decfile) & (monthi == mfile) & (yeari == yfile)
                ok3 = true
            else
                decfile = decfile + 1
                if decfile > 3
                    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
                end
                obsi = obsi + 1
            end
        end
        if eto_record.FromD > 20
            decfile = 3
        elseif eto_record.FromD > 10
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

    aover3, bover2, c = get_interpolation_parameters(c1, c2, c3)
    for dayi in 1:dayn
        t2 = t1 + 1
        eto_dataset[dayi].DayNr = dnr + dayi - 1
        eto_dataset[dayi].Param = aover3 * (t2 * t2 * t2 - t1 * t1 * t1) + bover2 * (t2 * t2 - t1 * t1) + c * (t2 - t1)
        if eto_dataset[dayi].Param < 0
            eto_dataset[dayi].Param = 0
        end
        t1 = t2
    end
    for dayi in (dayn+1):31
        eto_dataset[dayi].DayNr = dnr + dayn - 1 #OJO maybe is dayi
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
    if eto_record.FromY == 1901
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
        if eto_record.NrObs == 1
            t1 = x1
            x2 = x1 + ni
            c2 = c1
            x3 = x2 + ni
            c3 = c1
        elseif eto_record.NrObs == 2
            t1 = x1
            mfile = mfile + 1
            if mfile > 12
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3 = eto_array[cont]
            cont += 1
            c3 = c3 * ni
            if monthi == mfile
                c2 = c3
                x2 = x1 + ni
                x3 = x2 + ni
            else
                c2 = c1
                x2 = x1 + ni
                x3 = x2 + ni
            end
        elseif eto_record.NrObs == 3
            if monthi == mfile
                t1 = 0
            end
            mfile = mfile + 1
            if mfile > 12
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c2 = eto_array[cont]
            cont += 1
            c2 = c2 * ni
            x2 = x1 + ni
            if monthi == mfile
                t1 = x1
            end
            mfile = mfile + 1
            if mfile > 12
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
    if (!ok3) & (monthi == mfile) & (yeari == yfile)
        t1 = 0
        c1 = eto_array[cont]
        cont += 1
        c1 = c1 * ni
        x1 = ni
        mfile = mfile + 1
        if mfile > 12
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end
        c2 = eto_array[cont]
        cont += 1
        c2 = c2 * ni
        x2 = x1 + ni
        mfile = mfile + 1
        if mfile > 12
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end
        c3 = eto_array[cont]
        cont += 1
        c3 = c3 * ni
        x3 = x2 + ni
        ok3 = true
    end

    # 4. If last observation
    if (!ok3) & (monthi == eto_record.ToM)
        if (eto_record.FromY == 1901) | (yeari == eto_record.ToY)
            for nri in 1:(eto_record.NrObs-3)
                cont += 1
                mfile = mfile + 1
                if mfile > 12
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
            end
            c1 = eto_array[cont]
            cont += 1
            c1 = c1 * ni
            x1 = ni
            mfile = mfile + 1
            if mfile > 12
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c2 = eto_array[cont]
            cont += 1
            c2 = c2 * ni
            x2 = x1 + ni
            t1 = x2
            mfile = mfile + 1
            if mfile > 12
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
            if ((monthi == mfile) & (yeari == yfile))
                ok3 = true
            else
                mfile = mfile + 1
                if mfile > 12
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
        if mfile > 12
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end
        c2 = eto_array[cont]
        cont += 1
        c2 = c2 * ni
        x2 = x1 + ni
        mfile = mfile + 1
        if mfile > 12
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
        rain_dataset[nri].DayNr = dnr + nri - 1
        rain_dataset[nri].Param = c / ni
    end
    for nri in (ni+1):31
        rain_dataset[nri].DayNr = dnr + ni - 1
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
        raindec1 = (5 * c1 + 26 * c2 - 4 * c3) / (27 * 3) # mm/dec
        raindec2 = (-c1 + 29 * c2 - c3) / (27 * 3)
        raindec3 = (-4 * c1 + 26 * c2 + 5 * c3) / (27 * 3)
        for dayi in 1:10
            rain_dataset[dayi].DayNr = dnr + dayi - 1
            rain_dataset[dayi].Param = raindec1 / 10
            if rain_dataset[dayi].Param < eps()
                rain_dataset[dayi].Param = 0
            end
        end
        for dayi in 11:20
            rain_dataset[dayi].DayNr = dnr + dayi - 1
            rain_dataset[dayi].Param = raindec2 / 10
            if rain_dataset[dayi].Param < eps()
                rain_dataset[dayi].Param = 0
            end
        end
        for dayi in 21:dayn
            rain_dataset[dayi].DayNr = dnr + dayi - 1
            rain_dataset[dayi].Param = raindec3 / (dayn - 21 + 1)
            if rain_dataset[dayi].Param < eps()
                rain_dataset[dayi].Param = 0
            end
        end
    else
        for dayi in 1:dayn
            rain_dataset[dayi].DayNr = dnr + dayi - 1
            rain_dataset[dayi].Param = 0
        end
    end

    for dayi in (dayn+1):31
        rain_dataset[dayi].DayNr = dnr + dayn - 1
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
    if rain_record.FromY == 1901
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
        if rain_record.NrObs == 1
            c2 = c1
            c3 = c1
        elseif rain_record.NrObs == 2
            mfile = mfile + 1
            if mfile > 12
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3 = rain_array[cont]
            cont += 1
            if monthi == mfile
                c2 = c3
            else
                c2 = c1
            end
        end
        ok3 = true
    end

    # 3. If first observation
    if (!ok3) & (monthi == mfile) & (yeari == yfile)
        c1 = rain_array[cont]
        cont += 1
        c2 = c1
        c3 = rain_array[cont]
        cont += 1
        ok3 = true
    end

    # 4. If last observation
    if (!ok3) & (monthi == rain_record.ToM)
        if (rain_record.FromY == 1901) | (yeari == rain_record.ToY)
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
            if ((monthi == mfile) & (yeari == yfile))
                ok3 = true
            else
                mfile = mfile + 1
                if mfile > 12
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
        c1 = rain_array[cont]
        cont += 1
        c2 = rain_array[cont]
        cont += 1
        c3 = rain_array[cont]
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
            # tlow, thigh = read_output_from_tcropsim(outputs, i)
            setparameter!(gvars[:float_parameters], :tmin, tlow)
            setparameter!(gvars[:float_parameters], :tmax, thigh)
        else
            i = firstdaynr - simulation.FromDayNr + 1
            tlow, thigh = read_output_from_tempdatasim(outputs, i) 
            # tlow, thigh = read_output_from_tcropsim(outputs, i)
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
    initialize_run_part2!(outputs, gvars, projectinput::ProjectInputType, nrun; kwargs...)

run.f90:6672
"""
function initialize_run_part2!(outputs, gvars, projectinput::ProjectInputType, nrun; kwargs...)
    # Part2 (after reading the climate) of the run initialization
    # Calls InitializeSimulationRunPart2
    # Initializes write out for the run

    initialize_simulation_run_part2!(outputs, gvars, projectinput; kwargs...)

    # OUTPUT
    # if gvars[:bool_parameters][:outdaily] 
    #     this writes the lines 2:5 of OUT/OttawaPRMday.OUT
    #     TODO make a dataframe?
    #     call WriteTitleDailyResults(TheProjectType, NrRun)
    # end 

    # OUTPUT
    # if gvars[:bool_parameters][:part1Mult]
    #     this writes the lines 3:7 of OUT/OttawaPRMharvest.OUT
    #     TODO make a dataframe? (we do care about these results in Persefone)
    #     call WriteTitlePart1MultResults(TheProjectType, NrRun)
    # end 


    # OUTPUT
    # if gvars[:bool_parameters][:part2Eval] & (gvars[:string_parameters][:observations_file] != "(None)")
    #     this file is erased later when we call finalizerun2, is it necessary?
    #     call CreateEvalData(NrRun)
    # end 

    return nothing
end

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
    if (gvars[:crop].ModeCycle == :GDDays) &
       (gvars[:crop].Day1 < gvars[:integer_parameters][:daynri])
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
        dayfraction = (gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFullCanopy) /
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
            gddayfraction = (gvars[:crop].GDDaysToSenescence - gvars[:crop].GDDaysToFullCanopy) /
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
    ratdgdd = 1
    if gvars[:crop].ModeCycle == :GDDays
        if gvars[:crop].GDDaysToFullCanopySF < gvars[:crop].GDDaysToSenescence
            ratdgdd = (gvars[:crop].DaysToSenescence -
                       gvars[:crop].DaysToFullCanopySF) /
                      (gvars[:crop].GDDaysToSenescence -
                       gvars[:crop].GDDaysToFullCanopySF)
        end
    end
    # 13.1b DayCC for initial canopy cover
    dayi = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1
    if gvars[:crop].DaysToCCini == 0
        # sowing or transplant
        daycc = dayi
        setparameter!(gvars[:float_parameters], :dayfraction, undef_double)
    else
        # adjust time (calendar days) for regrowth
        daycc = dayi + gvars[:integer_parameters][:tadj] + gvars[:crop].DaysToGermination # adjusted time scale
        if daycc > gvars[:crop].DaysToHarvest
            daycc = gvars[:crop].DaysToHarvest # special case where L123 > L1234
        end
        if daycc > gvars[:crop].DaysToFullCanopy
            if dayi <= gvars[:crop].DaysToSenescence
                daycc = gvars[:crop].DaysToFullCanopy +
                        round(Int, gvars[:integer_parameters][:dayfraction] *
                                   (dayi + gvars[:integer_parameters][:tadj] + gvars[:crop].DaysToGermination -
                                    gvars[:crop].DaysToFullCanopy)) # slow down
            else
                daycc = dayi # switch time scale
            end
        end
    end
    # 13.1c SumGDDayCC for initial canopy cover
    sumgddfordaycc = undef_int
    if gvars[:crop].ModeCycle == :GDDays
        if gvars[:crop].GDDaysToCCini == 0
            sumgddfordaycc = gvars[:simulation].SumGDDfromDay1 - gvars[:float_parameters][:gddayi]
        else
            # adjust time (Growing Degree Days) for regrowth
            sumgddfordaycc = gvars[:simulation].SumGDDfromDay1 - gvars[:float_parameters][:gddayi] +
                             gvars[:integer_parameters][:gddtadj] + gvars[:crop].GDDaysToGermination
            if sumgddfordaycc > gvars[:crop].GDDaysToHarvest
                sumgddfordaycc = gvars[:crop].GDDaysToHarvest
                # special case where L123 > L1234
            end
            if sumgddfordaycc > gvars[:crop].GDDaysToFullCanopy
                if gvars[:simulation].SumGDDfromDay1 <= gvars[:crop].GDDaysToFullCanopy
                    sumgddfordaycc = gvars[:crop].GDDaysToFullCanopy +
                                     round(Int, gvars[:float_parameters][:gddayfraction] *
                                                (gvars[:simulation].SumGDDfromDay1 + gvars[:integer_parameters][:gddtadj] +
                                                 gvars[:crop].GDDaysToGermination - gvars[:crop].GDDaysToFullCanopy))
                    # slow down
                else
                    sumgddfordaycc = gvars[:simulation].SumGDDfromDay1 - gvars[:integer_parameters][:gddayi]
                    # switch time scale
                end
            end
        end
    end
    # 13.1d CCi at start of day (is CCi at end of previous day)
    if gvars[:integer_parameters][:daynri] <= gvars[:crop].Day1
        if gvars[:crop].DaysToCCini != 0
            # regrowth which starts on 1st day
            if gvars[:integer_parameters][:daynri] == gvars[:crop].Day1
                cciprev = cci_no_water_stress_sf(daycc,
                    gvars[:crop].DaysToGermination,
                    gvars[:crop].DaysToFullCanopySF,
                    gvars[:crop].DaysToSenescence, gvars[:crop].DaysToHarvest,
                    gvars[:crop].GDDaysToGermination,
                    gvars[:crop].GDDaysToFullCanopySF,
                    gvars[:crop].GDDaysToSenescence, gvars[:crop].GDDaysToHarvest,
                    gvars[:float_parameters][:ccototal], gvars[:float_parameters][:ccxtotal],
                    gvars[:crop].CGC,
                    gvars[:crop].GDDCGC, gvars[:float_parameters][:cdctotal],
                    gvars[:float_parameters][:gddcdctotal],
                    sumgddfordaycc, ratdgdd,
                    gvars[:simulation].EffectStress.RedCGC,
                    gvars[:simulation].EffectStress.RedCCX,
                    gvars[:simulation].EffectStress.CDecline, gvars[:crop].ModeCycle,
                    gvars[:simulation])
            else
                cciprev = 0.0
            end
            setparameter!(gvars[:float_parameters], :cciprev, cciprev)
        else
            # sowing or transplanting
            cciprev = 0.0
            setparameter!(gvars[:float_parameters], :cciprev, cciprev)
            if gvars[:integer_parameters][:daynri] == (gvars[:crop].Day1 + gvars[:crop].DaysToGermination)
                setparameter!(gvars[:float_parameters], :cciprev, gvars[:float_parameters][:ccototal])
            end
        end
    else
        if gvars[:integer_parameters][:daynri] > gvars[:crop].DayN
            # after cropping period
            cciprev = 0.0
        else
            cciprev = cci_no_water_stress_sf(daycc,
                gvars[:crop].DaysToGermination,
                gvars[:crop].DaysToFullCanopySF, gvars[:crop].DaysToSenescence,
                gvars[:crop].DaysToHarvest, gvars[:crop].GDDaysToGermination,
                gvars[:crop].GDDaysToFullCanopySF, gvars[:crop].GDDaysToSenescence,
                gvars[:crop].GDDaysToHarvest,
                gvars[:float_parameters][:ccototal], gvars[:float_parameters][:ccxtotal],
                gvars[:crop].CGC, gvars[:crop].GDDCGC,
                gvars[:float_parameters][:cdctotal],
                gvars[:float_parameters][:gddcdctotal],
                sumgddfordaycc, ratdgdd,
                gvars[:simulation].EffectStress.RedCGC,
                gvars[:simulation].EffectStress.RedCCX,
                gvars[:simulation].EffectStress.CDecline, gvars[:crop].ModeCycle,
                gvars[:simulation])
        end
        setparameter!(gvars[:float_parameters], :cciprev, cciprev)
    end
    # 13.2 specified CCini (%)
    if (gvars[:simulation].CCini > 0) &
       (round(Int, 10000 * gvars[:float_parameters][:cciprev]) > 0) &
       (round(Int, gvars[:simulation].CCini) != round(Int, 100 * gvars[:float_parameters][:cciprev]))
        # 13.2a Minimum CC
        ccinimin = 100 * (gvars[:crop].SizeSeedling / 10000) *
                   (gvars[:crop].PlantingDens / 10000)
        if (ccinimin - round(Int, ccinimin * 100) / 100) >= 0.00001
            ccinimin = round(Int, ccinimin * 100 + 1) / 100
        else
            ccinimin = round(Int, ccinimin * 100) / 100
        end
        # 13.2b Maximum CC
        ccinimax = 100 * gvars[:float_parameters][:cciprev]
        ccinimax = round(Int, ccinimax * 100) / 100
        # 13.2c accept specified CCini
        if (gvars[:simulation].CCini >= ccinimin) &
           (gvars[:simulation].CCini <= ccinimax)
            cciprev = gvars[:simulation].CCini / 100
            setparameter!(gvars[:float_parameters], :cciprev, cciprev)
        end
    end
    # 13.3
    gvars[:crop].CCxAdjusted = gvars[:float_parameters][:ccxtotal]
    gvars[:crop].CCoAdjusted = gvars[:float_parameters][:ccototal]
    gvars[:crop].CCxWithered = 0
    setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    setparameter!(gvars[:bool_parameters], :nomorecrop, false)
    setparameter!(gvars[:float_parameters], :cciactual, gvars[:float_parameters][:cciprev])

    # 14. Biomass and re-setting of GlobalZero
    if round(Int, 1000 * gvars[:simulation].Bini) > 0
        # overwrite settings in GlobalZero (in Global)
        gvars[:sumwabal].Biomass = gvars[:simulation].Bini
        gvars[:sumwabal].BiomassPot = gvars[:simulation].Bini
        gvars[:sumwabal].BiomassUnlim = gvars[:simulation].Bini
        gvars[:sumwabal].BiomassTot = gvars[:simulation].Bini
    end

    # 15. Transfer of assimilates
    if (gvars[:crop].subkind == :Forage) &
       # only valid for perennial herbaceous forage crops
       (strip(gvars[:string_parameters][:crop_file]) ==
        strip(gvars[:simulation].Storage.CropString)) &
       # only for the same crop
       (gvars[:simulation].YearSeason > 1) &
       # mobilization not possible in season 1
       (gvars[:simulation].YearSeason ==
        (gvars[:simulation].Storage.Season + 1))
        # season next to season in which storage took place
        # mobilization of assimilates
        if gvars[:simulation].YearSeason == 2
            gvars[:transfer].ToMobilize = gvars[:simulation].Storage.Btotal *
                                          0.2 * gvars[:crop].Assimilates.Mobilized / 100
        else
            gvars[:transfer].ToMobilize = gvars[:simulation].Storage.Btotal *
                                          gvars[:crop].Assimilates.Mobilized / 100
        end
        if round(Int, 1000 * gvars[:transfer].ToMobilize) > 0  # minimum 1 kg
            gvars[:transfer].Mobilize = true
        else
            gvars[:transfer].Mobilize = false
        end
    else
        gvars[:simulation].Storage.CropString = gvars[:string_parameters][:crop_file]
        # no mobilization of assimilates
        gvars[:transfer].ToMobilize = 0
        gvars[:transfer].Mobilize = false
    end
    # Storage is off and zero at start of season
    gvars[:simulation].Storage.Season = gvars[:simulation].YearSeason
    gvars[:simulation].Storage.Btotal = 0.0
    gvars[:transfer].Store = false
    # Nothing yet mobilized at start of season
    gvars[:transfer].Bmobilized = 0.0

    # 16. Initial rooting depth
    # 16.1 default value
    if gvars[:integer_parameters][:daynri] <= gvars[:crop].Day1
        setparameter!(gvars[:float_parameters], :ziprev, undef_double)
    else
        if gvars[:integer_parameters][:daynri] > gvars[:crop].DayN
            setparameter!(gvars[:float_parameters], :ziprev, undef_double)
        else
            #must set simulation.SCor = 1  before calling this function 
            gvars[:simulation].SCor = 1
            ziprev = actual_rooting_depth(
                gvars[:integer_parameters][:daynri] - gvars[:crop].Day1,
                gvars[:crop].DaysToGermination,
                gvars[:crop].DaysToMaxRooting,
                gvars[:crop].DaysToHarvest,
                gvars[:crop].GDDaysToGermination,
                gvars[:crop].GDDaysToMaxRooting,
                gvars[:float_parameters][:sumgddprev],
                gvars[:crop].RootMin,
                gvars[:crop].RootMax,
                gvars[:crop].RootShape,
                gvars[:crop].ModeCycle,
                gvars)
            setparameter!(gvars[:float_parameters], :ziprev, ziprev)
        end
    end
    # 16.2 specified or default Zrini (m)
    if (gvars[:simulation].Zrini > 0) &
       (gvars[:float_parameters][:ziprev] > 0) &
       (gvars[:simulation].Zrini <= gvars[:float_parameters][:ziprev])
        if (gvars[:simulation].Zrini >= gvars[:crop].RootMin) &
           (gvars[:simulation].Zrini <= gvars[:crop].RootMax)
            setparameter!(gvars[:float_parameters], :ziprev, gvars[:simulation].Zrini)
        else
            if gvars[:simulation].Zrini < gvars[:crop].RootMin
                setparameter!(gvars[:float_parameters], :ziprev, gvars[:crop].RootMin)
            else
                setparameter!(gvars[:float_parameters], :ziprev, gvars[:crop].RootMax)
            end
        end
        if (round(Int, gvars[:soil].RootMax * 1000) <
            round(Int, gvars[:crop].RootMax * 1000)) &
           (gvars[:float_parameters][:ziprev] > gvars[:soil].RootMax)
            setparameter!(gvars[:float_parameters], :ziprev, gvars[:soil].RootMax)
        end
        rooting_depth = gvars[:float_parameters][:ziprev]
        setparameter!(gvars[:float_parameters], :rooting_depth, rooting_depth)
        # NOT NEEDED since RootingDepth is calculated in the RUN by considering
        # Ziprev
    else
        gvars[:simulation].SCor = 1
        rooting_depth = actual_rooting_depth(
            gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1,
            gvars[:crop].DaysToGermination,
            gvars[:crop].DaysToMaxRooting,
            gvars[:crop].DaysToHarvest,
            gvars[:crop].GDDaysToGermination,
            gvars[:crop].GDDaysToMaxRooting,
            gvars[:float_parameters][:sumgddprev],
            gvars[:crop].RootMin,
            gvars[:crop].RootMax,
            gvars[:crop].RootShape,
            gvars[:crop].ModeCycle,
            gvars)
        setparameter!(gvars[:float_parameters], :rooting_depth, rooting_depth)
    end

    # 17. Multiple cuttings
    setparameter!(gvars[:integer_parameters], :nrcut, 0)
    setparameter!(gvars[:integer_parameters], :suminterval, 0)
    setparameter!(gvars[:integer_parameters], :daylastcut, 0)
    setparameter!(gvars[:float_parameters], :sumgddcuts, 0.0)
    setparameter!(gvars[:float_parameters], :bprevsum, 0.0)
    setparameter!(gvars[:float_parameters], :yprevsum, 0.0)
    setparameter!(gvars[:float_parameters], :cgcref, gvars[:crop].CGC)
    setparameter!(gvars[:float_parameters], :gddcgcref, gvars[:crop].GDDCGC)
    gvars[:cut_info_record1].IntervalInfo = 0
    gvars[:cut_info_record2].IntervalInfo = 0
    gvars[:cut_info_record1].MassInfo = 0
    gvars[:cut_info_record2].MassInfo = 0
    if gvars[:management].Cuttings.Considered
        open_harvest_info!(gvars, projectinput.ParentDir; kwargs...)
    end

    # 18. Tab sheets

    # 19. Labels, Plots and displays
    if gvars[:management].BundHeight < 0.01
        setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
        setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    end
    if gvars[:float_parameters][:rooting_depth] > 0
        # salinity in root zone
        determine_root_zone_salt_content!(gvars, gvars[:float_parameters][:rooting_depth])
        salt = ((gvars[:stresstot].NrD - 1) * gvars[:stresstot].Salt +
                100 * (1 - gvars[:root_zone_salt].KsSalt)) / gvars[:stresstot].NrD
        gvars[:stresstot].Salt = salt
    end

    # Harvest Index
    gvars[:simulation].HIfinal = gvars[:crop].HI
    setparameter!(gvars[:float_parameters], :hi_times_bef, undef_double)
    setparameter!(gvars[:float_parameters], :hi_times_at1, 1.0)
    setparameter!(gvars[:float_parameters], :hi_times_at2, 1.0)
    setparameter!(gvars[:float_parameters], :hi_times_at, 1.0)
    setparameter!(gvars[:float_parameters], :alfa_hi, undef_double)
    setparameter!(gvars[:float_parameters], :alfa_hi_adj, 0.0)
    if gvars[:simulation].FromDayNr <= (gvars[:simulation].DelayedDays +
                                        gvars[:crop].Day1 + gvars[:crop].DaysToFlowering)
        # not yet flowering
        setparameter!(gvars[:float_parameters], :scor_at1, 0.0)
        setparameter!(gvars[:float_parameters], :scor_at2, 0.0)
    else
        # water stress affecting leaf expansion
        # NOTE: time to reach end determinancy  is tHImax (i.e. flowering/2 or
        # senescence)
        if gvars[:crop].DeterminancyLinked
            thimax = round(Int, gvars[:crop].LengthFlowering / 2)
        else
            thimax = gvars[:crop].DaysToSenescence - gvars[:crop].DaysToFlowering
        end
        if (gvars[:simulation].FromDayNr <= (gvars[:simulation].DelayedDays +
                                             gvars[:crop].Day1 + gvars[:crop].DaysToFlowering + thimax)) & # not yet end period
           (thimax > 0)
            # not yet end determinancy
            scorat1 = (1 / thimax) * (gvars[:simulation].FromDayNr -
                                      (gvars[:simulation].DelayedDays + gvars[:crop].Day1 +
                                       gvars[:crop].DaysToFlowering))
            if scorat1 > 1
                setparameter!(gvars[:float_parameters], :scor_at1, 1.0)
            else
                setparameter!(gvars[:float_parameters], :scor_at1, scorat1)
            end
        else
            setparameter!(gvars[:float_parameters], :scor_at1, 1.0) # after period of effect
        end
        # water stress affecting stomatal closure
        # period of effect is yield formation
        if gvars[:crop].dHIdt > 99
            thimax = 0
        else
            thimax = round(Int, gvars[:crop].HI / gvars[:crop].dHIdt)
        end
        if (gvars[:simulation].FromDayNr <= (gvars[:simulation].DelayedDays +
                                             gvars[:crop].Day1 + gvars[:crop].DaysToFlowering + thimax)) & # not yet end period
           (thimax > 0)
            # not yet end yield formation
            scorat2 = (1 / thimax) * (gvars[:simulation].FromDayNr -
                                      (gvars[:simulation].DelayedDays + gvars[:crop].Day1 +
                                       gvars[:crop].DaysToFlowering))
            if scorat2 > 1
                setparameter!(gvars[:float_parameters], :scor_at2, 1.0)
            else
                setparameter!(gvars[:float_parameters], :scor_at2, scorat2)
            end
        else
            setparameter!(gvars[:float_parameters], :scor_at2, 1.0) # after period of effect
        end
    end

    if gvars[:bool_parameters][:outdaily]
        determine_growth_stage!(gvars, gvars[:integer_parameters][:daynri], gvars[:float_parameters][:cciprev])
    end

    # 20. Settings for start
    setparameter!(gvars[:bool_parameters], :startmode, true)
    setparameter!(gvars[:float_parameters], :stressleaf, undef_double)
    setparameter!(gvars[:float_parameters], :stresssenescence, undef_double)

    return nothing
end

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
            for i in gvars[:temperature_record].FromDayNr:(daynri-1)
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
                if dayx > tmin_dataset[31].DayNr
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, dayx,
                        (Tmin, Tmax),
                        gvars[:temperature_record])
                    i = 0
                end
                i = i + 1
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
                if dayx > tmin_dataset[31].DayNr
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, dayx,
                        (Tmin, Tmax),
                        gvars[:temperature_record])
                    i = 0
                end
                i = i + 1
                tmin = tmin_dataset[i].Param
                tmax = tmax_dataset[i].Param
                gvars[:simulation].SumGDD += degrees_day(gvars[:crop].Tbase,
                    gvars[:crop].Tupper,
                    tmin, tmax,
                    gvars[:simulparam].GDDMethod)
            end
        end
    end

    if gvars[:string_parameters][:temperature_file] == "(None)"
        dgrd = degrees_day(gvars[:crop].Tbase, gvars[:crop].Tupper,
            gvars[:simulparam].Tmin, gvars[:simulparam].Tmax,
            gvars[:simulparam].GDDMethod)
        sumgdd = (daynri - gvars[:crop].Day1 + 1) * dgrd
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
        dgrd = degrees_day(gvars[:crop].Tbase, gvars[:crop].Tupper,
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
        Irri_1 = gvars[:array_parameters][:Irri_1]
        Irri_2 = gvars[:array_parameters][:Irri_2]
        Irri_3 = gvars[:array_parameters][:Irri_3]
        Irri_4 = gvars[:array_parameters][:Irri_4]
        if irrimode == :Manual
            if gvars[:integer_parameters][:irri_first_daynr] == undef_int
                dnr = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
            else
                dnr = gvars[:integer_parameters][:daynri] - gvars[:integer_parameters][:irri_first_daynr] + 1
            end
            loopi = true
            while loopi
                if length(Irri_1) == 0
                    irri_info_record1.NoMoreInfo = true
                else
                    irri_info_record1.NoMoreInfo = false
                    ir1 = round(Int, popfirst!(Irri_1))
                    ir2 = round(Int, popfirst!(Irri_2))
                    irriecw = popfirst!(Irri_3)
                    gvars[:simulation].IrriECw = irriecw
                    irri_info_record1.TimeInfo = ir1
                    irri_info_record1.DepthInfo = ir2
                end
                if irri_info_record1.NoMoreInfo | (irri_info_record1.TimeInfo > dnr)
                    loopi = false
                end
            end
        elseif irrimode == :Generate
            irri_info_record1.NoMoreInfo = false
            fromday = round(Int, popfirst!(Irri_1))
            timeinfo = round(Int, popfirst!(Irri_1))
            depthinfo = round(Int, popfirst!(Irri_1))
            irriecw = popfirst!(Irri_4)
            irri_info_record1.FromDay = fromday
            irri_info_record1.TimeInfo = timeinfo
            irri_info_record1.DepthInfo = depthinfo
            gvars[:simulation].IrriECw = irriecw

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
        end
        setparameter!(gvars[:array_parameters], :Irri_1, Irri_1)
        setparameter!(gvars[:array_parameters], :Irri_2, Irri_2)
        setparameter!(gvars[:array_parameters], :Irri_3, Irri_3)
        setparameter!(gvars[:array_parameters], :Irri_4, Irri_4)
    end
    return nothing
end


"""
    zr = actual_rooting_depth(dap, l0, lzmax, l1234, gddl0, gddlzmax, 
                              sumgdd, zmin, zmax, shapefactor, typedays, gvars)

global.f90:7262
must set simulation.SCor = 1  before calling this function 
"""
function actual_rooting_depth(dap, l0, lzmax, l1234, gddl0, gddlzmax,
    sumgdd, zmin, zmax, shapefactor, typedays, gvars)
    soil_layers = gvars[:soil_layers]
    soil = gvars[:soil]

    if typedays == :GDDays
        zr = actual_rooting_depth_gddays(dap, l1234, gddl0, gddlzmax, sumgdd, zmin, zmax, shapefactor, gvars)
    else
        zr = actual_rooting_depth_days(dap, l0, lzmax, l1234, zmin, zmax, shapefactor, gvars)
    end

    # restrictive soil layer this is donw before calling this function
    # call SetSimulation_SCor(1._sp)

    rootmax_rounded = round(Int, soil.RootMax * 1000)
    zmax_rounded = round(Int, zmax * 1000)

    if rootmax_rounded < zmax_rounded
        zr = zr_adjusted_to_restrictive_layers(zr, soil_layers)
    end

    return zr
end

"""
    ardd = actual_rooting_depth_days(dap, l0, lzmax, l1234, zmin, zmax, shapefactor, gvars)

global.f90:7306
"""
function actual_rooting_depth_days(dap, l0, lzmax, l1234, zmin, zmax, shapefactor, gvars)
    simulation = gvars[:simulation]
    simulparam = gvars[:simulparam]

    # Actual rooting depth at the end of Dayi
    virtualday = dap - simulation.DelayedDays

    if (virtualday < 1) | (virtualday > l1234)
        ardd = 0
    elseif virtualday >= lzmax
        ardd = zmax
    elseif zmin < zmax
        zini = zmin * simulparam.RootPercentZmin / 100
        t0 = round(Int, l0 / 2)

        if lzmax <= t0
            zr = zini + (zmax - zini) * virtualday * 1 / lzmax
        elseif virtualday <= t0
            zr = zini
        else
            zr = zini + (zmax - zini) *
                        time_root_function(virtualday, shapefactor, lzmax, t0)
        end

        if zr > zmin
            ardd = zr
        else
            ardd = zmin
        end
    else
        ardd = zmax
    end
    return ardd
end

"""
    ardg = actual_rooting_depth_gddays(dap, l1234, gddl0, gddlzmax, sumgdd, zmin, zmax, shapefactor, gvars)

global.f90:7346
"""
function actual_rooting_depth_gddays(dap, l1234, gddl0, gddlzmax, sumgdd, zmin, zmax, shapefactor, gvars)
    simulation = gvars[:simulation]
    simulparam = gvars[:simulparam]

    # after sowing the crop has roots even when SumGDD = 0
    virtualday = dap - simulation.DelayedDays

    if (virtualday < 1) | (virtualday > l1234)
        ardg = 0
    elseif sumgdd >= gddlzmax
        ardg = zmax
    elseif zmin < zmax
        zini = zmin * simulparam.RootPercentZmin / 100
        gddt0 = gddl0 / 2

        if gddlzmax <= gddt0
            zr = zini + (zmax - zini) * sumgdd / gddlzmax
        else
            if sumgdd <= gddt0
                zr = zini
            else
                zr = zini + (zmax - zini) *
                            time_root_function(sumgdd, shapefactor, gddlzmax, gddt0)
            end
        end

        if zr > zmin
            ardg = zr
        else
            ardg = zmin
        end
    else
        ardg = zmax
    end

    return ardg
end

"""
    trf = time_root_function(t, shapefactor, tmax, t0)

global.f90:1263
"""
function time_root_function(t, shapefactor, tmax, t0)
    trf = exp((10 / shapefactor) * log((t - t0) / (tmax - t0)))
    return trf
end

"""
    open_harvest_info!(gvars, path; kwargs...)

run.f90:5937
"""
function open_harvest_info!(gvars, path; kwargs...)
    if gvars[:string_parameters][:man_file] != "(None)"
        if typeof(kwargs[:runtype]) == FortranRun
            man_file = gvars[:string_parameters][:man_file]
        else
            man_file = gvars[:string_parameters][:man_file][1:end-5] * ".csv"
        end
    else
        man_file = joinpath(path, "Cuttings.AqC")
    end

    Man = Float64[]
    Man_info = Float64[]
    open(man_file, "r") do file
        readline(file)
        if !endswith(man_file, ".csv")
            readline(file)
            if gvars[:string_parameters][:man_file] != "(None)"
                for i in 1:10
                    tempstring = readline(file) # management info
                end
            end
            for i in 1:12
                tempstring = readline(file)  # cuttings info (already loaded)
            end
        end
        # note that we read the whole file now, so when we call get_next_harvest! the file is already closed
        for line in eachline(file)
            if !gvars[:management].Cuttings.Generate
                push!(Man, parse(Float64, line))
            else
                splitedline = split(line)
                push!(Man, parse(Float64, popfirst!(splitedline)))
                push!(Man_info, parse(Float64, popfirst!(splitedline)))
            end
        end
    end
    setparameter!(gvars[:array_parameters], :Man, Man)
    setparameter!(gvars[:array_parameters], :Man_info, Man_info)

    get_next_harvest!(gvars)
    return nothing
end

"""
    get_next_harvest!(gvars)

run.f90:3670
"""
function get_next_harvest!(gvars)
    management = gvars[:management]
    cut_info_record1 = gvars[:cut_info_record1]
    cut_info_record2 = gvars[:cut_info_record2]
    crop = gvars[:crop]

    Man = gvars[:array_parameters][:Man]
    Man_info = gvars[:array_parameters][:Man_info]

    if !management.Cuttings.Generate
        if length(Man) > 0
            fromday = popfirst!(Man)
            cut_info_record1.FromDay = fromday
            cut_info_record1.NoMoreInfo = false
            if management.Cuttings.FirstDayNr != undef_int
                # scroll to start growing cycle
                daynrxx = management.Cuttings.FirstDayNr + cut_info_record1.FromDay - 1
                while (daynrxx < crop.Day1) & (cut_info_record1.NoMoreInfo == false)
                    if length(Man) > 0
                        fromday = popfirst!(Man)
                        cut_info_record1.FromDay = fromday
                        daynrxx = management.Cuttings.FirstDayNr + cut_info_record1.FromDay - 1
                    else
                        cut_info_record1.NoMoreInfo = true
                    end
                end
            end
        else
            cut_info_record1.NoMoreInfo = true
        end
    else
        if gvars[:integer_parameters][:nrcut] == 0
            if management.Cuttings.Criterion == :IntDay
                fromday = popfirst!(Man)
                intervalinfo = popfirst!(Man_info)
                cut_info_record1.FromDay = fromday
                cut_info_record1.IntervalInfo = round(Int, intervalinfo)
            elseif management.Cuttings.Criterion == :IntGDD
                fromday = popfirst!(Man)
                intervalgdd = popfirst!(Man_info)
                cut_info_record1.FromDay = fromday
                cut_info_record1.IntervalGDD = intervalgdd
            elseif (management.Cuttings.Criterion == :DryB) |
                   (management.Cuttings.Criterion == :DryY) |
                   (management.Cuttings.Criterion == :FreshY)
                fromday = popfirst!(Man)
                massinfo = popfirst!(Man_info)
                cut_info_record1.FromDay = fromday
                cut_info_record1.MassInfo = massinfo
            end
            if cut_info_record1.FromDay < management.Cuttings.Day1
                cut_info_record1.FromDay = management.Cuttings.Day1
            end
            infoloaded = false
        end
        while !infoloaded
            if length(Man) > 0
                if management.Cuttings.Criterion == :IntDay
                    fromday = popfirst!(Man)
                    intervalinfo = popfirst!(Man_info)
                    cut_info_record2.FromDay = fromday
                    cut_info_record2.IntervalInfo = round(Int, intervalinfo)
                elseif management.Cuttings.Criterion == :IntGDD
                    fromday = popfirst!(Man)
                    intervalgdd = popfirst!(Man_info)
                    cut_info_record2.FromDay = fromday
                    cut_info_record2.IntervalGDD = intervalgdd
                elseif (management.Cuttings.Criterion == :DryB) |
                       (management.Cuttings.Criterion == :DryY) |
                       (management.Cuttings.Criterion == :FreshY)
                    fromday = popfirst!(Man)
                    massinfo = popfirst!(Man_info)
                    cut_info_record2.FromDay = fromday
                    cut_info_record2.MassInfo = massinfo
                end
                if cut_info_record2.FromDay < management.Cuttings.Day1
                    cut_info_record2.FromDay = management.Cuttings.Day1
                end
                if cut_info_record2.FromDay <= cut_info_record1.FromDay
                    # CutInfoRecord2 becomes CutInfoRecord1
                    cut_info_record1.FromDay = cut_info_record2.FromDay
                    if management.Cuttings.Criterion == :IntDay
                        cut_info_record1.IntervalInfo = cut_info_record2.IntervalInfo
                    elseif management.Cuttings.Criterion == :IntGDD
                        cut_info_record1.IntervalGDD = cut_info_record2.IntervalGDD
                    elseif (management.Cuttings.Criterion == :DryB) |
                           (management.Cuttings.Criterion == :DryY) |
                           (management.Cuttings.Criterion == :FreshY)
                        cut_info_record1.MassInfo = cut_info_record2.MassInfo
                    end
                    cut_info_record1.NoMoreInfo = false
                else # complete CutInfoRecord1
                    cut_info_record1.ToDay = cut_info_record2.FromDay - 1
                    cut_info_record1.NoMoreInfo = false
                    if management.Cuttings.NrDays != undef_int
                        if cut_info_record1.ToDay > (management.Cuttings.Day1 + management.Cuttings.NrDays - 1)
                            cut_info_record1.ToDay = management.Cuttings.Day1 + management.Cuttings.NrDays - 1
                            cut_info_record1.NoMoreInfo = true
                        end
                    end
                    infoloaded = true
                end
            else
                if gvars[:integer_parameters][:nrcut] > 0 # CutInfoRecord2 becomes CutInfoRecord1
                    cut_info_record1.FromDay = cut_info_record2.FromDay
                    if management.Cuttings.Criterion == :IntDay
                        cut_info_record1.IntervalInfo = cut_info_record2.IntervalInfo
                    elseif management.Cuttings.Criterion == :IntGDD
                        cut_info_record1.IntervalGDD = cut_info_record2.IntervalGDD
                    elseif (management.Cuttings.Criterion == :DryB) |
                           (management.Cuttings.Criterion == :DryY) |
                           (management.Cuttings.Criterion == :FreshY)
                        cut_info_record1.MassInfo = cut_info_record2.MassInfo
                    end
                end
                cut_info_record1.ToDay = crop.DaysToHarvest
                if management.Cuttings.NrDays != undef_int
                    if cut_info_record1.ToDay > (management.Cuttings.Day1 + management.Cuttings.NrDays - 1)
                        cut_info_record1.ToDay = management.Cuttings.Day1 + management.Cuttings.NrDays - 1
                    end
                end
                cut_info_record1.NoMoreInfo = true
                infoloaded = true
            end
        end
    end
    setparameter!(gvars[:array_parameters], :Man, Man)
    setparameter!(gvars[:array_parameters], :Man_info, Man_info)
    return nothing
end

"""
    determine_root_zone_salt_content!(gvars, rootingdepth)

global.f90:4089
"""
function determine_root_zone_salt_content!(gvars, rootingdepth)
    compartments = gvars[:compartments]

    cumdepth = 0
    compi = 0
    zrece = 0
    zrecsw = 0
    zrecswfc = 0
    zrkssalt = 1
    if rootingdepth >= gvars[:crop].RootMin
        loopi = true
        while loopi
            compi = compi + 1
            cumdepth = cumdepth + compartments[compi].Thickness
            if cumdepth <= rootingdepth
                factor = 1
            else
                frac_value = rootingdepth - (cumdepth - compartments[compi].Thickness)
                if frac_value > 0
                    factor = frac_value / compartments[compi].Thickness
                else
                    factor = 0
                end
            end
            factor = factor * (compartments[compi].Thickness) / rootingdepth # weighting factor
            zrece = zrece + factor * ececomp(compartments[compi], gvars)
            zrecsw = zrecsw + factor * ecswcomp(compartments[compi], false, gvars) # not at FC
            zrecswfc = zrecswfc + factor * ecswcomp(compartments[compi], true, gvars) # at FC
            if (cumdepth >= rootingdepth) | (compi == length(compartments))
                loopi = false
            end
        end
        if (gvars[:crop].ECemin != undef_int) & (gvars[:crop].ECemax != undef_int) &
           (gvars[:crop].ECemin < gvars[:crop].ECemax)
            zrkssalt = ks_salinity(true, gvars[:crop].ECemin, gvars[:crop].ECemax, zrece, 0)
        else
            zrkssalt = ks_salinity(false, gvars[:crop].ECemin, gvars[:crop].ECemax, zrece, 0)
        end
    else
        zrece = undef_double
        zrecsw = undef_double
        zrecswfc = undef_double
        zrkssalt = undef_double
    end

    gvars[:root_zone_salt].ECe = zrece
    gvars[:root_zone_salt].ECsw = zrecsw
    gvars[:root_zone_salt].ECswFC = zrecswfc
    gvars[:root_zone_salt].KsSalt = zrkssalt

    return nothing
end


"""
    ecs = ecswcomp(compartment::CompartmentIndividual, atfc, gvars)

global.f90:2547
"""
function ecswcomp(compartment::CompartmentIndividual, atfc, gvars)
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]
    totsalt = 0
    for i in 1:soil_layers[compartment.Layer].SCP1
        totsalt = totsalt + compartment.Salt[i] + compartment.Depo[i] # g/m2
    end
    if atfc == true
        totsalt = totsalt / (soil_layers[compartment.Layer].FC * 10 * compartment.Thickness *
                             (1 - soil_layers[compartment.Layer].GravelVol / 100)) # g/l
    else
        totsalt = totsalt / (compartment.Theta * 1000 * compartment.Thickness *
                             (1 - soil_layers[compartment.Layer].GravelVol / 100)) # g/l
    end
    if totsalt > simulparam.SaltSolub
        totsalt = simulparam.SaltSolub
    end

    ecs = totsalt / equiv
    return ecs
end

"""
    m = ks_salinity(salinityresponsconsidered, ecen, ecex, ecevar, ksshapesalinity)

global.f90:2043
"""
function ks_salinity(salinityresponsconsidered, ecen, ecex, ecevar, ksshapesalinity)
    m = 1 # no correction applied
    if salinityresponsconsidered
        if (ecevar > ecen) & (ecevar < ecex)
            # within range for correction
            if (round(Int, ksshapesalinity * 10) != 0) &
               (round(Int, ksshapesalinity * 10) != 990)
                tmp_var = ecen
                m = ks_any(ecevar, tmp_var, ecex, ksshapesalinity)
                # convex or concave
            else
                if round(Int, ksshapesalinity * 10) == 0
                    m = 1 - (ecevar - ecen) / (ecex - ecen)
                    # linear (KsShapeSalinity = 0)
                else
                    m = ks_temperature(ecex, ecen, ecevar)
                    # logistic equation (KsShapeSalinity = 99)
                end
            end
        else
            if ecevar <= ecen
                m = 1  # no salinity stress
            end
            if ecevar >= ecex
                m = 0  # full salinity stress
            end
        end
    end
    if m > 1
        m = 1
    end
    if m < 0
        m = 0
    end

    return m
end

"""
    determine_growth_stage!(gvars, dayi, cciprev)

run.f90:4075
"""
function determine_growth_stage!(gvars, dayi, cciprev)
    crop = gvars[:crop]
    simulation = gvars[:simulation]

    virtualday = dayi - simulation.DelayedDays - crop.Day1
    if virtualday < 0
        # before cropping period
        setparameter!(gvars[:integer_parameters], :stagecode, 0)
    else
        if virtualday < crop.DaysToGermination
            # sown --> emergence OR transplant recovering
            setparameter!(gvars[:integer_parameters], :stagecode, 1)
        else
            # vegetative development
            setparameter!(gvars[:integer_parameters], :stagecode, 2)
            if (crop.subkind == :Grain) & (virtualday >= crop.DaysToFlowering)
                if virtualday < (crop.DaysToFlowering + crop.LengthFlowering)
                    # flowering
                    setparameter!(gvars[:integer_parameters], :stagecode, 3)
                else
                    # yield formation
                    setparameter!(gvars[:integer_parameters], :stagecode, 4)
                end
            end
            if (crop.subkind == :Tuber) & (virtualday >= crop.DaysToFlowering)
                # yield formation
                setparameter!(gvars[:integer_parameters], :stagecode, 4)
            end
            if (virtualday > crop.DaysToGermination) & (cciprev < eps())
                # no growth stage
                setparameter!(gvars[:integer_parameters], :stagecode, undef_int)
            end
            if virtualday >= sum(crop.Length[1:4])
                # after cropping period
                setparameter!(gvars[:integer_parameters], :stagecode, 0)
            end
        end
    end

    return nothing
end

