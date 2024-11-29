"""
    actualize_with_dict!(obj::T, aux::AbstractDict) where T<:AbstractParametersContainer
"""
function actualize_with_dict!(obj::T, aux::AbstractDict) where {T<:AbstractParametersContainer}
    field_names = String.(fieldnames(T))
    for key in keys(aux)
        if key in field_names
            if typeof(aux[key]) <: AbstractDict
                actualize_with_dict!(getfield(obj, Symbol(key)), aux[key])
            else
                setfield!(obj, Symbol(key), aux[key])
            end
        else
            if !startswith(key, "aux_")
                println("key " * key * " not found in type ", T)
            end
        end
    end
    return nothing
end

function actualize_with_dict!(obj::ParametersContainer{T}, aux::AbstractDict) where {T}
    for key in keys(aux)
        setparameter!(obj, Symbol(key), T(aux[key]))
    end
    return nothing
end

"""
    set_soil!(soil::RepSoil, soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

sets soil for a given soil_type
possible soil_type are 
["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay",
"sandy clay loam", "sandy loam", "silty clay loam", "paddy"]
"""
function set_soil!(soil::RepSoil, soil_type::AbstractString; aux::Union{AbstractDict,Nothing}=nothing)
    if soil_type == "sandy clay"
        # aquacrop version 6.0
        soil.CNValue = 77
        soil.REW = 10
        soil.NrSoilLayers = 1
    elseif soil_type == "clay"
        # aquacrop version 6.0
        soil.CNValue = 77
        soil.REW = 14
        soil.NrSoilLayers = 1
    elseif soil_type == "clay loam"
        # aquacrop version 6.0
        soil.CNValue = 72
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type == "loamy sand"
        # aquacrop version 6.0
        soil.CNValue = 46
        soil.REW = 5
        soil.NrSoilLayers = 1
    elseif soil_type == "loam"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 9
        soil.NrSoilLayers = 1
    elseif soil_type == "sand"
        # aquacrop version 6.0
        soil.CNValue = 46
        soil.REW = 4
        soil.NrSoilLayers = 1
    elseif soil_type == "silt"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type == "silty loam"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type == "silty clay"
        # aquacrop version 6.0
        soil.CNValue = 72
        soil.REW = 14
        soil.NrSoilLayers = 1
    elseif soil_type == "sandy clay loam"
        # aquacrop version 6.0
        soil.CNValue = 72
        soil.REW = 9
        soil.NrSoilLayers = 1
    elseif soil_type == "sandy loam"
        # aquacrop version 6.0
        soil.CNValue = 46
        soil.REW = 7
        soil.NrSoilLayers = 1
    elseif soil_type == "silty clay loam"
        # aquacrop version 6.0
        soil.CNValue = 72  
        soil.REW = 13
        soil.NrSoilLayers = 1
    elseif soil_type == "paddy"
        # aquacrop version 6.0
        soil.CNValue = 77
        soil.REW = 10     
        soil.NrSoilLayers = 2
    end

    if !isnothing(aux)
        actualize_with_dict!(soil, aux)
    end

    return nothing
end



"""
    set_soillayers!(soil_layers::Vector{SoilLayerIndividual}, soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

sets soil_layers for a given soil_type
possible soil_type are 
["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay",
"sandy clay loam", "sandy loam", "silty clay loam", "paddy"]
"""
function set_soillayers!(soil_layers::Vector{SoilLayerIndividual}, soil_type::AbstractString; aux::Union{AbstractDict,Nothing}=nothing)
    push!(soil_layers, SoilLayerIndividual())
    if soil_type == "sandy clay"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 50
        soil_layers[1].FC = 39
        soil_layers[1].WP = 27
        soil_layers[1].InfRate = 35
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.569100
        soil_layers[1].CRb = -1.613423
        soil_layers[1].Description = "sandy clay"
    elseif soil_type == "clay"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 55
        soil_layers[1].FC = 54
        soil_layers[1].WP = 39
        soil_layers[1].InfRate = 35
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.608600
        soil_layers[1].CRb = 0.594642
        soil_layers[1].Description = "clay"
    elseif soil_type == "clay loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 50
        soil_layers[1].FC = 39
        soil_layers[1].WP = 23
        soil_layers[1].InfRate = 125
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.572700
        soil_layers[1].CRb = -0.859573
        soil_layers[1].Description = "clay loam"
    elseif soil_type == "loamy sand"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 38
        soil_layers[1].FC = 16
        soil_layers[1].WP = 8
        soil_layers[1].InfRate = 2200
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.333200
        soil_layers[1].CRb = 0.365805
        soil_layers[1].Description = "loamy sand"
    elseif soil_type == "loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 46
        soil_layers[1].FC = 31
        soil_layers[1].WP = 15
        soil_layers[1].InfRate = 500
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.453600
        soil_layers[1].CRb = 0.837340
        soil_layers[1].Description = "loam"
    elseif soil_type == "sand"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 36
        soil_layers[1].FC = 13
        soil_layers[1].WP = 6
        soil_layers[1].InfRate = 3000
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.341200
        soil_layers[1].CRb = 0.440738
        soil_layers[1].Description = "sand"
    elseif soil_type == "silt"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 43
        soil_layers[1].FC = 33
        soil_layers[1].WP = 9
        soil_layers[1].InfRate = 500
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.453600
        soil_layers[1].CRb = 0.837340
        soil_layers[1].Description = "silt"
    elseif soil_type == "silty loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 46
        soil_layers[1].FC = 33
        soil_layers[1].WP = 13
        soil_layers[1].InfRate = 575
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.446850
        soil_layers[1].CRb = 0.904118
        soil_layers[1].Description = "silty loam"
    elseif soil_type == "silty clay"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 54
        soil_layers[1].FC = 50
        soil_layers[1].WP = 32
        soil_layers[1].InfRate = 100
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.556600
        soil_layers[1].CRb = 1.336132
        soil_layers[1].Description = "silty clay"
    elseif soil_type == "sandy clay loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 47
        soil_layers[1].FC = 32
        soil_layers[1].WP = 20
        soil_layers[1].InfRate = 225
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.576700
        soil_layers[1].CRb = -0.511485
        soil_layers[1].Description = "sandy clay loam"
    elseif soil_type == "sandy loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 41
        soil_layers[1].FC = 22
        soil_layers[1].WP = 10
        soil_layers[1].InfRate = 1200 
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.323200
        soil_layers[1].CRb = 0.219363
        soil_layers[1].Description = "sandy loam"
    elseif soil_type == "silty clay loam"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 4
        soil_layers[1].SAT = 52
        soil_layers[1].FC = 44
        soil_layers[1].WP = 23
        soil_layers[1].InfRate = 150 
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.516600
        soil_layers[1].CRb = 1.622512
        soil_layers[1].Description = "silty clay loam"
    elseif soil_type == "paddy"
        # aquacrop version 6.0
        soil_layers[1].Thickness = 0.5
        soil_layers[1].SAT = 54
        soil_layers[1].FC = 50
        soil_layers[1].WP = 32
        soil_layers[1].InfRate = 15 
        soil_layers[1].Penetrability = 100
        soil_layers[1].GravelMass = 0
        soil_layers[1].CRa = -0.624600
        soil_layers[1].CRb = -0.003804
        soil_layers[1].Description = "silty clay"

        soil_layers[2].Thickness = 1.5
        soil_layers[2].SAT = 55
        soil_layers[2].FC = 54
        soil_layers[2].WP = 39
        soil_layers[2].InfRate = 2 
        soil_layers[2].Penetrability = 100
        soil_layers[2].GravelMass = 0
        soil_layers[2].CRa = -0.635000
        soil_layers[2].CRb = -1.426930
        soil_layers[2].Description = "clay"
    end

    if !isnothing(aux)
        for i in eachindex(soil_layers)
            actualize_with_dict!(soil_layers[i], aux)
        end
    end

    for soillayer in soil_layers
        gravelv_temp = from_gravelmass_to_gravelvol(soillayer.SAT, soillayer.GravelMass)
        soillayer.GravelVol = gravelv_temp
    end

    return nothing
end

"""
    set_crop!(crop::RepCrop, crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

sets crop for a given crop_type
possible crop_type are 
["maize", "wheat", "cotton", "alfalfaGDD", "barley", "barleyGDD", "cottonGDD", "drybean", "drybeanGDD",
"maizeGDD", "wheatGDD", "sugarbeet", "sugarbeetGDD", "sunflower", "sunflowerGDD", "sugarcane",
"tomato", "tomatoGDD", "potato", "potatoGDD", "quinoa", "tef", "soybean", "soybeanGDD",
"sorghum", "sorghumGDD", "paddyrice", "paddyriceGDD"]
"""

function set_crop!(crop::RepCrop, crop_type::AbstractString; aux::Union{AbstractDict,Nothing}=nothing)
    if crop_type == "maize"
        # Default Maize, Calendar (Davis, 1Jun96)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.14      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.72      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.9       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.69      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 6.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.69      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.7       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.05      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.30      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.045     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.011     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 75000      # Number of plants per hectare
        crop.CGC = 0.16312   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11691   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 6         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 108         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 107         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 132         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 66         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 13         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 61         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 33.7       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 48         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 7.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "wheat"
        # Default Wheat, Calendar (Valenzano, 23Nov07)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 0.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 26.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 5.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.65      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 5         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 14.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 6         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 20         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.50      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 4500000      # Number of plants per hectare
        crop.CGC = 0.04901   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07179   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 13         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 93         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 158         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 197         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 127         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 15         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 67         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 48         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 7.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "cotton"
        # Default Cotton, Calendar (Cordoba, 15Apr86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 12.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 35.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.70      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.75      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.75      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 15         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 43         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = -9.0       # Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 8         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 28         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 120000      # Number of plants per hectare
        crop.CGC = 0.07611   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02917   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 14         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 98         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 144         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 174         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 64         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 52         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 200         # Excess of potential fruits (%)
        crop.DaysToHIo = 105         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 70         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 35         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 2.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 10.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 30         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 85         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "alfalfaGDD"
        # Artemis variety - Alfalfa
        # 7.1       # AquaCrop Version (August 2023)
        # skip this line 0         # File protected
        crop.subkind = :Forage # 4         # forage crop
        crop.Planting = :Seed # 1         # Crop is sown in 1st year
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 2037         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.55      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 600         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.90      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 2         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 8.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 16         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.15      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.050     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 3.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.020     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.010     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 2.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 19.38      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 2000000      # Number of plants per hectare
        crop.CGC = 0.11683   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = 9         # Number of years at which CCx declines to 90 % of its value due to self-thinning - for Perennials
        crop.CCxRoot = 0.50      # Shape factor of the decline of CCx over the years due to self-thinning - for Perennials
        # skip this line -9         # dummy - Parameter no Longer required
        crop.CCx = 0.95      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.05714   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 1         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 217         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 217         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 217         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 0         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = -9         # parameter NO LONGER required
        crop.DaysToHIo = 13         # Building up of Harvest Index starting at sowing/transplanting (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Sink strength (%) quatifying biomass response to elevated atmospheric CO2 concentration
        crop.HI = 100         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = -9         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = -9.0       # No effect on HI of stomatal closure during yield formation
        crop.DHImax = -9         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 5         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 2037         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 2037         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 2037         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 0         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 0         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.011512  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.006000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 98         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.30      # Minimum effective rooting depth (m) in first year (for perennials)
        crop.SownYear1 = true # 1         # Crop is sown in 1st year (for perennials)
        crop.Assimilates.On = true # 1         # Transfer of assimilates from above ground parts to root system is considered
        crop.Assimilates.Period = 180         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 65         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 60         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "barley"
        # Crop Barley file for Dejen (Tigray, Ethiopia)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 0.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 15.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.55      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 15         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 5         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 14.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 6         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 20         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.30      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 1500000      # Number of plants per hectare
        crop.CGC = 0.12410   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.80      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07697   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 7         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 60         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 65         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 93         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 60         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 12         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 27         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 33         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 5.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "barleyGDD"
        # Crop Barley file for Dejen (Tigray, Ethiopia)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 0.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 15.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1296         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.55      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 15         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 5         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 14.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 6         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 20         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.30      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 1500000      # Number of plants per hectare
        crop.CGC = 0.12410   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.80      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07971   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 7         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 60         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 65         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 93         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 60         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 12         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 27         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 33         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 5.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 98         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 854         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 924         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 1296         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 867         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 160         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.008697  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.006000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 351         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "cottonGDD"
        # Default Cotton, GDD (Cordoba, 15Apr86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 12.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 35.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1956         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.70      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.75      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.75      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 15         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 43         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = -9.0       # Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 8         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 27         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 120000      # Number of plants per hectare
        crop.CGC = 0.06712   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02823   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 14         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 99         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 144         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 174         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 65         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 52         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 200         # Excess of potential fruits (%)
        crop.DaysToHIo = 106         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 70         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 35         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 2.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 10.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 30         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 12         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 956         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1601         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 1956         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 502         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 709         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.006503  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.002465  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1403         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 85         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "drybean"
        # Dry Bean# Kc(Trx) = 1.05; HI effect very strong
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 9.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.5       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.88      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 5         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.05      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.70      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 25         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 10.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 10.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 131579      # Number of plants per hectare
        crop.CGC = 0.11804   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.99      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.08612   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 6         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 75         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 75         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 115         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 47         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 20         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 61         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 90         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 40         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 3         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 1.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 75         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "drybeanGDD"
        # Dry Bean GDD# Kc(Trx) = 1.05; HI effect very strong
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 9.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1298         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.5       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.88      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 5         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.05      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.70      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 25         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 10.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 10.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 131579      # Number of plants per hectare
        crop.CGC = 0.11804   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.99      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.08612   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 6         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 75         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 75         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 115         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 47         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 20         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 61         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 90         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 40         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 3         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 1.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 59         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 888         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 903         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 1298         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 556         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 233         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.009879  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.008813  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 668         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 75         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "maizeGDD"
        # Default Maize, GDD (Davis, 1Jun96)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1700         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.14      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.72      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.9       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.69      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 6.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.69      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.7       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.05      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.30      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.045     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.011     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 75000      # Number of plants per hectare
        crop.CGC = 0.16312   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11691   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 6         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 108         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 107         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 132         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 66         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 13         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 61         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 33.7       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 48         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 7.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 80         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 1409         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1400         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 1700         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 880         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 180         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.012494  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.010000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 750         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "wheatGDD"
        # Default Wheat, GDD (Valenzano, 23Nov07)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 0.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 26.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 2400         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 5.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.65      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 5         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 14.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 6         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 20         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.50      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 4500000      # Number of plants per hectare
        crop.CGC = 0.04902   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07179   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 13         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 93         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 158         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 197         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 127         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 15         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 67         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 48         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 7.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 150         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 864         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1700         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 2400         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 1250         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 200         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.005001  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.004000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1100         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sugarbeet"
        # Default Sugar Beet, Calendar (Foggia, 22Mar00)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Tuber # 3         # root/tuber crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.60      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.65      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.75      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 9.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 7         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 24         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 100000      # Number of plants per hectare
        crop.CGC = 0.13572   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07143   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 4         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 42         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 115         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 142         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 70         # Calendar Days# from sowing to start of yield formation
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = -9         # Excess of potential fruits - Not Applicable
        crop.DaysToHIo = 70         # Building up of Harvest Index starting at root/tuber enlargement (days)
        crop.WP = 17.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 70         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before start of yield formation
        crop.aCoeff = 4.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = -9.0       # No effect on HI of stomatal closure during yield formation
        crop.DHImax = 20         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to start tuber formation
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sugarbeetGDD"
        # Default Sugar Beet, GDD (Foggia, 22Mar00)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Tuber # 3         # root/tuber crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 2203         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.60      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.65      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.75      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 9.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 7         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 24         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 1.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 1.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 100000      # Number of plants per hectare
        crop.CGC = 0.13227   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07128   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 5         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 43         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 116         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 142         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 71         # Calendar Days# from sowing to start of yield formation
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = -9         # Excess of potential fruits - Not Applicable
        crop.DaysToHIo = 70         # Building up of Harvest Index starting at root/tuber enlargement (days)
        crop.WP = 17.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 70         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before start of yield formation
        crop.aCoeff = 4.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = -9.0       # No effect on HI of stomatal closure during yield formation
        crop.DHImax = 20         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 23         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 408         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1704         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 2203         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 865         # GDDays# from sowing to start tuber formation
        crop.GDDLengthFlowering = 0         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.010541  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.003857  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1301         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sunflower"
        # Default Sunflower, Calendar (Cordoba, 15Apr86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 4.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.5       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 12         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 5.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 5.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 58000      # Number of plants per hectare
        crop.CGC = 0.21970   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.13562   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 18         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 100         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 105         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 127         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 78         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 16         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 47         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 60         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 35         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sunflowerGDD"         
        # Default Sunflower, GDD (Cordoba, 15Apr86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 4.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 2400         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.5       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 12         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 5.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 5.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 57000      # Number of plants per hectare
        crop.CGC = 0.24606   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11476   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 18         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 106         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 112         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 138         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 81         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 18         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 55         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 60         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 35         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 5         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 170         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 1784         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1900         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 2400         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 1266         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 350         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.014993  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.006000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1087         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sugarcane"
        # as in Singels chpt
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Vegetative # 1         # leafy vegetable crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 9.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 32.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.25      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.55      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.50      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.60      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.90      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 19         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.80      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 140000      # Number of plants per hectare
        crop.CGC = 0.12548   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.95      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07615   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 7         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 60         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 330         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 365         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 0         # Calendar Days# from transplanting to flowering
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 20         # Building up of Harvest Index (% of growing cycle)
        crop.DaysToHIo = 73         # Building up of Harvest Index starting at sowing/transplanting (days)
        crop.WP = 30.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 35         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = -9         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = -9.0       # No effect on HI of stomatal closure during yield formation
        crop.DHImax = -9         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = -9         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = -9         # GDDays# from transplanting to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 30         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "tomato"
        # Default Tomato, Calendar (Cordoba, 1May86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 7.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 28.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.55      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.50      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.92      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = -9.0       # Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 15         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 20.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 20.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 33333      # Number of plants per hectare
        crop.CGC = 0.12286   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.75      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07238   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 4         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 55         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 91         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 110         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 34         # Calendar Days# from transplanting to flowering
        crop.LengthFlowering = 42         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 58         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 63         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = -9         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = -9         # GDDays# from transplanting to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 5         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "tomatoGDD"
        # Default Tomato, GDD (Cordoba, 1May86)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 7.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 28.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1933         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.55      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.50      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.92      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = -9.0       # Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 13         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 20.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 20.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 33333      # Number of plants per hectare
        crop.CGC = 0.10819   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.75      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.06333   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 5         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 65         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 106         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 130         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 41         # Calendar Days# from transplanting to flowering
        crop.LengthFlowering = 49         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 67         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 63         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 43         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = 891         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = 1553         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = 1933         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = 525         # GDDays# from transplanting to flowering
        crop.GDDLengthFlowering = 750         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.007504  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.004000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1050         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 5         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "potato"
        # Default Potato, Calendar (Lima, 17May95)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Tuber # 3         # root/tuber crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 2.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 26.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.60      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = -9         # Cold (air temperature) stress affecting pollination - not considered
        crop.Theat = -9         # Heat (air temperature) stress affecting pollination - not considered
        crop.GDtranspLow = 7.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.50      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 15.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 15.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 40000      # Number of plants per hectare
        crop.CGC = 0.18896   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.92      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.01884   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 16         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 100         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 90         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 121         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 47         # Calendar Days# from transplanting to start of yield formation
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = -9         # Excess of potential fruits - Not Applicable
        crop.DaysToHIo = 72         # Building up of Harvest Index starting at root/tuber enlargement (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 75         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 2         # Possible increase (%) of HI due to water stress before start of yield formation
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 10.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 5         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = -9         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = -9         # GDDays# from transplanting to start yield formation
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "potatoGDD"
        # Default Potato, GDD (Lima, 17May95)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File not protected
        crop.subkind = :Tuber # 3         # root/tuber crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 2.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 26.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1276         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.20      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.60      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = -9         # Cold (air temperature) stress affecting pollination - not considered
        crop.Theat = -9         # Heat (air temperature) stress affecting pollination - not considered
        crop.GDtranspLow = 7.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.50      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 15.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 15.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 40000      # Number of plants per hectare
        crop.CGC = 0.26994   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.92      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02781   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 11         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 66         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 59         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 80         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 32         # Calendar Days# from transplanting to start of yield formation
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = -9         # Excess of potential fruits - Not Applicable
        crop.DaysToHIo = 47         # Building up of Harvest Index starting at root/tuber enlargement (days)
        crop.WP = 18.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 75         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 2         # Possible increase (%) of HI due to water stress before start of yield formation
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 10.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 5         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 200         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = 1079         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = 984         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = 1276         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = 550         # GDDays# from transplanting to start yield formation
        crop.GDDLengthFlowering = 0         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.016150  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.002000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 700         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "quinoa"
        # Default Quinoa, Calendar (Bolivia, 15Oct)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 2.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.50      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.80      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 4.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 4.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.98      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 4.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 200         # Sum(ETo) during stress period to be exceeded before senescence is triggered
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 10         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = -9         # Cold (air temperature) stress affecting pollination - not considered
        crop.Theat = -9         # Heat (air temperature) stress affecting pollination - not considered
        crop.GDtranspLow = -9.0       # Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 5         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 18         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.50      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.50      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 200000      # Number of plants per hectare
        crop.CGC = 0.10000   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.75      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.10000   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 7         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 83         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 160         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 180         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 70         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 20         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false # 0         # Crop determinancy unlinked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 90         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 10.5       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 90         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 50         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 9.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "tef"
        # Dejen teff 2010
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 10.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.32      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.66      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.58      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.92      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 6         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 34         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 11.1       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 12         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 0.60      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 0.25      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 0.25      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 10000000      # Number of plants per hectare
        crop.CGC = 0.14644   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.81      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11600   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 14         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 55         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 75         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 99         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 55         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 11         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 40         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 14.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 27         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 0.5       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 10.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 40         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "soybean"
        # Default Soybean, Calendar (Patancheru, 25Jun96)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File not protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 5         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 25         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 5.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 5.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 330000      # Number of plants per hectare
        crop.CGC = 0.10569   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02885   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 9         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 92         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 104         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 130         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 71         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 29         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 59         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 60         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 40         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 3         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 85         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "soybeanGDD"
        # Default Soybean, GDD (Patancheru, 25Jun96)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 2700         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.60      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 5         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.00      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 25         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 5.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 5.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 330000      # Number of plants per hectare
        crop.CGC = 0.10425   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02778   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 10         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 93         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 106         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 133         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 72         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 30         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 60         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 60         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 40         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 3         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9.0       # No impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 10         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 200         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 1934         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 2200         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 2700         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 1500         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 600         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.005000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.001500  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 1180         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 85         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sorghum"
        # Bushland Texas 1991 Sorghum 25 June 1991
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.70      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.75      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 7         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 13         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.07      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.80      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 3.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 3.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 74000      # Number of plants per hectare
        crop.CGC = 0.18150   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.90      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11700   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 13         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 96         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 91         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 102         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 65         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 20         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 50         # Excess of potential fruits (%)
        crop.DaysToHIo = 37         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 33.7       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 45         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 4         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 1.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 25         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "sorghumGDD"
        # Bushland Texas 1993 Sorghum 27 May 1993
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Seed # 1         # Crop is sown
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1760         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.70      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.75      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 7         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 13         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.07      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.300     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 1.80      # Maximum effective rooting depth (m)
        crop.RootShape = 13         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 3.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 3.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 200000      # Number of plants per hectare
        crop.CGC = 0.14326   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.90      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11900   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 11         # Calendar Days# from sowing to emergence
        crop.DaysToMaxRooting = 132         # Calendar Days# from sowing to maximum rooting depth
        crop.DaysToSenescence = 132         # Calendar Days# from sowing to start senescence
        crop.DaysToHarvest = 147         # Calendar Days# from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 87         # Calendar Days# from sowing to flowering
        crop.LengthFlowering = 26         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 60         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 33.7       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 45         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 4         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 1.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 3.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 25         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 136         # GDDays# from sowing to emergence
        crop.GDDaysToMaxRooting = 1583         # GDDays# from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 1579         # GDDays# from sowing to start senescence
        crop.GDDaysToHarvest = 1760         # GDDays# from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 1041         # GDDays# from sowing to flowering
        crop.GDDLengthFlowering = 306         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.012001  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.009862  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 719         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "paddyrice"
        # Default Paddy Rice, Calendar (LosBanos, 15Jan04)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :CalendarDays # 1         # Determination of crop cycle # by calendar days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.00      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.40      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.50      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.55      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.75      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 0         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 3         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 11         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 0.50      # Maximum effective rooting depth (m)
        crop.RootShape = 25         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 1000000      # Number of plants per hectare
        crop.CGC = 0.12257   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.95      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.09330   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 3         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 21         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 73         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 104         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 65         # Calendar Days# from transplanting to flowering
        crop.LengthFlowering = 19         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 36         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 19.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 43         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 7.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = -9         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = -9         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = -9         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = -9         # GDDays# from transplanting to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type == "paddyriceGDD"
        # Default Paddy Rice, GDD (LosBanos, 15Jan04)
        # 7.0       # AquaCrop Version (June 2021)
        # skip this line 0         # File protected
        crop.subkind = :Grain # 2         # fruit/grain producing crop
        crop.Planting = :Transplat # 0         # Crop is transplanted
        crop.ModeCycle = :GDDays # 0         # Determination of crop cycle # by growing degree-days
        crop.pMethod = :FAOCorrection # 1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        # skip this line 1900         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.00      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.40      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3.0       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.50      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.55      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence= 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.75      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 0         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # skip this line -9         # dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 10.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 3         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 11         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # skip this line -9         # Dummy - no longer applicable
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range# 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range# 0 (none) to +200 (extreme))
        crop.KcTop = 1.10      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.150     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 0.50      # Maximum effective rooting depth (m)
        crop.RootShape = 25         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 50         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.00      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.00      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 1000000      # Number of plants per hectare
        crop.CGC = 0.12257   # Canopy growth coefficient (CGC)# Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.CCxRoot = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        # skip this line -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.95      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.09330   # Canopy decline coefficient (CDC)# Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 3         # Calendar Days# from transplanting to recovered transplant
        crop.DaysToMaxRooting = 21         # Calendar Days# from transplanting to maximum rooting depth
        crop.DaysToSenescence = 73         # Calendar Days# from transplanting to start senescence
        crop.DaysToHarvest = 104         # Calendar Days# from transplanting to maturity
        crop.DaysToFlowering = 65         # Calendar Days# from transplanting to flowering
        crop.LengthFlowering = 19         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true # 1         # Crop determinancy linked with flowering
        crop.fExcess = 100         # Excess of potential fruits (%)
        crop.DaysToHIo = 36         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 19.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 43         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = 0         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = 10.0       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = 7.0       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = 15         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 50         # GDDays# from transplanting to recovered transplant
        crop.GDDaysToMaxRooting = 370         # GDDays# from transplanting to maximum rooting depth
        crop.GDDaysToSenescence = 1300         # GDDays# from transplanting to start senescence
        crop.GDDaysToHarvest = 1900         # GDDays# from transplanting to maturity
        crop.GDDaysToFlowering = 1150         # GDDays# from transplanting to flowering
        crop.GDDLengthFlowering = 350         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.007004  # CGC for GGDays# Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.005003  # CDC for GGDays# Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 680         # GDDays# building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false # 0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false # 0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    end

    if !isnothing(aux)
        actualize_with_dict!(crop, aux)
    end

    crop.SmaxTop, crop.SmaxBot = derive_smax_top_bottom(crop)

    if ((crop.StressResponse.ShapeCGC > 24.9) & (crop.StressResponse.ShapeCCX > 24.9) &
        (crop.StressResponse.ShapeWP > 24.9) & (crop.StressResponse.ShapeCDecline > 24.9))
        crop.StressResponse.Calibrated = false
    else
        crop.StressResponse.Calibrated = true
    end

    if crop.RootMin > crop.RootMax
        crop.RootMin = crop.RootMax
    end

    crop.CCo = crop.PlantingDens / 10000 * crop.SizeSeedling / 10000
    crop.CCini = crop.PlantingDens / 10000 * crop.SizePlant / 10000

    if (crop.subkind == :Vegetative) | (crop.subkind == :Forage)
        crop.DaysToFlowering = 0
        crop.LengthFlowering = 0
    end

    if (crop.ModeCycle == :GDDays) & ((crop.subkind == :Vegetative) | (crop.subkind == :Forage))
        crop.GDDaysToFlowering = 0
        crop.GDDLengthFlowering = 0
    end

    return nothing
end

"""
    set_perennial_period!(perennial_period::RepPerennialPeriod, crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

sets perennial_period for a given crop_type
possible crop_type are 
["maize", "wheat", "cotton", "alfalfaGDD", "barley", "barleyGDD", "cottonGDD", "drybean", "drybeanGDD",
"maizeGDD", "wheatGDD", "sugarbeet", "sugarbeetGDD", "sunflower", "sunflowerGDD", "sugarcane",
"tomato", "tomatoGDD", "potato", "potatoGDD", "quinoa", "tef", "soybean", "soybeanGDD",
"sorghum", "sorghumGDD", "paddyrice", "paddyriceGDD"]
"""
function set_perennial_period!(perennial_period::RepPerennialPeriod, crop_type::AbstractString; aux::Union{AbstractDict,Nothing}=nothing)
    if crop_type == "alfalfaGDD"
        aux_GenerateOnset = 13         # The Restart of growth is generated by Growing-degree days
        perennial_period.OnsetFirstDay = 1         # First Day for the time window (Restart of growth)
        perennial_period.OnsetFirstMonth = 1         # First Month for the time window (Restart of growth)
        perennial_period.OnsetLengthSearchPeriod = 120         # Length (days) of the time window (Restart of growth)
        perennial_period.OnsetThresholdValue = 20.0       # Threshold for the Restart criterion# Growing-degree days
        perennial_period.OnsetPeriodValue = 8         # Number of successive days for the Restart criterion
        perennial_period.OnsetOccurrence = 2         # Number of occurrences before the Restart criterion applies
        aux_GenerateEnd = 63         # The End of growth is generated by Growing-degree days
        perennial_period.EndLastDay = 31         # Last Day for the time window (End of growth)
        perennial_period.EndLastMonth = 12         # Last Month for the time window (End of growth)
        perennial_period.ExtraYears = 0         # Number of years to add to the Onset year
        perennial_period.EndLengthSearchPeriod = 90         # Length (days) of the time window (End of growth)
        perennial_period.EndThresholdValue = 10.0       # Threshold for the End criterion# Growing-degree days
        perennial_period.EndPeriodValue = 8         # Number of successive days for the End criterion
        perennial_period.EndOccurrence = 2         # Number of occurrences before the End criterion applies
    else #default value
        aux_GenerateOnset = 0
        aux_GenerateEnd = 0
    end

    xx = aux_GenerateOnset
    if xx == 0
        perennial_period.GenerateOnset = false
    else
        perennial_period.GenerateOnset = true
        if xx == 12
            perennial_period.OnsetCriterion = :TMeanPeriod
        elseif xx == 13
            perennial_period.OnsetCriterion = :GDDPeriod
        else
            perennial_period.GenerateOnset = false
        end
    end


    xx = aux_GenerateEnd
    if xx == 0
        perennial_period.GenerateEnd = false
    else
        perennial_period.GenerateEnd = true
        if xx == 62
            perennial_period.EndCriterion = :TMeanPeriod
        elseif xx == 63
            perennial_period.EndCriterion = :GDDPeriod
        else
            perennial_period.GenerateEnd = false
        end
    end

    if !isnothing(aux)
        actualize_with_dict!(perennial_period, aux)
    end

    if perennial_period.OnsetOccurrence > 3
        perennial_period.OnsetOccurrence = 3
    end

    if perennial_period.EndOccurrence > 3
        perennial_period.EndOccurrence = 3
    end

    return nothing
end


"""
    load_projectinput_from_vardict(parentdir; kwargs...)
"""
function load_projectinput_from_vardict(parentdir; kwargs...)
    projectinput = ProjectInputType()
    projectinput.ParentDir = parentdir
    # 0. Year of cultivation and Simulation and Cropping period
    projectinput.Simulation_YearSeason = 1
    projectinput.Simulation_DayNr1 = determine_day_nr(kwargs[:Simulation_DayNr1])
    projectinput.Simulation_DayNrN = determine_day_nr(kwargs[:Simulation_DayNrN])
    projectinput.Crop_Day1 = determine_day_nr(kwargs[:Crop_Day1])
    projectinput.Crop_DayN = determine_day_nr(kwargs[:Crop_DayN])

    projectinput.Temperature_Filename = ""
    projectinput.ETo_Filename = ""
    projectinput.Rain_Filename = ""
    projectinput.CO2_Filename = "(None)"
    projectinput.Climate_Filename = "(None)"
    projectinput.Irrigation_Filename = "(None)"
    projectinput.Management_Filename = ""
    projectinput.Soil_Filename = ""
    projectinput.GroundWater_Filename = "(None)"
    projectinput.SWCIni_Filename = "(None)"
    projectinput.OffSeason_Filename = "(None)"
    projectinput.Observations_Filename = "(None)"
    projectinput.Calendar_Filename = "(None)"
    projectinput.Crop_Filename = ""

    return [projectinput]
end

"""
    load_resultsparameters_from_vardict(;kwargs...)
"""
function load_resultsparameters_from_vardict(; kwargs...)
    aggregationresultsparameters = ParametersContainer(Int)
    setparameter!(aggregationresultsparameters, :outputaggregate, 1)# :daily)

    dailyresultsparameters = ParametersContainer(Bool)
    setparameter!(dailyresultsparameters, :out1Wabal, true)
    setparameter!(dailyresultsparameters, :out2Crop, true)
    setparameter!(dailyresultsparameters, :out3Prof, true)
    setparameter!(dailyresultsparameters, :out4Salt, true)
    setparameter!(dailyresultsparameters, :out5CompWC, true)
    setparameter!(dailyresultsparameters, :out6CompEC, true)
    setparameter!(dailyresultsparameters, :out7Clim, true)
    setparameter!(dailyresultsparameters, :out8Irri, false)
    if (dailyresultsparameters[:out1Wabal] | dailyresultsparameters[:out2Crop]
        | dailyresultsparameters[:out3Prof] | dailyresultsparameters[:out4Salt]
        | dailyresultsparameters[:out5CompWC] | dailyresultsparameters[:out6CompEC]
        | dailyresultsparameters[:out7Clim])
        setparameter!(dailyresultsparameters, :outdaily, true)
    else
        setparameter!(dailyresultsparameters, :outdaily, false)
    end


    particularresultsparameters = ParametersContainer(Bool)
    setparameter!(particularresultsparameters, :part1Mult, true)
    setparameter!(particularresultsparameters, :part2Eval, false)
    return Dict{Symbol,AbstractParametersContainer}(
        :aggregationresults => aggregationresultsparameters,
        :dailyresults => dailyresultsparameters,
        :particularresults => particularresultsparameters)
end

"""
    set_clim_record!(record::RepClim; kwargs...)
"""
function set_clim_record!(record::RepClim; kwargs...)

    clim_symbol = Symbol(kwargs[:str])
    di, mi, yi = determine_date(kwargs[:InitialClimDate])
    record.Datatype = :Daily
    record.FromD = di
    record.FromM = mi
    record.FromY = yi

    if haskey(kwargs, clim_symbol)
        actualize_with_dict!(record, kwargs[clim_symbol])
    end

    return nothing 
end
