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

startunit.f90:767
"""
function load_gvars_from_toml!(simulparam::RepParam, auxparfile; kwargs...)
    aux = TOML.parsefile(auxparfile)

    i = aux["simulparam"]["CNcorrection"]
    if i == 1
        aux["simulparam"]["CNcorrection"] = true
    else
        aux["simulparam"]["CNcorrection"] = false
    end

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

