"""
    load_simulation_project!(outputs, gvars, projectinput::ProjectInputType; kwargs...) 

tempprocessing.f90:1932
"""
function load_simulation_project!(outputs, gvars, projectinput::ProjectInputType; kwargs...) 
    # 0. Year of cultivation and Simulation and Cropping period
    gvars[:simulation].YearSeason = projectinput.Simulation_YearSeason
    gvars[:crop].Day1 = projectinput.Crop_Day1
    gvars[:crop].DayN = projectinput.Crop_DayN

    # 1.1 Temperature
    if (projectinput.Temperature_Filename=="(None)") | (projectinput.Temperature_Filename=="(External)")
        temperature_file = projectinput.Temperature_Filename 
    else
        _temperature_file = joinpath([projectinput.ParentDir, projectinput.Temperature_Directory, projectinput.Temperature_Filename])
        if typeof(kwargs[:runtype]) == NormalFileRun
            temperature_file = _temperature_file
            setparameter!(gvars[:bool_parameters], :temperature_file_exists, isfile(temperature_file))
        elseif typeof(kwargs[:runtype]) == TomlFileRun 
            temperature_file = _temperature_file[1:end-5]*".csv"
            setparameter!(gvars[:bool_parameters], :temperature_file_exists, isfile(temperature_file))
        elseif typeof(kwargs[:runtype]) == NoFileRun
            temperature_file = ""
            if haskey(kwargs, :Tmin) & haskey(kwargs, :Tmax)
                setparameter!(gvars[:bool_parameters], :temperature_file_exists, true) 
            end
        end
        if gvars[:bool_parameters][:temperature_file_exists]
            read_temperature_file!(gvars[:array_parameters], temperature_file; kwargs...)
        end
        load_clim!(gvars[:temperature_record], _temperature_file;
                   nrobs=length(gvars[:array_parameters][:Tmin]),
                   str="temperature_record", kwargs...)
    end 
    setparameter!(gvars[:string_parameters], :temperature_file, temperature_file)

    # 1.2 ETo
    if (projectinput.ETo_Filename=="(None)") | (projectinput.ETo_Filename=="(External)")
        eto_file = projectinput.ETo_Filename 
    else
        _eto_file = joinpath([projectinput.ParentDir, projectinput.ETo_Directory, projectinput.ETo_Filename])
        if typeof(kwargs[:runtype]) == NormalFileRun
            eto_file = _eto_file
            setparameter!(gvars[:bool_parameters], :eto_file_exists, isfile(eto_file))
        elseif typeof(kwargs[:runtype]) == TomlFileRun 
            eto_file = _eto_file[1:end-5]*".csv"
            setparameter!(gvars[:bool_parameters], :eto_file_exists, isfile(eto_file))
        elseif typeof(kwargs[:runtype]) == NoFileRun
            eto_file = ""
            if haskey(kwargs, :ETo) 
                setparameter!(gvars[:bool_parameters], :eto_file_exists, true) 
            end
        end
        if gvars[:bool_parameters][:eto_file_exists]
            read_eto_file!(gvars[:array_parameters], eto_file; kwargs...)
        end
        load_clim!(gvars[:eto_record], _eto_file;
                   nrobs=length(gvars[:array_parameters][:ETo]),
                   str="eto_record", kwargs...)
    end 
    setparameter!(gvars[:string_parameters], :eto_file, eto_file)

    # 1.3 Rain
    if (projectinput.Rain_Filename=="(None)") | (projectinput.Rain_Filename=="(External)")
        rain_file = projectinput.Rain_Filename
    else
        _rain_file = joinpath([projectinput.ParentDir, projectinput.Rain_Directory, projectinput.Rain_Filename])
        if typeof(kwargs[:runtype]) == NormalFileRun
            rain_file = _rain_file
            setparameter!(gvars[:bool_parameters], :rain_file_exists, isfile(rain_file))
        elseif typeof(kwargs[:runtype]) == TomlFileRun 
            rain_file = _rain_file[1:end-5]*".csv"
            setparameter!(gvars[:bool_parameters], :rain_file_exists, isfile(rain_file))
        elseif typeof(kwargs[:runtype]) == NoFileRun
            rain_file = ""
            if haskey(kwargs, :Rain) 
                setparameter!(gvars[:bool_parameters], :rain_file_exists, true) 
            end
        end
        if gvars[:bool_parameters][:rain_file_exists]
            read_rain_file!(gvars[:array_parameters], rain_file; kwargs...)
        end
        load_clim!(gvars[:rain_record], _rain_file;
                   nrobs=length(gvars[:array_parameters][:Rain]),
                   str="rain_record", kwargs...)
    end 
    setparameter!(gvars[:string_parameters], :rain_file, rain_file)
    

    # 1.4 CO2 and Climate
    if projectinput.CO2_Filename != "(None)"
        co2_file = joinpath([projectinput.ParentDir, projectinput.CO2_Directory, projectinput.CO2_Filename])
        setparameter!(gvars[:string_parameters], :CO2_file, co2_file)
    end
    if projectinput.Climate_Filename != "(External)"
        set_clim_data!(gvars, projectinput)
    end
    adjust_onset_search_period!(gvars) # Set initial StartSearch and StopSearchDayNr

    # 3. Crop
    gvars[:simulation].LinkCropToSimPeriod = true
    crop_file = joinpath([projectinput.ParentDir, projectinput.Crop_Directory, projectinput.Crop_Filename])
    load_crop!(gvars[:crop], gvars[:perennial_period], crop_file; kwargs...)
    # copy to CropFileSet
    gvars[:crop_file_set].DaysFromSenescenceToEnd = gvars[:crop].DaysToHarvest - gvars[:crop].DaysToSenescence
    gvars[:crop_file_set].DaysToHarvest = gvars[:crop].DaysToHarvest
    if gvars[:crop].ModeCycle==:GDDays
        gvars[:crop_file_set].GDDaysFromSenescenceToEnd = gvars[:crop].GDDaysToHarvest - gvars[:crop].GDDaysToSenescence
        gvars[:crop_file_set].GDDaysToHarvest = gvars[:crop].GDDaysToHarvest
    else
        gvars[:crop_file_set].GDDaysFromSenescenceToEnd = undef_int
        gvars[:crop_file_set].GDDaysToHarvest = undef_int 
    end
    # maximum rooting depth in given soil profile
    gvars[:soil].RootMax = root_max_in_soil_profile(gvars[:crop].RootMax, gvars[:soil_layers])

    # Adjust crop parameters of Perennials
    if gvars[:crop].subkind==:Forage
        # adjust crop characteristics to the Year (Seeding/Planting or
        # Non-seesing/Planting year)
        adjust_year_perennials!(gvars[:crop], gvars[:simulation].YearSeason)
        # adjust length of season
        gvars[:crop].DaysToHarvest = gvars[:crop].DayN - gvars[:crop].Day1 + 1
        adjust_crop_file_parameters!(gvars)
    end 
    adjust_calendar_crop!(gvars)
    complete_crop_description!(gvars[:crop], gvars[:simulation], gvars[:management])
    # Onset.Off := true;
    clim_file = gvars[:string_parameters][:clim_file]
    if clim_file=="(None)" 
        # adjusting Crop.Day1 and Crop.DayN to ClimFile
        adjust_crop_year_to_climfile!(gvars[:crop], clim_file, gvars[:clim_record])
    else
        gvars[:crop].DayN = gvars[:crop].Day1 + gvars[:crop].DaysToHarvest - 1
    end 

    # adjusting ClimRecord.'TO' for undefined year with 365 days
    if (clim_file != "(None)") & (gvars[:clim_record].FromY == 1901) & (gvars[:clim_record].NrObs==365) 
        adjust_climrecord_to!(gvars[:clim_record], gvars[:crop].DayN)
    end 
    # adjusting simulation period
    adjust_simperiod!(gvars, projectinput)

    # 4. Irrigation
    if projectinput.Irrigation_Filename == "(None)" 
        irri_file = projectinput.Irrigation_Filename
        no_irrigation!(gvars)
    else
        irri_file = joinpath([projectinput.ParentDir, projectinput.Irrigation_Directory, projectinput.Irrigation_Filename])
        load_irri_schedule_info!(gvars, irri_file)
    end 
    setparameter!(gvars[:string_parameters], :irri_file, irri_file)

    # 5. Field Management
    if projectinput.Management_Filename == "(None)" 
        man_file = projectinput.Management_Filename
    else
        man_file = joinpath([projectinput.ParentDir, projectinput.Management_Directory, projectinput.Management_Filename])
        load_management!(gvars, man_file; kwargs...)
        # reset canopy development to soil fertility
        daystofullcanopy, RedCGC_temp, RedCCX_temp, fertstress = time_to_max_canopy_sf(
                              gvars[:crop].CCo, 
                              gvars[:crop].CGC,
                              gvars[:crop].CCx,
                              gvars[:crop].DaysToGermination,
                              gvars[:crop].DaysToFullCanopy,
                              gvars[:crop].DaysToSenescence,
                              gvars[:crop].DaysToFlowering,
                              gvars[:crop].LengthFlowering,
                              gvars[:crop].DeterminancyLinked,
                              gvars[:crop].DaysToFullCanopySF, 
                              gvars[:simulation].EffectStress.RedCGC,
                              gvars[:simulation].EffectStress.RedCCX,
                              gvars[:management].FertilityStress)
        gvars[:management].FertilityStress = fertstress
        gvars[:simulation].EffectStress.RedCGC = RedCGC_temp
        gvars[:simulation].EffectStress.RedCCX = RedCCX_temp
        gvars[:crop].DaysToFullCanopySF = daystofullcanopy
    end 
    setparameter!(gvars[:string_parameters], :man_file, man_file)

    # 6. Soil Profile
    if projectinput.Soil_Filename=="(External)"
        prof_file = projectinput.Soil_Filename
    elseif projectinput.Soil_Filename=="(None)"
        if typeof(kwargs[:runtype]) == NormalFileRun 
            prof_file = joinpath([test_dir, "SIMUL", "DEFAULT.SOL"])
        elseif typeof(kwargs[:runtype]) == TomlFileRun 
            prof_file = joinpath( test_toml_dir, "gvars.toml")
        elseif typeof(kwargs[:runtype]) == NoFileRun
            prof_file = joinpath( projectinput.ParentDir, "")
        end
    else
        # The load of profile is delayed to check if soil water profile need to be reset (see 8.)
        prof_file = joinpath([projectinput.ParentDir, projectinput.Soil_Directory, projectinput.Soil_Filename])
    end 
    setparameter!(gvars[:string_parameters], :prof_file, prof_file)


    # 7. Groundwater
    if projectinput.GroundWater_Filename=="(None)"
        groundwater_file = projectinput.GroundWater_Filename
    else
        # Loading the groundwater is done after loading the soil profile (see 9.)
        groundwater_file = joinpath([projectinput.ParentDir, projectinput.GroundWater_Directory, projectinput.GroundWater_Filename])
    end 
    setparameter!(gvars[:string_parameters], :groundwater_file, groundwater_file)

    # 8. Set simulation period
    gvars[:simulation].FromDayNr = projectinput.Simulation_DayNr1
    gvars[:simulation].ToDayNr = projectinput.Simulation_DayNrN
    if (gvars[:crop].Day1 != gvars[:simulation].FromDayNr) | (gvars[:crop].DayN != gvars[:simulation].ToDayNr)
        gvars[:simulation].LinkCropToSimPeriod = false
    end 

    # 9. Initial conditions
    if projectinput.SWCIni_Filename=="KeepSWC"
        # No load of soil file (which reset thickness compartments and Soil
        # water content to FC)
        swcini_file = projectinput.SWCIni_Filename
    else
        # start with load and complete profile description (see 5.) which reset
        # SWC to FC by default
        if prof_file=="(External)"
            load_profile_processing!(gvars[:soil], gvars[:soil_layers], gvars[:compartments], gvars[:simulparam])
        else
            soil, soil_layers, compartments = load_profile(outputs, prof_file, gvars[:simulparam]; kwargs...)
            gvars[:soil] = soil
            gvars[:soil_layers] = soil_layers
            gvars[:compartments] = compartments
        end 
        gvars[:soil].RootMax = root_max_in_soil_profile(gvars[:crop].RootMax, gvars[:soil_layers])
        complete_profile_description!(gvars[:soil_layers], gvars[:compartments], gvars[:simulation], gvars[:total_water_content]) 

        # Adjust size of compartments if required
        totdepth = 0
        for i in eachindex(gvars[:compartments]) 
            totdepth = totdepth + gvars[:compartments][i].Thickness
        end 
        if gvars[:simulation].MultipleRunWithKeepSWC
            # Project with a sequence of simulation runs and KeepSWC
            if round(Int, gvars[:simulation].MultipleRunConstZrx*1000)>round(Int, totdepth*1000) 
                adjust_size_compartments!(gvars, gvars[:simulation].MultipleRunConstZrx)
            end 
        else
            if round(Int, gvars[:crop].RootMax*1000)>round(Int, totdepth*1000)
                if round(Int, gvars[:soil].RootMax*1000)==round(Int, gvars[:crop].RootMax*1000)
                    # no restrictive soil layer
                    adjust_size_compartments!(gvars, gvars[:crop].RootMax)
                else
                    # restrictive soil layer
                    if round(Int, gvars[:soil].RootMax*1000)>round(Int, totdepth*1000)
                        adjust_size_compartments!(gvars, gvars[:soil].RootMax)
                    end 
                end 
            end
        end 

        if projectinput.SWCIni_Filename=="(None)"
            swcini_file = projectinput.SWCIni_Filename
        else
            swcini_file = projectinput.ParentDir * projectinput.SWCIni_Directory * projectinput.SWCIni_Filename
            load_initial_conditions!(gvars, swcini_file)
        end 
        setparameter!(gvars[:string_parameters], :swcini_file, swcini_file)

        if gvars[:simulation].IniSWC.AtDepths
            translate_inipoints_to_swprofile!(gvars, gvars[:simulation].IniSWC.NrLoc, gvars[:simulation].IniSWC.Loc, gvars[:simulation].IniSWC.VolProc, gvars[:simulation].IniSWC.SaltECe)
        else
            translate_inilayers_to_swprofile!(gvars, gvars[:simulation].IniSWC.NrLoc, gvars[:simulation].IniSWC.Loc, gvars[:simulation].IniSWC.VolProc, gvars[:simulation].IniSWC.SaltECe)
        end

        if gvars[:simulation].ResetIniSWC
            # to reset SWC and SALT at end of simulation run
            for i in eachindex(gvars[:compartments])
                gvars[:simulation].ThetaIni[i] = gvars[:compartments][i].Theta
                gvars[:simulation].ECeIni[i] = ececomp(gvars[:compartments][i], gvars)
            end 
            # ADDED WHEN DESINGNING 4.0 BECAUSE BELIEVED TO HAVE FORGOTTEN -
            # CHECK LATER
            if gvars[:management].BundHeight>=0.01
                gvars[:simulation].SurfaceStorageIni = gvars[:float_parameters][:surfacestorage]
                gvars[:simulation].ECStorageIni = gvars[:float_parameters][:ecstorage]
            end 
        end 
    end 

    # 10. load the groundwater file if it exists (only possible for Version 4.0
    # and higher)
    if groundwater_file != "(None)"
        load_groundwater!(gvars, groundwater_file)
    else
        setparameter!(gvars[:integer_parameters],:ziaqua, undef_int)
        setparameter!(gvars[:float_parameters],:eciaqua, undef_double)
        gvars[:simulparam].ConstGwt = true
    end
    calculate_adjusted_fc!(gvars[:compartments], gvars[:soil_layers], gvars[:integer_parameters][:ziaqua]/100)
    if gvars[:simulation].IniSWC.AtFC & (swcini_file != "KeepSWC")
        reset_swc_to_fc!(gvars[:simulation], gvars[:compartments], gvars[:soil_layers], gvars[:integer_parameters][:ziaqua])
    end 

    # 11. Off-season conditions
    if projectinput.OffSeason_Filename=="(None)"
        offseason_file = projectinput.OffSeason_Filename
    else
        offseason_file = joinpath([projectinput.ParentDir, projectinput.OffSeason_Directory, projectinput.OffSeason_Filename])
        load_offseason!(gvars, offseason_file)
    end 
    setparameter!(gvars[:string_parameters], :offseason_file, offseason_file)

    # 12. Field data
    if projectinput.Observations_Filename=="(None)"
        observations_file = projectinput.Observations_Filename
    else
        observations_file = joinpath([projectinput.ParentDir, projectinput.Observations_Directory, projectinput.Observations_Filename])
    end
    setparameter!(gvars[:string_parameters], :observations_file, observations_file)

    return nothing
end 

"""
    read_temperature_file!(array_parameters::ParametersContainer{T}, temperature_file) where T

tempprocessing.f90:307
"""
function read_temperature_file!(array_parameters::ParametersContainer{T}, temperature_file; kwargs...) where T
    return _read_temperature_file!(kwargs[:runtype], array_parameters, temperature_file; kwargs...) 
end


function _read_temperature_file!(runtype::NormalFileRun, array_parameters::ParametersContainer{T}, temperature_file; kwargs...) where T
    Tmin = Float64[] 
    Tmax = Float64[]
    
    open(temperature_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        for line in eachline(file)
            splitedline = split(line)
            
            tmin = parse(Float64,popfirst!(splitedline))
            tmax = parse(Float64,popfirst!(splitedline))
            push!(Tmin, tmin)
            push!(Tmax, tmax)
        end
    end

    setparameter!(array_parameters, :Tmin, Tmin)
    setparameter!(array_parameters, :Tmax, Tmax)

    return nothing
end

function _read_temperature_file!(runtype::TomlFileRun, array_parameters::ParametersContainer{T}, temperature_file; kwargs...) where T
    Tmin = Float64[] 
    Tmax = Float64[]
    
    open(temperature_file, "r") do file
        readline(file)

        for line in eachline(file)
            splitedline = split(line)
            
            tmin = parse(Float64,popfirst!(splitedline))
            tmax = parse(Float64,popfirst!(splitedline))
            push!(Tmin, tmin)
            push!(Tmax, tmax)
        end
    end

    setparameter!(array_parameters, :Tmin, Tmin)
    setparameter!(array_parameters, :Tmax, Tmax)

    return nothing
end

function _read_temperature_file!(runtype::NoFileRun, array_parameters::ParametersContainer{T}, temperature_file; kwargs...) where T
    setparameter!(array_parameters, :Tmin, kwargs[:Tmin])
    setparameter!(array_parameters, :Tmax, kwargs[:Tmax])
    return nothing
end

function read_eto_file!(array_parameters::ParametersContainer{T}, eto_file; kwargs...) where T
    return _read_eto_file!(kwargs[:runtype], array_parameters, eto_file; kwargs...) 
end

function _read_eto_file!(runtype::NormalFileRun, array_parameters::ParametersContainer{T}, eto_file; kwargs...) where T
    ETo = Float64[] 
    
    open(eto_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        for line in eachline(file)
            eto = parse(Float64, line)
            push!(ETo, eto)
        end
    end

    setparameter!(array_parameters, :ETo, ETo)
    return nothing
end

function _read_eto_file!(runtype::TomlFileRun, array_parameters::ParametersContainer{T}, eto_file; kwargs...) where T
    ETo = Float64[] 
    
    open(eto_file, "r") do file
        readline(file)

        for line in eachline(file)
            eto = parse(Float64, line)
            push!(ETo, eto)
        end
    end

    setparameter!(array_parameters, :ETo, ETo)
    return nothing
end

function _read_eto_file!(runtype::NoFileRun, array_parameters::ParametersContainer{T}, eto_file; kwargs...) where T
    setparameter!(array_parameters, :ETo, kwargs[:ETo])
    return nothing
end

function read_rain_file!(array_parameters::ParametersContainer{T}, rain_file; kwargs...) where T
    return _read_rain_file!(kwargs[:runtype], array_parameters, rain_file; kwargs...) 
end

function _read_rain_file!(runtype::NormalFileRun, array_parameters::ParametersContainer{T}, rain_file; kwargs...) where T
    Rain = Float64[] 
    
    open(rain_file, "r") do file
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        readline(file)

        for line in eachline(file)
            rain = parse(Float64, line)
            push!(Rain, rain)
        end
    end

    setparameter!(array_parameters, :Rain, Rain)
    return nothing
end

function _read_rain_file!(runtype::TomlFileRun, array_parameters::ParametersContainer{T}, rain_file; kwargs...) where T
    Rain = Float64[] 
    
    open(rain_file, "r") do file
        readline(file)

        for line in eachline(file)
            rain = parse(Float64, line)
            push!(Rain, rain)
        end
    end

    setparameter!(array_parameters, :Rain, Rain)
    return nothing
end

function _read_rain_file!(runtype::NoFileRun, array_parameters::ParametersContainer{T}, rain_file; kwargs...) where T
    setparameter!(array_parameters, :Rain, kwargs[:Rain])
    return nothing
end

"""
    load_clim!(record::RepClim, clim_file; kwargs...)

global.f90:5936
"""
function load_clim!(record::RepClim, clim_file; kwargs...)
    _load_clim!(kwargs[:runtype], record, clim_file; kwargs...)
    return nothing
end

function _load_clim!(runtype::NormalFileRun, record::RepClim, clim_file; kwargs...)
    if isfile(clim_file)
        open(clim_file, "r") do file
            readline(file)
            ni = parse(Int,split(readline(file))[1])
            if ni == 1
                record.Datatype = :Daily
            elseif ni == 2
                record.Datatype = :Decadely
            else
                record.Datatype = :Monthly
            end
            record.FromD = parse(Int,split(readline(file))[1]) 
            record.FromM = parse(Int,split(readline(file))[1]) 
            record.FromY = parse(Int,split(readline(file))[1]) 
            record.NrObs = kwargs[:nrobs]
        end
        complete_climate_description!(record)
    end
    return nothing
end

function _load_clim!(runtype::T, record::RepClim, clim_file; kwargs...) where T<:TomlFileRun
    if isfile(clim_file)
        load_gvars_from_toml!(record, clim_file; kwargs...) 
        record.NrObs = kwargs[:nrobs]
        complete_climate_description!(record)
    end
    return nothing
end

function _load_clim!(runtype::T, record::RepClim, clim_file; kwargs...) where T<:NoFileRun
    set_clim_record!(record; kwargs...)
    record.NrObs = kwargs[:nrobs]
    complete_climate_description!(record)
    return nothing
end

"""
    complete_climate_description!(record::RepClim)

global.f90:8223
"""
function complete_climate_description!(record::RepClim)
    record.FromDayNr = determine_day_nr(record.FromD, record.FromM, record.FromY)
    if record.Datatype == :Daily
        record.ToDayNr = record.FromDayNr + record.NrObs - 1
        record.ToD, record.ToM, record.ToY = determine_date(record.ToDayNr)
    elseif record.Datatype == :Decadely
        deci = round(Int, (record.FromD+9)/10) + record.NrObs - 1
        record.ToM = record.FromM
        record.ToY = record.FromY
        while (deci > 3)
            deci = deci - 3
            record.ToM = record.ToM + 1
            if (record.ToM > 12)
                record.ToM = 1
                record.ToY = record.ToY  + 1
            end
        end 
        record.ToD = 10
        if (deci == 2) 
            record.ToD = 20
        end 
        if (deci == 3) 
            record.ToD = DaysInMonth[record.ToM]
            if (record.ToM == 2) & isleapyear(record.ToY) 
                record.ToD = record.ToD + 1
            end 
        end 
        record.ToDayNr =  determine_day_nr(record.ToD, record.ToM, record.ToY)
    elseif record.Datatype == :Monthly
        record.ToY = record.FromY
        record.ToM = record.FromM + record.NrObs - 1
        while (record.ToM > 12)
            record.ToY = record.ToY + 1
            record.ToM = record.ToM - 12
        end
        record.ToD = DaysInMonth[record.ToM]
        if (record.ToM == 2) & isleapyear(record.ToY) 
            record.ToD = record.ToD + 1
        end 
        record.ToDayNr = determine_day_nr(record.ToD, record.ToM, record.ToY)
    end 
    return nothing
end

"""
    set_clim_data!(gvars, projectinput::ProjectInputType)

global.f90:4295
"""
function set_clim_data!(gvars, projectinput::ProjectInputType)
    clim_record = gvars[:clim_record]
    temperature_record = gvars[:temperature_record]
    eto_record = gvars[:eto_record]
    rain_record = gvars[:rain_record]
    clim_file = gvars[:string_parameters][:clim_file]
    eto_file = projectinput.ETo_Filename
    rain_file = projectinput.Rain_Filename
    temperature_file = projectinput.Temperature_Filename

    # Part A - ETo and Rain files --> ClimFile
    if ((eto_file == "(None)") & (rain_file == "(None)")) 
        clim_file = "(None)"
        clim_record.Datatype =:Daily
        clim_record.FromString = "any date"
        clim_record.ToString = "any date"
        clim_record.FromY = 1901
    else
        clim_file = "EToRainTempFile"
        if (eto_file == "(None)") 
            clim_record.FromY = rain_record.FromY
            clim_record.FromDayNr = rain_record.FromDayNr
            clim_record.ToDayNr = rain_record.ToDayNr
            clim_record.FromString = rain_record.FromString
            clim_record.ToString = rain_record.ToString
            if full_undefined_record(rain_record)
                clim_record.NrObs = 365
            end
        elseif (rain_file == "(None)") 
            clim_record.FromY = eto_record.FromY
            clim_record.FromDayNr = eto_record.FromDayNr
            clim_record.ToDayNr = eto_record.ToDayNr
            clim_record.FromString = eto_record.FromString
            clim_record.ToString = eto_record.ToString
            if full_undefined_record(eto_record)
                clim_record.NrObs = 365
            end
        else
            if full_undefined_record(eto_record) & full_undefined_record(rain_record) 
                clim_record.NrObs = 365
            end 

            if (eto_record.FromY == 1901) & (rain_record.FromY != 1901)
                eto_record.FromY = rain_record.FromY
                eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
                if (eto_record.FromDayNr < rain_record.FromDayNr) & (rain_record.FromY < rain_record.ToY)
                    eto_record.FromY = rain_record.FromY + 1
                    eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
                end
                clim_record = eto_record.FromY
                if full_undefined_record(eto_record)
                    eto_record.ToY = rain_record.ToY
                else
                    eto_record.ToY = eto_record.FromY
                end 
                eto_record.FromDayNr = determine_day_nr(eto_record.FromD, eto_record.FromM, eto_record.FromY)
            end 

            if (eto_record.FromY != 1901) & (rain_record.FromY == 1901)
                rain_record.FromY = eto_record.FromY
                rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
                if (rain_record.FromDayNr < eto_record.FromDayNr) & (eto_record.FromY < eto_record.ToY)
                    rain_record.FromY = eto_record.FromY + 1
                    rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
                end
                clim_record.FromY = rain_record.FromY
                if full_undefined_record(rain_record)
                    rain_record.ToY = eto_record.ToY
                else
                    rain_record.ToY = rain_record.FromY
                end 
                rain_record.FromDayNr = determine_day_nr(rain_record.FromD, rain_record.FromM, rain_record.FromY)
            end 
            # ! bepaal characteristieken van ClimRecord
            clim_record.FromY = eto_record.FromY
            clim_record.FromDayNr = eto_record.FromDayNr
            if clim_record.FromDayNr < rain_record.FromDayNr
                clim_record.FromY = rain_record.FromY
                clim_record.FromDayNr = rain_record.FromDayNr
            end
            clim_record.ToDayNr = eto_record.ToDayNr
            if clim_record.ToDayNr > rain_record.ToDayNr
                clim_record.ToDayNr = rain_record.ToDayNr
            end 
            if clim_record.ToDayNr < clim_record.FromDayNr
                clim_file = "(None)"
                clim_record.NrObs = 0
                clim_record.FromY = 1901
            end 
        end 
    end 

    # Part B - ClimFile and Temperature files --> ClimFile
    if (temperature_file != "(None)") 
        if clim_file == "(None)"
            clim_file = "EToRainTempFile"
            clim_record.FromY = temperature_record.FromY
            clim_record.FromDayNr = temperature_record.FromDayNr
            clim_record.ToDayNr = temperature_record.ToDayNr
            if full_undefined_record(temperature_record)
                clim_record.NrObs = 365
            else
                clim_record.NrObs = temperature_record.ToDayNr - temperature_record.FromDayNr + 1
            end
        else
            clim_record.FromD, clim_record.FromM, clim_record.FromY = determine_date(clim_record.FromDayNr)
            clim_record.ToD, clim_record.ToM, clim_record.ToY = determine_date(clim_record.ToDayNr)
            if (clim_record.FromY == 1901) & (full_undefined_record(temperature_record))
                clim_record.NrObs = 365
            else
                clim_record.NrObs = temperature_record.ToDayNr - temperature_record.FromDayNr + 1
            end 
            
            if (clim_record.FromY == 1901) & (temperature_record != 1901)
                clim_record.FromY = temperature_record.FromY
                clim_record.FromDayNr = determine_day_nr(clim_record.FromD, clim_record.FromM, clim_record.FromY)
                if (clim_record.FromDayNr < temperature_record.FromDayNr) & (temperature_record.FromY < temperature_record.ToY)
                    clim_record.FromY = temperature_record.FromY + 1
                    clim_record.FromDayNr = determine_day_nr(clim_record.FromD, clim_record.FromM, clim_record.FromY)
                end 
                if full_undefined_record(clim_record)
                    clim_record.ToY = temperature_record.ToY
                else
                    clim_record.ToY = clim_record.FromY
                end
                clim_record.ToDayNr = determine_day_nr(clim_record.ToD, clim_record.ToM, clim_record.ToY)
            end 

            if (clim_record.FromY != 1901) & (temperature_record == 1901)
                temperature_record.FromY = clim_record.FromY
                temperature_record.FromDayNr = determine_day_nr(temperature_record.FromD, temperature_record.FromM, temperature_record.FromY)
                if (temperature_record.FromDayNr < clim_record.FromDayNr) & (clim_record.FromY < clim_record.ToY)
                    temperature_record.FromY = clim_record.FromY + 1
                    temperature_record.FromDayNr = determine_day_nr(temperature_record.FromD, temperature_record.FromM, temperature_record.FromY)
                end 
                if full_undefined_record(temperature_record)
                    temperature_record.ToY = clim_record.ToY
                else
                    temperature_record.ToY = temperature_record.FromY
                end
                temperature_record.ToDayNr = determine_day_nr(temperature_record.ToD, temperature_record.ToM, temperature_record.ToY)
            end 

            # ! bepaal nieuwe characteristieken van ClimRecord
            if clim_record.FromDayNr < temperature_record.FromDayNr
                clim_record.FromY = temperature_record.FromY
                clim_record.FromDayNr = temperature_record.FromDayNr
            end
            if clim_record.ToDayNr > temperature_record.ToDayNr
                clim_record.ToDayNr = temperature_record.ToDayNr
            end
            if clim_record.ToDayNr < clim_record.FromDayNr
                clim_file = "(None)"
                clim_record.NrObs = 0
                clim_record.FromY = 1901
            end
        end 
    end 

    setparameter!(gvars[:string_parameters], :clim_file, clim_file)
    return nothing
end


"""
    logi = full_undefined_record(record::RepClim)

global.f90:2826
"""
function full_undefined_record(record::RepClim)
    fromy = record.FromY
    fromd = record.FromD
    fromm = record.FromM
    tod = record.ToD
    tom = record.ToM
    return ((fromy == 1901) & (fromd == 1) & (fromm == 1) & (tod == 31) & (tom == 12))
end


"""
    adjust_onset_search_period!(gvars)

global.f90:4214
"""
function adjust_onset_search_period!(gvars)
    onset = gvars[:onset]
    simulation = gvars[:simulation]
    clim_file = gvars[:string_parameters][:clim_file]
    clim_record = gvars[:clim_record]

    if clim_file=="(None)"
        onset.StartSearchDayNr = 1
        onset.StopSearchDayNr = onset.StartSearchDayNr + onset.LengthSearchPeriod + 1
    else
        onset.StartSearchDayNr = determine_day_nr(1, 1, simulation.YearStartCropCycle) # January 1st
        if onset.StartSearchDayNr < clim_record.FromDayNr
            onset.StartSearchDayNr = clim_record.FromDayNr
        end
        onset.StopSearchDayNr = onset.StartSearchDayNr + onset.LengthSearchPeriod - 1
        if onset.StopSearchDayNr > clim_record.ToDayNr
            onset.StopSearchDayNr = clim_record.ToDayNr
            onset.LengthSearchPeriod = onset.StopSearchDayNr - onset.StartSearchDayNr + 1
        end 
    end 

    return nothing
end

"""
    load_crop!(crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file; kwargs...)

global.f90:4799
"""
function load_crop!(crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file; kwargs...)
    _load_crop!(kwargs[:runtype], crop, perennial_period, crop_file; kwargs...)
    return nothing
end

function _load_crop!(runtype::NormalFileRun, crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file; kwargs...)
    open(crop_file, "r") do file
        readline(file)
        readline(file)
        readline(file)

        # subkind
        xx = parse(Int, split(readline(file))[1])
        if xx==1
            crop.subkind = :Vegetative
        elseif xx==2
            crop.subkind = :Grain
        elseif xx==3 
            crop.subkind = :Tuber
        elseif xx==4
            crop.subkind = :Forage
        end

        # type of planting
        xx = parse(Int, split(readline(file))[1])
        if xx==1
            crop.Planting = :Seed
        elseif xx==0
            crop.Planting = :Transplat
        elseif xx==-9
            crop.Planting = :Regrowth
        else
            crop.Planting = :Seed
        end

        # mode
        xx = parse(Int, split(readline(file))[1])
        if xx==0
            crop.ModeCycle = :GDDays
        else
            crop.ModeCycle = :CalendarDays
        end

        # adjustment p to ETo
        xx = parse(Int, split(readline(file))[1])
        if xx==0
            crop.pMethod = :NoCorrection
        elseif xx==1
            crop.pMethod = :FAOCorrection
        end

        # temperatures controlling crop development
        crop.Tbase = parse(Float64, split(readline(file))[1])
        crop.Tupper = parse(Float64, split(readline(file))[1])

        # required growing degree days to complete the crop cycle
        # (is identical as to maturity)
        crop.GDDaysToHarvest = parse(Float64, split(readline(file))[1])

        # water stress
        crop.pLeafDefUL = parse(Float64, split(readline(file))[1])
        crop.pLeafDefLL = parse(Float64, split(readline(file))[1])
        crop.KsShapeFactorLeaf = parse(Float64, split(readline(file))[1])
        crop.pdef = parse(Float64, split(readline(file))[1])
        crop.KsShapeFactorStomata = parse(Float64, split(readline(file))[1])
        crop.pSenescence = parse(Float64, split(readline(file))[1])
        crop.KsShapeFactorSenescence = parse(Float64, split(readline(file))[1])
        crop.SumEToDelaySenescence = parse(Float64, split(readline(file))[1])
        crop.pPollination = parse(Float64, split(readline(file))[1])
        crop.AnaeroPoint = parse(Int, split(readline(file))[1])

        # soil fertility/salinity stress
        # Soil fertility stress at calibration (%)
        crop.StressResponse.Stress = parse(Int, split(readline(file))[1])
        # Shape factor for the response of Canopy
        # Growth Coefficient to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCGC = parse(Float64, split(readline(file))[1])
        # Shape factor for the response of Maximum
        # Canopy Cover to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCCX = parse(Float64, split(readline(file))[1])
        # Shape factor for the response of Crop
        # Water Producitity to soil
        # fertility stress
        crop.StressResponse.ShapeWP = parse(Float64, split(readline(file))[1])
        # Shape factor for the response of Decline
        # of Canopy Cover to soil
        # fertility/salinity stress
        crop.StressResponse.ShapeCDecline = parse(Float64, split(readline(file))[1])

        readline(file)

        # continue with soil fertility/salinity stress
        if ((crop.StressResponse.ShapeCGC>24.9) & (crop.StressResponse.ShapeCCX>24.9) &
            (crop.StressResponse.ShapeWP>24.9) & (crop.StressResponse.ShapeCDecline>24.9))
            crop.StressResponse.Calibrated = false
        else
            crop.StressResponse.Calibrated = true 
        end

        # temperature stress
        # Minimum air temperature below which
        # pollination starts to fail
        # (cold stress) (degC)
        crop.Tcold = parse(Int, split(readline(file))[1])
        # Maximum air temperature above which
        # pollination starts to fail
        # eat stress) (degC)
        crop.Theat = parse(Int, split(readline(file))[1])
        # Minimum growing degrees required for full
        # biomass production (degC - day)
        crop.GDtranspLow = parse(Float64, split(readline(file))[1])

        # salinity stress (Version 3.2 and higher)
        # upper threshold ECe
        crop.ECemin = parse(Int, split(readline(file))[1])
        # lower threhsold ECe
        crop.ECemax = parse(Int, split(readline(file))[1])
        readline(file)

        crop.CCsaltDistortion = parse(Int, split(readline(file))[1])
        crop.ResponseECsw = parse(Int, split(readline(file))[1])

        # evapotranspiration
        crop.KcTop = parse(Float64, split(readline(file))[1])
        crop.KcDecline = parse(Float64, split(readline(file))[1])
        crop.RootMin = parse(Float64, split(readline(file))[1])
        crop.RootMax = parse(Float64, split(readline(file))[1])
        if crop.RootMin > crop.RootMax
            crop.RootMin = crop.RootMax
        end
        crop.RootShape = parse(Int, split(readline(file))[1])
        crop.SmaxTopQuarter = parse(Float64, split(readline(file))[1])
        crop.SmaxBotQuarter = parse(Float64, split(readline(file))[1])
        crop.SmaxTop, crop.SmaxBot = derive_smax_top_bottom(crop)
        crop.CCEffectEvapLate = parse(Int, split(readline(file))[1])

        # crop development
        crop.SizeSeedling = parse(Float64, split(readline(file))[1])
        # Canopy size of individual plant
        # (re-growth) at 1st day (cm2)
        crop.SizePlant = parse(Float64, split(readline(file))[1])

        crop.PlantingDens = parse(Int, split(readline(file))[1])
        crop.CCo = crop.PlantingDens/10000 * crop.SizeSeedling/10000
        crop.CCini = crop.PlantingDens/10000 * crop.SizePlant/10000

        crop.CGC = parse(Float64, split(readline(file))[1])

        # Number of years at which CCx declines
        # to 90 % of its value due to
        # self-thinning - for Perennials
        crop.YearCCx = parse(Int, split(readline(file))[1])
        # Shape factor of the decline of CCx over
        # the years due to self-thinning
        # for Perennials
        crop.CCxRoot = parse(Float64, split(readline(file))[1])

        readline(file)

        crop.CCx = parse(Float64, split(readline(file))[1])
        crop.CDC = parse(Float64, split(readline(file))[1])
        crop.DaysToGermination = parse(Int, split(readline(file))[1])
        crop.DaysToMaxRooting = parse(Int, split(readline(file))[1])
        crop.DaysToSenescence = parse(Int, split(readline(file))[1])
        crop.DaysToHarvest = parse(Int, split(readline(file))[1])
        crop.DaysToFlowering = parse(Int, split(readline(file))[1])
        crop.LengthFlowering = parse(Int, split(readline(file))[1])

        if (crop.subkind==:Vegetative) | (crop.subkind==:Forage)
            crop.DaysToFlowering = 0
            crop.LengthFlowering = 0
        end

        # Crop.DeterminancyLinked
        xx = parse(Int, split(readline(file))[1])
        if xx==1
            crop.DeterminancyLinked = true
        else
            crop.DeterminancyLinked = false
        end

        # Potential excess of fruits (%) and building up HI
        if (crop.subkind==:Vegetative) | (crop.subkind==:Forage)
            readline(file)
            crop.fExcess = undef_int
        else
            crop.fExcess = parse(Int, split(readline(file))[1])
        end
        crop.DaysToHIo = parse(Int, split(readline(file))[1])

        # yield response to water
        crop.WP = parse(Float64, split(readline(file))[1])
        crop.WPy = parse(Int, split(readline(file))[1])
        # adaptation to elevated CO2 (Version 3.2 and higher)
        crop.AdaptedToCO2 = parse(Int, split(readline(file))[1])
        crop.HI = parse(Int, split(readline(file))[1])
        # possible increase (%) of HI due
        # to water stress before flowering
        crop.HIincrease = parse(Int, split(readline(file))[1])
        # coefficient describing impact of
        # restricted vegetative growth at
        # flowering on HI
        crop.aCoeff = parse(Float64, split(readline(file))[1])
        # coefficient describing impact of
        # stomatal closure at flowering on HI
        crop.bCoeff = parse(Float64, split(readline(file))[1])
        # allowable maximum increase (%) of
        # specified HI
        crop.DHImax = parse(Int, split(readline(file))[1])

        # growing degree days
        crop.GDDaysToGermination = parse(Int, split(readline(file))[1])
        crop.GDDaysToMaxRooting = parse(Int, split(readline(file))[1])
        crop.GDDaysToSenescence = parse(Int, split(readline(file))[1])
        crop.GDDaysToHarvest = parse(Int, split(readline(file))[1])
        crop.GDDaysToFlowering = parse(Int, split(readline(file))[1])
        crop.GDDLengthFlowering = parse(Int, split(readline(file))[1])
        crop.GDDCGC = parse(Float64, split(readline(file))[1])
        crop.GDDCDC = parse(Float64, split(readline(file))[1])
        crop.GDDaysToHIo = parse(Float64, split(readline(file))[1])

        # leafy vegetable crop has an Harvest Index which builds up
        # starting from sowing
        if (crop.ModeCycle==:GDDays) & ((crop.subkind==:Vegetative) | (crop.subkind==:Forage))
            crop.GDDaysToFlowering = 0
            crop.GDDLengthFlowering = 0
        end

        # dry matter content (%)
        # of fresh yield
        crop.DryMatter = parse(Int, split(readline(file))[1])

        # Minimum rooting depth in first
        # year in meter (for regrowth)
        crop.RootMinYear1 = parse(Float64, split(readline(file))[1])

        xx = parse(Int, split(readline(file))[1])
        if xx==1
            # crop is sown in 1 st year
            # (for perennials)
            crop.SownYear1 = true
        else
            # crop is transplanted in
            # 1st year (for regrowth)
            crop.SownYear1 = false
        end

        # transfer of assimilates
        xx = parse(Int, split(readline(file))[1])
        if xx==1
            # Transfer of assimilates from
            # above ground parts to root
            # system is considered
            crop.Assimilates.On = true
        else
            # Transfer of assimilates from
            # above ground parts to root
            # system is NOT considered
            crop.Assimilates.On = false 
        end
        # Number of days at end of season
        # during which assimilates are
        # stored in root system
        crop.Assimilates.Period = parse(Int, split(readline(file))[1])
        # Percentage of assimilates,
        # transferred to root system
        # at last day of season
        crop.Assimilates.Stored = parse(Int, split(readline(file))[1])
        # Percentage of stored
        # assimilates, transferred to above
        # ground parts in next season
        crop.Assimilates.Mobilized = parse(Int, split(readline(file))[1])

        if crop.subkind==:Forage
            # data for the determination of the growing period
            # 1. Title
            readline(file)
            readline(file)
            readline(file)
            # 2. ONSET
            xx = parse(Int, split(readline(file))[1])
            if xx==0
                perennial_period.GenerateOnset = false
            else
                perennial_period.GenerateOnset = true
                if xx==12
                    perennial_period.OnsetCriterion = :TMeanPeriod
                elseif xx==13
                    perennial_period.OnsetCriterion = :GDDPeriod
                else
                    perennial_period.GenerateOnset = false
                end
            end
            
            perennial_period.OnsetFirstDay = parse(Int, split(readline(file))[1])
            perennial_period.OnsetFirstMonth = parse(Int, split(readline(file))[1])
            perennial_period.OnsetLengthSearchPeriod = parse(Int, split(readline(file))[1])
            # Mean air temperature
            # or Growing-degree days
            perennial_period.OnsetThresholdValue = parse(Float64, split(readline(file))[1])
            # number of succesive days
            perennial_period.OnsetPeriodValue = parse(Int, split(readline(file))[1])
            # number of occurrence
            perennial_period.OnsetOccurrence = parse(Int, split(readline(file))[1])
            if perennial_period.OnsetOccurrence > 3
                perennial_period.OnsetOccurrence = 3
            end
            
            # 3. END of growing period
            xx = parse(Int, split(readline(file))[1])
            if xx==0
                # end is fixed on a
                # specific day
                perennial_period.GenerateEnd = false
            else
                # end is generated by an air temperature criterion
                perennial_period.GenerateEnd = true
                if xx==62
                    # Criterion: mean air temperature
                    perennial_period.EndCriterion = :TMeanPeriod
                elseif xx==63
                    # Criterion: growing-degree days
                    perennial_period.EndCriterion = :GDDPeriod
                else
                    perennial_period.GenerateEnd = false
                end
            end

            perennial_period.EndLastDay = parse(Int, split(readline(file))[1])
            perennial_period.EndLastMonth = parse(Int, split(readline(file))[1])
            perennial_period.ExtraYears = parse(Int, split(readline(file))[1])
            perennial_period.EndLengthSearchPeriod = parse(Int, split(readline(file))[1])
            # Mean air temperature
            # or Growing-degree days
            perennial_period.EndThresholdValue = parse(Float64, split(readline(file))[1])
            # number of succesive days
            perennial_period.EndPeriodValue = parse(Int, split(readline(file))[1])
            # number of occurrence
            perennial_period.EndOccurrence = parse(Int, split(readline(file))[1])
            if perennial_period.EndOccurrence > 3
                perennial_period.EndOccurrence = 3
            end
        end
    end
    return nothing
end

function _load_crop!(runtype::T, crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file; kwargs...) where T<:TomlFileRun
    load_gvars_from_toml!(crop, crop_file)
    load_gvars_from_toml!(perennial_period, crop_file)
    return nothing
end 

function _load_crop!(runtype::T, crop::RepCrop, perennial_period::RepPerennialPeriod, crop_file; kwargs...) where T<:NoFileRun
    set_crop!(crop, kwargs[:crop_type]; aux = haskey(kwargs, :crop) ? kwargs[:crop] : nothing)
    set_perennial_period!(perennial_period, kwargs[:crop_type]; aux = haskey(kwargs, :perennial_period) ? kwargs[:perennial_period] : nothing)
    return nothing
end

"""
    sxtop, sxbot = derive_smax_top_bottom(crop::RepCrop)

global.f90:1944
"""
function derive_smax_top_bottom(crop::RepCrop)
    sxtopq = crop.SmaxTopQuarter
    sxbotq = crop.SmaxBotQuarter
    v1 = sxtopq
    v2 = sxbotq
    if (abs(v1 - v2) < 1e-12) 
        sxtop = v1
        sxbot = v2
    else
        if (sxtopq < sxbotq) 
            v1 = sxbotq
            v2 = sxtopq
        end 
        x = 3 * v2/(v1-v2)
        if (x < 0.5) 
            v11 = (4/3.5) * v1
            v22 = 0
        else
            v11 = (x + 3.5) * v1/(x+3)
            v22 = (x - 0.5) * v2/x
        end 
        if (sxtopq > sxbotq) 
            sxtop = v11
            sxbot = v22
        else
            sxtop = v22
            sxbot = v11
        end 
    end 

    return sxtop, sxbot
end


"""
    adjust_year_perennials!(crop::RepCrop, theyearseason)

global.f90:4690
"""
function adjust_year_perennials!(crop::RepCrop, theyearseason)
    sownyear1  = crop.SownYear1
    thecyclemode = crop.ModeCycle
    zmax = crop.RootMax
    zminyear1 = crop.RootMinYear1
    thecco = crop.CCo
    thesizeseedling = crop.SizeSeedling
    thecgc = crop.CGC
    theccx = crop.CCx
    thegddcgc = crop.GDDCGC
    theplantingdens  = crop.PlantingDens
    thesizeplant = crop.SizePlant

    if (theyearseason == 1) 
        if (sownyear1 == true)  # planting
            typeofplanting = :Seed
        else
            typeofplanting = :Transplant
        end 
        zmin = zminyear1  # rooting depth
    else
        typeofplanting = :Regrowth # planting
        zmin = zmax  # rooting depth
        # plant size by regrowth
        if (round(Int, 100*thesizeplant) < round(100*thesizeseedling)) 
            thesizeplant = 10 * thesizeseedling
        end 
        if (round(Int, 100*thesizeplant) > 
            round(Int, (100*theccx*10000)/(theplantingdens/10000))) 
            # adjust size plant to maximum possible
            thesizeplant = (theccx*10000)/(theplantingdens/10000p)
        end 
    end 
    theccini = (theplantingdens/10000) * (thesizeplant/10000)
    thedaystoccini = time_to_cc_ini(typeofplanting, theplantingdens, 
                       thesizeseedling, thesizeplant, theccx, thecgc)
    if (thecyclemode == :GDDays) 
        thegddaystoccini = time_to_cc_ini(typeofplanting, theplantingdens, 
                       thesizeseedling, thesizeplant, theccx, thegddcgc)
    else
        thegddaystoccini = undef_int
    end 

    crop.Planting = typeofplanting
    crop.RootMin = zmin
    crop.SizePlant = thesizeplant
    crop.CCini = theccini
    crop.DaysToCCini = thedaystoccini  
    crop.GDDaysToCCini = thegddaystoccini

    return nothing
end

"""
    adjust_crop_file_parameters!(gvars)

tempprocessing.f90:1882
"""
function adjust_crop_file_parameters!(gvars)
    crop = gvars[:crop]
    crop_file_set = gvars[:crop_file_set]
    simulparam = gvars[:simulparam]

    lseasondays = crop.DaysToHarvest
    thecropday1 = crop.Day1
    themodecycle = crop.ModeCycle
    thetbase = crop.Tbase
    thetupper = crop.Tupper


    # Adjust some crop parameters (CROP.*) as specified by the generated length
    # season (LseasonDays)
    # time to maturity
    if (themodecycle == :GDDays) 
        tmin_tmp = simulparam.Tmin 
        tmax_tmp = simulparam.Tmax 
        gdd1234 = growing_degree_days(lseasondays, thecropday1, thetbase, thetupper, gvars, tmin_tmp, tmax_tmp) 

    else
        gdd1234 = undef_int
    end 

    # time to senescence  (reference is given in thecropfileset
    if (themodecycle == :GDDays) 
        gdd123 = gdd1234 - crop_file_set.GDDaysFromSenescenceToEnd
        if (gdd123 >= gdd1234) 
            gdd123 = gdd1234
            l123 = lseasondays
        else
            tmin_tmp = simulparam.Tmin 
            tmax_tmp = simulparam.Tmax 
            l123 = sum_calendar_days(gdd123, thecropday1, thetbase, thetupper, tmin_tmp, tmax_tmp, gvars)
        end 
    else
        l123 = lseasondays - crop_file_set.DaysFromSenescenceToEnd
        if (l123 >= lseasondays)
            l123 = lseasondays
        end
        gdd123 = undef_int
    end 
    crop.DaysToSenescence = l123
    crop.GDDaysToSenescence = gdd123
    crop.GDDaysToHarvest = gdd1234

    return nothing
end 

"""
    gdd1234 = growing_degree_days(valperiod, firstdayperiod, tbase, tupper, gvars, tdaymin, tdaymax)

tempprocessing.f90:871
"""
function growing_degree_days(valperiod, firstdayperiod, tbase, tupper, gvars, tdaymin, tdaymax)
    temperature_file = gvars[:string_parameters][:temperature_file]
    temperature_file_exists = gvars[:bool_parameters][:temperature_file_exists]
    simulparam = gvars[:simulparam]
    temperature_record = gvars[:temperature_record]
    Tmin = gvars[:array_parameters][:Tmin]
    Tmax = gvars[:array_parameters][:Tmax]

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    tdaymin_local = tdaymin
    tdaymax_local = tdaymax
    gddays = 0

    if (valperiod > 0) 
        if (temperature_file=="(None)") 
            # given average Tmin and Tmax
            daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
            gddays = round(Int, valperiod * daygdd)
        else
            # temperature file
            daynri = firstdayperiod
            if full_undefined_record(temperature_record)
                adjustdaynri = true
                daynri = set_daynr_to_yundef(daynri)
            else
                adjustdaynri = false
            end 

            if temperature_file_exists & (temperature_record.ToDayNr>daynri) & (temperature_record.FromDayNr<=daynri)
                remainingdays = valperiod
                if temperature_record.Datatype == :Daily
                    # Tmin and Tmax arrays contain the TemperatureFilefull data
                    i = daynri - temperature_record.FromDayNr + 1
                    tdaymin_local = Tmin[i]
                    tdaymax_local = Tmax[i]

                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1

                    while ((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) | adjustdaynri))
                        i = i + 1
                        if (i == length(Tmin)) 
                            i = 1
                        end 
                        tdaymin_local = Tmin[i]
                        tdaymax_local = Tmax[i]

                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)

                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end 

                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 
                elseif temperature_record.Datatype == :Decadely
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                    i = 1
                    while (tmin_dataset[i].DayNr != daynri)
                        i = i+1
                    end 
                    tdaymin_local = tmin_dataset[i].Param
                    tdaymax_local = tmax_dataset[i].Param

                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)

                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1
                    while ((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) |  adjustdaynri))
                        if (daynri > tmin_dataset[31].DayNr)
                            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                        end
                        i = 1
                        while (tmin_dataset[i].DayNr != daynri)
                            i = i+1
                        end
                        tdaymin_local = tmin_dataset[i].Param
                        tdaymax_local = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end
                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 
                elseif temperature_record.Datatype == :Monthly
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                    i = 1
                    while (tmin_dataset[i].DayNr != daynri)
                        i = i+1
                    end
                    tdaymin_local = tmin_dataset[i].Param
                    tdaymax_local = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                    gddays = gddays + daygdd
                    remainingdays = remainingdays - 1
                    daynri = daynri + 1
                    while((remainingdays > 0) & ((daynri < temperature_record.ToDayNr) | adjustdaynri))
                        if (daynri > tmin_dataset[31].DayNr) 
                            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                        end
                        i = 1
                        while (tmin_dataset[i].DayNr != daynri)
                            i = i+1
                        end
                        tdaymin_local = tmin_dataset[i].Param
                        tdaymax_local = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_local, tdaymax_local, simulparam.GDDMethod)
                        gddays = gddays + daygdd
                        remainingdays = remainingdays - 1
                        daynri = daynri + 1
                    end 
                    if (remainingdays > 0) 
                        gddays = undef_int
                    end 
                end 
            end
        end
    else
        gddays = undef_int
    end
    gdd1234 = round(Int, gddays)
    return gdd1234
end 

"""
    dgrd = degrees_day(tbase, tupper, tdaymin, tdaymax, gddselectedmethod)

global.f90:2419
"""
function degrees_day(tbase, tupper, tdaymin, tdaymax, gddselectedmethod)
    if gddselectedmethod==1
        # method 1. - no adjustemnt of tmax, tmin before calculation of taverage
        tavg = (tdaymax+tdaymin)/2
        if (tavg > tupper) 
            tavg = tupper
        end 
        if (tavg < tbase) 
            tavg = tbase
        end
    elseif gddselectedmethod==2
        # method 2. -  adjustment for tbase before calculation of taverage
        tstarmax = tdaymax
        if (tdaymax < tbase) 
            tstarmax = tbase
        end 
        if (tdaymax > tupper) 
            tstarmax = tupper
        end 
        tstarmin = tdaymin
        if (tdaymin < tbase) 
            tstarmin = tbase
        end 
        if (tdaymin > tupper) 
            tstarmin = tupper
        end 
        tavg = (tstarmax+tstarmin)/2
    else
        # method 3.
        tstarmax = tdaymax
        if (tdaymax < tbase) 
             tstarmax = tbase
        end 
        if (tdaymax > tupper) 
            tstarmax = tupper
        end 
        tstarmin = tdaymin
        if (tdaymin > tupper) 
            tstarmin = tupper
        end 
        tavg = (tstarmax+tstarmin)/2
        if (tavg < tbase) 
            tavg = tbase
        end 
    end 
    dgrd =  tavg - tbase
    return  dgrd
end 

"""
    daynri = set_daynr_to_yundef(daynri)

tempprocessing.f90:351
"""
function set_daynr_to_yundef(daynri)
    dayi, monthi, yeari = determine_date(daynri)
    yeari = 1901
    return determine_day_nr(dayi, monthi, yeari)
end


"""
    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_array, temperature_record::RepClim)

tempprocessing.f90:362
"""
function get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_array, temperature_record::RepClim)
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
    c1min, c1max, c2min, c2max, c3min, c3max = get_set_of_three_temperature(dayn, deci, monthi, yeari, temperature_array, temperature_record)
    dnr = determine_day_nr(dayi, monthi, yeari)

    ulmin, llmin, midmin = get_parameters(c1min, c2min, c3min)
    for nri in 1:ni
        tmin_dataset[nri].DayNr = dnr+nri-1
        if (nri <= (ni/2+0.01)) 
            tmin_dataset[nri].Param = (2*ulmin + (midmin-ulmin)*(2*nri-1)/(ni/2))/2
        else
            if ((ni == 11) | (ni == 9)) & (nri < (ni+1.01)/2) 
                tmin_dataset[nri].Param = midmin
            else
                tmin_dataset[nri].Param = (2*midmin + (llmin-midmin)*(2*nri-(ni+1))/(ni/2))/2
            end 
        end 
    end 

    ulmax, llmax, midmax = get_parameters(c1max, c2max, c3max)
    for nri in 1:ni
        tmax_dataset[nri].DayNr = dnr+nri-1
        if (nri <= (ni/2+0.01)) 
            tmax_dataset[nri].Param = (2*ulmax + (midmax-ulmax)*(2*nri-1)/(ni/2))/2
        else
            if ((ni == 11) | (ni == 9)) & (nri < (ni+1.01)/2) 
                tmax_dataset[nri].Param = midmax
            else
                tmax_dataset[nri].Param = (2*midmax + (llmax-midmax)*(2*nri-(ni+1))/(ni/2))/2
            end 
        end 
    end 

    for nri in (ni+1):31
        tmin_dataset[nri].DayNr = dnr+ni-1
        tmin_dataset[nri].Param = 0
        tmax_dataset[nri].DayNr = dnr+ni-1
        tmax_dataset[nri].Param = 0
    end 

    return nothing
end

"""
    ul, ll, mid = get_parameters(c1, c2, c3)

tempprocessing.f90:580
"""
function get_parameters(c1, c2, c3)
    ul = (c1+c2)/2
    ll = (c2+c3)/2
    mid = 2*c2 - (ul+ll)/2
    # --previous decade-->/ul/....... mid ......../ll/<--next decade--
    return ul, ll, mid
end 

"""
    c1min, c1max, c2min, c2max, c3min, c3max = get_set_of_three_temperature(dayn, deci, monthi, yeari, temperature_array, temperature_record::RepClim)

tempprocessing.f90:439
"""
function get_set_of_three_temperature(dayn, deci, monthi, yeari, temperature_array, temperature_record::RepClim)
    # 1 = previous decade, 2 = Actual decade, 3 = Next decade;
    if temperature_record.FromD>20
        decfile=3
    elseif temperature_record.FromD>10
        decfile=2
    else
        decfile=1
    end
    mfile = temperature_record.FromM
    if temperature_record.FromY==1901
        yfile = yeari
    else
        yfile = temperature_record.FromY
    end
    ok3 = false
    
    cont = 1
    if temperature_record.NrObs<=2
        c1min = temperature_array[1][cont]
        c1max = temperature_array[2][cont]
        cont += 1
        if temperature_record.NrObs==0
            c2min = c1min
            c2max = c1max #OJO in the original code says c2max = c2max but makes not much sense
            c3min = c1min
            c3max = c1max
        elseif temperature_record.NrObs==1
            decfile += 1
            if decfile>3
                decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)
            end
            c3min = temperature_array[1][cont]
            c3max = temperature_array[2][cont]
            cont += 1
            if (deci == decfile) 
                c2min = c3min
                c2max = c3max
                c3min = c2min+(c2min-c1min)/4
                c3max = c2max+(c2max-c1max)/4
            else
                c2min = c1min
                c2max = c1max
                c1min = c2min + (c2min-c3min)/4
                c1max = c2max + (c2max-c3max)/4
            end 
        end
        ok3 = true
    end

    if (!ok3) & (deci==decfile) & (monthi==mfile) & (yeari==yfile)
        c1min = temperature_array[1][cont]
        c1max = temperature_array[2][cont]
        cont += 1
        c2min = c1min
        c2max = c1max
        c3min = temperature_array[1][cont]
        c3max = temperature_array[2][cont]
        cont += 1
        c1min = c2min + (c2min-c3min)/4
        c1max = c2max + (c2max-c3max)/4
        ok3 = true
    end 

    if (!ok3) & (dayn==temperature_record.ToD) & (monthi==temperature_record.ToM)
        if (temperature_record.FromY==1901) | (yeari==temperature_record.ToY)
            for Nri in 1:(temperature_record.NrObs-2)
                cont += 1
            end 
            c1min = temperature_array[1][cont]
            c1max = temperature_array[2][cont]
            cont += 1
            c2min = temperature_array[1][cont]
            c2max = temperature_array[2][cont]
            cont += 1
            c3min = c2min+(c2min-c1min)/4
            c3max = c2max+(c2max-c1max)/4
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
        if temperature_record.FromD>20
            decfile = 3
        elseif temperature_record.FromD>10
            decfile = 2
        else
            decfile = 1
        end
        for nri in 1:(obsi-2)
            cont += 1
        end 
        c1min = temperature_array[1][cont]
        c1max = temperature_array[2][cont]
        cont += 1
        c2min = temperature_array[1][cont]
        c2max = temperature_array[2][cont]
        cont += 1
        c3min = temperature_array[1][cont]
        c3max = temperature_array[2][cont]
        cont += 1
    end 

    return c1min, c1max, c2min, c2max, c3min, c3max
end 

""" 
    decfile, mfile, yfile = adjust_decade_month_and_year(decfile, mfile, yfile)

tempprocessing.f90:293
"""
function adjust_decade_month_and_year(decfile, mfile, yfile)
    decfile = 1
    mfile = mfile + 1
    if (mfile > 12) 
        mfile = 1
        yfile = yfile + 1
    end 
    return decfile, mfile, yfile
end


"""
    mfile, yfile = adjust_month_and_year(mfile, yfile)

tempprocessing.f90:284
"""
function adjust_month_and_year(mfile, yfile)
    mfile = mfile - 12
    yfile = yfile + 1
    return mfile, yfile
end

"""
    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_array, temperature_record::RepClim)

tempprocessing.f90:596
"""
function get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, temperature_array, temperature_record::RepClim)
    dayi, monthi, yeari = determine_date(daynri)
    c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1 = get_set_of_three_months_temperature(monthi, yeari, temperature_array, temperature_record)

    dayi = 1
    dnr = determine_day_nr(dayi, monthi, yeari)
    dayn = DaysInMonth[monthi]
    if ((monthi == 2) & isleapyear(yeari)) 
        dayn = dayn + 1
    end 

    aover3min, bover2min, cmin = get_interpolation_parameters(c1min, c2min, c3min)
    aover3max, bover2max, cmax = get_interpolation_parameters(c1max, c2max, c3max)
    for dayi in 1:dayn
        t2 = t1 + 1
        tmin_dataset[dayi].DayNr = dnr+dayi-1
        tmax_dataset[dayi].DayNr = dnr+dayi-1
        tmin_dataset[dayi].Param = aover3min*(t2*t2*t2-t1*t1*t1) + bover2min*(t2*t2-t1*t1) + cmin*(t2-t1)
        tmax_dataset[dayi].Param = aover3max*(t2*t2*t2-t1*t1*t1) + bover2max*(t2*t2-t1*t1) + cmax*(t2-t1)
        t1 = t2
    end 
    for dayi in (dayn+1):31
        tmin_dataset[dayi].DayNr = dnr+dayn-1 #OJO maybe is dayi
        tmax_dataset[dayi].DayNr = dnr+dayn-1 #OJO maybe is dayi
        tmin_dataset[dayi].Param = 0
        tmax_dataset[dayi].Param = 0
    end 
    return nothing
end 

"""
    c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1 = get_set_of_three_months_temperature(monthi, yeari, temperature_array, temperature_record::RepClim)

tempprocessing.f90:645
"""
function get_set_of_three_months_temperature(monthi, yeari, temperature_array, temperature_record::RepClim)
    n1 = 30
    n2 = 30
    n3 = 30

    # 1. Prepare record
    mfile = temperature_record.FromM
    if temperature_record.FromY==1901
        yfile = yeari
    else
        yfile = temperature_record.FromY
    end
    ok3 = false

    cont = 1
    # 2. IF 3 or less records
    if temperature_record.NrObs<=3
        c1min, c1max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x1 = n1
        if temperature_record.NrObs==0
            t1 = x1
            x2 = x1 + n1
            c2min = c1min
            c2max = c1max
            x3 = x2 + n1
            c3min = c1min
            c3max = c1max
        elseif temperature_record.NrObs==1
            t1 = x1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3min, c3max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            if monthi==mfile 
                c2min = c3min
                c2max = c3max
                x2 = x1 + n3
                x3 = x2 + n3
            else
                c2min = c1min
                c2max = c1max
                x2 = x1 + n1
                x3 = x2 + n3
            end 
        elseif temperature_record.NrObs==2
            if monthi==mfile 
                t1 = 0
            end 
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c2min, c2max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            x2 = x1 + n2
            if monthi==mfile 
                t1 = x1
            end 
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
            c3min, c3max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            x3 = x2 + n3
            if monthi==mfile 
                t1 = x2
            end 
        end
        ok3 = true
    end 

    # 3. If first observation
    if (!ok3) & (monthi==mfile) & (yeari==yfile)
        t1 = 0
        c1min, c1max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x1 = n1
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c2min, c2max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x2 = x1 + n2
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c3min, c3max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x3 = x2 + n3
        ok3 = true
    end 

    # 4. If last observation
    if (!ok3) & (monthi==temperature_record.ToM)
        if (temperature_record.FromY==1901) | (yeari==temperature_record.ToY)
            for nri in 1:(temperature_record.NrObs-3)
                cont += 1
                mfile = mfile + 1
                if mfile>12 
                    mfile, yfile = adjust_month_and_year(mfile, yfile)
                end 
            end 
            c1min, c1max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            x1 = n1
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c2min, c2max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            x2 = x1 + n2
            t1 = x2
            mfile = mfile + 1
            if mfile>12 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end 
            c3min, c3max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
            cont += 1
            x3 = x2 + n3
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
        mfile = temperature_record.FromM 
        for nri in 1:(obsi-2)
            cont += 1
            mfile = mfile + 1
            if (mfile > 12) 
                mfile, yfile = adjust_month_and_year(mfile, yfile)
            end
        end
        c1min, c1max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x1 = n1
        t1 = x1
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end 
        c2min, c2max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x2 = x1 + n2
        mfile = mfile + 1
        if mfile>12 
            mfile, yfile = adjust_month_and_year(mfile, yfile)
        end
        c3min, c3max = adjust_month(temperature_array[1][cont], temperature_array[2][cont])
        cont += 1
        x3 = x2 + n3
    end 

    return c1min, c2min, c3min, c1max, c2max, c3max, x1, x2, x3, t1
end 

"""
    cimin, cimax = adjust_month(tlow, thigh)

this comes from read_month tempprocessing.f90:837
"""
function adjust_month(tlow, thigh)
    ni = 30
    cimin = tlow  * ni
    cimax = thigh * ni

    return cimin, cimax
end

"""
     aover3, bover2, c = get_interpolation_parameters(c1, c2, c3)

tempprocessing.f90:854
"""
function get_interpolation_parameters(c1, c2, c3)
    # n1=n2=n3=30 --> better parabola
    aover3 = (c1-2*c2+c3)/(6*30*30*30)
    bover2 = (-6*c1+9*c2-3*c3)/(6*30*30)
    c = (11*c1-7*c2+2*c3)/(6*30)
    return aover3, bover2, c
end


"""
    nrcdays = sum_calendar_days(valgddays, firstdaycrop, tbase, tupper, tdaymin, tdaymax, gvars)

tempprocessing.f90:1035
"""
function sum_calendar_days(valgddays, firstdaycrop, tbase, tupper, tdaymin, tdaymax, gvars)
    temperature_file = gvars[:string_parameters][:temperature_file]
    temperature_file_exists = gvars[:bool_parameters][:temperature_file_exists]
    temperature_record = gvars[:temperature_record]
    simulparam = gvars[:simulparam]
    Tmin = gvars[:array_parameters][:Tmin]
    Tmax = gvars[:array_parameters][:Tmax]

    tmin_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]
    tmax_dataset = RepDayEventDbl[RepDayEventDbl() for _ in 1:31]

    tdaymin_loc = tdaymin
    tdaymax_loc = tdaymax

    nrcdays = 0
    if valgddays>0 
        if temperature_file=="(None)"
            # given average Tmin and Tmax
            daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
            if abs(daygdd) < eps()
                nrcdays = undef_int
            else
                nrcdays = round(Int, valgddays/daygdd)
            end 
        else
            daynri = firstdaycrop
            if full_undefined_record(temperature_record)
                adjustdaynri = true
                daynri = set_daynr_to_yundef(daynri)
            else
                adjustdaynri = false
            end 

            if temperature_file_exists & (temperature_record.ToDayNr>daynri) & (temperature_record.FromDayNr<=daynri)
                remaininggddays = valgddays
                if temperature_record.Datatype==:Daily
                    # Tmin and Tmax arrays contain the TemperatureFilefull data
                    i = daynri - temperature_record.FromDayNr + 1
                    tdaymin_loc = Tmin[i]
                    tdaymax_loc = Tmax[i]

                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1

                    while ((remaininggddays > 0) & ((daynri < temperature_record.ToDayNr) | adjustdaynri))
                        i = i + 1
                        if i==length(Tmin) 
                            i = 1
                        end 
                        tdaymin_loc = Tmin[i]
                        tdaymax_loc = Tmax[i]

                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 

                    if remaininggddays>0 
                        nrcdays = undef_int
                    end 
                elseif temperature_record.Datatype==:Decadely
                    get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                    i = 1
                    while tmin_dataset[i].DayNr != daynri
                        i = i+1
                    end 
                    tdaymin_loc = tmin_dataset[i].Param
                    tdaymax_loc = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1
                    while (remaininggddays>0) & ((daynri<temperature_record.ToDayNr) | (adjustdaynri))
                        if daynri>tmin_dataset[31].DayNr 
                            get_decade_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                        end
                        i = 1
                        while tmin_dataset[i].DayNr != daynri
                            i = i+1
                        end 
                        tdaymin_loc = tmin_dataset[i].Param
                        tdaymax_loc = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 
                    if remaininggddays>0 
                        nrcdays = undef_int
                    end 
                elseif  temperature_record.Datatype==:Monthly
                    get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                    i = 1
                    while tmin_dataset[i].DayNr != daynri
                        i = i+1
                    end 
                    tdaymin_loc = tmin_dataset[i].Param
                    tdaymax_loc = tmax_dataset[i].Param
                    daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                    nrcdays = nrcdays + 1
                    remaininggddays = remaininggddays - daygdd
                    daynri = daynri + 1
                    while (remaininggddays>0) & ((daynri<temperature_record.ToDayNr) | adjustdaynri)
                        if daynri>tmin_dataset[31].DayNr 
                            get_monthly_temperature_dataset!(tmin_dataset, tmax_dataset, daynri, (Tmin, Tmax), temperature_record)
                        end
                        i = 1
                        while tmin_dataset[i].DayNr != daynri
                            i = i+1
                        end 
                        tdaymin_loc = tmin_dataset[i].Param
                        tdaymax_loc = tmax_dataset[i].Param
                        daygdd = degrees_day(tbase, tupper, tdaymin_loc, tdaymax_loc, simulparam.GDDMethod)
                        nrcdays = nrcdays + 1
                        remaininggddays = remaininggddays - daygdd
                        daynri = daynri + 1
                    end 
                    if remaininggddays>0 
                        nrcdays = undef_int
                    end 
                end 
            else
                nrcdays = undef_int
            end
        end
    end
    return nrcdays
end 

"""
    adjust_calendar_crop!(gvars)

tempprocessing.f90:1467
"""
function adjust_calendar_crop!(gvars)
    crop = gvars[:crop]
    cgcisgiven = true

    if crop.ModeCycle==:GDDays
        crop.GDDaysToFullCanopy = crop.GDDaysToGermination +
                round(Int, log((0.25*crop.CCx^2/crop.CCo)/(crop.CCx-0.98*crop.CCx))/crop.GDDCGC)
        if crop.GDDaysToFullCanopy>crop.GDDaysToHarvest 
            crop.GDDaysToFullCanopy = crop.GDDaysToHarvest
        end 
        adjust_calendar_days!(gvars, cgcisgiven)
    end 
    return nothing
end 


"""
    adjust_calendar_days!(gvars, iscgcgiven)

tempprocessing.f90:1327
"""
function adjust_calendar_days!(gvars, iscgcgiven)
    crop = gvars[:crop]
    simulparam = gvars[:simulparam]
    plantdaynr = crop.Day1
    infocroptype = crop.subkind
    tbase = crop.Tbase
    tupper = crop.Tupper
    notempfiletmin = simulparam.Tmin
    notempfiletmax = simulparam.Tmax
    gddl0 = crop.GDDaysToGermination
    gddl12 = crop.GDDaysToFullCanopy
    gddflor = crop.DaysToFlowering
    gddlengthflor = crop.GDDLengthFlowering
    gddl123 = crop.GDDaysToSenescence
    gddharvest = crop.GDDaysToHarvest
    gddlzmax = crop.GDDaysToMaxRooting
    gddhimax = crop.GDDaysToHIo
    gddcgc = crop.GDDCGC
    gddcdc = crop.GDDCDC
    cco = crop.CCo
    ccx = crop.CCx
    hindex = crop.HI
    thedaystoccini = crop.DaysToCCini
    thegddaystoccini = crop.GDDaysToCCini
    theplanting = crop.Planting
    d0 = crop.DaysToGermination
    d12 = crop.DaysToFullCanopy
    dflor = crop.DaysToFlowering
    lengthflor = crop.LengthFlowering
    d123 = crop.DaysToSenescence
    dharvest = crop.DaysToHarvest
    dlzmax = crop.DaysToMaxRooting
    lhimax = crop.DaysToHIo
    stlength = crop.Length
    cgc = crop.CGC
    cdc = crop.CDC
    dhidt = crop.dHIdt
    notempfiletmax = simulparam.Tmax
    notempfiletmin = simulparam.Tmin

    tmp_notempfiletmin = notempfiletmin
    tmp_notempfiletmax = notempfiletmax

    succes = true
    if thedaystoccini==0 
        # planting/sowing
        d0 = sum_calendar_days(gddl0, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, gvars)
        d12 = sum_calendar_days(gddl12, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, gvars)
    else
        # regrowth
        if thedaystoccini>0 
           # ccini < ccx
           extragddays = gddl12 - gddl0 - thegddaystoccini
           extradays = sum_calendar_days(extragddays, plantdaynr, tbase, tupper, notempfiletmin, notempfiletmax, gvars)
           d12 = d0 + thedaystoccini + extradays
        end 
    end 

    if infocroptype!=:Forage 
        d123 = sum_calendar_days(gddl123, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
        dharvest = sum_calendar_days(gddharvest, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
    end 

    dlzmax = sum_calendar_days(gddlzmax, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
    if (infocroptype==:Grain) | (infocroptype==:Tuber)
        dflor = sum_calendar_days(gddflor, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
        if dflor!=undef_int 
            if infocroptype==:Grain 
                lengthflor = sum_calendar_days(gddlengthflor, (plantdaynr+dflor), tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
            else
                lengthflor = 0
            end 
            lhimax = sum_calendar_days(gddhimax, (plantdaynr+dflor), tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
            if (lengthflor==undef_int) | (lhimax==undef_int) 
                succes = false
            end 
        else
            lengthflor = undef_int
            lhimax = undef_int
            succes = false
        end 
    elseif (infocroptype==:Vegetative) | (infocroptype==:Forage)
        lhimax = sum_calendar_days(gddhimax, plantdaynr, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
    end 
    if (d0==undef_int) | (d12 == undef_int) | (d123==undef_int) | (dharvest==undef_int) | (dlzmax==undef_int) 
        succes = false
    end 

    if succes 
        cgc = gddl12/d12 * gddcgc
        cdc = gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, tmp_notempfiletmin, tmp_notempfiletmax, gvars)
        d123, stlength, d12, cgc = determine_length_growth_stages(cco, ccx, cdc, d0, dharvest, iscgcgiven, thedaystoccini, theplanting, d123, stlength, d12, cgc)
        if (infocroptype==:Grain) | (infocroptype==:Tuber) 
            dhidt = hindex/lhimax
        end 
        if (infocroptype==:Vegetative) | (infocroptype==:Forage) 
            if (lhimax > 0) 
                if (lhimax > dharvest) 
                    dhidt = hindex/dharvest
                else
                    dhidt = hindex/lhimax
                end 
                if (dhidt > 100) 
                    dhidt = 100 # 100 is maximum tempdhidt (see setdhidt)
                    lhimax = 0
                end 
            else
                dhidt = 100 # 100 is maximum tempdhidt (see setdhidt)
                lhimax = 0
            end 
        end 
    end 


    crop.GDDaysToHIo = gddhimax
    crop.DaysToGermination = d0
    crop.DaysToFullCanopy = d12
    crop.DaysToFlowering = dflor
    crop.LengthFlowering = lengthflor
    crop.DaysToSenescence = d123
    crop.DaysToHarvest = dharvest
    crop.DaysToMaxRooting = dlzmax
    crop.DaysToHIo = lhimax
    crop.Length = stlength
    crop.CGC = cgc
    crop.CDC = cdc
    crop.dHIdt = dhidt

    return nothing
end 


"""
    cdc = gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, notempfiletmin, notempfiletmax, gvars)

tempprocessing.f90:1545
"""
function gddcdc_to_cdc(plantdaynr, d123, gddl123, gddharvest, ccx, gddcdc, tbase, tupper, notempfiletmin, notempfiletmax, gvars)
    gddi = length_canopy_decline(ccx, gddcdc)
    if (gddl123+gddi)<=gddharvest 
        cci = 0 # full decline
    else
        # partly decline
        if gddl123<gddharvest 
            gddi = gddharvest - gddl123
        else
            gddi = 5
        end 
        # cc at time ti
        cci = ccx * (1 - 0.05 *(exp(gddi*gddcdc*3.33/(ccx+2.29))-1)) 
    end 
    ti = sum_calendar_days(gddi, (plantdaynr+d123), tbase, tupper, notempfiletmin, notempfiletmax, gvars)
    if ti>0 
        cdc = ((ccx+2.29)/ti * log(1 + (1-cci/ccx)/0.05))/3.33
    else
        cdc = undef_int
    end 

    return cdc
end 


"""
    adjust_crop_year_to_climfile!(crop::RepCrop, clim_file, clim_record)

global.f90:6447
"""
function adjust_crop_year_to_climfile!(crop::RepCrop, clim_file, clim_record)
    cday1 = crop.Day1
    cdayn = crop.DayN
    dayi, monthi, yeari = determine_date(cday1)
    if clim_file=="(None)" 
        yeari = 1901  # yeari = 1901 if undefined year
    else
        yeari = clim_record.FromY # yeari = 1901 if undefined year
    end 
    cday1 = determine_day_nr(dayi, monthi, yeari)

    # This function determines Crop.DayN and the string
    cdayn = cday1 + crop.DaysToHarvest - 1
    if cdayn<cday1 
        cdayn = cday1
    end

    crop.Day1 = cday1
    crop.DayN = cdayn
    return nothing
end 

"""
    adjust_climrecord_to!(clim_record::RepClim, cdayn)

global.f90:6163
"""
function adjust_climrecord_to!(clim_record::RepClim, cdayn)
    dayi, monthi, yeari = determine_date(cdayn)
    clim_record.ToD = 31
    clim_record.ToM = 12
    clim_record.ToY = yeari
    clim_record.ToDayNr = determine_day_nr(31, 12, yeari)
    return nothing
end

"""
    adjust_simperiod!(gvars, projectinput::ProjectInputType)

global.f90:4692
"""
function adjust_simperiod!(gvars, projectinput::ProjectInputType)
    simulation = gvars[:simulation]
    crop = gvars[:crop]
    clim_file = gvars[:string_parameters][:clim_file]
    clim_record = gvars[:clim_record]
    simulparam = gvars[:simulparam]
    groundwater_file = gvars[:string_parameters][:groundwater_file]


    inisimfromdaynr = simulation.FromDayNr
    if simulation.LinkCropToSimPeriod
        determine_linked_simday1!(simulation, crop, clim_record, clim_file)
        if (crop.Day1==simulation.FromDayNr) 
            simulation.ToDayNr = crop.DayN
        else
            simulation.ToDayNr = simulation.FromDayNr + 30
        end 
        if (clim_file != "(None)") 
            if (simulation.ToDayNr>clim_record.ToDayNr) 
                simulation.ToDayNr = clim_record.ToDayNr
            end 
            if (simulation.ToDayNr<clim_record.FromDayNr) 
                simulation.ToDayNr = clim_record.FromDayNr
            end 
        end 
    else 
        if (simulation.FromDayNr>crop.Day1) 
            simulation.FromDayNr = crop.Day1
        end 
        simulation.ToDayNr = crop.DayN
        if (clim_file != "(None)") & ((simulation.FromDayNr<=clim_record.FromDayNr) | (simulation.FromDayNr>=clim_record.ToDayNr)) 
            simulation.FromDayNr = clim_record.FromDayNr
            simulation.ToDayNr = simulation.FromDayNr + 30
        end 
    end 

    # adjust initial depth and quality of the groundwater when required
    if (!simulparam.ConstGwt) & (inisimfromdaynr != simulation.FromDayNr) 
        if (groundwater_file != "(None)") 
            fullfilename = projectinput.ParentDir * "/GroundWater.AqC"
        else
            fullfilename = groundwater_file
        end 
        # initialize ZiAqua and ECiAqua
        load_groundwater!(gvars, fullfilename)
        calculate_adjusted_fc!(gvars[:compartments], gvars[:soil_layers], gvars[:integer_parameters][:ziaqua]/100)
        if gvars[:simulation].IniSWC.AtFC 
            reset_swc_to_fc!(gvars[:simulation], gvars[:compartments], gvars[:soil_layers], gvars[:integer_parameters][:ziaqua])
        end 
    end 

    return nothing
end 

"""
    determine_linked_simday1!(simulation::RepSim, crop::RepCrop, clim_record::RepClim, clim_file)

global.f90:4677
"""
function determine_linked_simday1!(simulation::RepSim, crop::RepCrop, clim_record::RepClim, clim_file)
    simday1 = crop.Day1
    if clim_file != "(None)" 
        if (simday1<clim_record.FromDayNr) | (simday1>clim_record.ToDayNr) 
            simulation.LinkCropToSimPeriod = false
            simday1 = clim_record.FromDayNr
        end 
    end
    simulation.FromDayNr = simday1
    return nothing
end

"""
    load_groundwater!(gvars, groundwater_file)

global.f90:5981
"""
function load_groundwater!(gvars, groundwater_file)
    simulparam = gvars[:simulparam]
    simulation = gvars[:simulation]
    atdaynr = simulation.FromDayNr

    atdaynr_local = atdaynr
    # initialize
    theend = false
    year1gwt = 1901
    daynr1 = 1
    daynr2 = 1

    if isfile(groundwater_file)
        open(groundwater_file, "r") do file
            readline(file)
            readline(file)

            # mode groundwater table
            i = parse(Int, split(readline(file))[1])
            if i==0
                # no groundwater table
                zcm = undef_int
                ecdsm = undef_double 
                simulparam.ConstGwt = true
                theend = true
            elseif i==1
                # constant groundwater table
                simulparam.ConstGwt = true
            else
                simulparam.ConstGwt = false 
            end

            # first day of observations (only for variable groundwater table)
            if !simulparam.ConstGwt 
                dayi = parse(Int, split(readline(file))[1])
                monthi = parse(Int, split(readline(file))[1])
                year1gwt = parse(Int, split(readline(file))[1])
                daynr1gwt = determine_day_nr(dayi, monthi, year1gwt)
            end 

            # single observation (Constant Gwt) or first observation (Variable Gwt)
            if i>0 
                # groundwater table is present
                readline(file)
                readline(file)
                readline(file)
                splitedline = split(readline(file))
                daydouble = parse(Float64, popfirst!(splitedline))
                z2 = parse(Float64, popfirst!(splitedline))
                ec2 = parse(Float64, popfirst!(splitedline))
                if (i==1) | eof(file) 
                    # Constant groundwater table or single observation
                    Zcm = round(Int,100*z2)
                    ecdsm = ec2
                    theend = true
                else
                    daynr2 = daynr1gwt + round(Int, daydouble) - 1
                end 
            end 

            # other observations
            if !theend 
                # variable groundwater table with more than 1 observation
                # adjust AtDayNr
                dayi, monthi, yeari = determine_date(atdaynr_local)
                if (yeari==1901) & (year1gwt != 1901) 
                    # Make AtDayNr defined
                    atdaynr_local = determine_day_nr(dayi, monthi, year1gwt)
                end 
                if (yeari != 1901) & (year1gwt==1901) 
                    # Make AtDayNr undefined
                    atdaynr_local = determine_day_nr(dayi, monthi, year1gwt)
                end 
                # get observation at AtDayNr
                if year1gwt != 1901 
                    # year is defined
                    if atdaynr_local<=daynr2 
                        zcm = round(Int,100*z2)
                        ecdsm = ec2
                    else
                        while !theend
                            daynr1 = daynr2
                            z1 = z2
                            ec1 = ec2
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z2 = parse(Float64, popfirst!(splitedline))
                            ec2 = parse(Float64, popfirst!(splitedline))
                            daynr2 = daynr1gwt + round(Int, daydouble) - 1
                            if (atdaynr_local <= daynr2) 
                                zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                                theend = true
                            end 
                            if eof(file) & (!theend)
                                zcm = round(Int,100*z2)
                                ecdsm = ec2
                                theend = true
                            end 
                        end 
                    end 
                else
                    # year is undefined
                    if (atdaynr_local <= daynr2) 
                        daynr2 = daynr2 + 365
                        atdaynr_local = atdaynr_local + 365
                        while !eof(file)
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z1 = parse(Float64, popfirst!(splitedline))
                            ec1 = parse(Float64, popfirst!(splitedline))
                            daynr1 = daynr1gwt + round(Int, daydouble) - 1
                        end 
                        zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                    else
                        daynrn = daynr2 + 365
                        zn = z2
                        ecn = ec2
                        while !theend
                            daynr1 = daynr2
                            z1 = z2
                            ec1 = ec2
                            splitedline = split(readline(file))
                            daydouble = parse(Float64, popfirst!(splitedline))
                            z2 = parse(Float64, popfirst!(splitedline))
                            ec2 = parse(Float64, popfirst!(splitedline))
                            daynr2 = daynr1gwt + round(Int, daydouble) - 1
                            if (atdaynr_local <= daynr2) 
                                zcm, ecdsm =  find_values(atdaynr_local, daynr1, daynr2, z1, ec1, z2, ec2)
                                theend = true
                            end 
                            if eof(file) & (!theend)
                                zcm, ecdsm =  find_values(atdaynr_local, daynr2, daynrn, z2, ec2, zn, ecn)
                                theend = true
                            end 
                        end 
                    end 
                end 
                # variable groundwater table with more than 1 observation
            end 
            gvars[:integer_parameters][:ziaqua] = zcm
            gvars[:float_parameters][:eciaqua] = ecdsm
        end 
    end

    return nothing 
end 

"""
    zcn, ecdsm = find_values(atdaynr, daynr1, daynr2, z1, ec1, z2, ec2)

global.f90:6140
"""
function find_values(atdaynr, daynr1, daynr2, z1, ec1, z2, ec2)
        zcm = round(Int, 100 * (z1 + (z2-z1) * (atdaynr-daynr1)/(daynr2-daynr1)))
        ecdsm = ec1 + (ec2-ec1) * (atdaynr-daynr1)/(daynr2-daynr1)
        return zcm, ecdsm
end 


"""
    calculate_adjusted_fc!(compartadj::Vector{CompartmentIndividual}, soil_layers::Vector{SoilLayerIndividual}, depthaquifer)

global.f90:4141
"""
function calculate_adjusted_fc!(compartadj::Vector{CompartmentIndividual}, soil_layers::Vector{SoilLayerIndividual}, depthaquifer)
    depth = 0
    for compi in eachindex(compartadj)
        depth = depth + compartadj[compi].Thickness
    end 

    compi = length(compartadj)

    while compi>=1
        zi = depth - compartadj[compi].Thickness/2
        xmax = no_adjustment(soil_layers[compartadj[compi].Layer].FC)

        if (depthaquifer<0) | ((depthaquifer - zi)>=xmax) 
            for ic in 1:compi
                compartadj[ic].FCadj = soil_layers[compartadj[ic].Layer].FC
            end 
            compi = 0
        else
            if (soil_layers[compartadj[compi].Layer].FC>=soil_layers[compartadj[compi].Layer].SAT)
                compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].FC
            else
                if (zi >= depthaquifer) 
                    compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].SAT
                else
                    deltav = soil_layers[compartadj[compi].Layer].SAT - soil_layers[compartadj[compi].Layer].FC
                    deltafc = (deltav/(xmax^2)) * (zi - (depthaquifer - xmax))^2
                    compartadj[compi].FCadj = soil_layers[compartadj[compi].Layer].FC + deltafc
                end 
            end 
            depth = depth - compartadj[compi].Thickness
            compi = compi - 1
        end 
    end 

    return nothing
end

function calculate_adjusted_fc!(compartadj::Vector{AbstractParametersContainer}, soil_layers::Vector{AbstractParametersContainer}, depthaquifer)
    calculate_adjusted_fc!(CompartmentIndividual[c for c in compartadj], SoilLayerIndividual[s for s in soil_layers], depthaquifer)
    return nothing
end
"""
    nadj = no_adjustment(fcvolpr)

global.f90:4195
"""
function no_adjustment(fcvolpr)
    if fcvolpr<=10
        nadj = 1
    else
        if fcvolpr>=30 
            nadj = 2
        else
            pf = 2 + 0.3 * (fcvolpr-10)/20
            nadj = (exp(pf*log(10)))/100
        end 
    end 
    return nadj
end 


"""
    reset_swc_to_fc!(simulation::RepSim, compartments::Vector{CompartmentIndividual},
                     soil_layers::Vector{SoilLayerIndividual}, ziaqua)

global.f90:4758
"""
function reset_swc_to_fc!(simulation::RepSim, compartments::Vector{CompartmentIndividual},
                           soil_layers::Vector{SoilLayerIndividual}, ziaqua)
    simulation.IniSWC.AtDepths = false
    if ziaqua<0  # no ground water table
        simulation.IniSWC.NrLoc = length(soil_layers)
        for layeri = 1:simulation.IniSWC.NrLoc 
            simulation.IniSWC.Loc[layeri] = soil_layers[layeri].Thickness
            simulation.IniSWC.VolProc[layeri] = soil_layers[layeri].FC
            simulation.IniSWC.SaltECe[layeri] = 0 
        end 
    else
        simulation.IniSWC.NrLoc = length(compartments)
        for loci = 1:simulation.IniSWC.NrLoc 
            simulation.IniSWC.Loc[loci] = compartments[loci].Thickness
            simulation.IniSWC.VolProc[loci] = compartments[loci].FCadj
            simulation.IniSWC.SaltECe[loci] = 0 
        end 
    end 
    for compi in eachindex(compartments) 
        compartments[compi].Theta = compartments[compi].FCadj/100
        simulation.ThetaIni[compi] = compartments[compi].Theta
        for celli in 1:soil_layers[compartments[compi].Layer].SCP1
            # salinity in cells
            compartments[compi].Salt[celli] = 0
            compartments[compi].Depo[celli] = 0
        end 
    end 

    return nothing
end 

function reset_swc_to_fc!(simulation::RepSim, compartments::Vector{AbstractParametersContainer},
                           soil_layers::Vector{AbstractParametersContainer}, ziaqua)
    reset_swc_to_fc!(simulation, CompartmentIndividual[c for c in compartments], SoilLayerIndividual[s for s in soil_layers], ziaqua)
    return nothing
end
"""
    no_irrigation!(gvars)

global.f90:2838
"""
function no_irrigation!(gvars)
    setparameter!(gvars[:symbol_parameters], :irrimode, :NoIrri)
    setparameter!(gvars[:symbol_parameters], :irrimethod, :MSprinkler)
    gvars[:simulation].IrriECw = 0
    setparameter!(gvars[:symbol_parameters], :timemode, :AllRAW)
    setparameter!(gvars[:symbol_parameters], :depthmode, :ToFC)

    for nri = 1:5
        gvars[:irri_before_season][nri].DayNr = 0
        gvars[:irri_before_season][nri].Param = 0
        gvars[:irri_after_season][nri].DayNr = 0
        gvars[:irri_after_season][nri].Param = 0
    end 
    gvars[:irri_ecw].PreSeason = 0 
    gvars[:irri_ecw].PostSeason = 0 

    return nothing
end 

"""
    load_irri_schedule_info!(gvars, irri_file)

global.f90:2860
"""
function load_irri_schedule_info!(gvars, irri_file)
    open(irri_file, "r") do file
        readline(file)
        readline(file)

        # irrigation method
        i = parse(Int, split(readline(file))[1])
        if i==1
            gvars[:symbol_parameters][:irrimethod] = :MSprinkler
        elseif i==2
            gvars[:symbol_parameters][:irrimethod] = :MBasin
        elseif i==3
            gvars[:symbol_parameters][:irrimethod] = :MBorder
        elseif i==4
            gvars[:symbol_parameters][:irrimethod] = :MFurrow 
        else
            gvars[:symbol_parameters][:irrimethod] = :MDrip 
        end
        # fraction of soil surface wetted
        gvars[:simulparam].IrriFwInSeason = parse(Int, split(readline(file))[1])

        # irrigation mode and parameters
        i = parse(Int, split(readline(file))[1])
        if i==0
            gvars[:symbol_parameters][:irrimode] = :NoIrri
        elseif i==1
            gvars[:symbol_parameters][:irrimode] = :Manual
        elseif i==2
            gvars[:symbol_parameters][:irrimode] = :Generate
        else
            gvars[:symbol_parameters][:irrimode] = :Inet
        end 

        # 1. Irrigation schedule
        if i == 1
            gvars[:integer_parameters][:irri_first_daynr] = parse(Int, split(readline(file))[1])
        end 


        # 2. Generate
        if gvars[:symbol_parameters][:irrimode] == :Generate 
            i = parse(Int, split(readline(file))[1])
            if i==1
                gvars[:symbol_parameters][:timemode] = :FixInt
            elseif i==2
                gvars[:symbol_parameters][:timemode] = :AllDepl
            elseif i==3
                gvars[:symbol_parameters][:timemode] = :AllRAW
            elseif i==4
                gvars[:symbol_parameters][:timemode] = :WaterBetweenBunds
            else
                gvars[:symbol_parameters][:timemode] = :AllRAW
            end
            i = parse(Int, split(readline(file))[1])
            if i==1
                gvars[:symbol_parameters][:depthmode] = :ToFc
            else
                gvars[:symbol_parameters][:depthmode] = :FixDepth
            end 
        end 

        # 3. Net irrigation requirement
        if gvars[:symbol_parameters][:irrimode] == :Inet 
            gvars[:simulparam].PercRAW = parse(Int, split(readline(file))[1])
        end 

        # 4. If irigation is :Manual or :Generate we read the rest of the file and save in arrays
        if gvars[:symbol_parameters][:irrimode] == :Manual 
            readline(file)
            readline(file)
            Irri_1 = Float64[]
            Irri_2 = Float64[]
            Irri_3 = Float64[]
            for line in eachline(file)
                splitedline = split(line)
                ir1 = parse(Int, popfirst!(splitedline))
                ir2 = parse(Int, popfirst!(splitedline))
                irriecw = parse(Float64, popfirst!(splitedline))
                push!(Irri_1, ir1)
                push!(Irri_2, ir2)
                push!(Irri_3, irriecw)
            end
            setparameter!(gvars[:array_parameters], :Irri_1, Irri_1)
            setparameter!(gvars[:array_parameters], :Irri_2, Irri_2)
            setparameter!(gvars[:array_parameters], :Irri_3, Irri_3)
        end

        if gvars[:symbol_parameters][:irrimode] == :Generate 
            readline(file)
            readline(file)
            readline(file)
            Irri_1 = Float64[]
            Irri_2 = Float64[]
            Irri_3 = Float64[]
            Irri_4 = Float64[]
            for line in eachline(file)
                splitedline = split(line)
                fromday = parse(Int, popfirst!(splitedline))
                timeinfo = parse(Int, popfirst!(splitedline))
                depthinfo = parse(Int, popfirst!(splitedline))
                irriecw = parse(Float64, popfirst!(splitedline))
                push!(Irri_1, fromday)
                push!(Irri_2, timeinfo)
                push!(Irri_3, depthinfo)
                push!(Irri_4, irriecw)
            end
            setparameter!(gvars[:array_parameters], :Irri_1, Irri_1)
            setparameter!(gvars[:array_parameters], :Irri_2, Irri_2)
            setparameter!(gvars[:array_parameters], :Irri_3, Irri_3)
            setparameter!(gvars[:array_parameters], :Irri_4, Irri_4)
        end
    end

    return nothing
end 

"""
    load_management!(gvars, man_file; kwargs...)

global.f90:3350
"""
function load_management!(gvars, man_file; kwargs...)
    _load_management!(kwargs[:runtype], gvars, man_file) 
    return nothing
end

function _load_management!(runtype::NormalFileRun, gvars, man_file)
    management = gvars[:management]
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    open(man_file, "r") do file
        readline(file)
        readline(file)
        # mulches
        management.Mulch = parse(Int, split(readline(file))[1])
        management.EffectMulchInS = parse(Int, split(readline(file))[1])
        # soil fertility
        management.FertilityStress = parse(Int, split(readline(file))[1])
        simulation.EffectStress = crop_stress_parameters_soil_fertility(crop.StressResponse, management.FertilityStress)
        # soil bunds
        management.BundHeight = parse(Float64, split(readline(file))[1])
        simulation.SurfaceStorageIni = 0
        simulation.ECStorageIni = 0
        # surface run-off
        i = parse(Int, split(readline(file))[1])
        if i==1 
            management.RunoffOn = false # prevention of surface runoff
        else
            management.RunoffOn = true # surface runoff is not prevented
        end 
        management.CNcorrection = parse(Int, split(readline(file))[1])
        # weed infestation
        management.WeedRC = parse(Int, split(readline(file))[1])# relative cover of weeds (%)
        management.WeedDeltaRC = parse(Int, split(readline(file))[1])
        # shape factor of the CC expansion
        # function in a weed infested field
        management.WeedShape = parse(Float64, split(readline(file))[1])
        management.WeedAdj = parse(Int, split(readline(file))[1])
        # multiple cuttings
        i = parse(Int, split(readline(file))[1])
        if i==0 
            management.Cuttings.Considered = false
        else
            management.Cuttings.Considered = true 
        end 
        # Canopy cover (%) after cutting
        management.Cuttings.CCcut = parse(Int, split(readline(file))[1])
        # Next line is expected to be present in the input file, however
        # A PARAMETER THAT IS NO LONGER USED since AquaCrop version 7.1
        readline(file)
        # Considered first day when generating cuttings
        # (1 = start of growth cycle)
        management.Cuttings.Day1 = parse(Int, split(readline(file))[1])
        # Considered number owhen generating cuttings
        # (-9 = total growth cycle)
        management.Cuttings.NrDays = parse(Int, split(readline(file))[1])
        i = parse(Int, split(readline(file))[1])
        if i==1 
            management.Cuttings.Generate = true
        else
            management.Cuttings.Generate = false 
        end
        # Time criterion for generating cuttings
        i = parse(Int, split(readline(file))[1])
        if i==0
            # not applicable
            management.Cuttings.Criterion = :NA
        elseif i==1
            # interval in days
            management.Cuttings.Criterion = :IntDay
        elseif i==2
            # interval in Growing Degree Days
            management.Cuttings.Criterion = :IntGDD
        elseif i==3
            # produced dry above ground biomass (ton/ha)
            management.Cuttings.Criterion = :DryB
        elseif i==4
            # produced dry yield (ton/ha)
            management.Cuttings.Criterion = :DryY
        elseif i==5
            # produced fresh yield (ton/ha)
            management.Cuttings.Criterion = :FreshY
        end 
        # final harvest at crop maturity:
        i = parse(Int, split(readline(file))[1])
        if i==1 
            management.Cuttings.HarvestEnd = true
        else
            management.Cuttings.HarvestEnd = false
        end 
        # dayNr for Day 1 of list of cuttings
        # (-9 = Day1 is start growing cycle)
        management.Cuttings.FirstDayNr = parse(Int, split(readline(file))[1])
    end
    return nothing
end 

function _load_management!(runtype::T, gvars, man_file) where T<:TomlFileRun
    load_gvars_from_toml!(gvars[:management], man_file)

    management = gvars[:management]
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    simulation.EffectStress = crop_stress_parameters_soil_fertility(crop.StressResponse, management.FertilityStress)
    # soil bunds
    simulation.SurfaceStorageIni = 0
    simulation.ECStorageIni = 0
    return nothing
end

function _load_management!(runtype::T, gvars, man_file; kwargs...) where T<:NoFileRun
    if haskey(kwargs, :management)
        actualize_with_dict!(gvars[:management], kwargs[:management])
    end

    management = gvars[:management]
    crop = gvars[:crop]
    simulation = gvars[:simulation]
    simulation.EffectStress = crop_stress_parameters_soil_fertility(crop.StressResponse, management.FertilityStress)
    # soil bunds
    simulation.SurfaceStorageIni = 0
    simulation.ECStorageIni = 0
    return nothing
end
    
"""
    adjust_size_compartments!(gvars, cropzx)

global.f90:6563
"""
function adjust_size_compartments!(gvars, cropzx)
    compartments = gvars[:compartments]
    simulparam = gvars[:simulparam]

    # 1. Save intial soil water profile (required when initial soil
    # water profile is NOT reset at start simulation - see 7.)
    # 2. Actual total depth of compartments
    prevnrcomp = length(compartments)
    prevthickcomp = Float64[]
    prevvolprcomp = Float64[]
    totdepthc = 0
    for compi in eachindex(compartments)
        push!(prevthickcomp, compartments[compi].Thickness)
        push!(prevvolprcomp, compartments[compi].Theta * 100)
        totdepthc += compartments[compi].Thickness
    end

    # 3. Increase number of compartments (if less than 12)
    if (length(compartments) < max_no_compartments) 
        logi = true
        while logi
            if (cropzx-totdepthc)>simulparam.CompDefThick
                push!(compartments, CompartmentIndividual(Thickness=simulparam.CompDefThick))
            else
                push!(compartments, CompartmentIndividual(Thickness=cropzx-totdepthc))
            end 
            totdepthc += compartments[end].Thickness
            if (length(compartments)==max_no_compartments) | ((totdepthc+0.00001)>=cropzx) 
                logi = false
            end
        end 
    end 

    # 4. Adjust size of compartments (if total depth of compartments < rooting depth)
    if (totdepthc+0.00001)<cropzx
        fadd = (cropzx/0.1 - 12)/78
        totdepthc = 0
        for i in eachindex(compartments)
            compartments[i].Thickness = round(Int, 20*0.1 * (1 + i*fadd))*0.05
            totdepthc += compartments[i].Thickness
        end 
        if totdepthc<cropzx 
            logi = true
            while logi
                compartments[12].Thickness += 0.05
                totdepthc += 0.05
                if totdepthc>=cropzx 
                    logi = false
                end
            end 
        else
            while (totdepthc - 0.04999999)>=cropzx
                compartments[12].Thickness -= 0.05
                totdepthc = totdepthc - 0.05
            end 
        end 
    end 
    # 5. Adjust soil water content and theta initial
    prevecdscomp = zero(prevvolprcomp) #OJO this is not declared in fortran code, but it is implicit value is 0 and that is what we do here
    adjust_theta_initial!(gvars, prevnrcomp, prevthickcomp, prevvolprcomp, prevecdscomp)
    return nothing
end 

"""
    adjust_theta_initial!(gvars, prevnrcomp, prevthickcomp, prevvolprcomp, prevecdscomp)

global.f90:5852
"""
function adjust_theta_initial!(gvars, prevnrcomp, prevthickcomp, prevvolprcomp, prevecdscomp)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulation = gvars[:simulation]

    # 1. Actual total depth of compartments
    totdepthc = 0
    for compi in eachindex(compartments)
        totdepthc += compartments[compi].Thickness
    end 

    # 2. Stretch thickness of bottom soil layer if required
    totdepthl = 0
    for layeri in eachindex(soil_layers)
        totdepthl += soil_layers[layeri].Thickness
    end 
    if totdepthc>totdepthl 
        soil_layers[end].Thickness += (totdepthc - totdepthl)
    end 

    # 3. Assign a soil layer to each soil compartment
    designate_soillayer_to_compartments!(compartments, soil_layers)

    # 4. Adjust initial Soil Water Content of soil compartments
    if simulation.ResetIniSWC 
        if simulation.IniSWC.AtDepths 
            translate_inipoints_to_swprofile!(gvars, simulation.IniSWC.NrLoc, simulation.IniSWC.Loc, simulation.IniSWC.VolProc, simulation.IniSWC.SaltECe)
        else
            translate_inilayers_to_swprofile!(gvars, simulation.IniSWC.NrLoc, simulation.IniSWC.Loc, simulation.IniSWC.VolProc, simulation.IniSWC.SaltECe)
        end 
    else
        translate_inilayers_to_swprofile!(gvars, prevnrcomp, prevthickcomp, prevvolprcomp, prevecdscomp) 
    end 

    # 5. Adjust watercontent in soil layers and determine ThetaIni
    for layeri in eachindex(soil_layers)
        soil_layers[layeri].WaterContent = 0
    end 
    for compi in eachindex(compartments)
        simulation.ThetaIni[compi] = compartments[compi].Theta
        soil_layers[compartments[compi].Layer].WaterContent += simulation.ThetaIni[compi]*100*10*compartments[compi].Thickness
    end 
    total = 0
    for layeri in eachindex(soil_layers)
        total += soil_layers[layeri].WaterContent
    end 
    gvars[:total_water_content].BeginDay = total

    return nothing
end 

"""
    translate_inipoints_to_swprofile!(gvars, nrloc, locdepth, locvolpr, locecds)

global.f90:6258
"""
function translate_inipoints_to_swprofile!(gvars, nrloc, locdepth, locvolpr, locecds)
    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]
    simulparam = gvars[:simulparam]
    nrcomp = length(compartments)

    totd = 0
    for compi in eachindex(compartments)
        compartments[compi].Theta = 0
        compartments[compi].WFactor = 0 # used for salt in (10*volsat*dz * ec)
        totd += compartments[compi].Thickness
    end 
    compi = 0
    depthi = 0
    addcomp = true
    th2 = locvolpr[1]
    ec2 = locecds[1]
    d2 = 0
    loci = 0
    while (compi<nrcomp) | ((compi==nrcomp) & (addcomp==false))
        # upper and lower boundaries location
        d1 = d2
        th1 = th2
        ec1 = ec2
        if loci<nrloc 
            loci += 1
            d2 = locdepth[loci]
            th2 = locvolpr[loci]
            ec2 = locecds[loci]
        else
            d2 = totd
        end 
        # transfer water to compartment (swc in mm) and salt in (10*volsat*dz * ec)
        theend = false
        dtopcomp = d1  # depthi is the bottom depth
        thbotcomp = th1
        ecbotcomp = ec1
        while !theend
            thtopcomp = thbotcomp
            ectopcomp = ecbotcomp
            if (addcomp) 
                compi = compi + 1
                depthi = depthi + compartments[compi].Thickness
            end 
            if depthi<d2 
                thbotcomp = th1 + (th2-th1)*(depthi-d1)/(d2-d1)
                compartments[compi].Theta = compartments[compi].Theta + 10*(depthi-dtopcomp)*(thtopcomp+thbotcomp)/2
                ecbotcomp = ec1 + (ec2-ec1)*(depthi-d1)/(d2-d1)
                compartments[compi].WFactor = compartments[compi].WFactor + 10*(depthi-dtopcomp)*soil_layers[compartments[compi].Layer].SAT*(ectopcomp+ecbotcomp)/2
                addcomp = true
                dtopcomp = depthi
                if compi==nrcomp 
                    theend = true
                end 
            else
                thbotcomp = th2
                ecbotcomp = ec2
                compartments[compi].Theta = compartments[compi].Theta + 10*(d2-dtopcomp)*(thtopcomp+thbotcomp)/2
                compartments[compi].WFactor = compartments[compi].WFactor + (10*(d2-dtopcomp)*soil_layers[compartments[compi].Layer].SAT*(ectopcomp+ecbotcomp)/2)
                if abs(depthi - d2)<eps()
                    addcomp = true
                else
                    addcomp = false
                end 
                theend = true
            end 
        end 
    end 

    for compi in eachindex(compartments)
        # from mm(water) to theta and final check
        compartments[compi].Theta = compartments[compi].Theta/(1000*compartments[compi].Thickness)
        if (compartments[compi].Theta>soil_layers[compartments[compi].Layer].SAT/100)
            compartments[compi].Theta = soil_layers[compartments[compi].Layer].SAT/100
        end 
        if compartments[compi].Theta<0 
            compartments[compi].Theta=0
        end 
        # from (10*VolSat*dZ * EC) to ECe and distribution in cellls
        compartments[compi].WFactor = compartments[compi].WFactor/(10*compartments[compi].Thickness*soil_layers[compartments[compi].Layer].SAT)

        determine_salt_content!(compartments[compi], soil_layers, simulparam)
    end 

    return nothing
end 

"""
    determine_salt_content!(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual}, simulparam::RepParam)

global.f90:4258
"""
function determine_salt_content!(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual}, simulparam::RepParam)
    ece = compartment.WFactor
    totsalt = ece*equiv*soil_layers[compartment.Layer].SAT*10*compartment.Thickness
    celn = active_cells(compartment, soil_layers)
    sat = soil_layers[compartment.Layer].SAT/100  # m3/m3
    ul = soil_layers[compartment.Layer].UL # m3/m3   ! Upper limit of SC salt cel
    dx = soil_layers[compartment.Layer].Dx  # m3/m3  ! Size of salts cel (expect last one)
    mm1 = dx*1000*compartment.Thickness * (1-soil_layers[compartment.Layer].GravelVol/100) # g/l ! volume [mm]=[l/m2] of cells
    mmn = (sat-ul)*1000*compartment.Thickness * (1-soil_layers[compartment.Layer].GravelVol/100) # g/l ! volume [mm]=[l/m2] of last cell
    sumdf = 0
    for i in 1:soil_layers[compartment.Layer].SCP1
        compartment.Salt[i] = 0
        compartment.Depo[i] = 0
    end 
    for i in 1:celn
        sumdf += soil_layers[compartment.Layer].SaltMobility[i]
    end 
    for i in 1:celn
        compartment.Salt[i] = totsalt * soil_layers[compartment.Layer].SaltMobility[i]/sumdf
        mm = mm1
        if i==soil_layers[compartment.Layer].SCP1 
            mm = mmn
        end
        salt_solution_deposit!(compartment, simulparam, i, mm)
    end 

    return nothing
end 

function determine_salt_content!(compartment::CompartmentIndividual, soil_layers::Vector{AbstractParametersContainer}, simulparam::RepParam)
    determine_salt_content!(compartment, SoilLayerIndividual[s for s in soil_layers], simulparam)
    return nothing
end

"""
    celi = active_cells(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual})

globa.f90:4241
"""
function active_cells(compartment::CompartmentIndividual, soil_layers::Vector{SoilLayerIndividual})
    if compartment.Theta<=soil_layers[compartment.Layer].UL 
        celi = 1
        while (compartment.Theta>(soil_layers[compartment.Layer].Dx * celi))
            celi = celi + 1
        end 
    else
        celi = soil_layers[compartment.Layer].SCP1
    end 
    return celi
end 

function active_cells(compartment::CompartmentIndividual, soil_layers::Vector{AbstractParametersContainer})
    return active_cells(compartment, SoilLayerIndividual[s for s in soil_layers])
end

"""
    salt_solution_deposit!(compartment::CompartmentIndividual, simulparam::RepParam, i, mm)

global.f90:2572
"""
function salt_solution_deposit!(compartment::CompartmentIndividual, simulparam::RepParam, i, mm) # mm = l/m2, SaltSol/Saltdepo = g/m2
    saltsolution = compartment.Salt[i]
    saltdeposit = compartment.Depo[i]

    saltsolution = saltsolution + saltdeposit
    if saltsolution>simulparam.SaltSolub*mm 
        saltdeposit = saltsolution - simulparam.SaltSolub * mm
        saltsolution = simulparam.SaltSolub * mm
    else
        saltdeposit = 0
    end 

    compartment.Salt[i] = saltsolution
    compartment.Depo[i] = saltdeposit

    return nothing
end 

"""
    translate_inilayers_to_swprofile!(gvars, nrlay, laythickness, layvolpr, layecds)

global.f90:6179
"""
function translate_inilayers_to_swprofile!(gvars, nrlay, laythickness, layvolpr, layecds)
    compartments = gvars[:compartments]
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]
    nrcomp = length(compartments)

    # from specific layers to Compartments
    for compi in eachindex(compartments)
        compartments[compi].Theta = 0
        compartments[compi].WFactor = 0  # used for ECe in this procedure
    end 
    compi = 0
    sdcomp = 0
    layeri = 1
    sdlay = laythickness[1]
    goon = true
    while compi < nrcomp
        fracc = 0
        compi = compi + 1
        sdcomp = sdcomp + compartments[compi].Thickness
        if sdlay>=sdcomp 
            compartments[compi].Theta = compartments[compi].Theta + (1-fracc)*layvolpr[layeri]/100
            compartments[compi].WFactor = compartments[compi].WFactor + (1-fracc)*layecds[layeri]
        else
            # go to next layer
            while ((sdlay<sdcomp) & goon)
                # finish handling previous layer
                fracc = (sdlay - (sdcomp-compartments[compi].Thickness))/(compartments[compi].Thickness) - fracc
                compartments[compi].Theta = compartments[compi].Theta + fracc*layvolpr[layeri]/100
                compartments[compi].WFactor = compartments[compi].WFactor + fracc*layecds[layeri]
                fracc = (sdlay - (sdcomp-compartments[compi].Thickness))/(compartments[compi].Thickness)
                # add next layer
                if layeri<nrlay 
                    layeri = layeri + 1
                    sdlay = sdlay + laythickness[layeri]
                else
                    goon = false
                end 
            end 
            compartments[compi].Theta = compartments[compi].Theta + (1-fracc)*layvolpr[layeri]/100
            compartments[compi].WFactor = compartments[compi].WFactor + (1-fracc)*layecds[layeri]
        end 
        # next Compartment
    end 
    if  !goon
        for i in (compi+1):length(compartments)
            compartments[i].Theta = layvolpr[nrlay]/100
            compartments[i].WFactor = layecds[nrlay]
        end 
    end 

    # final check of SWC
    for compi in eachindex(compartments)
        if (compartments[compi].Theta > soil_layers[compartments[compi].Layer].SAT/100) 
            compartments[compi].Theta = soil_layers[compartments[compi].Layer].SAT/100
        end 
        # salt distribution in cellls
        determine_salt_content!(compartments[compi], soil_layers, simulparam)
    end 

    return nothing
end 

"""
     load_initial_conditions!(gvars, swcinifilefull)

global.f90:6486
"""
function load_initial_conditions!(gvars, swcinifilefull)
    simulation = gvars[:simulation]
    # IniSWCRead attribute of the function was removed to fix a
    # bug occurring when the function was called in TempProcessing.pas
    # Keep in mind that this could affect the graphical interface
    open(swcinifilefull, "r") do file
        readline(file)
        simulation.CCini = parse(Float64, split(readline(file))[1]) 
        simulation.Bini = parse(Float64, split(readline(file))[1]) 
        simulation.Zrini = parse(Float64, split(readline(file))[1]) 
        setparameter!(gvars[:float_parameters], :surfacestorage, parse(Float64, split(readline(file))[1]))
        simulation.ECStorageIni = parse(Float64, split(readline(file))[1])
        i = parse(Int, split(readline(file))[1])
        if i==1
            simulation.IniSWC.AtDepths = true
        else
            simulation.IniSWC.AtDepths = false 
        end
        simulation.IniSWC.NrLoc = parse(Int, split(readline(file))[1])
        readline(file)
        readline(file)
        readline(file)
        for i in 1:simulation.IniSWC.NrLoc
            splitedline = split(readline(file))
            simulation.IniSWC.Loc[i] =parse(Float64,  popfirst!(splitedline))
            simulation.IniSWC.VolProc[i] = parse(Float64,  popfirst!(splitedline))
            simulation.IniSWC.SaltECe[i] = parse(Float64,  popfirst!(splitedline))
        end
    end
    simulation.IniSWC.AtFC = false

    return nothing
end 

"""
    ece = ececomp(compartment::CompartmentIndividual, gvars)

global.f90:2523
"""
function ececomp(compartment::CompartmentIndividual, gvars)
    soil_layers = gvars[:soil_layers]
    simulparam = gvars[:simulparam]

    volsat = soil_layers[compartment.Layer].SAT
    totsalt = 0
    for i in 1:soil_layers[compartment.Layer].SCP1
        totsalt = totsalt + compartment.Salt[i] + compartment.Depo[i] # g/m2
    end 

    denominator = volsat*10 * compartment.Thickness * (1 - soil_layers[compartment.Layer].GravelVol/100)
    totsalt = totsalt / denominator  # g/l

    if totsalt>simulparam.SaltSolub
        totsalt = simulparam.SaltSolub
    end
    return totsalt / equiv # ds/m
end 

"""
    load_offseason!(gvars, offseason_file)

global.f90:5769
"""
function load_offseason!(gvars, offseason_file)
    management = gvars[:management]
    simulation = gvars[:management]
    irri_before_season = gvars[:irri_before_season]
    irri_after_season = gvars[:irri_after_season]
    irri_ecw = gvars[:irri_ecw]

    if isfile(offseason_file)
        open(offseason_file, "r") do file
            readline(file)
            readline(file)
            management.SoilCoverBefore = parse(Int, split(readline(file))[1])
            management.SoilCoverAfter = parse(Int, split(readline(file))[1])
            management.EffectMulchOffS = parse(Int, split(readline(file))[1])

            # irrigation events - initialise
            for nri in 1:5
                irri_before_season.DayNr[nri] = 0
                irri_before_season.Param[nri] = 0
                irri_after_season.DayNr[nri] = 0
                irri_after_season.Param[nri] = 0
            end
            # number of irrigation events BEFORE growing period
            nrevents1 = parse(Int, split(readline(file))[1])
            # irrigation water quality BEFORE growing period
            irri_ecw.PreSeason = parse(Float64, split(readline(file))[1])
            # number of irrigation events AFTER growing period
            nrevents2 = parse(Int, split(readline(file))[1])
            # irrigation water quality AFTER growing period
            irri_ecw.PostSeason = parse(Float64, split(readline(file))[1])

            # percentage of soil surface wetted
            simulation.IrriFwOffSeason = parse(Int, split(readline(file))[1])

            # irrigation events - get events before and after season
            if (nrevents1>0) | (nrevents2>0) 
                for _ in 1:3
                    readline(file)
                end
            end 
            if nrevents1>0 
                for nri in 1:nrevents1
                    # events BEFORE growing period
                    splitedline = split(readline(file))
                    irri_before_season.DayNr[nri] = parse(Int, popfirst!(splitedline))
                    irri_before_season.Param[nri] = parse(Int, popfirst!(splitedline))
                end 
            end 
            if nrevents2>0 
                for nri in 2:nrevents1
                    # events AFTER growing period
                    splitedline = split(readline(file))
                    irri_after_season.DayNr[nri] = parse(Int, popfirst!(splitedline))
                    irri_after_season.Param[nri] = parse(Int, popfirst!(splitedline))
                end 
            end 
        end
    end
    return nothing
end 

"""
    adjust_compartments!(gvars)

run.f90:6619
"""
function adjust_compartments!(gvars)
    simulation = gvars[:simulation]
    crop = gvars[:crop]
    soil = gvars[:soil]
    soil_layers = gvars[:soil_layers]
    compartments = gvars[:compartments]
    ziaqua = gvars[:integer_parameters][:ziaqua]
    # Adjust size of compartments if required
    totdepth = 0
    for i in eachindex(compartments) 
        totdepth += compartments[i].Thickness
    end 
    if simulation.MultipleRunWithKeepSWC 
        # Project with a sequence of simulation runs and KeepSWC
        if round(Int, simulation.MultipleRunConstZrx*1000)>round(Int,totdepth*1000)
            adjust_size_compartments!(gvars, simulation.MultipleRunConstZrx)
        end 
    else
        if round(Int, crop.RootMax*1000)>round(Int,totdepth*1000)
            if round(Int, soil.RootMax*1000)==round(Int, crop.RootMax*1000)
                # no restrictive soil layer
                adjust_size_compartments!(gvars, crop.RootMax)
                # adjust soil water content
                calculate_adjusted_fc!(compartments, soil_layers, ziaqua/100) 
                if simulation.IniSWC.AtFC
                    reset_swc_to_fc!(simulation, compartments, soil_layers, ziaqua) 
                end
            else
                # restrictive soil layer
                if round(Int, soil.RootMax*1000)>round(Int,totdepth*1000)
                    adjust_size_compartments!(gvars, soil.RootMax)
                    # adjust soil water content
                    calculate_adjusted_fc!(compartments, soil_layers, ziaqua/100) 
                    if simulation.IniSWC.AtFC
                        reset_swc_to_fc!(simulation, compartments, soil_layers, ziaqua) 
                    end
                end 
            end 
        end 
    end 
    return nothing
end 

"""
    reset_previous_sum!(gvars)

run.f90:3445
"""
function reset_previous_sum!(gvars)
    gvars[:previoussum] = RepSum()
    
    setparameter!(gvars[:float_parameters], :sumeto, 0.0)
    setparameter!(gvars[:float_parameters], :sumgdd, 0.0)
    setparameter!(gvars[:float_parameters], :previoussumeto, 0.0)
    setparameter!(gvars[:float_parameters], :previoussumgdd, 0.0)
    setparameter!(gvars[:float_parameters], :previousbmob, 0.0)
    setparameter!(gvars[:float_parameters], :previousbsto, 0.0)
    return nothing
end 

