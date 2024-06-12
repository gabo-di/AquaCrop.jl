#TODO

abstract type AbstractFieldCrop end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct FieldAquaCrop <: AbstractFieldCrop
    gvars::ComponentArray
    outputs::ComponentArray
end

function Base.getindex(b::FieldAquaCrop, s::Symbol)
    if s in fieldnames(FieldAquaCrop)
        return getfield(b, s) 
    else
        return getfield(b, :gvars)[s]
    end
end

function Base.getproperty(b::B, s::Symbol)
    if s in fieldnames(FieldAquaCrop)
        return getfield(b, s) 
    else
        return getfield(b, :gvars)[s]
    end
end



"""
    FieldAquaCrop(inputDataDir::String)

Starts the struct FieldAquaCrop that has all the data for the simulation of AquaCrop
"""
function FieldAquaCrop(inputDataDir::String)
    data = readdata(inputDataDir)
    FieldAquaCrop(data)
end


"""
    dailyupdate!(fieldcrop::AbstractFieldCrop)

Updates the FieldCrop by one day
"""
function dailyupdate!(fieldcrop::AbstractFieldCrop)
    return nothing
end

