"""
    checkget_gvar_file(outputs, filename)

we check if the file exists, if not we give the default file path
"""
function checkget_gvar_file(outputs, filename)
    file_ = ""
    if isfile(filename)
        file_ = filename
    else
        add_output_in_logger!(outputs, "using default file for gvars")
        file_ = joinpath([@__DIR__, "test/testcase/TOML_FILES/gvars.toml"])
    end
    return file_
end
        
"""
    checkget_resultsparameters_file(outputs, filename)

we check if the file exists, if not we give the default file path
"""
function checkget_resultsparameters_file(outputs, filename)
    file_ = ""
    if isfile(filename)
        file_ = filename
    else
        add_output_in_logger!(outputs, "using default file for resultsparameters")
        file_ = joinpath([@__DIR__, "test/testcase/TOML_FILES/resultsparameters.toml"])
    end
    return file_
end

"""
    checkget_projectfiles_file(outputs, filename)

we check if the file exists, if not we give the default file path
"""
function checkget_projectfiles_file(outputs, filename)
    file_ = ""
    if isfile(filename)
        file_ = filename
    else
        add_output_in_logger!(outputs, "using default file for project_filenames")
        file_ = joinpath([@__DIR__, "test/testcase/TOML_FILES/projectfilenames.toml"])
    end
    return file_
end

"""
    actualize_with_dict!(obj::T, aux::AbstractDict) where T<:AbstractParametersContainer
"""
function actualize_with_dict!(obj::T, aux::AbstractDict) where T<:AbstractParametersContainer
    field_names = String.(fieldnames(T))
    for key in keys(aux) 
        if key in field_names
            if typeof(aux[key]) <: AbstractDict
                actualize_with_dict!( getfield(obj, Symbol(key)), aux[key])
            else
                setfield!(obj, Symbol(key), aux[key]) 
            end
        end
    end
    return nothing
end

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


    actualize_with_dict!(crop, aux["crop"])


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
            aux["perennial_period"]["OnsetCriterion"] = :TMeanPeriod
        elseif xx==13
            aux["perennial_period"]["OnsetCriterion"] = :GDDPeriod
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
        aux["resultsparameters"]["dailyresultsparameters"]["outdailyresults"] = true
    end

    return ComponentArray(aggregationresults=aux["resultsparameters"]["aggregationresultsparameters"],
                dailyresults=aux["resultsparameters"]["dailyresultsparameters"],
                paricularresults=aux["resultsparameters"]["particularresultsparameters"])
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

# MISSING maybe ?
# resultsparameters.aggregationresultsparameters   initialsettings.jl:1460  (add to main!!)
# resultsparameters.dailyresultsparameters         initialsettings.jl:1478  (add to main!!)
# resultsparameters.particularresultsparameters    initialsettings.jl:1513  (add to main!!)
# project_filenames    initialsettings.jl:1403    (add to main!!)
# soil               initialsettings.jl.1047 (add to main!!)
# soillayer          initialsettings.jl.1047 (add to main!!)
# crop               loadsimulation.jl.608 (add to main!!)
# perennial_period   loadsimulation.jl.608 (add to main!!)
# simulparam         initialsettings.jl:86 (add to main!!)
# management         loadsimulation.jl:2615 (add to main!!)
# projectinput       initialsettings.jl:212 (add to main!!)
# -----------        initialsettings.jl:58  (add to main!!)
# record             loadsimulation.jl.314 (it is missing the part of NrObs that is actually related to th csv file)
#
