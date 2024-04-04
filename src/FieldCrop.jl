abstract type AbstractFieldCrop end


"""
    FieldCrop

Has all the data for the simulation of AquaCrop
"""
struct FieldCrop <: AbstractFieldCrop
    data::Int
end


"""
    FieldCrop(inputDataDir::String)

Starts the struct FieldCrop that has all the data for the simulation of AquaCrop
"""
function FieldCrop(inputDataDir::String)
    data = readdata(inputDataDir)
    FieldCrop(data)
end


"""
    dailyupdate!(fieldcrop::AbstractFieldCrop)

Updates the FieldCrop by one day
"""
function dailyupdate!(fieldcrop::AbstractFieldCrop)
    return nothing
end

