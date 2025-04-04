"""
    d = struct_to_dict(s::AbstractParametersContainer)

converts an AbstractParametersContainer to a dictionary
"""
function struct_to_dict(s::AbstractParametersContainer)
    d = Dict()
    for key in propertynames(s)
        a = getfield(s, key)
        if typeof(a) <: AbstractParametersContainer
            b = struct_to_dict(a)
            d[string(key)] = b
        else
            d[string(key)] = a
        end
    end
    return d
end

"""
    write_gvar_in_toml(crop::RepCrop, io::IO=stdin; kwargs...)

crop     crop to be saved
head     header to describe the file.

Writes the crop into a toml file. Useful after tunning a crop
"""
function write_gvar_in_toml(crop::RepCrop, io::IO=stdin; kwargs...)

    aux = Dict()
    aux["crop"] = struct_to_dict(crop)

    xx = aux["crop"]["subkind"]
    if xx==:Vegetative
        aux["crop"]["subkind"] = 1
    elseif xx==:Grain
        aux["crop"]["subkind"] = 2
    elseif xx==:Tuber
        aux["crop"]["subkind"] = 3
    elseif xx==:Forage
        aux["crop"]["subkind"] = 4
    end

    xx = aux["crop"]["Planting"]
    if xx==:Seed
        aux["crop"]["Planting"] = 1
    elseif xx==:Transplant
        aux["crop"]["Planting"] = 0
    elseif xx==:Regrowth
        aux["crop"]["Planting"] = -9
    else
        aux["crop"]["Planting"] = 1
    end

    xx = aux["crop"]["ModeCycle"]
    if xx==:GDDays
        aux["crop"]["ModeCycle"] = 0
    else
        aux["crop"]["ModeCycle"] = 1
    end

    xx = aux["crop"]["pMethod"]
    if xx==:NoCorrection
        aux["crop"]["pMethod"] = 0
    elseif xx==:FAOCorrection
        aux["crop"]["pMethod"] = 1
    end

    xx = aux["crop"]["Assimilates"]["On"]
    if xx==true
        aux["crop"]["Assimilates"]["On"] = 1
    else
        aux["crop"]["Assimilates"]["On"] = 0
    end

    xx = aux["crop"]["DeterminancyLinked"]
    if xx==true
        aux["crop"]["DeterminancyLinked"] = 1
    else
        aux["crop"]["DeterminancyLinked"] = 0
    end

    xx = aux["crop"]["SownYear1"]
    if xx==true
        aux["crop"]["SownYear1"] = 1
    else
        aux["crop"]["SownYear1"] = 0
    end

    TOML.print(io, aux)

    return nothing
end
