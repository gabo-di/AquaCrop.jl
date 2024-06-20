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
    load_program_parameters_project_plugin_toml!(simulparam::RepParam, auxparfile)

startunit.f90:767
"""
function load_program_parameters_project_plugin_toml!(simulparam::RepParam, auxparfile)
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
