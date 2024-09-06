"""
    load_gvars_from_toml!(simulparam::RepParam, auxparfile; kwargs...)
"""
function load_gvars_from_toml!(simulparam::RepParam, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    gddmethod = aux["simulparam"]["GDDMethod"]
    if gddmethod > 3
        aux["simulparam"]["GDDMethod"] = 3
    end
    if gddmethod < 1
        aux["simulparam"]["GDDMethod"] = 1
    end

    i = aux["simulparam"]["EffectiveRain"]["method"]
    if i == 0 
        aux["simulparam"]["EffectiveRain"]["method"] = :Full
    elseif i == 1 
        aux["simulparam"]["EffectiveRain"]["method"] = :USDA
    elseif i == 2 
        aux["simulparam"]["EffectiveRain"]["method"] = :Percentage
    end

    i = aux["simulparam"]["CNcorrection"]
    if i == 1 
        aux["simulparam"]["CNcorrection"] = true
    else
        aux["simulparam"]["CNcorrection"] = false
    end 

    actualize_with_dict!(simulparam, aux["simulparam"])
    return nothing
end

function load_gvars_from_toml!(soil::RepSoil, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    actualize_with_dict!(soil, aux["soil"])
    return nothing
end

function load_gvars_from_toml!(soil_layers::Vector{SoilLayerIndividual}, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    for i in eachindex(aux["soil_layers"]) 
        soillayer = SoilLayerIndividual()

        actualize_with_dict!(soillayer, aux["soil_layers"][i])

        gravelv_temp = from_gravelmass_to_gravelvol(soillayer.SAT, soillayer.GravelMass)
        soillayer.GravelVol = gravelv_temp

        push!(soil_layers, soillayer)
    end

    return nothing
end

function load_gvars_from_toml!(record::RepClim, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    key = kwargs[:str]

    ni = aux[key]["Datatype"]
    if ni == 1
       aux[key]["Datatype"] = :Daily 
    elseif ni == 2
       aux[key]["Datatype"] = :Decadely 
    else
       aux[key]["Datatype"] = :Monthly
    end

    # OJO missing record.NrObs

    actualize_with_dict!(record, aux[key])
    return nothing
end

function load_gvars_from_toml!(management::RepManag, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)
    
    i = aux["management"]["RunoffOn"]
    if i == 1
        aux["management"]["RunoffOn"] = false
    else
        aux["management"]["RunoffOn"] = true
    end

    i = aux["management"]["Cuttings"]["Criterion"]
    if i==0
        aux["management"]["Cuttings"]["Criterion"] = :NA
    elseif i==1
        aux["management"]["Cuttings"]["Criterion"] = :IntDay
    elseif i==2
        aux["management"]["Cuttings"]["Criterion"] = :IntGDD
    elseif i==3 
        aux["management"]["Cuttings"]["Criterion"] = :DryB
    elseif i==4 
        aux["management"]["Cuttings"]["Criterion"] = :DryY
    elseif i==5 
        aux["management"]["Cuttings"]["Criterion"] = :FreshY
    end


    actualize_with_dict!(management, aux["management"])
    return nothing
end

function load_gvars_from_toml!(crop::RepCrop, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    xx = aux["crop"]["subkind"]
    if xx==1
        aux["crop"]["subkind"] = :Vegetative
    elseif xx==2
        aux["crop"]["subkind"] = :Grain
    elseif xx==3
        aux["crop"]["subkind"] = :Tuber
    elseif xx==4
        aux["crop"]["subkind"] = :Forage
    end

    xx = aux["crop"]["Planting"]
    if xx==1
        aux["crop"]["Planting"] = :Seed
    elseif xx==0 
        aux["crop"]["Planting"] = :Transplant
    elseif xx==-9 
        aux["crop"]["Planting"] = :Regrowth
    else
        aux["crop"]["Planting"] = :Seed
    end

    xx = aux["crop"]["ModeCycle"]
    if xx==0
        aux["crop"]["ModeCycle"] = :GDDays
    else
        aux["crop"]["ModeCycle"] = :CalendarDays
    end

    xx = aux["crop"]["pMethod"]
    if xx==0
        aux["crop"]["pMethod"] = :NoCorrection
    elseif xx==1
        aux["crop"]["pMethod"] = :FAOCorrection
    end

    xx = aux["crop"]["Assimilates"]["On"]
    if xx==1
        aux["crop"]["Assimilates"]["On"] = true
    else
        aux["crop"]["Assimilates"]["On"] = false 
    end

    xx = aux["crop"]["DeterminancyLinked"]
    if xx==1
        aux["crop"]["DeterminancyLinked"] = true
    else
        aux["crop"]["DeterminancyLinked"] = false
    end

    xx = aux["crop"]["SownYear1"]
    if xx==1
        aux["crop"]["SownYear1"] = true
    else
        aux["crop"]["SownYear1"] = false
    end

    actualize_with_dict!(crop, aux["crop"])


    crop.SmaxTop, crop.SmaxBot = derive_smax_top_bottom(crop)

    if ((crop.StressResponse.ShapeCGC>24.9) & (crop.StressResponse.ShapeCCX>24.9) &
        (crop.StressResponse.ShapeWP>24.9) & (crop.StressResponse.ShapeCDecline>24.9))
        crop.StressResponse.Calibrated = false
    else
        crop.StressResponse.Calibrated = true 
    end

    if crop.RootMin > crop.RootMax
        crop.RootMin = crop.RootMax
    end

    crop.CCo = crop.PlantingDens/10000 * crop.SizeSeedling/10000
    crop.CCini = crop.PlantingDens/10000 * crop.SizePlant/10000

    if (crop.subkind==:Vegetative) | (crop.subkind==:Forage)
        crop.DaysToFlowering = 0
        crop.LengthFlowering = 0
    end

    if (crop.ModeCycle==:GDDays) & ((crop.subkind==:Vegetative) | (crop.subkind==:Forage))
        crop.GDDaysToFlowering = 0
        crop.GDDLengthFlowering = 0
    end

    
    return nothing
end

function load_gvars_from_toml!(perennial_period::RepPerennialPeriod, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    if !haskey(aux, "perennial_period")
        return nothing
    end

    xx = aux["perennial_period"]["aux_GenerateOnset"]
    if xx==0
        aux["perennial_period"]["GenerateOnset"] = false
    else
        aux["perennial_period"]["GenerateOnset"] = true 
        if xx==12
            aux["perennial_period"]["OnsetCriterion"] = :TMeanPeriod
        elseif xx==13
            aux["perennial_period"]["OnsetCriterion"] = :GDDPeriod
        else
            aux["perennial_period"]["GenerateOnset"] = false
        end
    end


    xx = aux["perennial_period"]["aux_GenerateEnd"]
    if xx==0
        aux["perennial_period"]["GenerateEnd"] = false
    else
        aux["perennial_period"]["GenerateEnd"] = true 
        if xx==62
            aux["perennial_period"]["EndCriterion"] = :TMeanPeriod
        elseif xx==63
            aux["perennial_period"]["EndCriterion"] = :GDDPeriod
        else
            aux["perennial_period"]["GenerateEnd"] = false
        end
    end


    actualize_with_dict!(perennial_period, aux["perennial_period"])

    if perennial_period.OnsetOccurrence > 3
        perennial_period.OnsetOccurrence = 3
    end

    if perennial_period.EndOccurrence > 3
        perennial_period.EndOccurrence = 3
    end

    return nothing 
end

function load_resultsparameters_from_toml(auxparfile)
    aux = TOML.parsefile(auxparfile)
    
    dailyresultsparameters = aux["resultsparameters"]["dailyresultsparameters"]
    if ( dailyresultsparameters["out1Wabal"] | dailyresultsparameters["out2Crop"] 
        | dailyresultsparameters["out3Prof"] | dailyresultsparameters["out4Salt"]
        | dailyresultsparameters["out5CompWC"] | dailyresultsparameters["out6CompEC"]
        | dailyresultsparameters["out7Clim"])
        aux["resultsparameters"]["dailyresultsparameters"]["outdaily"] = true
    else
        aux["resultsparameters"]["dailyresultsparameters"]["outdaily"] = false 
    end

    aggregationresultsparameters = aux["resultsparameters"]["aggregationresultsparameters"]
    aggregationtype = aggregationresultsparameters["outputaggregate"]
    if aggregationtype == 1
        aux["resultsparameters"]["aggregationresultsparameters"]["outputaggregate"] = 1 #"daily"
    elseif aggregationtype == 2
        aux["resultsparameters"]["aggregationresultsparameters"]["outputaggregate"] = 2 #"daily_10"
    elseif aggregationtype == 3
        aux["resultsparameters"]["aggregationresultsparameters"]["outputaggregate"] = 3 #"monthly"
    else
        aux["resultsparameters"]["aggregationresultsparameters"]["outputaggregate"] = 0 #"none"
    end



    aggregationresultsparameters = ParametersContainer(Int)
    actualize_with_dict!(aggregationresultsparameters, aux["resultsparameters"]["aggregationresultsparameters"])

    dailyresultsparameters = ParametersContainer(Bool)
    actualize_with_dict!(dailyresultsparameters, aux["resultsparameters"]["dailyresultsparameters"])

    particularresultsparameters = ParametersContainer(Bool)
    actualize_with_dict!(particularresultsparameters, aux["resultsparameters"]["particularresultsparameters"])

    return Dict{Symbol, AbstractParametersContainer}(
                :aggregationresults => aggregationresultsparameters,
                :dailyresults => dailyresultsparameters,
                :particularresults => particularresultsparameters)
end

function load_projectfilenames_from_toml(auxparfile)
    aux = TOML.parsefile(auxparfile)
    return aux["project_filenames"]
end

function load_projectinput_from_toml(auxparfile, parentdir) 
    aux = TOML.parsefile(auxparfile)
    projectinput = ProjectInputType[]
    for i in eachindex(aux["projectinput"])
        aux["projectinput"][i]["ParentDir"] = parentdir
        self = ProjectInputType()
        actualize_with_dict!(self, aux["projectinput"][i])
        push!(projectinput, self)
    end

    return projectinput
end
