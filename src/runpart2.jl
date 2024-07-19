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
    GetSimulation_FromDayNr(), GetSimulation_ToDayNr())
    # climatic data for first day
    open_climfiles_and_get_data_firstday(GetDayNri())
end # notend

"""
    create_daily_climfiles(outputs, gvars; kwargs...)

run.f90:5592
"""
function create_daily_climfiles(outputs, gvars; kwargs...)
    simulation = gvars[:simulation]
    eto_record = gvars[:eto_record]

    fromsimday = simulation.FromDayNr
    tosimday = simulation.ToDayNr

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    eto_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    rain_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    # 1. ETo file
    if gvars[:string_parameters][:eto_file] != "(None)"
        if typeof(kwargs[:runtype]) == FortranRun
            totalname = gvars[:string_parameters][:eto_file]
        else
            totalname = gvars[:string_parameters][:eto_file][1:end-5]*".csv"
        end
        if isfile(totalname)
            # open file and find first day of simulation period
            if eto_record.DataType == :Daily
                open(totalname, "r") do file
                    readline(file)
                    if !endswith(totalname, ".csv")
                        readline(file)
                        readline(file)
                        readline(file)
                        readline(file)
                        readline(file)
                        readline(file)
                        readline(file)
                    end

                    for i in eto_record.FromDayNr:(fromsimday - 1)
                        readline(file)
                    end
                    eto = parse(Float64, readline(file))
                    setparameter!(gvars[:float_parameters], :eto, eto)
                end
            elseif eto_record.DataType == :Decadely
                get_decade_eto_dataset!(eto_dataset, fromsimday, totalname, eto_record)
                i = 1
                while eto_dataset[i].DayNr != fromsimday
                    i = i+1
                end
                eto = eto_dataset[i].Param
                setparameter!(gvars[:float_parameters], :eto, eto)
            elseif eto_record.DataType == :Monthly
                get_monthly_eto_dataset!(eto_dataset, fromsimday, totalname, eto_record)
                i = 1
                while eto_dataset[i].DayNr != fromsimday
                    i = i+1
                end
                eto = eto_dataset[i].Param
                setparameter!(gvars[:float_parameters], :eto, eto)
            end 

            # create SIM file and record first day
            totalnameOUT = GetPathNameSimul() // 'EToData.SIM'
            open(newunit=fEToS, file=trim(totalnameOUT), status='replace', &
                                                         action='write')
            write(fEToS, '(f10.4)') GetETo()
            # next days of simulation period
            for RunningDay = (FromSimDay + 1), ToSimDay
                select case (GetEToRecord_DataType())
                case(datatype_Daily)
                    if (rc == iostat_end) then
                        rewind(fETo)
                        read(fETo, *, iostat=rc) # description
                        read(fETo, *, iostat=rc) # time step
                        read(fETo, *, iostat=rc) # day
                        read(fETo, *, iostat=rc) # month
                        read(fETo, *, iostat=rc) # year
                        read(fETo, *, iostat=rc)
                        read(fETo, *, iostat=rc)
                        read(fETo, *, iostat=rc)
                        read(fETo, *) ETo_temp
                        call SetETo(ETo_temp)
                    else
                        read(fETo, *) ETo_temp
                        call SetETo(ETo_temp)
                    end
                case(datatype_Decadely)
                    if (RunningDay > GetEToDataSet_DayNr(31)) then
                        EToDataSet_temp = GetEToDataSet()
                        call GetDecadeEToDataSet(RunningDay, EToDataSet_temp)
                        call SetEToDataSet(EToDataSet_temp)
                    end
                    i = 1
                    while (GetEToDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end
                    call SetETo(GetEToDataSet_Param(i))
                case(datatype_Monthly)
                    if (RunningDay > GetEToDataSet_DayNr(31)) then
                        EToDataSet_temp = GetEToDataSet()
                        call GetMonthlyEToDataSet(RunningDay, EToDataSet_temp)
                        call SetEToDataSet(EToDataSet_temp)
                    end
                    i = 1
                    while (GetEToDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end
                    call SetETo(GetEToDataSet_Param(i))
                end select
                write(fEToS, '(f10.4)') GetETo()
            end
            # Close files
            if (GetEToRecord_DataType() == datatype_Daily) then
                close(fETo)
            end
            close(fEToS)
        end 
    end 

    # 2. Rain File
    if (GetRainFile() /= '(None)') then
        totalname = GetRainFilefull()
        if (FileExists(totalname)) then
            # open file and find first day of simulation period
            select case (GetRainRecord_DataType())
            case(datatype_Daily)
                open(newunit=fRain, file=trim(totalname), status='old', &
                                                          action='read')
                read(fRain, *, iostat=rc) # description
                read(fRain, *, iostat=rc) # time step
                read(fRain, *, iostat=rc) # day
                read(fRain, *, iostat=rc) # month
                read(fRain, *, iostat=rc) # year
                read(fRain, *, iostat=rc)
                read(fRain, *, iostat=rc)
                read(fRain, *, iostat=rc)
                for i = GetRainRecord_FromDayNr(), (FromSimDay - 1)
                    read(fRain, *, iostat=rc)
                end
                read(fRain, *, iostat=rc) tmpRain
                call SetRain(tmpRain)
            case(datatype_Decadely)
                RainDataSet_temp = GetRainDataSet()
                call GetDecadeRainDataSet(FromSimDay, RainDataSet_temp)
                call SetRainDataSet(RainDataSet_temp)
                i = 1
                while (GetRainDataSet_DayNr(i) /= FromSimDay)
                    i = i+1
                end
                call SetRain(GetRainDataSet_Param(i))
            case(datatype_Monthly)
                RainDataSet_temp = GetRainDataSet()
                call GetMonthlyRainDataSet(FromSimDay, RainDataSet_temp)
                call SetRainDataSet(RainDataSet_temp)
                i = 1
                while (GetRainDataSet_DayNr(i) /= FromSimDay)
                    i = i+1
                end 
                call SetRain(GetRainDataSet_Param(i))
            end select

            # create SIM file and record first day
            totalnameOUT = GetPathNameSimul() // 'RainData.SIM'
            open(newunit=fRainS, file=trim(totalnameOUT), status='replace', &
                                                          action='write')
            write(fRainS, '(f10.4)') GetRain()
            # next days of simulation period
            do RunningDay = (FromSimDay + 1), ToSimDay
                select case (GetRainRecord_DataType())
                case(datatype_daily)
                    if (rc == iostat_end) then
                        rewind(fRain)
                        read(fRain, *, iostat=rc) # description
                        read(fRain, *, iostat=rc) # time step
                        read(fRain, *, iostat=rc) # day
                        read(fRain, *, iostat=rc) # month
                        read(fRain, *, iostat=rc) # year
                        read(fRain, *, iostat=rc)
                        read(fRain, *, iostat=rc)
                        read(fRain, *, iostat=rc)
                        read(fRain, *, iostat=rc) tmpRain
                        call SetRain(tmpRain)
                    else
                        read(fRain, *, iostat=rc) tmpRain
                        call SetRain(tmpRain)
                    end
                case(datatype_Decadely)
                    if (RunningDay > GetRainDataSet_DayNr(31)) then
                        RainDataSet_temp = GetRainDataSet()
                        call GetDecadeRainDataSet(RunningDay, RainDataSet_temp)
                        call SetRainDataSet(RainDataSet_temp)
                    end
                    i = 1
                    while (GetRainDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end
                    call SetRain(GetRainDataSet_Param(i))
                case(datatype_monthly)
                    if (RunningDay > GetRainDataSet_DayNr(31)) then
                        RainDataSet_temp = GetRainDataSet()
                        call GetMonthlyRainDataSet(RunningDay, RainDataSet_temp)
                        call SetRainDataSet(RainDataSet_temp)
                    end
                    i = 1
                    while (GetRainDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end
                    call SetRain(GetRainDataSet_Param(i))
                end select
                write(fRainS, '(f10.4)') GetRain()
            end 
            # Close files
            if (GetRainRecord_DataType() == datatype_Daily) then
                close(fRain)
            end 
            close(fRainS)
        end 
    end 

    # 3. Temperature file
    if (GetTemperatureFile() /= '(None)') then
        totalname = GetTemperatureFilefull()
        if (FileExists(totalname)) then
            # open file and find first day of simulation period
            select case (GetTemperatureRecord_DataType())
            case(datatype_daily)
                open(newunit=fTemp, file=trim(totalname), status='old', &
                                                          action='read')
                read(fTemp, *, iostat=rc) # description
                read(fTemp, *, iostat=rc) # time step
                read(fTemp, *, iostat=rc) # day
                read(fTemp, *, iostat=rc) # month
                read(fTemp, *, iostat=rc) # year
                read(fTemp, *, iostat=rc)
                read(fTemp, *, iostat=rc)
                read(fTemp, *, iostat=rc)
                for i = GetTemperatureRecord_FromDayNr(), (FromSimDay - 1)
                    read(fTemp, *, iostat=rc)
                end
                read(fTemp, '(a)', iostat=rc) StringREAD  # i.e. DayNri
                Tmin_temp = GetTmin()
                Tmax_temp = GetTmax()
                call SplitStringInTwoParams(StringREAD, Tmin_temp, Tmax_temp)
                call SetTmin(Tmin_temp)
                call SetTmax(Tmax_temp)
            case(datatype_Decadely)
                TminDataSet_temp = GetTminDataSet()
                TmaxDataSet_temp = GetTmaxDataSet()
                call GetDecadeTemperatureDataSet(FromSimDay, TminDataSet_temp, &
                                                              TmaxDataSet_temp)
                call SetTminDataSet(TminDataSet_temp)
                call SetTmaxDataSet(TmaxDataSet_temp)
                i = 1
                while (GetTminDataSet_DayNr(i) /= FromSimDay)
                    i = i+1
                end
                call SetTmin(GetTminDataSet_Param(i))
                call SetTmax(GetTmaxDataSet_Param(i))
            case(datatype_Monthly)
                TminDataSet_temp = GetTminDataSet()
                TmaxDataSet_temp = GetTmaxDataSet()
                call GetMonthlyTemperatureDataSet(FromSimDay, TminDataSet_temp, &
                                                              TmaxDataSet_temp)
                call SetTminDataSet(TminDataSet_temp)
                call SetTmaxDataSet(TmaxDataSet_temp)
                i = 1
                while (GetTminDataSet_DayNr(i) /= FromSimDay)
                    i = i+1
                end
                call SetTmin(GetTminDataSet_Param(i))
                call SetTmax(GetTmaxDataSet_Param(i))
            end select

            # create SIM file and record first day
            totalnameOUT = GetPathNameSimul() // 'TempData.SIM'
            open(newunit=fTempS, file=trim(totalnameOUT), status='replace', &
                                                          action='write')
            write(fTempS, '(2f10.4)') GetTmin(), GetTmax()
            # next days of simulation period
            for RunningDay = (FromSimDay + 1), ToSimDay
                select case (GetTemperatureRecord_Datatype())
                case(datatype_Daily)
                    if (rc == iostat_end) then
                        rewind(fTemp)
                        read(fTemp, *, iostat=rc) # description
                        read(fTemp, *, iostat=rc) # time step
                        read(fTemp, *, iostat=rc) # day
                        read(fTemp, *, iostat=rc) # month
                        read(fTemp, *, iostat=rc) # year
                        read(fTemp, *, iostat=rc)
                        read(fTemp, *, iostat=rc)
                        read(fTemp, *, iostat=rc)
                        read(fTemp, '(a)', iostat=rc) StringREAD
                        Tmin_temp = GetTmin()
                        Tmax_temp = GetTmax()
                        call SplitStringInTwoParams(StringREAD, Tmin_temp, &
                                                                Tmax_temp)
                        call SetTmin(Tmin_temp)
                        call SetTmax(Tmax_temp)
                    else
                        read(fTemp, *, iostat=rc) Tmin_temp, Tmax_temp
                        call SetTmin(Tmin_temp)
                        call SetTmax(Tmax_temp)
                    end 
                case(datatype_Decadely)
                    if (RunningDay > GetTminDataSet_DayNr(31)) then
                        TminDataSet_temp = GetTminDataSet()
                        TmaxDataSet_temp = GetTmaxDataSet()
                        call GetDecadeTemperatureDataSet(RunningDay, &
                                                         TminDataSet_temp, &
                                                         TmaxDataSet_temp)
                        call SetTminDataSet(TminDataSet_temp)
                        call SetTmaxDataSet(TmaxDataSet_temp)
                    end 
                    i = 1
                    while (GetTminDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end
                    call SetTmin(GetTminDataSet_Param(i))
                    call SetTmax(GetTmaxDataSet_Param(i))
                case(datatype_Monthly)
                    if (RunningDay > GetTminDataSet_DayNr(31)) then
                        TminDataSet_temp = GetTminDataSet()
                        TmaxDataSet_temp = GetTmaxDataSet()
                        call GetMonthlyTemperatureDataSet(RunningDay, &
                                                          TminDataSet_temp, &
                                                          TmaxDataSet_temp)
                        call SetTminDataSet(TminDataSet_temp)
                        call SetTmaxDataSet(TmaxDataSet_temp)
                    end 
                    i = 1
                    while (GetTminDataSet_DayNr(i) /= RunningDay)
                        i = i+1
                    end 
                    call SetTmin(GetTminDataSet_Param(i))
                    call SetTmax(GetTmaxDataSet_Param(i))
                end select
                write(fTempS, '(2f10.4)') GetTmin(), GetTmax()
            end 
            # Close files
            if (GetTemperatureRecord_datatype() == datatype_Daily) then
                close(fTemp)
            end 
            close(fTempS)
        end 
    end 
end #notend


"""
    get_decade_eto_dataset!(eto_dataset, daynri, eto_file, eto_record::RepClim)

climprocessing.f90:325
"""
function get_decade_eto_dataset!(eto_dataset, daynri, eto_file, eto_record::RepClim)
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
    c1, c2, c3 = get_set_of_three(Val(1){}, dayn, deci, monthi, yeari, eto_file, eto_record)
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
    c1, c2, c3 = get_set_of_three(val::Val{1}, dayn, deci, monthi, yeari, eto_file, eto_record::RepClim)

climprocessing.f90:393
"""
function get_set_of_three(val::Val{1}, dayn, deci, monthi, yeari, eto_file, eto_record::RepClim)
    # 1 = previous decade, 2 = Actual decade, 3 = Next decade;
    open(eto_file, "r") do file
        readline(file)
        if !endswith(eto_file, ".csv")
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
        end


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

        if eto_record.NrObs <= 2
            c1 = parse(Float64, readline(file))
            # OJO for some reason this ==1 and ==2 are different for temperature get_set_of_three
            if eto_record.NrObs==1
                c2 = c1
                c3 = c1
            elseif eto_record.NrObs==2
                decfile += 1
                if decfile>3
                    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
                end
                c1 = parse(Float64, readline(file))
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
            c1 = parse(Float64, readline(file))
            c2 = c1
            c3 = parse(Float64, readline(file))
            c1 = c2 + (c2-c3)/4
            ok3 = true
        end

        if (!ok3) & (dayn==eto_record.ToD) & (monthi==eto_record.ToM)
            if (eto_record.FromY==1901) | (yeari==eto_record.ToY)
                for Nri in 1:(eto_record.NrObs-2)
                    readline(file)
                end 
                c1 = parse(Float64, readline(file)) 
                c2 = parse(Float64, readline(file)) 
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
                readline(file)
            end 
            c1 = parse(Float64, readline(file)) 
            c2 = parse(Float64, readline(file)) 
            c3 = parse(Float64, readline(file)) 
        end 
    end 

    return c1, c2, c3
end

"""
    get_monthly_eto_dataset!(eto_dataset, daynri, eto_file, eto_record::RepClim)

climprocessing.f90:87
"""
function get_monthly_eto_dataset!(eto_dataset, daynri, eto_file, eto_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)
    c1, c2, c3, x1, x2, x3, t1 = get_set_of_three_months(Val(1){}, monthi, yeari, eto_file, eto_record)

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
    c1, c2, c3, x1, x2, x3, t1 = get_set_of_three_months(val::Val{1}, monthi, yeari, eto_file, eto_record)

climprocessing.f90:128
"""
function get_set_of_three_months(val::Val{1}, monthi, yeari, eto_file, eto_record)
    ni = 30

    # 1. Prepare record
    open(eto_file, "r") do file
        readline(file)
        if !endswith(eto_file, ".csv")
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
            readline(file)
        end

        mfile = eto_record.FromM
        if eto_record.FromY==1901
            yfile = yeari
        else
            yfile = eto_record.FromY
        end
        ok3 = false

        # 2. IF 3 or less records
        if eto_record.NrObs <= 3
            c1 = parse(Float64, readline(file))
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
                c3 = parse(Float64, readline(file))
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
                c2 = parse(Float64, readline(file))
                c2 = c2 * ni
                x2 = x1 + ni
                if monthi==mfile 
                    t1 = x1
                end 
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
                c3 = parse(Float64, readline(file))
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
            c1 = parse(Float64, readline(file))
            c1 = c1 * ni
            x1 = ni
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2 = parse(Float64, readline(file))
            c2 = c2 * ni
            x2 = x1 + ni
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3 = parse(Float64, readline(file))
            c3 = c3 * ni
            x3 = x2 + ni
            ok3 = true
        end 

        # 4. If last observation
        if (!ok3) & (monthi==eto_record.ToM)
            if (eto_record.FromY==1901) | (yeari==eto_record.ToY)
                for nri in 1:(eto_record.NrObs-3)
                    readline(file)
                    mfile = mfile + 1
                    if mfile>12 
                        mfile, yfile = adjust_month_and_year(mfile, yfile)
                    end 
                end 
                c1 = parse(Float64, readline(file))
                c1 = c1 * ni
                x1 = ni
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
                c2 = parse(Float64, readline(file))
                c2 = c2 * ni
                x2 = x1 + ni
                t1 = x2
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
                c3 = parse(Float64, readline(file))
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
                readline(file)
                mfile = mfile + 1
                if (mfile > 12) 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end
            end
            c1 = parse(Float64, readline(file))
            c1 = c1 * ni
            x1 = ni
            t1 = x1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2 = parse(Float64, readline(file))
            c2 = c2 * ni
            x2 = x1 + ni
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3 = parse(Float64, readline(file))
            c3 = c3 * ni
            x3 = x2 + ni
        end 
    end

    return c1, c2, c3, x1, x2, x3, t1
end
