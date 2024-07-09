# constantstype

const equiv = 0.64 # conversion factor: 1 dS/m = 0.64 g/l
const max_SoilLayers = 5
const max_no_compartments = 12
const undef_double = -9.9 # value for 'undefined' real(dp) variables
const undef_int = -9 # value for 'undefined' int32 variables
const undef_str = "" # value for 'undefined' string variables
const undef_bool = false # value for 'undefined' bool variables
const undef_symbol = :undef_symbol # value for 'undefined' symbol variables
const CO2Ref = 369.41 # reference CO2 in ppm by volume for year 2000 for Mauna Loa (Hawaii,USA)
const EvapZmin = 15.0 # cm  minimum soil depth for water extraction by evaporation
const epsilon = 10E-08
const ElapsedDays = [0.0, 31.0, 59.25,
    90.25, 120.25, 151.25,
    181.25, 212.25, 243.25,
    273.25, 304.25, 334.25]
const DaysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

const NameMonth = ["January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"]









# types

"""
    AbstractParametersContainer
"""
abstract type AbstractParametersContainer end

Base.length(p::AbstractParametersContainer) = 1

function _isapprox(a, b; kwargs...)
    ans = true
    for field in fieldnames(typeof(a))
        if isapprox(getfield(a, field), getfield(b, field); kwargs...)
            continue
        else
            println("\n\n\n")
            println(field)
            println(getfield(a, field), "   ", getfield(b, field))
            println("\n\n\n")
            ans = false
        end
    end
    return ans 
end

Base.isapprox(a::T, b::T; kwargs...) where {T<:AbstractParametersContainer} = _isapprox(a, b, kwargs...)

Base.isapprox(a::Vector{T}, b::Vector{T}; kwargs...) where {T<:AbstractParametersContainer} = all([_isapprox(aa, bb; kwargs...) for (aa, bb) in zip(a, b)])

"""
    pc = ParametersContainer(T)

Contains parameters in a Dictionary of type Symbol=>T.
it is used for parameters without a type in the original AquaCrop.f90
"""
struct ParametersContainer{T} <: AbstractParametersContainer
    parameters::AbstractDict{Symbol,T}
end

function ParametersContainer(::Type{T}) where {T}
    ParametersContainer(Dict{Symbol,T}())
end

Base.isapprox(a::Dict{Symbol, T}, b::Dict{Symbol, T}; kwargs...) where {T} = begin 
    ans = true
    for key in keys(a)
        if isapprox(a[key], b[key]; kwargs...)
            continue
        else
            println("\n\n\n")
            println(key)
            println(a[key], "   ", b[key])
            println("\n\n\n")
            ans = false
        end
    end
    return ans 
end


"""
    setparameter!(parameterscontainer::ParametersContainer{T}, parameterkey::Symbol, parameter::T)

sets an entry in parameterscontainer. 
"""
function setparameter!(parameterscontainer::ParametersContainer{T}, parameterkey::Symbol, parameter::T) where {T}
    parameterscontainer.parameters[parameterkey] = parameter
    return nothing
end

"""
    getparameter(parameterscontainer::ParametersContainer{T}, parameterkey::Symbol)

gets the  parameterkey from parameterscontainer
if  parameterkey does not exist returns missing. 
"""
function getparameter(parameterscontainer::ParametersContainer, parameterkey::Symbol)
    get(parameterscontainer.parameters, parameterkey, missing)
end

Base.getindex(parameterscontainer::ParametersContainer, parameterkey::Symbol) = getparameter(parameterscontainer, parameterkey)

# Base.length(parameterscontainer::ParametersContainer) = length(parameterscontainer.parameters)

"""
    effectiverain = RepEffectiveRain()

set from
initialsettings.f90:244
"""
@kwdef mutable struct RepEffectiveRain <: AbstractParametersContainer
    "Undocumented"
    method::Symbol = :USDA
    "IF Method = Percentage"
    PercentEffRain::Int = 70
    "adjustment of surface run-off"
    ShowersInDecade::Int = 2
    "Root for reduction in soil evaporation"
    RootNrEvap::Int = 5
end


"""
    simulparams = RepParams()

contains the simulation parameters.

set from
initialsettings.f90:216
"""
@kwdef mutable struct RepParam <: AbstractParametersContainer
    #  DEFAULT.PAR
    # crop parameters IN CROP.PAR - with Reset option
    "exponential decline with relative soil water [1 = small ... 8 = sharp]"
    EvapDeclineFactor::Int = 4
    "Soil evaporation coefficients from wet bare soil"
    KcWetBare::Float64 = 1.10
    "CC threshold below which HI no longer increase (% of 100)"
    PercCCxHIfinal::Int = 5
    "starting depth of root sine function in % of Zmin (sowing depth)"
    RootPercentZmin::Int = 70
    "maximum root zone expansion in cm/day - fixed at 5 cm/day"
    MaxRootZoneExpansion::Float64 = 5.0
    "shape factro for the effect of water stress on root zone expansion"
    KsShapeFactorRoot::Int = -6
    "Soil water content (% TAW) required at sowing depth for germination"
    TAWGermination::Int = 20
    "Adjustment factor for FAO-adjustment of soil water depletion (p) for various ET"
    pAdjFAO::Float64 = 1.0
    "delay [days] for full effect of anaeroby"
    DelayLowOxygen::Int = 3
    "exponent of senescence factor adjusting drop in photosynthetic activity of dying crop"
    ExpFsen::Float64 = 1.0
    "Percentage decrease of p(senescence) once early canopy senescence is triggered"
    Beta::Int = 12
    "Thickness of top soil for determination of its Soil Water Content (cm)"
    ThicknessTopSWC::Int = 10

    # Field parameter IN FIELD.PAR  - with Reset option
    "cm  maximum soil depth for water extraction by evaporation"
    EvapZmax::Int = 30

    # Runoff parameters IN RUNOFF.PAR  - with Reset option
    "considered depth (m) of soil profile for calculation of mean soil water content for CN adjustment"
    RunoffDepth::Float64 = 0.30
    "correction Antecedent Moisture Class (On/Off)"
    CNcorrection::Bool = true

    # Temperature parameters IN TEMPERATURE.PAR  - with Reset option
    "Default Minimum and maximum air temperature (degC) if no temperature file"
    Tmin::Float64 = 12.0
    "Default Minimum and maximum air temperature (degC) if no temperature file"
    Tmax::Float64 = 28.0
    "1 for Method 1, 2 for Method 2, 3 for Method 3"
    GDDMethod::Int = 3

    # General parameters IN GENERAL.PAR
    "allowable percent RAW depletion for determination Inet"
    PercRAW::Int = 50
    "Default thickness of soil compartments [m]"
    CompDefThick::Float64 = 0.10
    "First day after sowing/transplanting (DAP = 1)"
    CropDay1::Int = 81
    "Default base and upper temperature (degC) assigned to crop"
    Tbase::Float64 = 10.0
    "Default base and upper temperature (degC) assigned to crop"
    Tupper::Float64 = 30.0
    "Percentage of soil surface wetted by irrigation in crop season"
    IrriFwInSeason::Int = 100
    "Percentage of soil surface wetted by irrigation off-season"
    IrriFwOffSeason::Int = 100

    # Showers parameters (10-day or monthly rainfall) IN SHOWERS.PAR
    "10-day or Monthly rainfall --> Runoff estimate"
    ShowersInDecade::Vector{Int} = fill(undef_int, 12)
    "10-day or Monthly rainfall --> Effective rainfall" #Note that in fortran code printing simulparam.effectiverain gives an error, we have to use getsimulparam_effectiverain_(etc)
    EffectiveRain::RepEffectiveRain = RepEffectiveRain()

    # Salinity
    "salt diffusion factor (capacity for salt diffusion in micro pores) [%]"
    SaltDiff::Int = 20
    "salt solubility [g/liter]"
    SaltSolub::Int = 100

    # Groundwater table
    "groundwater table is constant (or absent) during the simulation period"
    ConstGwt::Bool = true

    # Capillary rise
    "Undocumented"
    RootNrDF::Int = 16

    # Initial abstraction for surface runoff
    "Undocumented"
    IniAbstract::Int = 5
end


"""
    soil = RepSoil()

set from
defaultcropsoil.f90:289
"""
@kwdef mutable struct RepSoil <: AbstractParametersContainer
    "(* Readily evaporable water mm *)"
    REW::Int = 9
    NrSoilLayers::Int = 1
    CNValue::Int = 61
    "maximum rooting depth in soil profile for selected crop"
    RootMax::Float64 = undef_double
end


"""
    soillayer = SoilLayerIndividual()

creates a soil layer with a given soil class.

set from
defaultcropsoil.f90:289
"""
@kwdef mutable struct SoilLayerIndividual <: AbstractParametersContainer
    "Undocumented"
    Description::String = "Loamy soil horizon"
    "meter"
    Thickness::Float64 = 4.0
    "Vol % at Saturation"
    SAT::Float64 = 50.0
    "Vol % at Field Capacity"
    FC::Float64 = 30.0
    "Vol % at Wilting Point"
    WP::Float64 = 10.0
    "drainage factor 0 ... 1"
    tau::Float64 = undef_double
    "Infiltration rate at saturation mm/day"
    InfRate::Float64 = 500.0
    "root zone expansion rate in percentage"
    Penetrability::Int = 100
    "mass percentage of gravel"
    GravelMass::Int = 0
    "volume percentage of gravel"
    GravelVol::Float64 = 0.0
    "mm"
    WaterContent::Float64 = 0.0

    # salinity parameters (cells)
    "Macropores : from Saturation to Macro [vol%]"
    Macro::Int = undef_int
    "Mobility of salt in the various salt cellS"
    SaltMobility::Vector{Float64} = fill(undef_double, 11)
    "number of Saltcels between 0 and SC/(SC+2)*SAT vol%"
    SC::Int = undef_int
    "SC + 1   (1 extra Saltcel between SC/(SC+2)*SAT vol% and SAT) THis last celL is twice as large as the other cels *)"
    SCP1::Int = undef_int
    "Upper Limit of SC salt cells = SC/(SC+2) * (SAT/100) in m3/m3"
    UL::Float64 = undef_double
    "Size of SC salt cells [m3/m3] = UL/SC"
    Dx::Float64 = undef_double

    # capilary rise parameters
    "1 = sandy, 2 = loamy, 3 = sandy clayey, 4 - silty clayey soils"
    SoilClass::Int = undef_int
    "coefficients for Capillary Rise"
    CRa::Float64 = undef_double
    "coefficients for Capillary Rise"
    CRb::Float64 = undef_double
end


"""
    shape = RepShapes()

set from
defaultcropsoil.f90:175
"""
@kwdef mutable struct RepShapes <: AbstractParametersContainer
    "Percentage soil fertility stress for calibration"
    Stress::Int = 50
    "Shape factor for the response of Canopy Growth Coefficient to soil fertility stress"
    ShapeCGC::Float64 = 2.16
    "Shape factor for the response of Maximum Canopy Cover to soil fertility stress"
    ShapeCCX::Float64 = 0.79
    "Shape factor for the response of Crop Water Producitity to soil fertility stress"
    ShapeWP::Float64 = 1.67
    "Shape factor for the response of Decline of Canopy Cover to soil fertility stress"
    ShapeCDecline::Float64 = 1.67
    "Undocumented"
    Calibrated::Bool = true
end


"""
    assimilates = RepAssimilates()

set from
defaultcropsoil.f90:274
"""
@kwdef mutable struct RepAssimilates <: AbstractParametersContainer
    "Undocumented"
    On::Bool = false
    "Number of days at end of season during which assimilates are stored in root system"
    Period::Int = 0
    "Percentage of assimilates, transferred to root system at last day of season"
    Stored::Int = 0
    "Percentage of stored assimilates, transferred to above ground parts in next season"
    Mobilized::Int = 0
end


"""
    crop = RepCrop()

set from 
defaultcropsoil.f90:140
"""
@kwdef mutable struct RepCrop <: AbstractParametersContainer
    "Undocumented"
    subkind::Symbol = :Grain
    "Undocumented"
    ModeCycle::Symbol = :CalendarDays
    "1 = sown, 0 = transplanted, -9 = regrowth"
    Planting::Symbol = :Seed
    "Undocumented"
    pMethod::Symbol = :FAOCorrection
    "soil water depletion fraction for no stomatal stress as defined (ETo = 5 mm/day)"
    pdef::Float64 = 0.5
    "actual p for no stomatal stress for ETo of the day"
    pActStom::Float64 = undef_double
    "Undocumented"
    KsShapeFactorLeaf::Float64 = 3.0
    "Undocumented"
    KsShapeFactorStomata::Float64 = 3.0
    "Undocumented"
    KsShapeFactorSenescence::Float64 = 3.0
    "soil water depletion fraction for leaf expansion (ETo = 5 mm/day)"
    pLeafDefUL::Float64 = 0.25
    "soil water depletion fraction for leaf expansion (ETo = 5 mm/day)"
    pLeafDefLL::Float64 = 0.6
    "actual p for upper limit leaf expansion for ETo of the day"
    pLeafAct::Float64 = undef_double
    "soil water depletion fraction for canopys senescence (ETo = 5 mm/day)"
    pSenescence::Float64 = 0.85
    "actual p for canopy senescence for ETo of the day"
    pSenAct::Float64 = undef_double
    "soil water depletion fraction for failure of pollination"
    pPollination::Float64 = 0.9
    "Undocumented"
    SumEToDelaySenescence::Int = 50
    "(SAT - [vol%]) at which deficient aeration"
    AnaeroPoint::Int = 5
    "is reponse to soil fertility stress"
    StressResponse::RepShapes = RepShapes()
    "lower threshold for salinity stress (dS/m)"
    ECemin::Int = 2
    "upper threshold for salinity stress (dS/m)"
    ECemax::Int = 12
    "distortion canopy cover for calibration for simulation of effect of salinity stress (%)"
    CCsaltDistortion::Int = 25
    "Response of Ks stomata to ECsw for calibration: From 0 (none) to +200 (very strong)"
    ResponseECsw::Int = 100
    "Smax Top 1/4 root zone HOOGLAND"
    SmaxTopQuarter::Float64 = 0.048
    "Smax Bottom 1/4 root zone HOOGLAND"
    SmaxBotQuarter::Float64 = 0.012
    "Smax Top root zone HOOGLAND"
    SmaxTop::Float64 = undef_double
    "Smax Bottom root zone HOOGLAND"
    SmaxBot::Float64 = undef_double
    "Undocumented"
    KcTop::Float64 = 1.1
    "Reduction Kc (%CCx/day) as result of ageing effects, nitrogen defficiency, etc."
    KcDecline::Float64 = 0.15
    "%"
    CCEffectEvapLate::Int = 50
    "Daynummer: first day of croping period starting from sowing/transplanting"
    Day1::Int = undef_int
    "Daynummer: last day = harvest day"
    DayN::Int = undef_int
    "Length : rep_int_array; @ 1 .. 4 :  = the four growth stages"
    Length::Vector{Int} = fill(undef_int, 4)
    "rooting depth in meter"
    RootMin::Float64 = 0.3
    "rooting depth in meter"
    RootMax::Float64 = 1.0
    "10 times the root of the root function"
    RootShape::Int = 15
    "Base Temperature (degC)"
    Tbase::Float64 = 5.5
    "Upper temperature threshold (degC)"
    Tupper::Float64 = 30.0
    "Minimum air temperature below which pollination starts to fail (cold stress) (degC)"
    Tcold::Int = 8
    "Maximum air temperature above which pollination starts to fail (heat stress) (degC)"
    Theat::Int = 40
    "Minimum growing degrees required for full crop transpiration (degC - day)"
    GDtranspLow::Float64 = 11.1
    "Canopy cover per seedling (cm2)"
    SizeSeedling::Float64 = 6.5
    "Canopy cover of plant on 1st day (cm2) when regrowth"
    SizePlant::Float64 = 6.5
    "number of plants per hectare"
    PlantingDens::Int = 185000
    "starting canopy size  (fraction canopy cover)"
    CCo::Float64 = 6.5 / 10000 * 185000 / 10000
    "starting canopy size for regrowth (fraction canopy cover)"
    CCini::Float64 = 6.5 / 10000 * 185000 / 10000
    "Canopy growth coefficient (increase of CC in fraction per day)"
    CGC::Float64 = 0.15
    "Canopy growth coefficient (increase of CC in fraction per growing-degree day)"
    GDDCGC::Float64 = undef_double
    "expected maximum canopy cover  (fraction canopy cover)"
    CCx::Float64 = 0.8
    "Canopy Decline Coefficient (decrease of CC in fraction per day)"
    CDC::Float64 = 0.1275
    "Canopy Decline Coefficient (decrease of CC in fraction per growing-degree day)"
    GDDCDC::Float64 = undef_double
    "maximum canopy cover given water stress"
    CCxAdjusted::Float64 = undef_double
    "maximum existed CC during season (for correction Evap for withered canopy)"
    CCxWithered::Float64 = undef_double
    "initial canopy size after soil water stress"
    CCoAdjusted::Float64 = undef_double
    "required for regrowth (if CCini > CCo)"
    DaysToCCini::Int = 0
    "given or calculated from GDD"
    DaysToGermination::Int = 5
    "given or calculated from GDD"
    DaysToFullCanopy::Int = undef_int
    "adjusted to soil fertility"
    DaysToFullCanopySF::Int = undef_int
    "given or calculated from GDD"
    DaysToFlowering::Int = 70
    "given or calculated from GDD"
    LengthFlowering::Int = 10
    "given or calculated from GDD"
    DaysToSenescence::Int = 110
    "given or calculated from GDD"
    DaysToHarvest::Int = 125
    "given or calculated from GDD"
    DaysToMaxRooting::Int = 100
    "given or calculated from GDD"
    DaysToHIo::Int = 50
    "required for regrowth (if CCini > CCo)"
    GDDaysToCCini::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToGermination::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToFullCanopy::Int = undef_int
    "adjusted to soil fertility"
    GDDaysToFullCanopySF::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToFlowering::Int = undef_int
    "given or calculated from Calendar Days"
    GDDLengthFlowering::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToSenescence::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToHarvest::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToMaxRooting::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToHIo::Int = undef_int
    "(normalized) water productivity (gram/m2)"
    WP::Float64 = 17.0
    "(normalized) water productivity during yield formation (Percent WP)"
    WPy::Int = 100
    "Crop performance under elevated atmospheric CO2 concentration (%)"
    AdaptedToCO2::Int = 100
    "HI harvest index (percentage)"
    HI::Int = 50
    "average rate of change in harvest index (% increase per calendar day)"
    dHIdt::Float64 = undef_double
    "possible increase (%) of HI due to water stress before flowering"
    HIincrease::Int = 5
    "coefficient describing impact of restricted vegetative growth at flowering on HI"
    aCoeff::Float64 = 10.0
    "coefficient describing impact of stomatal closure at flowering on HI"
    bCoeff::Float64 = 8.0
    "allowable maximum increase (%) of specified HI"
    DHImax::Int = 15
    "linkage of determinancy with flowering"
    DeterminancyLinked::Bool = true
    "potential excess of fruits (%) ranging form"
    fExcess::Int = 50
    "dry matter content (%) of fresh yield"
    DryMatter::Int = 25
    "minimum rooting depth in first year in meter (for perennial crops)"
    RootMinYear1::Float64 = 0.3
    "True = Sown, False = transplanted (for perennial crops)"
    SownYear1::Bool = true
    "number of years at which CCx declines to 90 % of its value due to self-thinning - Perennials"
    YearCCx::Int = undef_int
    "shape factor of the decline of CCx over the years due to self-thinning - Perennials"
    CCxRoot::Float64 = undef_double
    "Undocumented"
    Assimilates::RepAssimilates = RepAssimilates()
end


"""
    compartment = CompartmentIndividual()
"""
@kwdef mutable struct CompartmentIndividual <: AbstractParametersContainer
    "meter"
    Thickness::Float64 = undef_double
    "m3/m3"
    Theta::Float64 = undef_double
    "mm/day"
    Fluxout::Float64 = undef_double
    "Undocumented"
    Layer::Int = undef_int
    "Maximum root extraction m3/m3.day"
    Smax::Float64 = undef_double
    "Vol % at Field Capacity adjusted to Aquifer"
    FCadj::Float64 = undef_double
    "number of days under anaerobic conditions"
    DayAnaero::Int = 0

    # weighting factor 0 ... 1
    # Importance of compartment in calculation of
    # - relative wetness (RUNOFF)
    # - evaporation process
    # - transpiration process *)
    "weighting factor 0 ... 1"
    WFactor::Float64 = undef_double

    # salinity factors
    "salt content in solution in cells (g/m2)"
    Salt::Vector{Float64} = zeros(Float64, 11)
    "salt deposit in cells (g/m2)"
    Depo::Vector{Float64} = zeros(Float64, 11)
end

Base.isapprox(a::CompartmentIndividual, b::CompartmentIndividual; kwargs...) = _isapprox(a, b; kwargs...)

"""
    iniswc = RepIniSWC()
"""
@kwdef mutable struct RepIniSWC <: AbstractParametersContainer
    "at specific depths or for specific layers"
    AtDepths::Bool = false
    "number of depths or layers considered"
    NrLoc::Int = undef_int
    "depth or layer thickness [m]"
    Loc::Vector{Float64} = fill(undef_double, max_no_compartments)
    "soil water content (vol%)"
    VolProc::Vector{Float64} = fill(undef_double, max_no_compartments)
    "ECe in dS/m"
    SaltECe::Vector{Float64} = fill(undef_double, max_no_compartments)
    "If iniSWC is at FC"
    AtFC::Bool = true
end


"""
    effectstress = RepEffectStress()
"""
@kwdef mutable struct RepEffectStress <: AbstractParametersContainer
    "Reduction of CGC (%)"
    RedCGC::Int = 0 #TODO maybe from timetomaxcanopysf
    "Reduction of CCx (%)"
    RedCCX::Int = 0 #TODO maybe from timetomaxcanopysf
    "Reduction of WP (%)"
    RedWP::Int = undef_int
    "Average decrease of CCx in mid season (%/day)"
    CDecline::Float64 = undef_double
    "Reduction of KsSto (%)"
    RedKsSto::Int = undef_int
end


"""
    storage = RepStorage()
"""
@kwdef mutable struct RepStorage <: AbstractParametersContainer
    "assimilates (ton/ha) stored in root systemn by CropString in Storage-Season"
    Btotal::Float64 = undef_double
    "full name of crop file which stores Btotal during Storage-Season"
    # OJO maybe it is Vector{String}
    CropString::String = ""
    "season in which Btotal is stored"
    Season::Int = undef_int
end


"""
    simulation = RepSim()

set from
global.f90:7694
"""
@kwdef mutable struct RepSim <: AbstractParametersContainer
    "daynumber"
    FromDayNr::Int = undef_int
    "daynumber"
    ToDayNr::Int = undef_int
    "Undocumented"
    IniSWC::RepIniSWC = RepIniSWC()
    "dS/m"
    ThetaIni::Vector{Float64} = fill(undef_double, max_no_compartments)
    "dS/m"
    ECeIni::Vector{Float64} = zeros(Float64, max_no_compartments)
    "Undocumented"
    SurfaceStorageIni::Float64 = 0.0
    "Undocumented"
    ECStorageIni::Float64 = 0.0
    "Undocumented"
    CCini::Float64 = undef_double
    "Undocumented"
    Bini::Float64 = 0
    "Undocumented"
    Zrini::Float64 = undef_double
    "Undocumented"
    LinkCropToSimPeriod::Bool = true
    "soil water and salts"
    ResetIniSWC::Bool = true
    "Undocumented"
    InitialStep::Int = 10
    "soil evap is before late season stage limited due to sheltering effect of (partly) withered canopy cover"
    EvapLimitON::Bool = false
    "remaining water (mm) in surface soil layer for stage 1 evaporation [REW .. 0]"
    EvapWCsurf::Float64 = undef_double
    "% extra to define upper limit of soil water content at start of stage 2 [100 .. 0]"
    EvapStartStg2::Int = undef_int
    "actual soil depth (m) for water extraction by evaporation  [EvapZmin/100 .. EvapZmax/100]"
    EvapZ::Float64 = undef_double
    "final Harvest Index might be smaller than HImax due to early canopy decline"
    HIfinal::Int = undef_int
    "delayed days since sowing/planting due to water stress (crop cannot germinate)"
    DelayedDays::Int = undef_int
    "germinate is false when crop cannot germinate due to water stress"
    Germinate::Bool = undef_bool
    "Sum ETo during stress period to delay canopy senescence"
    SumEToStress::Float64 = undef_double
    "Sum of Growing Degree-days"
    SumGDD::Float64 = undef_double
    "Sum of Growing Degree-days since Crop.Day1"
    SumGDDfromDay1::Float64 = undef_double
    "correction factor for Crop.SmaxBot if restrictive soil layer inhibit root development"
    SCor::Float64 = undef_double
    "Project with a sequence of simulation runs"
    MultipleRun::Bool = false
    "Undocumented"
    NrRuns::Int = 1
    "Project with a sequence of simulation runs and initial SWC is once or more KeepSWC"
    MultipleRunWithKeepSWC::Bool = false
    "Maximum rooting depth for multiple projects with KeepSWC"
    MultipleRunConstZrx::Float64 = undef_double
    "quality of irrigation water (dS/m)"
    IrriECw::Float64 = 0
    "number of days under anaerobic conditions"
    DayAnaero::Int = 0
    "effect of soil fertility and salinity stress on CC, WP and KsSto"
    EffectStress::RepEffectStress = RepEffectStress()
    "Undocumented"
    SalinityConsidered::Bool = undef_bool
    "IF protected (before CC = 1.25 CC0), seedling triggering of early senescence is switched off"
    ProtectedSeedling::Bool = undef_bool
    "Top soil is relative wetter than root zone and determines water stresses"
    SWCtopSoilConsidered::Bool = undef_bool
    "Default length of cutting interval (days)"
    LengthCuttingInterval::Int = 40
    "year number for perennials (1 = 1st year, 2, 3, 4, max = 127)"
    YearSeason::Int = 1
    "adjusted relative cover of weeds with self thinning for perennials"
    RCadj::Int = undef_int
    "Undocumented"
    Storage::RepStorage = RepStorage()
    "calendar year in which crop cycle starts"
    YearStartCropCycle::Int = undef_int
    "previous daynumber at the start of teh crop cycle"
    CropDay1Previous::Int = undef_int
end




"""
    endseason = RepEndSeason()
"""
@kwdef mutable struct RepEndSeason <: AbstractParametersContainer
    "to add to YearStartCropCycle"
    ExtraYears::Int = undef_int
    "by temperature criterion"
    AirTCriterion::Int = undef_int
    "Undocumented"
    GenerateTempOn::Bool = undef_bool
    "daynumber"
    StartSearchDayNr::Int = undef_int
    "daynumber"
    StopSearchDayNr::Int = undef_int
    "days"
    LengthSearchPeriod::Int = undef_int
end


"""
    content = RepContent()
"""
@kwdef mutable struct RepContent <: AbstractParametersContainer
    "at the beginning of the day"
    BeginDay::Float64 = undef_double
    "at the end of the day"
    EndDay::Float64 = undef_double
    "error on WaterContent or SaltContent over the day"
    ErrorDay::Float64 = undef_double
end


"""
    cuttings = RepCuttings()

set from
global.f90:3338
"""
@kwdef mutable struct RepCuttings <: AbstractParametersContainer
    "Undocumented"
    Considered::Bool = false
    "Canopy cover (%) after cutting"
    CCcut::Int = 30
    "first day after time window for generating cuttings (1 = start crop cycle)"
    Day1::Int = 1
    "number of days of time window for generate cuttings (-9 is whole crop cycle)"
    NrDays::Int = undef_int
    "ture: generate cuttings; false : schedule for cuttings"
    Generate::Bool = false
    "time criterion for generating cuttings"
    Criterion::Symbol = :NA
    "final harvest at crop maturity"
    HarvestEnd::Bool = false
    "first dayNr of list of specified cutting events (-9 = onset growing cycle)"
    FirstDayNr::Int = undef_int
end


"""
    management = RepManag()

set from
global.f90:3311
"""
@kwdef mutable struct RepManag <: AbstractParametersContainer
    "percent soil cover by mulch in growing period"
    Mulch::Int = 0
    "percent soil cover by mulch before growing period"
    SoilCoverBefore::Int = 0
    "percent soil cover by mulch after growing period"
    SoilCoverAfter::Int = 0
    "effect Mulch on evaporation before and after growing period"
    EffectMulchOffS::Int = 50
    "effect Mulch on evaporation in growing period"
    EffectMulchInS::Int = 50
    "Undocumented"
    FertilityStress::Int = 0
    "meter;"
    BundHeight::Float64 = 0
    "surface runoff"
    RunoffOn::Bool = true
    "percent increase/decrease of CN"
    CNcorrection::Int = 0
    "Relative weed cover in percentage at canopy closure"
    WeedRC::Int = 0
    "Increase/Decrease of Relative weed cover in percentage during mid season"
    WeedDeltaRC::Int = 0
    "Shape factor for crop canopy suppression"
    WeedShape::Float64 = -0.01
    "replacement (%) by weeds of the self-thinned part of the Canopy Cover - only for perennials"
    WeedAdj::Int = 100
    "Multiple cuttings" #Note that in fortran code printin management.cuttins gives an error, we have to use getmanagement_cuttings_(etc)
    Cuttings::RepCuttings = RepCuttings()
end

"""
    summ = RepSum()

set from
global.f90:7153
"""
@kwdef mutable struct RepSum <: AbstractParametersContainer
    # Undocumented
    Epot::Float64 = 0
    Tpot::Float64 = 0
    Rain::Float64 = 0
    Irrigation::Float64 = 0
    Infiltrated::Float64 = 0
    # mm
    Runoff::Float64 = 0
    Drain::Float64 = 0
    Eact::Float64 = 0
    Tact::Float64 = 0
    TrW::Float64 = 0
    ECropCycle::Float64 = 0
    CRwater::Float64 = 0
    # ton/ha
    Biomass::Float64 = 0
    YieldPart::Float64 = 0
    BiomassPot::Float64 = 0
    BiomassUnlim::Float64 = 0
    BiomassTot::Float64 = 0
    # ton/ha
    SaltIn::Float64 = 0
    SaltOut::Float64 = 0
    CRsalt::Float64 = 0
end

"""
    a = RepDayEventInt()

set from
global.f90:2838
"""
@kwdef mutable struct RepDayEventInt <: AbstractParametersContainer
    "Undocumented"
    DayNr::Int = 0
    "Undocumented"
    Param::Int = 0
end

"""
    a = RepDayEventDbl()
"""
@kwdef mutable struct RepDayEventDbl <: AbstractParametersContainer
    "Undocumented"
    DayNr::Int = undef_int
    "Undocumented"
    Param::Float64 = undef_double
end


"""
    irriecw = RepIrriECw()

set from
global.f90:2838
"""
@kwdef mutable struct RepIrriECw <: AbstractParametersContainer
    "Undocumented"
    PreSeason::Float64 = 0
    "Undocumented"
    PostSeason::Float64 = 0
end

"""
    onset = RepOnset()

set from
initialsettings.f90:464
"""
@kwdef mutable struct RepOnset <: AbstractParametersContainer
    "by rainfall or temperature criterion"
    GenerateOn::Bool = undef_bool
    "by temperature criterion"
    GenerateTempOn::Bool = undef_bool
    "Undocumented"
    Criterion::Symbol = :RainPeriod
    "Undocumented"
    AirTCriterion::Symbol = :CumulGDD
    "daynumber"
    StartSearchDayNr::Int = 1
    "daynumber"
    StopSearchDayNr::Int = 0
    "days"
    LengthSearchPeriod::Int = 0
end

"""
    projectinput = ProjectInputType()

Container for project file input data.
"""
@kwdef mutable struct ProjectInputType <: AbstractParametersContainer
    "The directory where we are working"
    ParentDir::String = undef_str
    "AquaCrop version number (common for all runs)"
    VersionNr::Float64 = undef_double
    "Project description (common for all runs)"
    Description::String = undef_str
    "Year number of cultivation (1 = seeding/planting year)"
    Simulation_YearSeason::Int = undef_int
    "First day of simulation period"
    Simulation_DayNr1::Int = undef_int
    "Last day of simulation period"
    Simulation_DayNrN::Int = undef_int
    "First day of cropping period"
    Crop_Day1::Int = undef_int
    "Last day of cropping period"
    Crop_DayN::Int = undef_int
    "Climate info"
    Climate_Info::String = undef_str
    "Climate file name"
    Climate_Filename::String = undef_str
    "Climate file directory"
    Climate_Directory::String = undef_str
    "Temperature info"
    Temperature_Info::String = undef_str
    "Temperature file name"
    Temperature_Filename::String = undef_str
    "Temperature file directory"
    Temperature_Directory::String = undef_str
    "ETo info"
    ETo_Info::String = undef_str
    "ETo file name"
    ETo_Filename::String = undef_str
    "ETo file directory"
    ETo_Directory::String = undef_str
    "Rain info"
    Rain_Info::String = undef_str
    "Rain file name"
    Rain_Filename::String = undef_str
    "Rain file directory"
    Rain_Directory::String = undef_str
    "CO2 info"
    CO2_Info::String = undef_str
    "CO2 file name"
    CO2_Filename::String = undef_str
    "CO2 file directory"
    CO2_Directory::String = undef_str
    "Calendar info"
    Calendar_Info::String = undef_str
    "Calendar file name"
    Calendar_Filename::String = undef_str
    "Calendar file directory"
    Calendar_Directory::String = undef_str
    "Crop info"
    Crop_Info::String = undef_str
    "Crop file name"
    Crop_Filename::String = undef_str
    "Crop file directory"
    Crop_Directory::String = undef_str
    "Irrigation info"
    Irrigation_Info::String = undef_str
    "Irrigation file name"
    Irrigation_Filename::String = undef_str
    "Irrigation file directory"
    Irrigation_Directory::String = undef_str
    "Management info"
    Management_Info::String = undef_str
    "Management file name"
    Management_Filename::String = undef_str
    "Management file directory"
    Management_Directory::String = undef_str
    "Groundwater info"
    GroundWater_Info::String = undef_str
    "Groundwater file name"
    GroundWater_Filename::String = undef_str
    "Groundwater file directory"
    GroundWater_Directory::String = undef_str
    "Soil info"
    Soil_Info::String = undef_str
    "Soil file name"
    Soil_Filename::String = undef_str
    "Soil file directory"
    Soil_Directory::String = undef_str
    "SWCIni info"
    SWCIni_Info::String = undef_str
    "SWCIni file name"
    SWCIni_Filename::String = undef_str
    "SWCIni file directory"
    SWCIni_Directory::String = undef_str
    "OffSeason info"
    OffSeason_Info::String = undef_str
    "OffSeason file name"
    OffSeason_Filename::String = undef_str
    "OffSeason file directory"
    OffSeason_Directory::String = undef_str
    "Observations info"
    Observations_Info::String = undef_str
    "Observations file name"
    Observations_Filename::String = undef_str
    "Observations file directory"
    Observations_Directory::String = undef_str
end

"""
    fileok = RepFileOK()
"""
@kwdef mutable struct RepFileOK <: AbstractParametersContainer
    Climate_Filename::Bool = undef_bool
    Temperature_Filename::Bool = undef_bool
    ETo_Filename::Bool = undef_bool
    Rain_Filename::Bool = undef_bool
    CO2_Filename::Bool = undef_bool
    Calendar_Filename::Bool = undef_bool
    Crop_Filename::Bool = undef_bool
    Irrigation_Filename::Bool = undef_bool
    Management_Filename::Bool = undef_bool
    GroundWater_Filename::Bool = undef_bool
    Soil_Filename::Bool = undef_bool
    SWCIni_Filename::Bool = undef_bool
    OffSeason_Filename::Bool = undef_bool
    Observations_Filename::Bool = undef_bool
end


"""
    record_clim = RepClim()
"""
@kwdef mutable struct RepClim <: AbstractParametersContainer
    "Undocumented"
    Datatype::Symbol = undef_symbol
    "D = day or decade, Y=1901 is not linked to specific year"
    FromD::Int = undef_int
    FromM::Int = undef_int
    FromY::Int = undef_int
    "Undocumented"
    ToD::Int = undef_int
    ToM::Int = undef_int
    ToY::Int = undef_int
    "daynumber"
    FromDayNr::Int = undef_int
    ToDayNr::Int = undef_int
    "Undocumented"
    FromString::String = undef_str
    ToString::String = undef_str
    "number of observations"
    NrObs::Int = undef_int
end

"""
    perennial_period = RepPerennialPeriod()
"""
@kwdef mutable struct RepPerennialPeriod <: AbstractParametersContainer
    "onset is generated by air temperature criterion"
    GenerateOnset::Bool = undef_bool
    "another doscstring"
    OnsetCriterion::Symbol = undef_symbol
    "Undocumented"
    OnsetFirstDay::Int = undef_int
    "Undocumented"
    OnsetFirstMonth::Int = undef_int
    "daynumber"
    OnsetStartSearchDayNr::Int = undef_int
    "daynumber"
    OnsetStopSearchDayNr::Int = undef_int
    "days"
    OnsetLengthSearchPeriod::Int = undef_int
    "degC or degree-days"
    OnsetThresholdValue::Float64 = undef_double
    "number of successive days"
    OnsetPeriodValue::Int = undef_int
    "number of occurrences (1,2 or 3)"
    OnsetOccurrence::Int = undef_int
    "end is generate by air temperature criterion"
    GenerateEnd::Bool = undef_bool
    "Undocumented"
    EndCriterion::Symbol = undef_symbol
    "Undocumented"
    EndLastDay::Int = undef_int
    "Undocumented"
    EndLastMonth::Int = undef_int
    "number of years to add to the onset year"
    ExtraYears::Int = undef_int
    "daynumber"
    EndStartSearchDayNr::Int = undef_int
    "daynumber"
    EndStopSearchDayNr::Int = undef_int
    "days"
    EndLengthSearchPeriod::Int = undef_int
    "degC or degree-days"
    EndThresholdValue::Float64 = undef_double
    "number of successive days"
    EndPeriodValue::Int = undef_int
    "number of occurrences (1,2 or 3)"
    EndOccurrence::Int = undef_int
    "Undocumented"
    GeneratedDayNrOnset::Int = undef_int
    "Undocumented"
    GeneratedDayNrEnd::Int = undef_int
end

"""
    crop_file_set = RepCropFileSet()
"""
@kwdef mutable struct RepCropFileSet <: AbstractParametersContainer
    "Undocumented"
    DaysFromSenescenceToEnd::Int = undef_int
    "given or calculated from GDD"
    DaysToHarvest::Int = undef_int
    "Undocumented"
    GDDaysFromSenescenceToEnd::Int = undef_int
    "given or calculated from Calendar Days"
    GDDaysToHarvest::Int = undef_int
end

"""
    gwtable = RepGwTable()
"""
@kwdef mutable struct RepGwTable <: AbstractParametersContainer
    "Undocumented"
    DNr1::Int = undef_int
    DNr2::Int = undef_int
    "cm"
    Z1::Int = undef_int
    Z2::Int = undef_int
    "dS/m"
    EC1::Float64 = undef_double
    EC2::Float64 = undef_double
end


"""
    stresstot = RepStressTot()
"""
@kwdef mutable struct RepStressTot <: AbstractParametersContainer
    "Undocumented"
    Salt::Float64 = undef_double
    "Undocumented"
    Temp::Float64 = undef_double
    "Undocumented"
    Exp::Float64 = undef_double
    "Undocumented"
    Sto::Float64 = undef_double
    "Undocumented"
    Weed::Float64 = undef_double
    "Undocumented"
    NrD::Int = undef_int
end

"""
    stress_indexes = StressIndexesBio()
"""
@kwdef mutable struct StressIndexesBio <: AbstractParametersContainer
    "Undocumented"
    StressProc::Int=undef_int
    "Undocumented"
    BioMProc::Float64=undef_double
    "Undocumented"
    BioMSquare::Float64=undef_double
end


"""
    stress_indexes = StressIndexesSalt()
"""
@kwdef mutable struct StressIndexesSalt <: AbstractParametersContainer
    "Undocumented"
    CCxReduction::Int=undef_int
    "Undocumented"
    SaltProc::Float64=undef_double
    "Undocumented"
    SaltSquare::Float64=undef_double
end

