abstract type AbstractCropField end


"""
    FieldAquaCrop

Has all the data for the simulation of AquaCrop
"""
struct AquaCropField <: AbstractCropField
    gvars::Dict
    outputs::Dict
    lvars::Dict
    parentdir::AbstractString
end

function Base.getindex(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    elseif s in keys(b.outputs)
        return getfield(b, :outputs)[s]
    else
        return getfield(b, :gvars)[s]
    end
end

function Base.getproperty(b::AquaCropField, s::Symbol)
    if s in fieldnames(AquaCropField)
        return getfield(b, s) 
    elseif s in keys(b.outputs)
        return getfield(b, :outputs)[s]
    else
        return getfield(b, :gvars)[s]
    end
end


"""
    AquaCropField(parentdir::AbstractString, runtype=nothing)

Starts the struct AquaCropField that has all the data for the simulation of AquaCrop
"""
function AquaCropField(parentdir::AbstractString, runtype=nothing)
    cropfield, all_ok = initialize_cropfield(parentdir, runtype)
    return cropfield
end


"""
    dailyupdate!(cropfield::AquaCropField)

Updates the AquaCropField by one day
"""
function dailyupdate!(cropfield::AquaCropField)
    nrrun = 1


    repeattoday = cropfield.gvars[:simulation].ToDayNr
    if (cropfield.gvars[:integer_parameters][:daynri]) <= repeattoday
        advance_one_time_step!(cropfield.outputs, cropfield.gvars,
                               cropfield.lvars, cropfield.parentdir, nrrun)
        read_climate_nextday!(cropfield.outputs, cropfield.gvars)
        set_gdd_variables_nextday!(cropfield.gvars)
    end
    return nothing
end

"""
    season_run!(cropfield::AquaCropField)

Updates the AquaCropField for all days in season 1
"""
function season_run!(cropfield::AquaCropField)
    nrrun = 1

    repeattoday = cropfield.gvars[:simulation].ToDayNr
    loopi = true
    while loopi
        dailyupdate!(cropfield)
        if (cropfield.gvars[:integer_parameters][:daynri] - 1) == repeattoday
            loopi = false
        end
    end
    finalize_run1!(cropfield.outputs, cropfield.gvars, nrrun)
    finalize_run2!(cropfield.outputs, cropfield.gvars)
    
    return nothing
end

"""
    harvest!(cropfield::AquaCropField)

does a daily update with harvest
"""
function harvest!(cropfield::AquaCropField)
    gvars = cropfield.gvars

    cutlog = gvars[:management].Cuttings.Considered 
    gvars[:management].Cuttings.Considered = true

    genlog = gvars[:management].Cuttings.Generate
    gvars[:management].Cuttings.Generate = false

    if gvars[:management].Cuttings.FirstDayNr != undef_int 
       # adjust DayInSeason
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:management].Cuttings.FirstDayNr + 1
    else
        dayinseason = gvars[:integer_parameters][:daynri] - gvars[:crop].Day1 + 1
    end 

    cut_info_record1 = deepcopy(gvars[:cut_info_record1])
    gvars[:cut_info_record1].FromDay = dayinseason
    gvars[:cut_info_record1].NoMoreInfo = false 

    Man = deepcopy(gvars[:array_parameters][:Man])
    Man_info = deepcopy(gvars[:array_parameters][:Man_info])

    dailyupdate!(cropfield) 

    cropfield.gvars[:cut_info_record1] = cut_info_record1
    cropfield.gvars[:management].Cuttings.Considered = cutlog 
    cropfield.gvars[:management].Cuttings.Generate = genlog 
    setparameter!(cropfield.gvars[:array_parameters], :Man, Man)
    setparameter!(cropfield.gvars[:array_parameters], :Man_info, Man_info)



    return nothing
end

"""
    biomass = biomass(cropfield::AquaCropField)

biomass in ton/ha
"""
function biomass(cropfield::AquaCropField)
    gvars = cropfield.gvars
    biomass = gvars[:sumwabal].Biomass - gvars[:float_parameters][:bprevsum]
    return  biomass*ton*u"ha^-1"
end

"""
    dryyield = dryyield(cropfield::AquaCropField)

dryyield in ton/ha
"""
function dryyield(cropfield::AquaCropField)
    gvars = cropfield.gvars
    dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
    return dry_yield*ton*u"ha^-1"
end

"""
    freshyield = freshyield(cropfield::AquaCropField)

freshyield in ton/ha
"""
function freshyield(cropfield::AquaCropField)
    gvars = cropfield.gvars
    if gvars[:crop].DryMatter == undef_int
        fresh_yield = 0
    else
        dry_yield = gvars[:sumwabal].YieldPart - gvars[:float_parameters][:yprevsum]
        fresh_yield = dry_yield/(gvars[:crop].DryMatter/100)
    end
    return fresh_yield*ton*u"ha^-1"
end

"""
    canopycover(cropfield::AquaCropField; actual=true)

canopy cover in % of terrain, 
"""
function canopycover(cropfield::AquaCropField; actual=true)
    gvars = cropfield.gvars
    if actual 
        return gvars[:float_parameters][:cciactual] * 100
    else
        return gvars[:float_parameters][:cciprev] * 100
    end
end


"""
    outputs = basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)

runs a basic AquaCrop simulation, the outputs variable has the final dataframes
with the results of the simulation

runtype allowed for now is :Fortran or :Toml  
where :Fortran will use the input from a files like in AquaCrop Fortran
and :Toml will use the input from TOML files (see AquaCrop.jl/test/testcase/TOML_FILES)`
"""

function basic_run(parentdir::AbstractString, runtype::Union{Symbol,Nothing}=nothing)
    outputs = start_outputs()
    kwargs, all_ok = initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        return outputs
    end

    start_the_program!(outputs, parentdir; kwargs...)
    return outputs
end

"""
    kwargs, all_ok = initialize_kwargs(outputs, runtype)

initializes the kwargs with the proper runtype, check if all_ok.logi == true 
"""
function initialize_kwargs(outputs, runtype)

    all_ok = AllOk(true, "") 
    # runtype allowed for now is :Fortran, :Toml or :NoFile 
    if isnothing(runtype)
        kwargs = (runtype = NormalFileRun(),)
        add_output_in_logger!(outputs, "using default NormalFileRun")
    elseif runtype == :Fortran 
        kwargs = (runtype = NormalFileRun(),)
        add_output_in_logger!(outputs, "using default NormalFileRun")
    elseif runtype == :Toml
        kwargs = (runtype = TomlFileRun(),)
        add_output_in_logger!(outputs, "using default TomlFileRun")
    else 
        kwargs = (runtype = nothing,)
        all_ok.logi = false
        all_ok.msg = "invalid runtype"
    end

    return kwargs, all_ok 
end

"""
    cropfield, all_ok = initialize_cropfield(;runtype=:Toml, parentdir=nothing)

initializes the crop with the proper runtype, check if all_ok.logi == true 
start + setup = initialize
"""
function initialize_cropfield(;runtype=:Toml, parentdir=nothing)
    # this variables are here in case later we want to give more control in the season (nrrun)
    # and the project number (nproject)
    nproject = 1
    nrrun = 1

    outputs = start_outputs()
    kwargs, all_ok = initialize_kwargs(outputs, runtype)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    all_ok = AllOk(true, "")

    filepaths = initialize_the_program(outputs, parentdir; kwargs...) 
    project_filenames = initialize_project_filename(outputs, filepaths; kwargs...)
    if length(project_filenames) < nproject
        all_ok.logi = false
        all_ok.msg = "no project loaded"
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    theprojectfile = project_filenames[nproject]
    theprojecttype = get_project_type(theprojectfile; kwargs...)
    if theprojecttype == :typenone 
        all_ok.logi = false
        all_ok.msg = "bad projecttype for "*theprojectfile
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    gvars, projectinput, all_ok = initialize_project(outputs, theprojectfile, theprojecttype, filepaths; kwargs...)
    if !all_ok.logi
        add_output_in_logger!(outputs, all_ok.msg)
        finalize_outputs!(outputs)
        gvars = Dict()
        lvars = Dict()
        return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
    end

    # run all previouss simulations
    for i in 1:(nrrun-1)
        run_simulation!(outputs, gvars, projectinput; kwargs...)
    end
    initialize_run_part1!(outputs, gvars, projectinput[nrrun]; kwargs...)
    initialize_climate!(outputs, gvars; kwargs...)
    initialize_run_part2!(outputs, gvars, projectinput[nrrun], nrrun; kwargs...)
    lvars = initialize_lvars()

    return AquaCropField(gvars, outputs, lvars, parentdir), all_ok
end



"""
    soil, all_ok = get_soil(soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

gets soil for a given soil_type, check if all_ok.logi == true
possible soil_type are 
["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay"]
"""
function get_soil(soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)
    all_ok = AllOk(true, "") 
    soil = RepSoil()
    if soil_type=="sandy clay"
        # aquacrop version 6.0
        soil.CNValue = 77
        soil.REW = 10
        soil.NrSoilLayers = 1
    elseif soil_type=="clay"
        # aquacrop version 6.0
        soil.CNValue = 77
        soil.REW = 14
        soil.NrSoilLayers = 1
    elseif soil_type=="clay loam"
        # aquacrop version 6.0
        soil.CNValue = 72
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type=="loamy sand"
        # aquacrop version 6.0
        soil.CNValue = 46
        soil.REW = 5
        soil.NrSoilLayers = 1
    elseif soil_type=="loam"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 9
        soil.NrSoilLayers = 1
    elseif soil_type=="sand"
        # aquacrop version 6.0
        soil.CNValue = 46
        soil.REW = 4
        soil.NrSoilLayers = 1
    elseif soil_type=="silt"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type=="silty loam"
        # aquacrop version 6.0
        soil.CNValue = 61
        soil.REW = 11
        soil.NrSoilLayers = 1
    elseif soil_type=="silty clay"
        # aquacrop version 6.0
        soil.CNValue = 72
        soil.REW = 14
        soil.NrSoilLayers = 1
    else
        all_ok.logi = false
        all_ok.msg = "wrong soil type "*soil_type
    end

    if !isnothing(aux)
        actualize_with_dict!(soil, aux)
    end

    return soil, all_ok
end



"""
    soil_layers, all_ok = get_soillayers(soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

gets soil_layers for a given soil_type, check if all_ok.logi == true
possible soil_type are 
["sandy clay", "clay", "clay loam", "loamy sand", "loam", "sand", "silt", "silty loam", "silty clay"]
"""
function get_soillayers(soil_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)
    all_ok = AllOk(true, "") 
    soil_layers = SoilLayerIndividual[]
    push!(soil_layers, SoilLayerIndividual())
    if soil_type=="sandy clay"
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
    elseif soil_type=="clay"
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
    elseif soil_type=="clay loam"
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
    elseif soil_type=="loamy sand"
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
    elseif soil_type=="loam"
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
    elseif soil_type=="sand"
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
    elseif soil_type=="silt"
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
    elseif soil_type=="silty loam"
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
    elseif soil_type=="silty clay"
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
    else
        all_ok.logi = false
        all_ok.msg = "wrong soil type "*soil_type
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

    return soil_layers, all_ok
end

"""
    crop, all_ok = get_crop(crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

gets crop for a given crop_type, check if all_ok.logi == true
possible crop_type are 
["maize", "wheat", "cotton", "alfalfaGDD"]
"""

function get_crop(crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)
    all_ok = AllOk(true, "") 
    crop = RepCrop()
    if crop_type=="maize" 
        # Default Maize, Calendar (Davis, 1Jun96)
        # aquacrop version  7.0 
        crop.subkind = :Grain #2         # fruit/grain producing crop
        crop.Planting = :Seed #1         # Crop is sown
        crop.ModeCycle = :CalendarDays #1         # Determination of crop cycle : by calendar days
        crop.pMethod = :FAOCorrection #1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 8.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        #this is set later -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.14      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.72      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 2.9       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.69      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 6.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.69      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence = 2.7       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.80      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # -9         : dummy - Parameter no Longer required
        crop.Tcold = 10         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 12.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 10         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # -9         : dummy - Parameter no Longer required
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range: 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range: 0 (none) to +200 (extreme))
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
        crop.CGC = 0.16312   # Canopy growth coefficient (CGC): Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        crop.CCxRoot =  -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.11691   # Canopy decline coefficient (CDC): Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 6         # Calendar Days: from sowing to emergence
        crop.DaysToMaxRooting = 108         # Calendar Days: from sowing to maximum rooting depth
        crop.DaysToSenescence = 107         # Calendar Days: from sowing to start senescence
        crop.DaysToHarvest = 132         # Calendar Days: from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 66         # Calendar Days: from sowing to flowering
        crop.LengthFlowering = 13         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true #1         # Crop determinancy linked with flowering
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
        crop.GDDaysToGermination = -9         # GDDays: from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays: from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays: from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays: from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays: from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays: Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays: Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays: building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false #0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false #0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type=="wheat" 
        # Default Wheat, Calendar (Valenzano, 23Nov07)
        # aquacrop version  7.0 
        crop.subkind = :Grain #2         # fruit/grain producing crop
        crop.Planting = :Seed #1         # Crop is sown
        crop.ModeCycle = :CalendarDays #1         # Determination of crop cycle : by calendar days
        crop.pMethod = :FAOCorrection #1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 0.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 26.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        #this is set later -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.2      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.65      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 5       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.65      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.7      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence = 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # -9         : dummy - Parameter no Longer required
        crop.Tcold = 5         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 35         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 14.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 6         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 20         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # -9         : dummy - Parameter no Longer required
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range: 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range: 0 (none) to +200 (extreme))
        crop.KcTop = 1.1      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
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
        crop.CGC = 0.04901   # Canopy growth coefficient (CGC): Increase in canopy cover (fraction soil cover per day)
        # -9         : Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.YearCCx = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        crop.CCxRoot =  -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.96      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.07179   # Canopy decline coefficient (CDC): Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 13         # Calendar Days: from sowing to emergence
        crop.DaysToMaxRooting = 93         # Calendar Days: from sowing to maximum rooting depth
        crop.DaysToSenescence = 158         # Calendar Days: from sowing to start senescence
        crop.DaysToHarvest = 197         # Calendar Days: from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 127         # Calendar Days: from sowing to flowering
        crop.LengthFlowering = 15         # Length of the flowering stage (days)
        crop.DeterminancyLinked = true #1         # Crop determinancy linked with flowering
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
        crop.GDDaysToGermination = -9         # GDDays: from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays: from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays: from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays: from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays: from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays: Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays: Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays: building-up of Harvest Index during yield formation
        crop.DryMatter = 90         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false #0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false #0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type=="cotton" 
        # Default Cotton, Calendar (Cordoba, 15Apr86)
        # aquacrop version  7.0 
        crop.subkind = :Grain #2         # fruit/grain producing crop
        crop.Planting = :Seed #1         # Crop is sown
        crop.ModeCycle = :CalendarDays #1         # Determination of crop cycle : by calendar days
        crop.pMethod = :FAOCorrection #1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 12.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 35.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        #this is set later -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.2      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.70      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.75      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 2.5       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.75      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence = 2.5       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 50         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.85      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 5         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # -9         : dummy - Parameter no Longer required
        crop.Tcold = 15         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 43         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        # -9.0       : Cold (air temperature) stress on crop transpiration not considered
        crop.ECemin = 8         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 28         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # -9         : dummy - Parameter no Longer required
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range: 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range: 0 (none) to +200 (extreme))
        crop.KcTop = 1.1      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.30     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 2.0      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.048     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.012     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 6.0      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 6.0      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 120000      # Number of plants per hectare
        crop.CGC = 0.07611   # Canopy growth coefficient (CGC): Increase in canopy cover (fraction soil cover per day)
        # -9         : Maximum decrease of Canopy Growth Coefficient in and between seasons - Not Applicable
        crop.YearCCx = -9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        crop.CCxRoot =  -9.0       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        crop.CCx = 0.98      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.02917   # Canopy decline coefficient (CDC): Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 14         # Calendar Days: from sowing to emergence
        crop.DaysToMaxRooting = 98         # Calendar Days: from sowing to maximum rooting depth
        crop.DaysToSenescence = 144         # Calendar Days: from sowing to start senescence
        crop.DaysToHarvest = 174         # Calendar Days: from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 64         # Calendar Days: from sowing to flowering
        crop.LengthFlowering = 52         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false #0         # Crop determinancy linked with flowering
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
        crop.GDDaysToGermination = -9         # GDDays: from sowing to emergence
        crop.GDDaysToMaxRooting = -9         # GDDays: from sowing to maximum rooting depth
        crop.GDDaysToSenescence = -9         # GDDays: from sowing to start senescence
        crop.GDDaysToHarvest = -9         # GDDays: from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = -9         # GDDays: from sowing to flowering
        crop.GDDLengthFlowering = -9         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = -9.000000  # CGC for GGDays: Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = -9.000000  # CDC for GGDays: Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = -9         # GDDays: building-up of Harvest Index during yield formation
        crop.DryMatter = 85         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.00      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = false #0         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = false #0         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 0         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 0         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 0         # Percentage of stored assimilates transferred to above ground parts in next season
    elseif crop_type=="alfalfaGDD" 
        # aquacrop version  7.1 
        crop.subkind = :Forage #4         # fruit/grain producing crop
        crop.Planting = :Seed #1         # Crop is sown
        crop.ModeCycle = :GDDays #0         # Determination of crop cycle : by calendar days
        crop.pMethod = :FAOCorrection #1         # Soil water depletion factors (p) are adjusted by ETo
        crop.Tbase = 5.0       # Base temperature (°C) below which crop development does not progress
        crop.Tupper = 30.0       # Upper temperature (°C) above which crop development no longer increases with an increase in temperature
        #this is set later -9         # Total length of crop cycle in growing degree-days
        crop.pLeafDefUL = 0.15      # Soil water depletion factor for canopy expansion (p-exp) - Upper threshold
        crop.pLeafDefLL = 0.55      # Soil water depletion factor for canopy expansion (p-exp) - Lower threshold
        crop.KsShapeFactorLeaf = 3       # Shape factor for water stress coefficient for canopy expansion (0.0 = straight line)
        crop.pdef = 0.6      # Soil water depletion fraction for stomatal control (p - sto) - Upper threshold
        crop.KsShapeFactorStomata = 3.0       # Shape factor for water stress coefficient for stomatal control (0.0 = straight line)
        crop.pSenescence = 0.70      # Soil water depletion factor for canopy senescence (p - sen) - Upper threshold
        crop.KsShapeFactorSenescence = 3.0       # Shape factor for water stress coefficient for canopy senescence (0.0 = straight line)
        crop.SumEToDelaySenescence = 600         # Sum(ETo) during dormant period to be exceeded before crop is permanently wilted
        crop.pPollination = 0.90      # Soil water depletion factor for pollination (p - pol) - Upper threshold
        crop.AnaeroPoint = 2         # Vol% for Anaerobiotic point (* (SAT - [vol%]) at which deficient aeration occurs *)
        crop.StressResponse.Stress = 50         # Considered soil fertility stress for calibration of stress response (%)
        crop.StressResponse.ShapeCGC = 25.00      # Response of canopy expansion is not considered
        crop.StressResponse.ShapeCCX = 25.00      # Response of maximum canopy cover is not considered
        crop.StressResponse.ShapeWP = 25.00      # Response of crop Water Productivity is not considered
        crop.StressResponse.ShapeCDecline = 25.00      # Response of decline of canopy cover is not considered
        # -9         : dummy - Parameter no Longer required
        crop.Tcold = 8         # Minimum air temperature below which pollination starts to fail (cold stress) (°C)
        crop.Theat = 40         # Maximum air temperature above which pollination starts to fail (heat stress) (°C)
        crop.GDtranspLow = 8.0       # Minimum growing degrees required for full crop transpiration (°C - day)
        crop.ECemin = 2         # Electrical Conductivity of soil saturation extract at which crop starts to be affected by soil salinity (dS/m)
        crop.ECemax = 16         # Electrical Conductivity of soil saturation extract at which crop can no longer grow (dS/m)
        # -9         : dummy - Parameter no Longer required
        crop.CCsaltDistortion = 25         # Calibrated distortion (%) of CC due to salinity stress (Range: 0 (none) to +100 (very strong))
        crop.ResponseECsw = 100         # Calibrated response (%) of stomata stress to ECsw (Range: 0 (none) to +200 (extreme))
        crop.KcTop = 1.15      # Crop coefficient when canopy is complete but prior to senescence (KcTr,x)
        crop.KcDecline = 0.050     # Decline of crop coefficient (%/day) as a result of ageing, nitrogen deficiency, etc.
        crop.RootMin = 0.30      # Minimum effective rooting depth (m)
        crop.RootMax = 3.0      # Maximum effective rooting depth (m)
        crop.RootShape = 15         # Shape factor describing root zone expansion
        crop.SmaxTopQuarter = 0.020     # Maximum root water extraction (m3water/m3soil.day) in top quarter of root zone
        crop.SmaxBotQuarter = 0.010     # Maximum root water extraction (m3water/m3soil.day) in bottom quarter of root zone
        crop.CCEffectEvapLate = 60         # Effect of canopy cover in reducing soil evaporation in late season stage
        crop.SizeSeedling = 2.5      # Soil surface covered by an individual seedling at 90 % emergence (cm2)
        crop.SizePlant = 19.38      # Canopy size of individual plant (re-growth) at 1st day (cm2)
        crop.PlantingDens = 2000000      # Number of plants per hectare
        crop.CGC = 0.11683   # Canopy growth coefficient (CGC): Increase in canopy cover (fraction soil cover per day)
        crop.YearCCx = 9         # Number of seasons at which maximum decrease of Canopy Growth Coefficient is reached - Not Applicable
        crop.CCxRoot =  0.5       # Shape factor for decrease Canopy Growth Coefficient - Not Applicable
        #-9         : dummy - Parameter no Longer required
        crop.CCx = 0.95      # Maximum canopy cover (CCx) in fraction soil cover
        crop.CDC = 0.05714   # Canopy decline coefficient (CDC): Decrease in canopy cover (in fraction per day)
        crop.DaysToGermination = 1         # Calendar Days: from sowing to emergence
        crop.DaysToMaxRooting = 217         # Calendar Days: from sowing to maximum rooting depth
        crop.DaysToSenescence = 217         # Calendar Days: from sowing to start senescence
        crop.DaysToHarvest = 217         # Calendar Days: from sowing to maturity (length of crop cycle)
        crop.DaysToFlowering = 0        # Calendar Days: from sowing to flowering
        crop.LengthFlowering = 0         # Length of the flowering stage (days)
        crop.DeterminancyLinked = false #0         # Crop determinancy linked with flowering
        crop.fExcess = -9         # Excess of potential fruits (%)
        crop.DaysToHIo = 13         # Building up of Harvest Index starting at flowering (days)
        crop.WP = 15.0       # Water Productivity normalized for ETo and CO2 (WP*) (gram/m2)
        crop.WPy = 100         # Water Productivity normalized for ETo and CO2 during yield formation (as % WP*)
        crop.AdaptedToCO2 = 50         # Crop performance under elevated atmospheric CO2 concentration (%)
        crop.HI = 100         # Reference Harvest Index (HIo) (%)
        crop.HIincrease = -9         # Possible increase (%) of HI due to water stress before flowering
        crop.aCoeff = -9       # Coefficient describing positive impact on HI of restricted vegetative growth during yield formation
        crop.bCoeff = -9       # Coefficient describing negative impact on HI of stomatal closure during yield formation
        crop.DHImax = -9         # Allowable maximum increase (%) of specified HI
        crop.GDDaysToGermination = 5         # GDDays: from sowing to emergence
        crop.GDDaysToMaxRooting = 2037         # GDDays: from sowing to maximum rooting depth
        crop.GDDaysToSenescence = 2037         # GDDays: from sowing to start senescence
        crop.GDDaysToHarvest = 2037         # GDDays: from sowing to maturity (length of crop cycle)
        crop.GDDaysToFlowering = 0         # GDDays: from sowing to flowering
        crop.GDDLengthFlowering = 0         # Length of the flowering stage (growing degree days)
        crop.GDDCGC = 0.011512  # CGC for GGDays: Increase in canopy cover (in fraction soil cover per growing-degree day)
        crop.GDDCDC = 0.006000  # CDC for GGDays: Decrease in canopy cover (in fraction per growing-degree day)
        crop.GDDaysToHIo = 98         # GDDays: building-up of Harvest Index during yield formation
        crop.DryMatter = 20         # dry matter content (%) of fresh yield
        crop.RootMinYear1 = 0.30      # Minimum effective rooting depth (m) in first year - required only in case of regrowth
        crop.SownYear1 = true #1         # Crop is transplanted in 1st year - required only in case of regrowth
        crop.Assimilates.On = true #1         # Transfer of assimilates from above ground parts to root system is NOT considered
        crop.Assimilates.Period = 180         # Number of days at end of season during which assimilates are stored in root system
        crop.Assimilates.Stored = 65         # Percentage of assimilates transferred to root system at last day of season
        crop.Assimilates.Mobilized = 60         # Percentage of stored assimilates transferred to above ground parts in next season
    else
        all_ok.logi = false
        all_ok.msg = "wrong crop type "*crop_type
    end

    if !isnothing(aux)
        actualize_with_dict!(soil, aux)
    end

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

    return crop, all_ok
end

"""
    perennial_period, all_ok = get_perennial_period(crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)

gets perennial_period for a given crop_type, check if all_ok.logi == true
possible crop_type are 
["maize", "wheat", "cotton", "alfalfaGDD"]
"""
function get_perennial_period(crop_type::AbstractString; aux::Union{AbstractDict, Nothing}=nothing)
    all_ok = AllOk(true, "") 
    perennial_period = RepPerennialPeriod()

    if crop_type=="maize"
        aux_GenerateOnset = 0
        aux_GenerateEnd = 0
    elseif crop_type=="wheat"
        aux_GenerateOnset = 0
        aux_GenerateEnd = 0
    elseif crop_type=="cotton"
        aux_GenerateOnset = 0
        aux_GenerateEnd = 0
    elseif crop_type=="alfalfaGDD"
        aux_GenerateOnset = 13           # The Restart of growth is generated by Growing-degree days
        perennial_period.OnsetFirstDay = 1                # First Day for the time window (Restart of growth)
        perennial_period.OnsetFirstMonth = 1              # First Month for the time window (Restart of growth)
        perennial_period.OnsetLengthSearchPeriod = 120    # Length (days) of the time window (Restart of growth)
        perennial_period.OnsetThresholdValue = 20.0       # Threshold for the Restart criterion: Growing-degree days
        perennial_period.OnsetPeriodValue = 8             # Number of successive days for the Restart criterion
        perennial_period.OnsetOccurrence = 2              # Number of occurrences before the Restart criterion applies
        aux_GenerateEnd = 63             # The End of growth is generated by Growing-degree days
        perennial_period.EndLastDay = 31                  # Last Day for the time window (End of growth)
        perennial_period.EndLastMonth = 12                # Last Month for the time window (End of growth)
        perennial_period.ExtraYears = 0                   # Number of years to add to the Onset year
        perennial_period.EndLengthSearchPeriod = 90       # Length (days) of the time window (End of growth)
        perennial_period.EndThresholdValue = 10.0         # Threshold for the End criterion: Growing-degree days
        perennial_period.EndPeriodValue = 8               # Number of successive days for the End criterion
        perennial_period.EndOccurrence = 2                # Number of occurrences before the End criterion applies
    else
        all_ok.logi = false
        all_ok.msg = "wrong crop type "*crop_type
    end

    xx = aux_GenerateOnset 
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


    xx = aux_GenerateEnd 
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

    if !isnothing(aux)
        actualize_with_dict!(soil, aux)
    end

    if perennial_period.OnsetOccurrence > 3
        perennial_period.OnsetOccurrence = 3
    end

    if perennial_period.EndOccurrence > 3
        perennial_period.EndOccurrence = 3
    end

    return perennial_period, all_ok
end



