# constants

const equiv = 0.64 # conversion factor: 1 dS/m = 0.64 g/l
const max_SoilLayers = 5
const max_No_compartments = 12
const undef_double = -9.9 # value for 'undefined' real(dp) variables
const undef_int = -9 # value for 'undefined' int32 variables
const undef_str = "" # value for 'undefined' string variables
const CO2Ref = 369.41 # reference CO2 in ppm by volume for year 2000 for Mauna Loa (Hawaii,USA)
const EvapZmin = 15.0 # cm  minimum soil depth for water extraction by evaporation
const eps =10E-08
const ElapsedDays = [0.0, 31.0, 59.25, 
                    90.25, 120.25, 151.25, 
                    181.25, 212.25, 243.25, 
                    273.25, 304.25, 334.25]
const DaysInMonth = [31,28,31,30,31,30,31,31,30,31,30,31]

const NameMonth = ["January","February","March","April","May","June",
                "July","August","September","October","November","December"]









# types

"""
    AbstractParametersContainer
"""
abstract type AbstractParametersContainer end

"""
    pc = ParametersContainer(T)

Contains parameters in a Dictionary of type Symbol=>T.
it is used for parameters without a type in the original AquaCrop.f90
"""
struct ParametersContainer{T} <: AbstractParametersContainer 
    parameters::AbstractDict{Symbol, T}
end

function ParametersContainer(::Type{T}) where{T}
    ParametersContainer(Dict{Symbol, T}())    
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
    get(parameterscontainer, parameterkey, missing)
end

Base.getindex(parameterscontainer::ParametersContainer, parameterkey::Symbol) = getparameter(parameterscontainer, parameterkey)


"""
    effectiverain = RepEffectiveRain()
"""
@kwdef mutable struct RepEffectiveRain <: AbstractParametersContainer
    "Undocumented"
    method::Symbol=:USDA
    "IF Method = Percentage"
    PercentEffRain::Int=70
    "adjustment of surface run-off"
    ShowersInDecade::Int=2
    "Root for reduction in soil evaporation"
    RootNrEvap::Int=5
end

"""
    simulparams = RepParams()

contains the simulation parameters.
"""
@kwdef mutable struct RepParam <: AbstractParametersContainer
    #  DEFAULT.PAR
    # crop parameters IN CROP.PAR - with Reset option
    "exponential decline with relative soil water [1 = small ... 8 = sharp]"
    EvapDeclineFactor::Int=4
    "Soil evaporation coefficients from wet bare soil"
    KcWetBare::Int=1.10    
    "CC threshold below which HI no longer increase (% of 100)"
    PercCCxHIfinal::Int=5
    "starting depth of root sine function in % of Zmin (sowing depth)"
    RootPercentZmin::Int=70
    "maximum root zone expansion in cm/day - fixed at 5 cm/day"
    MaxRootZoneExpansion::Float64=5.0
    "shape factro for the effect of water stress on root zone expansion"
    KsShapeFactorRoot::Int=-6
    "Soil water content (% TAW) required at sowing depth for germination"
    TAWGermination::Int=20
    "Adjustment factor for FAO-adjustment of soil water depletion (p) for various ET"
    pAdjFAO::Float64=1.0
    "delay [days] for full effect of anaeroby"
    DelayLowOxygen::Int=3
    "exponent of senescence factor adjusting drop in photosynthetic activity of dying crop"
    ExpFsen::Float64=1.0
    "Percentage decrease of p(senescence) once early canopy senescence is triggered"
    Beta::Int=12
    "Thickness of top soil for determination of its Soil Water Content (cm)"
    ThicknessTopSWC::Int=10

    # Field parameter IN FIELD.PAR  - with Reset option
    "cm  maximum soil depth for water extraction by evaporation"
    EvapZmax::Int=30

    # Runoff parameters IN RUNOFF.PAR  - with Reset option
    "considered depth (m) of soil profile for calculation of mean soil water content for CN adjustment"
    RunoffDepth::Float64=0.30
    "correction Antecedent Moisture Class (On/Off)"
    CNcorrection::Bool=true

    # Temperature parameters IN TEMPERATURE.PAR  - with Reset option
    "Default Minimum and maximum air temperature (degC) if no temperature file"
    Tmin::Float64=12.0
    "Default Minimum and maximum air temperature (degC) if no temperature file"
    Tmax::Float64=28.0
    "1 for Method 1, 2 for Method 2, 3 for Method 3"
    GDDMethod::Int=3

    # General parameters IN GENERAL.PAR
    "allowable percent RAW depletion for determination Inet"
    PercRAW::Int=50
    "Default thickness of soil compartments [m]"
    CompDefThick::Float64=0.10
    "First day after sowing/transplanting (DAP = 1)"
    CropDay1::Int=51
    "Default base and upper temperature (degC) assigned to crop"
    Tbase::Float64=10.0
    "Default base and upper temperature (degC) assigned to crop"
    Tupper::Float64=30.0
    "Percentage of soil surface wetted by irrigation in crop season"
    IrriFwInSeason::Int=100
    "Percentage of soil surface wetted by irrigation off-season"
    IrriFwOffSeason::Int=100

    # Showers parameters (10-day or monthly rainfall) IN SHOWERS.PAR
    "10-day or Monthly rainfall --> Runoff estimate"
    ShowersInDecade::Vector{Int}=fill(undef_int,12)
    "10-day or Monthly rainfall --> Effective rainfall"
    EffectiveRain::RepEffectiveRain=RepEffectiveRain()

    # Salinity
    "salt diffusion factor (capacity for salt diffusion in micro pores) [%]"
    SaltDiff::Int=20
    "salt solubility [g/liter]"
    SaltSolub::Int=100

    # Groundwater table
    "groundwater table is constant (or absent) during the simulation period"
    ConstGwt::Bool=true

    # Capillary rise
    "Undocumented"
    RootNrDF::Int=16

    # Initial abstraction for surface runoff
    "Undocumented"
    IniAbstract::Int=5
end

"""
    soil = RepSoil()
"""
@kwdef mutable struct RepSoil <: AbstractParametersContainer
    "(* Readily evaporable water mm *)"
    REW::Int=9
    NrSoilLayers::Int=1
    CNValue::Int=61
    "maximum rooting depth in soil profile for selected crop"
    RootMax::Float64=undef_double
end

"""
    soillayer = SoilLayerIndividual()

creates a soil layer with a given soil class.
"""
@kwdef mutable struct SoilLayerIndividual <: AbstractParametersContainer
    "Undocumented"
    Description::String="Loamy soil horizon"
    "meter"
    Thickness::Float64=4.0
    "Vol % at Saturation"
    SAT::Float64=50.0
    "Vol % at Field Capacity"
    FC::Float64=30.0
    "Vol % at Wilting Point"
    WP::Float64=10.0
    "drainage factor 0 ... 1"
    tau::Float64=undef_double
    "Infiltration rate at saturation mm/day"
    InfRate::Float64=500.0
    "root zone expansion rate in percentage"
    Penetrability::Int=100
    "mass percentage of gravel"
    GravelMass::Int=0
    "volume percentage of gravel"
    GravelVol::Float64=0.0
    "mm"
    WaterContent::Float64=0.0

    # salinity parameters (cells)
    "Macropores : from Saturation to Macro [vol%]"
    Macro::Int=undef_int
    "Mobility of salt in the various salt cellS"
    SaltMobility::Vector{Float64}=fill(undef_double, 11)
    "number of Saltcels between 0 and SC/(SC+2)*SAT vol%"
    SC::Int=undef_int
    "SC + 1   (1 extra Saltcel between SC/(SC+2)*SAT vol% and SAT) THis last celL is twice as large as the other cels *)"
    SCP1::Int=undef_int
    "Upper Limit of SC salt cells = SC/(SC+2) * (SAT/100) in m3/m3"
    UL::Float64=undef_double
    "Size of SC salt cells [m3/m3] = UL/SC"
    Dx::Float64=undef_double

    # capilary rise parameters
    "1 = sandy, 2 = loamy, 3 = sandy clayey, 4 - silty clayey soils"
    SoilClass::Int=undef_int
    "coefficients for Capillary Rise"
    CRa::Float64=undef_double
    "coefficients for Capillary Rise"
    CRb::Float64=undef_double
end

"""
    shape = RepShapes()
"""
@kwdef mutable struct RepShapes <: AbstractParametersContainer
    "Percentage soil fertility stress for calibration"
    Stress::Int=50
    "Shape factor for the response of Canopy Growth Coefficient to soil fertility stress"
    ShapeCGC::Float64=2.16
    "Shape factor for the response of Maximum Canopy Cover to soil fertility stress"
    ShapeCCX::Float64=0.79
    "Shape factor for the response of Crop Water Producitity to soil fertility stress"
    ShapeWP::Float64=1.67
    "Shape factor for the response of Decline of Canopy Cover to soil fertility stress"
    ShapeCDecline::Float64=1.67
    "Undocumented"
    Calibrated::Bool=true
end

"""
    assimilates = RepAssimilates()
"""
@kwdef mutable struct RepAssimilates <: AbstractParametersContainer
    "Undocumented"
    On::Bool=false
    "Number of days at end of season during which assimilates are stored in root system"
    Period::Int=0
    "Percentage of assimilates, transferred to root system at last day of season"
    Stored::Int=0
    "Percentage of stored assimilates, transferred to above ground parts in next season"
    Mobilized::Int=0
end 

"""
    crop = RepCrop()
"""
@kwdef mutable struct RepCrop <: AbstractParametersContainer
    "Undocumented"
    subkind::Symbol=:Grain
    "Undocumented"
    ModeCycle::Symbol=:CalendarDays
    "1 = sown, 0 = transplanted, -9 = regrowth"
    Planting::Symbol=:Seed
    "Undocumented"
    pMethod::Symbol=:FAOCorrection
    "soil water depletion fraction for no stomatal stress as defined (ETo = 5 mm/day)"
    pdef::Float64=0.5
    "actual p for no stomatal stress for ETo of the day"
    pActStom::Float64=undef_double
    "Undocumented"
    KsShapeFactorLeaf::Float64=3.0
    "Undocumented"
    KsShapeFactorStomata::Float64=3.0
    "Undocumented"
    KsShapeFactorSenescence::Float64=3.0
    "soil water depletion fraction for leaf expansion (ETo = 5 mm/day)"
    pLeafDefUL::Float64=0.25
    "soil water depletion fraction for leaf expansion (ETo = 5 mm/day)"
    pLeafDefLL::Float64=0.6
    "actual p for upper limit leaf expansion for ETo of the day"
    pLeafAct::Float64=undef_double
    "soil water depletion fraction for canopys senescence (ETo = 5 mm/day)"
    pSenescence::Float64=0.85
    "actual p for canopy senescence for ETo of the day"
    pSenAct::Float64=undef_double
    "soil water depletion fraction for failure of pollination"
    pPollination::Float64=0.9
    "Undocumented"
    SumEToDelaySenescence::Int=50
    "(SAT - [vol%]) at which deficient aeration"
    AnaeroPoint::Int=5
    "is reponse to soil fertility stress"
    StressResponse::RepShapes=RepShapes()
    "lower threshold for salinity stress (dS/m)"
    ECemin::Int=2
    "upper threshold for salinity stress (dS/m)"
    ECemax::Int=12
    "distortion canopy cover for calibration for simulation of effect of salinity stress (%)"
    CCsaltDistortion::Int=25
    "Response of Ks stomata to ECsw for calibration: From 0 (none) to +200 (very strong)"
    ResponseECsw::Int=100
    "Smax Top 1/4 root zone HOOGLAND"
    SmaxTopQuarter::Float64=0.048
    "Smax Bottom 1/4 root zone HOOGLAND"
    SmaxBotQuarter::Float64=0.012
    "Smax Top root zone HOOGLAND"
    SmaxTop::Float64=undef_double
    "Smax Bottom root zone HOOGLAND"
    SmaxBot::Float64=undef_double
    "Undocumented"
    KcTop::Float64=1.1
    "Reduction Kc (%CCx/day) as result of ageing effects, nitrogen defficiency, etc."
    KcDecline::Float64=0.15
    "%"
    CCEffectEvapLate::Int=50
    "Daynummer: first day of croping period starting from sowing/transplanting"
    Day1::Int=undef_int
    "Daynummer: last day = harvest day"
    DayN::Int=undef_int
    "Length : rep_int_array; @ 1 .. 4 :  = the four growth stages"
    Length::Vector{Int}=fill(undef_int,4)
    "rooting depth in meter"
    RootMin::Float64=0.3
    "rooting depth in meter"
    RootMax::Float64=1.0
    "10 times the root of the root function"
    RootShape::Int=15
    "Base Temperature (degC)"
    Tbase::Float64=5.5
    "Upper temperature threshold (degC)"
    Tupper::Float64=30.0
    "Minimum air temperature below which pollination starts to fail (cold stress) (degC)"
    Tcold::Int=8
    "Maximum air temperature above which pollination starts to fail (heat stress) (degC)"
    Theat::Int=40
    "Minimum growing degrees required for full crop transpiration (degC - day)"
    GDtranspLow::Float64=11.1
    "Canopy cover per seedling (cm2)"
    SizeSeedling::Float64=6.5
    "Canopy cover of plant on 1st day (cm2) when regrowth"
    SizePlant::Float64=6.5
    "number of plants per hectare"
    PlantingDens::Int=185000
    "starting canopy size  (fraction canopy cover)"
    CCo::Float64=6.5/10000 * 185000/10000
    "starting canopy size for regrowth (fraction canopy cover)"
    CCini::Float64=6.5/10000 * 185000/10000
    "Canopy growth coefficient (increase of CC in fraction per day)"
    CGC::Float64=0.15
    "Canopy growth coefficient (increase of CC in fraction per growing-degree day)"
    GDDCGC::Float64=undef_double
    "expected maximum canopy cover  (fraction canopy cover)"
    CCx::Float64=0.8
    "Canopy Decline Coefficient (decrease of CC in fraction per day)"
    CDC::Float64=0.1275
    "Canopy Decline Coefficient (decrease of CC in fraction per growing-degree day)"
    GDDCDC::Float64=undef_double
    "maximum canopy cover given water stress"
    CCxAdjusted::Float64=undef_double
    "maximum existed CC during season (for correction Evap for withered canopy)"
    CCxWithered::Float64=undef_double
    "initial canopy size after soil water stress"
    CCoAdjusted::Float64=undef_double
    "required for regrowth (if CCini > CCo)"
    DaysToCCini::Int=0
    "given or calculated from GDD"
    DaysToGermination::Int=5
    "given or calculated from GDD"
    DaysToFullCanopy::Int=undef_int
    "adjusted to soil fertility"
    DaysToFullCanopySF::Int=undef_int
    "given or calculated from GDD"
    DaysToFlowering::Int=70
    "given or calculated from GDD"
    LengthFlowering::Int=10
    "given or calculated from GDD"
    DaysToSenescence::Int=110
    "given or calculated from GDD"
    DaysToHarvest::Int=125
    "given or calculated from GDD"
    DaysToMaxRooting::Int=100
    "given or calculated from GDD"
    DaysToHIo::Int=50
    "required for regrowth (if CCini > CCo)"
    GDDaysToCCini::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToGermination::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToFullCanopy::Int=undef_int
    "adjusted to soil fertility"
    GDDaysToFullCanopySF::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToFlowering::Int=undef_int
    "given or calculated from Calendar Days"
    GDDLengthFlowering::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToSenescence::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToHarvest::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToMaxRooting::Int=undef_int
    "given or calculated from Calendar Days"
    GDDaysToHIo::Int=undef_int
    "(normalized) water productivity (gram/m2)"
    WP::Float64=17.0
    "(normalized) water productivity during yield formation (Percent WP)"
    WPy::Int=100
    "Crop performance under elevated atmospheric CO2 concentration (%)"
    AdaptedToCO2::Int=100
    "HI harvest index (percentage)"
    HI::Int=50
    "average rate of change in harvest index (% increase per calendar day)"
    dHIdt::Float64=undef_double
    "possible increase (%) of HI due to water stress before flowering"
    HIincrease::Int=5
    "coefficient describing impact of restricted vegetative growth at flowering on HI"
    aCoeff::Float64=10.0
    "coefficient describing impact of stomatal closure at flowering on HI"
    bCoeff::Float64=8.0
    "allowable maximum increase (%) of specified HI"
    DHImax::Int=15
    "linkage of determinancy with flowering"
    DeterminancyLinked::Bool=true
    "potential excess of fruits (%) ranging form"
    fExcess::Int=50
    "dry matter content (%) of fresh yield"
    DryMatter::Int=25
    "minimum rooting depth in first year in meter (for perennial crops)"
    RootMinYear1::Float64=0.3
    "True = Sown, False = transplanted (for perennial crops)"
    SownYear1::Bool=true
    "number of years at which CCx declines to 90 % of its value due to self-thinning - Perennials"
    YearCCx::Int=undef_int
    "shape factor of the decline of CCx over the years due to self-thinning - Perennials"
    CCxRoot::Float64=undef_double
    "Undocumented"
    Assimilates::RepAssimilates=RepAssimilates()
end 


"""
    compartment = CompartmentIndividual()
"""
@kwdef mutable struct CompartmentIndividual <: AbstractParametersContainer
    "meter"
    Thickness::Float64=undef_double
    "m3/m3"
    theta::Float64=undef_double
    "mm/day"
    fluxout::Float64=undef_double
    "Undocumented"
    Layer::Int=undef_int
    "Maximum root extraction m3/m3.day"
    Smax::Float64=undef_double
    "Vol % at Field Capacity adjusted to Aquifer"
    FCadj::Float64=undef_double
    "number of days under anaerobic conditions"
    DayAnaero::Int=0

    # weighting factor 0 ... 1
    # Importance of compartment in calculation of
    # - relative wetness (RUNOFF)
    # - evaporation process
    # - transpiration process *)
    "weighting factor 0 ... 1"
    WFactor::Float64=undef_double

    # salinity factors
    "salt content in solution in cells (g/m2)"
    Salt::Vector{Float64}=zeros(Float64,11)
    "salt deposit in cells (g/m2)"
    Depo::Vector{Float64}=zeros(Float64,11)
end 

"""
    iniswc = RepIniSWC()
"""
@kwdef mutable struct RepIniSWC <: AbstractParametersContainer
    "at specific depths or for specific layers"
    AtDepths::Bool=false
    "number of depths or layers considered"
    NrLoc::Int=undef_int
    "depth or layer thickness [m]"
    Loc::Vector{Float64}=fill(undef_double,max_No_compartments)
    "soil water content (vol%)"
    VolProc::Vector{Float64}=fill(undef_double,max_No_compartments)
    "ECe in dS/m"
    SaltECe::Vector{Float64}=zeros(undef_double,max_No_compartments)
    "If iniSWC is at FC"
    AtFC::Bool=true
end

"""
    effectstress = RepEffectStress()
"""
@kwdef mutable struct RepEffectStress <: AbstractParametersContainer
    "Reduction of CGC (%)"
    RedCGC::Int=0 #TODO maybe from timetomaxcanopysf
    "Reduction of CCx (%)"
    RedCCX::Int=0 #TODO maybe from timetomaxcanopysf
    "Reduction of WP (%)"
    RedWP::Int=undef_int
    "Average decrease of CCx in mid season (%/day)"
    CDecline::Float64=undef_double
    "Reduction of KsSto (%)"
    RedKsSto::Int=undef_int
end

"""
    storage = RepStorage()
"""
@kwdef mutable struct RepStorage <: AbstractParametersContainer 
    "assimilates (ton/ha) stored in root systemn by CropString in Storage-Season"
    Btotal::Float64=undef_double
    "full name of crop file which stores Btotal during Storage-Season"
    # OJO maybe it is Vector{String}
    CropString::String=""
    "season in which Btotal is stored"
    Season::Int=undef_int
end

"""
    simulation = RepSim()
"""
@kwdef mutable struct RepSim <: AbstractParametersContainer
    "daynumber"
    FromDayNr::Int=undef_int
    "daynumber"
    ToDayNr::Int=undef_int
    "Undocumented"
    IniSWC::RepIniSWC=RepIniSWC()
    "dS/m"
    ThetaIni::Vector{Float64}=fill(undef_double,max_No_compartments)
    "dS/m"
    ECeIni::Vector{Float64}=zeros(Float64,max_No_compartments)
    "Undocumented"
    SurfaceStorageIni::Float64=0.0
    "Undocumented"
    ECStorageIni::Float64=0.0
    "Undocumented"
    CCini::Float64=undef_double
    "Undocumented"
    Bini::Float64=0
    "Undocumented"
    Zrini::Float64=undef_double
    "Undocumented"
    LinkCropToSimPeriod::Bool=true
    "soil water and salts"
    ResetIniSWC::Bool=true
    "Undocumented"
    InitialStep::Int=undef_int
    "soil evap is before late season stage limited due to sheltering effect of (partly) withered canopy cover"
    EvapLimitON::Bool=false
    "remaining water (mm) in surface soil layer for stage 1 evaporation [REW .. 0]"
    EvapWCsurf::Float64=undef_double
    "% extra to define upper limit of soil water content at start of stage 2 [100 .. 0]"
    EvapStartStg2::Int=undef_int
    "actual soil depth (m) for water extraction by evaporation  [EvapZmin/100 .. EvapZmax/100]"
    EvapZ::Float64=undef_double
    "final Harvest Index might be smaller than HImax due to early canopy decline"
    HIfinal::Int=undef_int
    "delayed days since sowing/planting due to water stress (crop cannot germinate)"
    DelayedDays::Int=undef_int
    "germinate is false when crop cannot germinate due to water stress"
    Germinate::Bool=missing
    "Sum ETo during stress period to delay canopy senescence"
    SumEToStress::Float64=undef_double
    "Sum of Growing Degree-days"
    SumGDD::Float64=undef_double
    "Sum of Growing Degree-days since Crop.Day1"
    SumGDDfromDay1::Float64=undef_double
    "correction factor for Crop.SmaxBot if restrictive soil layer inhibit root development"
    SCor::Float64=undef_double
    "Project with a sequence of simulation runs"
    MultipleRun::Bool=missing
    "Undocumented"
    NrRuns::Int=undef_int
    "Project with a sequence of simulation runs and initial SWC is once or more KeepSWC"
    MultipleRunWithKeepSWC::Bool=missing
    "Maximum rooting depth for multiple projects with KeepSWC"
    MultipleRunConstZrx::Float64=undef_double
    "quality of irrigation water (dS/m)"
    IrriECw::Float64=undef_double
    "number of days under anaerobic conditions"
    DayAnaero::Int=0
    "effect of soil fertility and salinity stress on CC, WP and KsSto"
    EffectStress::RepEffectStress=RepEffectStress()
    "Undocumented"
    SalinityConsidered::Bool=missing
    "IF protected (before CC = 1.25 CC0), seedling triggering of early senescence is switched off"
    ProtectedSeedling::Bool=missing
    "Top soil is relative wetter than root zone and determines water stresses"
    SWCtopSoilConsidered::Bool=missing
    "Default length of cutting interval (days)"
    LengthCuttingInterval::Int=undef_int
    "year number for perennials (1 = 1st year, 2, 3, 4, max = 127)"
    YearSeason::Int=1
    "adjusted relative cover of weeds with self thinning for perennials"
    RCadj::Int=undef_int
    "Undocumented"
    Storage::RepStorage=RepStorage()
    "calendar year in which crop cycle starts"
    YearStartCropCycle::Int=undef_int
    "previous daynumber at the start of teh crop cycle"
    CropDay1Previous::Int=undef_int
end


"""
    dayevent = RepDayEventInt()
"""
@kwdef mutable struct RepDayEventInt <: AbstractParametersContainer
    "Undocumented"
    DayNr::Int=undef_int
    "Undocumented"
    param::Int=undef_int
end

"""
    onset = RepOnset()
"""
@kwdef mutable struct RepOnset <: AbstractParametersContainer
    "by rainfall or temperature criterion"
    GenerateOn::Bool=missing
    "by temperature criterion"
    GenerateTempOn::Bool=missing
    "Undocumented"
    Criterion::Int=undef_int
    "Undocumented"
    AirTCriterion::Int=undef_int
    "daynumber"
    StartSearchDayNr::Int=undef_int
    "daynumber"
    StopSearchDayNr::Int=undef_int
    "days"
    LengthSearchPeriod::Int=undef_int
end

"""
    endseason = RepEndSeason()
"""
@kwdef mutable struct RepEndSeason <: AbstractParametersContainer
    "to add to YearStartCropCycle"
    ExtraYears::Int=undef_int
    "by temperature criterion"
    AirTCriterion::Int=undef_int
    "Undocumented"
    GenerateTempOn::Bool=missing
    "daynumber"
    StartSearchDayNr::Int=undef_int
    "daynumber"
    StopSearchDayNr::Int=undef_int
    "days"
    LengthSearchPeriod::Int=undef_int
end

"""
    content = RepContent()
"""
@kwdef mutable struct RepContent <: AbstractParametersContainer
    "at the beginning of the day"
    BeginDay::Float64=undef_double
    "at the end of the day"
    EndDay::Float64=undef_double
    "error on WaterContent or SaltContent over the day"
    ErrorDay::Float64=undef_double
end

"""
    cuttings = RepCuttings()
"""
@kwdef mutable struct RepCuttings <: AbstractParametersContainer
    "Undocumented"
    Considered::Bool=false
    "Canopy cover (%) after cutting"
    CCcut::Int=30
    "first day after time window for generating cuttings (1 = start crop cycle)"
    Day1::Int=1
    "number of days of time window for generate cuttings (-9 is whole crop cycle)"
    NrDays::Int=undef_int
    "ture: generate cuttings; false : schedule for cuttings"
    Generate::Bool=false
    "time criterion for generating cuttings"
    Criterion::Bool=:NA
    "final harvest at crop maturity"
    HarvestEnd::Bool=false
    "first dayNr of list of specified cutting events (-9 = onset growing cycle)"
    FirstDayNr::Int=undef_int
end

"""
    management = RepManag()
"""
@kwdef mutable struct RepManag <: AbstractParametersContainer
    "percent soil cover by mulch in growing period"
    Mulch::Int=0
    "percent soil cover by mulch before growing period"
    SoilCoverBefore::Int=undef_int
    "percent soil cover by mulch after growing period"
    SoilCoverAfter::Int=undef_int
    "effect Mulch on evaporation before and after growing period"
    EffectMulchOffS::Int=undef_int
    "effect Mulch on evaporation in growing period"
    EffectMulchInS::Int=50
    "Undocumented"
    FertilityStress::Int=0
    "meter;"
    BundHeight::Float64=0
    "surface runoff"
    RunoffOn::Bool=true
    "percent increase/decrease of CN"
    CNcorrection::Int=0
    "Relative weed cover in percentage at canopy closure"
    WeedRC::Int=0
    "Increase/Decrease of Relative weed cover in percentage during mid season"
    WeedDeltaRC::Int=0
    "Shape factor for crop canopy suppression"
    WeedShape::Float64=-0.01
    "replacement (%) by weeds of the self-thinned part of the Canopy Cover - only for perennials"
    WeedAdj::Int=100
    "Multiple cuttings"
    Cuttings::RepCuttings=RepCuttings()
end

"""
    summ = RepSum()
"""
@kwdef mutable struct RepSum <: AbstractParametersContainer
    # Undocumented
    Epot::Float64=undef_double
    Tpot::Float64=undef_double
    Rain::Float64=undef_double
    Irrigation::Float64=undef_double
    Infiltrated::Float64=undef_double
    # mm
    Runoff::Float64=undef_double
    Drain::Float64=undef_double
    Eact::Float64=undef_double
    Tact::Float64=undef_double
    TrW::Float64=undef_double
    ECropCycle::Float64=undef_double
    CRwater::Float64=undef_double
    # ton/ha
    Biomass::Float64=0
    YieldPart::Float64=0
    BiomassPot::Float64=0
    BiomassUnlim::Float64=0
    BiomassTot::Float64=0
    # ton/ha
    SaltIn::Float64=undef_double
    SaltOut::Float64=undef_double
    CRsalt::Float64=undef_double
end




# setup

function starttheprogram(parentdir=nothing)
    if isnothing(parentdir)
        parentdir = pwd()
    end

    filepaths, resultsparameters = initializetheprogram(parentdir) 
    projectfilenames = initializeprojectfilename(filepaths)

    nprojects = length(projectfilenames)
    # TODO write some messages if nprojects==0 like in startunit.F90:957
    # and then early return

    for i in eachindex(projectfilenames)
        theprojectfile = projectfilenames[i]
        theprojecttype = getprojecttype(theprojectfile)
        initializeproject(i, theprojectfile, theprojecttype, filepaths)
        # runsimulation(theprojectfile, theprojecttype)
    end
end # not end



function initializeproject(i, theprojectfile, theprojecttype, filepaths)
    canselect = true

    # check if project file exists
    if theprojecttype != :typenone 
        testfile = filepaths[:list] * theprojectfile
        if !isfile(testfile) 
            canselect = false
        end 
    end 

    if (theprojecttype != :typenone) & canselect
        initialsettings = initializesettings(true, true, filepaths)
    
    else
        # TODO better logging
        if canselect
            error("bad projecttype for "*theprojectfile)
        else
            error("did not find the file "*theprojectfile)
        end
    end
    return 
end # not end

"""
    is = initializesettings(usedefaultsoilfile, usedefaultcropfile, filepaths)

gets the initial settings.
"""
function initializesettings(usedefaultsoilfile, usedefaultcropfile, filepaths)
    # 1. Program settings
    nrcompartments = max_No_compartments # Number of soil compartments (maximum is 12) (not a program parameter)
    simulparam = RepParam()
    preday = false
    inipercTAW = 50 # Default Value for Percentage TAW for Display in Initial Soil Water Content Menu



    # TODO 2a. Ground water table initialsettings.f90:311
    # note that we allready did the set of simulparam.ConstGwt=true like in initialsettings.f90:317

    # 2b. Soil profile and initial soil water content
    # TODO save soil profile defaultcropsoil.f90:322 maybe write a @show method?
    # OJO do not change soil.RootMax like in global.f90:4029 since it will be taken care later

    if usedefaultsoilfile
        soil, soillayers, compartments = loadprofile(filepaths[:simul]*"DEFAULT.SOL", simulparam)
    else
        soil = RepSoil()
        soillayers = [SoilLayerIndividual()]
        compartments = fill(CompartmentIndividual(Thickness=simulparam.CompDefThick), max_No_compartments)
        determinate_soilclass!(soillayers[1])
        determinate_coeffcapillaryrise!(soillayers[1])
    end
    
    simulation = RepSim()
    totalwatercontent = RepContent()
    completeprofiledescription!(soillayers, compartments, simulation, totalwatercontent)


    # 3. Crop characteristics and cropping period
    crop = RepCrop()
    # TODO save crop profile defaultcropsoil.f90:284  maybe write a @show method?
    soil.RootMax = rootmaxinsoilprofile(crop.RootMax, soillayers)

    # determine miscellaneous
    crop.Day1 = simulparam.CropDay1
    management = RepManag()
    completecropdescription!(crop, simulation, management)


    # 4. Field Management
    management.FertilityStress = 0
    cropstressparameterssoilfertility!(crop.StressResponse, management.FertilityStress, simulation.EffectStress)

    sumwabal = RepSum()
    
    # 5. Climate
    #
    # 5.6 Set Climate and Simulation Period
    crop.DayN = crop.Day1 + crop.DaysToHarvest - 1
    # adjusting simulation period
    # call AdjustSimPeriod()
    #
    # ! 6. irrigation
    # call NoIrrigation()
    #
    # ! 7. Off-season
    # call NoManagementOffSeason()
    #
    # ! 8. Project and Multiple Project file
    # call SetSimulation_MultipleRun(.false.) ! No sequence of simulation
    #                                         ! runs in the project
    # call SetSimulation_NrRuns(1)
    # call SetSimulation_MultipleRunWithKeepSWC(.false.)
    # call SetSimulation_MultipleRunConstZrx(real(undef_int, kind=dp))
    # call SetMultipleProjectFile(GetProjectFile())
    # call SetMultipleProjectFileFull(GetProjectFileFull())
    # call SetMultipleProjectDescription(GetProjectDescription())
    #
    # ! 11. Onset
    # call SetOnset_Criterion(Criterion_RainPeriod)
    # call SetOnset_AirTCriterion(AirTCriterion_CumulGDD)
    # call AdjustOnsetSearchPeriod()
    #
    # ! 12. Simulation run
    # call SetETo(5.0_dp)
    # call SetRain(0._dp)
    # call SetIrrigation(0._dp)
    # call SetSurfaceStorage(0._dp)
    # call SetECstorage(0.0_dp)
    # call SetDaySubmerged(0)
    # SumWaBal_temp = GetSumWaBal()
    # call GlobalZero(SumWaBal_temp)
    # call SetSumWaBal(SumWaBal_temp)
    # call SetDrain(0.0_dp) ! added 4.0
    # call SetRunoff(0.0_dp)! added 4.0
    # call SetInfiltrated(0.0_dp) ! added 4.0
    # call SetCRwater(0._dp) ! added 4.0
    # call SetCRsalt(0._dp) ! added 4.0
    # call SetSimulation_ResetIniSWC(.true.)
    # call SetSimulation_EvapLimitON(.false.)
    # call SetMaxPlotNew(50)
    # call SetMaxPlotTr(10_int8)
    # call SetSimulation_InitialStep(10) ! Length of period (days) for displaying
    #                                 ! intermediate results during simulation run
    # call SetSimulation_LengthCuttingInterval(40) ! Default length of
    #                                              ! cutting interval (days)


    return ComponentArray(
        :simulparam = simulparam,
        :nrcompartments = nrcompartments,
        :preday = preday,
        :inipercTAW = inipercTAW,
        :soil = soil,
        :soillayers = soillayers,
        :compartments = compartments,
    )
end #not end

function cropstressparameterssoilfertility!(stressout::RepEffectStress, cropsresp::RepShapes, stresslevel)
    pllactual = 1

    # decline canopy growth coefficient (cgc)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCGC)
    stressout.RedCGC = round(Int,(1-ksi)*100)      
    # decline maximum canopy cover (ccx)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCCX)
    stressout.RedCCX = round(Int, (1-ksi)*100)
    # decline crop water productivity (wp)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeWP)
    stressout.RedWP = round(Int, (1-ksi)*100)
    # decline canopy cover (cdecline)
    pulactual = 0
    ksi = ksany(stresslevel/100, pulactual, pllactual, cropsresp.ShapeCDecline)
    stressout.CDecline = 1 - ksi
    # inducing stomatal closure (kssto) not applicable
    ksi = 1
    stressout.RedKsSto = round(Int, (1-ksi)*100)
end #not end


"""
    completecropdescription!(crop::RepCrop, simulation::RepSim, management::RepManag)
"""
function completecropdescription!(crop::RepCrop, simulation::RepSim, management::RepManag)
    if ((crop.subkind == :Vegetative) |
        (crop.subkind == :Forage)) 
        if (crop.DaysToHIo > 0) 
            if (crop.DaysToHIo > crop.DaysToHarvest)
                crop.dHIdt = crop.HI/crop.DaysToHarvest
            else
                crop.dHIdt = crop.HI/crop.DaysToHIo
            end 
            if (crop.dHIdt > 100) 
                crop.dHIdt = 100
            end 
        else
            crop.dHIdt = 100
        end 
    else
        #  grain or tuber crops
        if (crop.DaysToHIo > 0) 
            crop.dHIdt = crop.HI/crop.DaysToHIo
        else
            crop.dHIdt = undef_double
        end
    end

    if (crop.ModeCycle == :CalendarDays) 
        crop.DaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                       crop.SizePlant, crop.CCx, crop.CGC)
        crop.DaysToFullCanopy = daystoreachccwithgivencgc(0.98*crop.CCx, crop.CCo, crop.CCx,
                                                          crop.CGC, crop.DaysToGermination)
        if (management.FertilityStress() != 0) 
            fertstress = management.FertilityStress
            daystofullcanopy, RedCGC_temp, RedCCX_temp, fertstress = timetomaxcanopysf(crop.CCo, crop.CGC, crop.CCx,
                              crop.DaysToGermination,
                              crop.DaysToFullCanopy,
                              crop.DaysToSenescence,
                              crop.DaysToFlowering,
                              crop.LengthFlowering,
                              crop.DeterminancyLinked,
                              crop.DaysToFullCanopySF,
                              simulation.EffectStress.RedCGC,
                              simulation.EffectStress.RedCCX,
                              management.FertilityStress
                              )
            management.FertilityStress = fertstress
            simulation.EffectStress.RedCGC = RedCGC_temp
            simulation.EffectStress.RedCCX = RedCCX_temp
            crop.DaysToFullCanopySF = daystofullcanopy
        else
            crop.DaysToFullCanopySF = crop.DaysToFullCanopy 
        end 
    else
        crop.GDDaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                         crop.SizePlant, crop.CCx, crop.GDDCGC)
        crop.DaysToCCini = timetoccini(crop.Planting, crop.PlantingDens, crop.SizeSeedling,
                                         crop.SizePlant, crop.CCx, crop.CGC)
        crop.GDDaysToFullCanopy = daystoreachccwithgivencgc(0.98*crop.CCx, crop.CCo, crop.CCx,
                                                          crop.GDDCGC, crop.GDDaysToGermination)
    end 

    cgcisgiven = true # required to adjust crop.daystofullcanopy (does not exist)
    length123, stlength, length12, cgcval = determinelengthgrowthstages(crop.CCo, crop.CCx, 
                                                            crop.CDC, crop.DaysToGermination,
                                                            crop.DaysToHarvest, cgcisgiven,
                                                            crop.DaysToCCini, crop.Planting,
                                                            crop.DaysToSenescence, crop.Length,
                                                            crop.DaysToFullCanopy, crop.CGC)
    crop.DaysToSenescence = length123
    crop.Length .= stlength
    crop.DaysToFullCanopy = length12
    crop.CGC = cgcval

    crop.CCoAdjusted = crop.CCo
    crop.CCxAdjusted = crop.CCx
    crop.CCxWithered = crop.CCx
end 


"""
    length123, stlength, length12, cgcval = determinelengthgrowthstages(ccoval, ccxval, cdcval, l0, totallength, 
                                                                        cgcgiven, thedaystoccini, theplanting, 
                                                                        length123, stlength, length12, cgcval)
"""
function determinelengthgrowthstages(ccoval, ccxval, cdcval, l0, totallength, 
                                     cgcgiven, thedaystoccini, theplanting, 
                                     length123, stlength, length12, cgcval)
    #OJO this function might have problems
    if (length123 < length12) 
        length123 = length12
    end 

    # 1. Initial and 2. Crop Development stage
    # CGC is given and Length12 is already adjusted to it
    # OR Length12 is given and CGC has to be determined
    if ((ccoval >= ccxval) | (length12 <= l0)) 
        length12 = 0
        stlength[1] = 0
        stlength[2] = 0
        cgcval = undef_int
    else
        if (!cgcgiven)  # length12 is given and cgc has to be determined
            cgcval = log((0.25*ccxval/ccoval)/(1-0.98))/(length12-l0)
            # check if cgc < maximum value (0.40) and adjust length12 if required
            if (cgcval > 0.40) 
                cgcval = 0.40
                ccxval_scaled = 0.98*ccxval
                length12 = daystoreachccwithgivencgc(ccxval_scaled , ccoval, 
                                                             ccxval, cgcval, l0)
                if (length123 < length12) 
                    length123 = length12
                end 
            end 
        end 
        # find stlength[1]
        cctoreach = 0.10
        stlength[1] = daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, 
                                                                    cgcval, l0)
        # find stlength[2]
        stlength[2] = length12 - stlength[1]
    end 
    l12adj = length12

    # adjust Initial and Crop Development stage, in case crop starts as regrowth
    if (theplanting == :Regrowth) 
        if (thedaystoccini == undef_int) 
            # maximum canopy cover is already reached at start season
            l12adj = 0
            stlength[1] = 0
            stlength[2] = 0
        else
            if (thedaystoccini == 0) 
                # start at germination
                l12adj = length12 - l0
                stlength[1] = stlength[1] - l0
            else
                # start after germination
                l12adj = length12 - (l0 + thedaystoccini)
                stlength[1] = stlength[1] - (l0 + thedaystoccini)
            end 
            if (stlength[1] < 0) 
                stlength[1] = 0
            end
            stlength[2] = l12adj - stlength[1]
        end 
    end 

    # 3. Mid season stage
    stlength[3] = length123 - l12adj

    # 4. Late season stage
    stlength[4] = lengthcanopydecline(ccxval, cdcval)

    # final adjustment
    if (stlength[1] > totallength) 
        stlength[1] = totallength
        stlength[2] = 0
        stlength[3] = 0
        stlength[4] = 0
    else
        if ((stlength[1]+stlength[2]) > totallength) 
            stlength[2] = totallength - stlength[1]
            stlength[3] = 0
            stlength[4] = 0
        else
            if ((stlength[1]+stlength[2]+stlength[3]) > totallength) 
                stlength[3] = totallength - stlength[1] - stlength[2]
                stlength[4] = 0
            elseif ((stlength[1]+stlength[2]+stlength[3]+stlength[4]) > totallength) 
                stlength[4] = totallength - stlength[1] - stlength[2] - stlength[3]
            end 
        end 
    end 

    return length123, stlength, length12, cgcval
end


"""
    nd = lengthcanopydecline(ccx, cdc)
"""
function lengthcanopydecline(ccx, cdc)
    nd = 0
    if (ccx > 0) 
        if (cdc <= eps(1.0)) 
            nd = undef_int
        else
            nd = round(Int, (((ccx+2.29)/(cdc*3.33))*log(1 + 1/0.05) + 0.50))
                         # + 0.50 to guarantee that cc is zero
        end 
    end 
    return nd
end



"""
    l12sf, redcgc, redccx, classsf = timetomaxcanopysf(cco, cgc, ccx, l0, l12, l123, ltoflor, lflor, determinantcrop, l12sf, redcgc, redccx, classsf)
"""
function timetomaxcanopysf(cco, cgc, ccx, l0, l12, l123, ltoflor, lflor, determinantcrop, l12sf, redcgc, redccx, classsf)
    if ((classsf == 0) | ((redccx == 0) & (redcgc == 0))) then
        l12sf = l12
    else
        cctoreach = 0.98*(1-redccx/100)*ccx
        l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
        # determine l12sfmax
        if (determinantcrop) then
            l12sfmax = ltoflor + round(Int, lflor/2)
        else
            l12sfmax = l123
        end
        # check for l12sfmax
        if (l12sf > l12sfmax) then
            # full canopy cannot be reached in potential period for vegetative growth
            # classsf := undef_int; ! switch to user defined soil fertility
            # 1. increase cgc(soil fertility)
            while ((l12sf > l12sfmax) & (redcgc > 0))
                redcgc = redcgc - 1
                l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
            end
            # 2. if not sufficient decrease ccx(soil fertility)
            while ((l12sf > l12sfmax) & ( ((1-redccx/100)*ccx) > 0.10) & (redccx <= 50))
                redccx = redccx + 1
                cctoreach = 0.98*(1-redccx/100)*ccx
                l12sf = daystoreachccwithgivencgc(cctoreach, cco, ((1-redccx/100)*ccx), (cgc*(1-(redcgc)/100)), l0)
            end
        end 
    end 
    return l12sf, redcgc, redccx, classsf
end

"""
    daystoresult = daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, cgcval, l0)
"""
function daystoreachccwithgivencgc(cctoreach, ccoval, ccxval, cgcval, l0)
    cctoreach_local = cctoreach
    if ((ccoval > cctoreach_local) | (ccoval >= ccxval)) 
        l = 0
    else
        if (cctoreach_local > (0.98*ccxval)) 
            cctoreach_local = 0.98*ccxval
        end 
        if (cctoreach_local <= ccxval/2) 
            l = log(cctoreach_local/ccoval)/cgcval
        else
            l = log((0.25*ccxval*ccxval/ccoval)/(ccxval-cctoreach_local))/cgcval
        end
    end 
    daystoresult = l0 + round(Int, l)
    return daystoresult
end

"""
    elapsedtime = timetoccini(theplantingtype, thecropplantingdens, 
                          thesizeseedling, thesizeplant, thecropccx, thecropcgc)
"""
function timetoccini(theplantingtype, thecropplantingdens, 
                          thesizeseedling, thesizeplant, thecropccx, thecropcgc)
    if ((theplantingtype == plant_seed) | (theplantingtype == plant_transplant) |
        (thesizeseedling >= thesizeplant))
        elapsedtime = 0
    else
        thecropcco = (thecropplantingdens/10000) * (thesizeseedling/10000)
        thecropccini = (thecropplantingdens/10000) * (thesizeplant/10000)
        if (thecropccini >= (0.98*thecropccx)) then
            elapsedtime = undef_int
        else
            elapsedtime = daystoreachccwithgivencgc(thecropccini, thecropcco, 
                                                    thecropccx, thecropcgc, 0)
        end 
    end 
    return elapsedtime
end

"""
    zmax = rootmaxinsoilprofile(zmaxcrop, soillayers::Vector{SoilLayerIndividual})
"""
function rootmaxinsoilprofile(zmaxcrop, soillayers::Vector{SoilLayerIndividual})
    nrsoillayers = length(soillayers)
    zmax = zmaxcrop
    zsoil = 0

    layi = 0
    while ((layi < nrsoillayers) & (zmax > 0))
        layi = layi + 1

        if ((soillayers[layi].Penetrability < 100) &
            (round(Int, zsoil*1000) < round(Int, zmaxcrop*1000)) 
            zmax = undef_double
        end 

        zsoil += soillayers[layi].Thickness
    end 

    if (zmax < 0) 
        zmax = zradjustedtorestrictivelayers(zmaxcrop, soillayers)
    end 

    return zmax
end

"""
    zrout = zradjustedtorestrictivelayers(zrin, soillayers::Vector{SoilLayerIndividual})
"""
function zradjustedtorestrictivelayers(zrin, soillayers::Vector{SoilLayerIndividual})
    nrsoillayers = length(soillayers)

    zrout = zrin

    # initialize (layer 1)
    layi = 1
    zsoil = soillayers[layi].Thickness
    zradj = 0
    zrremain = zrin
    deltaz = zsoil
    theend = false

    # check succesive layers
    while !theend
        zrtest = zradj + zrremain * (soillayers[layi].Penetrability/100)

        if ((layi == nrsoillayers) |
            (soillayers[layi].Penetrability == 0) |
            (round(Int, ZrTest*10000) <= round(Int, Zsoil*10000))) 
            # no root expansion in layer
            zrout = zrtest
            theend = true
        else
            zradj = zsoil
            zrremain -= deltaz/(soillayers[layi].Penetrability/100)
            layi += 1
            zsoil += zsoil + soillayers[layi].Thickness
            deltaz = soillayers[layi].Thickness
        end
    end 
    return zrout
end

"""
    completeprofiledescription!(soillayers::Vector{SoilLayerIndividual}, 
            compartments::Vector{CompartmentIndividual}, simulation::RepSim, totalwatercontent::RepContent)  
"""
function completeprofiledescription!(soillayers::Vector{SoilLayerIndividual}, 
            compartments::Vector{CompartmentIndividual}, simulation::RepSim, totalwatercontent::RepContent)  
    nrcompartments = length(compartments)
    nrsoillayers = length(soillayers)
    designate_soillayer_to_compartments!(compartments, nrsoillayers)

    for compi in 1:nrcompartments
        compartments[compi].Theta = soillayers[compartments[compi].Layer].FC/100
        compartments[compi].FCadj = soillayers[compartments[compi].Layer].FC 

        simulation.ThetaIni[compi] = compartments[compi].Theta

        soillayers[compartments[compi].Layer].WaterContent += 
            simulation.ThetaIni[compi]*100 * 10*compartments[compi].Thickness
    end

    total = 0
    for layeri in 1:nrsoillayers
        total += soillayers[layeri].WaterContent
    end 
    totalwatercontent.BeginDay(total)

    # initial soil water content and no salts
    simulation.IniSWC.NrLoc = nrsoillayers

    for layeri in 1:nrsoillayers
        simulation.IniSWC.Loc[layeri] = soillayers[layeri].Thickness
        simulation.IniSWC.VolProc[layeri] = soillayers[layeri].FC
        simulation.IniSWC.SaltECe[layeri] = 0
    end 
    return nothing
end 

"""
    designate_soillayer_to_compartments!(compartments::Vector{CompartmentIndividual}, nrsoillayers)
"""
function designate_soillayer_to_compartments!(compartments::Vector{CompartmentIndividual}, nrsoillayers)
    nrcompartments = length(compartments)
    depth = 0
    depthi = 0
    layeri = 1
    compi = 1
    
    outer_loop = true
    while outer_loop 
        depth = depth + soillayers[layeri].Thickness
        inner_loop = true
        while inner_loop
            depthi = depthi + compartments[compi].Thickness/2

            if (depthi <= depth) then
                compartments[compi].Layer = layeri
                nextlayer = false
                depthi = depthi + compartments[compi].Thickness/2 
                compi = compi + 1
                finished = (compi > nrcompartments)
            else
                depthi = depthi - compartments[compi].Thickness/2 
                nextlayer = true
                layeri = layeri + 1
                finished = (layeri > nrsoillayers)
            end 

            if (finished | nextlayer) 
                inner_loop = false
            end
        end

        if (finished)
            outer_loop = false
        end
    end

    for i in compi:nrcompartments
        compartments[i].Layer = nrsoillayers
    end 
    return nothing
end 

"""
    soil, soillayers, compartments = loadprofile(filepath, simulparam::RepParam)

loads data from filepath.
"""
function loadprofile(filepath, simulparam::RepParam)
    # note that we only consider version 7.1 parsing style
    soil = RepSoil()
    soillayers = SoilLayerIndividual[]
    compartments = CompartmentIndividual[]

    open(filepath, "r") do file
        profdescriptionlocal = strip(readline(file))
        versionnr = parse(Float64,strip(readline(file))[1:4])
        cnvalue = parse(Int,strip(readline(file))[1:4])
        soil.CNValue = cnvalue
        rew = parse(Int,strip(readline(file))[1:4])
        soil.REW = rew
        nrsoillayers = parse(Int,strip(readline(file))[1:4])
        soil.NrSoilLayers = nrsoillayers
        readline(file)
        readline(file)
        readline(file)
        for i in 1:nrsoillayers
            soillayer = SoilLayerIndividual()

            splitedline = split(readline(file))

            thickness_temp = parse(Float64,popfirst!(splitedline))
            soillayer.Thickness = thickness_temp
            SAT_temp = parse(Float64,popfirst!(splitedline))
            soillayer.SAT = SAT_temp
            FC_temp = parse(Float64,popfirst!(splitedline))
            soillayer.FC = FC_temp
            WP_temp = parse(Float64,popfirst!(splitedline))
            soillayer.WP = WP_temp
            infrate_temp = parse(Float64,popfirst!(splitedline))
            soillayer.InfRate = infrate_temp
            penetrability_temp = parse(Int,popfirst!(splitedline))
            soillayer.Penetrability = penetrability_temp
            gravelm_temp = parse(Int,popfirst!(splitedline))
            soillayer.GravelMass = gravelm_temp
            cra_temp = parse(Float64,popfirst!(splitedline))
            soillayer.CRa = cra_temp
            crb_temp = parse(Float64,popfirst!(splitedline))
            soillayer.CRb = crb_temp
            description_temp = join(splitedline," ") 
            soillayer.Description = description_temp
            gravelv_temp = from_gravelmass_to_gravelvol(SAT_temp, gravelm_temp)
            soillayer.GravelVol = gravelv_temp
            push!(soillayers, soillayer)
        end
    end

    loadprofileprocessing!(soil, soillayers, compartments, simulparam)

    return soil, soillayers, compartments
end

"""
    loadprofileprocessing!(soil::RepSoil, soillayers::Vector{SoilLayerIndividual},
        compartments::Vector{CompartmentIndividual}, simulparam::RepParam)

loads some data.
"""
function loadprofileprocessing!(soil::RepSoil, soillayers::Vector{SoilLayerIndividual},
        compartments::Vector{CompartmentIndividual}, simulparam::RepParam)

    # OJO set simulation parameters from global.f90:7691 done with @kwdef

    for i in eachindex(soillayers)
        soillayer = soillayers[i]
        
        # determine drainage coefficient
        tau = taufromksat(soillayer.InfRate)
        soillayer.tau = tau

        # determine number of salt cells based on infiltration rate
        if soillayer.InfRate < 112
            scp1 = 11
        else
            scp1 = round(Int, 1.6 + 1000/soillayer.InfRate )
            if scp1<2
                scp1 = 2
            end
        end
        soillayer.SCP1 = scp1

        # determine parameters for soil salinity
        sc = scp1 - 1
        soillayer.SC = sc
        Macro = round(Int, soillayer.FC)
        soillayer.Macro = Macro
        ul = soillayer.SAT/100 * sc/(sc + 2) # m3/m3
        soillayer.UL
        dx = ul / sc
        soillayer.Dx = dx

        calculate_saltmobility!(soillayer, simulparam.SaltDiff)

        # determine default parameters for capillary rise if missing
        determinate_soilclass!(soillayer)
    end

    determinenrandthicknesscompartments!(compartments, soillayers, simulparam.CompDefThick)

    # OJO do not call set soil root max like in global.f90:7744 since it we need crop data
    return nothing
end


"""
    determinenrandthicknesscompartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual}, compdefthick)
"""
function determinenrandthicknesscompartments!(compartments::Vector{CompartmentIndividual}, soillayers::Vector{SoilLayerIndividual}, compdefthick)
    totaldepthl = 0
    for i in eachindex(soillayers)
        totaldepthl += soillayers[i].Thickness
    end 
    totaldepthc = 0
    nrcompartments = 0
    loopi = true
    while loopi
        compartment = CompartmentIndividual()
        deltaz = (totaldepthl - totaldepthc)
        nrcompartments += 1
        if (deltaz > compdefthick)
            compartment.Thickness = compdefthick
        else
            compartment.Thickness = deltaz
        end 
        totaldepthc += compartment.Thickness
        push!(compartments, compartment)
        if (nrcompartments == max_No_compartments) | (abs(totaldepthc - totaldepthl) < 0.0001))
            loopi = false
        end
    end
    return nothing
end


"""
    calculate_saltmobility!(soillayer::SoilLayerIndividual, saltdiffusion)

sets the salt mobility
"""
function calculate_saltmobility!(soillayer::SoilLayerIndividual, saltdiffusion)
    Macro = soillayer.Macro
    Mobil = soillayer.SaltMobility

    Mix = saltdiffusion/100 # global salt mobility expressed as a fraction
    UL = soillayer.UL * 100 # upper limit in VOL% of SC cell

    # 1. convert Macro (vol%) in SaltCelNumber
    if (Macro > UL) 
        CelMax = soillayer.SCP1 
    else
        CelMax = round(Int, (Macro/UL)*soillayer.SC)
    end 

    if (CelMax <= 0) 
        CelMax = 1
    end

    # 2. find a and b
    if (Mix < 0.5) 
        a = Mix * 2
        b = exp(10*(0.5-Mix)*log(10))
    else
        a = 2 * (1 - Mix)
        b = exp(10*(Mix-0.5)*log(10))
    end 

    # 3. calculate mobility for cells = 1 to Macro
    for i in 1:CelMax-1
        xi = i *1 / (CelMax-1)
        if (Mix > 0) 
            if (Mix < 0.5) 
                yi = exp(log(a)+xi*log(b))
                Mobil[i] = (yi-a)/(a*b-a)
            elseif ((Mix >= 0.5 - eps(0.0)) & (Mix <= 0.5 + eps(0.0)))
                Mobil[i] = xi
            elseif (Mix < 1) then
                yi = exp(log(a)+(1-xi)*log(b))
                Mobil[i] = 1 - (yi-a)/(a*b-a)
            else
                Mobil[i] = 1
            end 
        else
            Mobil[i] = 0
        end 
    end 

    # 4. Saltmobility between Macro and SAT
    for i in CelMax:soillayer.SCP1 
        Mobil[i] = 1
    end 
    return nothing
end 

"""
    tau = taufromksat(ksat)
"""
function taufromksat(ksat)
    if (abs(ksat) < eps(1.0)) then
        tau = 0
    else
        tautemp = round(Int,100.0*0.0866*exp(0.35*log(ksat)))
        if (tautemp < 0) then
            tautemp = 0
        end 
        if (tautemp > 100) then
            tautemp = 100
        end 
        tau = tautemp/100.0
    end 
    return tau
end


"""
    gravelvol = from_gravelmass_to_gravelvol(porositypercent, gravelmasspercent)

calculates the gravel volume of soil layer.
"""
function from_gravelmass_to_gravelvol(porositypercent, gravelmasspercent)
    mineralbd = 2.65 # mg/m3
    if (gravelmasspercent > 0) 
        matrixbd = mineralbd * (1.0 - porositypercent/100.0)
        soilbd = 100.0/(gravelmasspercent/mineralbd + (100.0-gravelmasspercent)/matrixbd)
        fromgravelmasstogravelvolume = gravelmasspercent * (soilbd/mineralbd)
    else
       fromgravelmasstogravelvolume = 0.0
    end
    return fromgravelmasstogravelvolume
end

"""
    determinate_soilclass!(soillayer::SoilLayerIndividual)

sets the soil class of soillayer considering its own data.
"""
function determinate_soilclass!(soillayer::SoilLayerIndividual) 
    satvolpro = soillayer.SAT
    fcvolpro = soillayer.FC
    pwpvolpro = soillayer.WP
    ksatmm = soillayer.InfRate

    if (satvolpro <= 55.0) 
        if (pwpvolpro >= 20.0)
            if ((satvolpro >= 49.0) & (fcvolpro >= 40.0))
                numbersoilclass = 4  # silty clayey soils
            else
                numbersoilclass = 3  # sandy clayey soils
            end
        else
            if (fcvolpro < 23.0)
                numbersoilclass = 1 # sandy soils
            else
                if ((pwpvolpro > 16.0) & (ksatmm < 100.0)) 
                    numbersoilclass = 3 # sandy clayey soils
                else
                    if ((pwpvolpro < 6.0) & (fcvolpro < 28.0) & (ksatmm >750.0)) 
                        numbersoilclass = 1 # sandy soils
                    else
                        numbersoilclass = 2  # loamy soils
                    end 
                end 
            end 
        end 
    else
        numbersoilclass = 4 # silty clayey soils
    end 
    soillayer.SoilClass = numbersoilclass
    return nothing
end 

"""
    determinate_coeffcapillaryrise!(soillayer::SoilLayerIndividual)

sets the coefficients for capillary rise of soillayer considering its own data.
"""
function determinate_coeffcapillaryrise!(soillayer::SoilLayerIndividual)
    soilclass = soillayer.SoilClass
    ksatmm = soillayer.InfRate

    # determine parameters
    if (round(ksatmm*1000) <= 0)
        aparam = undef_double
        bparam = undef_double
    else
        if soilclass == 1
            aparam = -0.3112 - ksatmm/100000.0
            bparam = -1.4936 + 0.2416*log(ksatmm)
        elseif soilclass == 2
            aparam = -0.4986 + 9.0*ksatmm/100000.0
            bparam = -2.1320 + 0.4778*log(ksatmm)
        elseif soilclass == 3 
            aparam = -0.5677 - 4.0*ksatmm/100000.0
            bparam = -3.7189 + 0.5922*log(ksatmm)
        else
            aparam = -0.6366 + 8.0*ksatmm/10000.0
            bparam = -1.9165 + 0.7063*log(ksatmm)
        end
    end

    soillayer.CRa = aparam
    soillayer.CRb = bparam
    return nothing
end

"""
    pt = getprojecttype(theprojectfile)

gets the project type for a given file.
"""
function getprojecttype(theprojectfile)
    if endswith(theprojectfile, "PRO")
        theprojecttype = :typepro
    elseif endswith(theprojectfile, "PRM")
        theprojecttype = :typeprm
    else
        theprojecttype = :typenone
    end
    return theprojecttype
end


"""
    projectfilenames = initializeprojectfilename(filepaths)

Gets all the names of the projects files.
"""
function initializeprojectfilename(filepaths)
    projectfilenames = String[]

    listprojectsfile = filepaths[:list]*"ListProjects.txt"
    listprojectsfileexist = isfile(listprojectsfile)

    if !listprojectsfileexist
        cmd_1 = `ls -1 $(filepaths[:list])`
        cmd_2 = `grep -E ".*.PR[O,M]\$"`
        rc = run(pipeline( pipeline(cmd_1,cmd_2), stdout = listprojectsfile))
        if rc.exitcode != 0
            error("Failed to create "*listprojectsfile)
        end
    end

    open(listprojectsfile, "r") do file
        for line in eachline(file)
            projectfile = strip(line)
            if !isempty(projectfile)
                push!(projectfilenames, projectfile)
            end
        end
    end
    return projectfilenames
end

"""
    filepaths, resultsparameters = initializetheprogram(parentdir)
    
Gets the file paths and the simulation parameters.
"""
function initializetheprogram(parentdir)
    filepaths = defaultfilepaths(parentdir)

    resultsparameters = getresultsparameters(filepaths[:simul])

    # TODO startunit.F90:429  PrepareReport()

    return filepaths, resultsparameters 
end


"""
    fl = defaultfilepaths(parentdir::AbstractString)

sets the default directories for the input files.
"""
function defaultfilepaths(parentdir::AbstractString)
    return ComponentArray(
    outp=parentdir*"OUTP/",
    simul=parentdir*"SIMUL/",
    list=parentdir*"LIST/",
    param=parentdir*"PARAM/",
    prog=parentdir*"")
end

"""
    resultsparameters = getresultsparameters(path::String)

gets all the results parameters in filepaths[:simul].
"""
function getresultsparameters(path::String)
    aggregationresultsparameters = ParametersContainer(Symbol)
    filename = path*"AggregationResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            aggregationtype = strip(readline(filen))[1]
            if aggregationtype == '1'
                setparameter!(aggregationresultsparameters, :outputaggregate, :daily)
            elseif aggregationtype == '2'
                setparameter!(aggregationresultsparameters, :outputaggregate, :daily_10)
            elseif  aggregationtype == '3'
                setparameter!(aggregationresultsparameters, :outputaggregate, :monthly)
            else
                setparameter!(aggregationresultsparameters, :outputaggregate, :seasonal)
            end
        end
    end

    dailyresultsparameters = ParametersContainer(Bool)
    filename = path*"DailyResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            for line in eachline(file)
                outpar = strip(line)[1]
                if outpar == '1'
                    setparameter!(dailyresultsparameters, :out1Wabal, true)
                elseif outpar == '2'
                    setparameter!(dailyresultsparameters, :out2Crop, true)
                elseif outpar == '3'
                    setparameter!(dailyresultsparameters, :out3Prof, true)
                elseif outpar == '4'
                    setparameter!(dailyresultsparameters, :out4Salt, true)
                elseif outpar == '5'
                    setparameter!(dailyresultsparameters, :out5CompWC, true)
                elseif outpar == '6'
                    setparameter!(dailyresultsparameters, :out6CompEC, true)
                elseif outpar == '7'
                    setparameter!(dailyresultsparameters, :out7Clim, true)
                end
            end
            if ( dailyresultsparameters[:out1Wabal] | dailyresultsparameters[:out2Crop] 
                | dailyresultsparameters[:out3Prof] | dailyresultsparameters[:out4Salt]
                | dailyresultsparameters[:out5CompWC] | dailyresultsparameters[:out6CompEC]
                | dailyresultsparameters[:out7Clim])
                setparameter!(dailyresultsparameters, :outdailyresults, true)
            end
        end
    end

    particularresultsparameters = ParametersContainer(Bool)
    filename = path*"ParticularResults.SIM"
    if isfile(filename) 
        open(filename, "r") do file
            for line in eachline(file)
                outpar = strip(line)[1]
                if outpar == '1'
                    setparameter!(particularresultsparameters, :part1Mult, true)
                elseif outpar == '2'
                    setparameter!(particularresultsparameters, :part2Eval, true)
                end
            end
        end
    end


    return ComponentArray(aggregationresults=aggregationresultsparameters,
                dailyresults=dailyresultsparameters,
                paricularresults=particularresultsparameters)
end
