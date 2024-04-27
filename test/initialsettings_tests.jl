using AquaCrop
using Test
using ComponentArrays

function declare_initial_variables()
    # Local variables
    simulation = AquaCrop.RepSim(
        FromDayNr=81,
        ToDayNr=205,
        IniSWC=AquaCrop.RepIniSWC(
            AtDepths=false,
            NrLoc=1,
            Loc=[4, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double],
            VolProc=[30, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double],
            SaltECe=[0, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double],
            AtFC=true
        ),
        ThetaIni=[0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3, 0.3],
        ECeIni=[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        SurfaceStorageIni=0,
        ECStorageIni=0,
        CCini=AquaCrop.undef_double,#-9,
        Bini=0,
        Zrini=AquaCrop.undef_double,#-9,
        LinkCropToSimPeriod=true,
        ResetIniSWC=true,
        InitialStep=10,
        EvapLimitON=false,
        EvapWCsurf=AquaCrop.undef_double,#0,
        EvapStartStg2=AquaCrop.undef_int,#0,
        EvapZ=AquaCrop.undef_double,#0,
        HIfinal=AquaCrop.undef_int,#0,
        DelayedDays=AquaCrop.undef_int,#0,
        Germinate=false,
        SumEToStress=AquaCrop.undef_double,#0,
        SumGDD=AquaCrop.undef_double,#0,
        SumGDDfromDay1=AquaCrop.undef_double,#0,
        SCor=AquaCrop.undef_double,#0,
        MultipleRun=false,
        NrRuns=1,
        MultipleRunWithKeepSWC=false,
        MultipleRunConstZrx=AquaCrop.undef_double,#-9, 
        IrriECw=0,
        DayAnaero=0,
        EffectStress=AquaCrop.RepEffectStress(
            RedCGC=0,
            RedCCX=0,
            RedWP=0,
            CDecline=0,
            RedKsSto=0
        ),
        SalinityConsidered=false,
        ProtectedSeedling=false,
        SWCtopSoilConsidered=false,
        LengthCuttingInterval=40,
        YearSeason=1,
        RCadj=AquaCrop.undef_int,#0,
        Storage=AquaCrop.RepStorage(
            Btotal=AquaCrop.undef_double,#0,
            CropString="",
            Season=AquaCrop.undef_int#0
        ),
        YearStartCropCycle=AquaCrop.undef_int,#0,
        CropDay1Previous=AquaCrop.undef_int#0
    )

    soil = AquaCrop.RepSoil(
        REW=9,
        NrSoilLayers=1,
        CNValue=61,
        RootMax=1
    )

    soil_layers = AquaCrop.SoilLayerIndividual[
        AquaCrop.SoilLayerIndividual(
        Description="Loamy",
        Thickness=4,
        SAT=50,
        FC=30,
        WP=10,
        tau=0.76,
        InfRate=500,
        Penetrability=100,
        GravelMass=0,
        GravelVol=0,
        WaterContent=360,
        Macro=30,
        SaltMobility=[0.030653430031715494, 0.99999999999999989, 1, 1, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double], # [0.030653430031715494, 0.99999999999999989, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        SC=3,
        SCP1=4,
        UL=0.29999999999999999,
        Dx=0.099999999999999992,
        SoilClass=2,
        CRa=-0.4536,
        CRb=0.83734
    )
    ]

    compartments = AquaCrop.CompartmentIndividual[
        AquaCrop.CompartmentIndividual(
            Thickness=0.10000000000000001,
            theta=0.29999999999999999,
            fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=30,
            DayAnaero=0,
            WFactor=AquaCrop.undef_double, #0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        )
        for _ in 1:12
    ]

    simulparam = AquaCrop.RepParam(
        EvapDeclineFactor=4,
        KcWetBare=1.1,
        PercCCxHIfinal=5,
        RootPercentZmin=70,
        MaxRootZoneExpansion=5,
        KsShapeFactorRoot=-6,
        TAWGermination=20,
        pAdjFAO=1,
        DelayLowOxygen=3,
        ExpFsen=1,
        Beta=12,
        ThicknessTopSWC=10,
        EvapZmax=30,
        RunoffDepth=0.3,
        CNcorrection=true,
        Tmin=12,
        Tmax=28,
        GDDMethod=3,
        PercRAW=50,
        CompDefThick=0.1,
        CropDay1=81,
        Tbase=10,
        Tupper=30,
        IrriFwInSeason=100,
        IrriFwOffSeason=100,
        ShowersInDecade=fill(AquaCrop.undef_int, 12),
        EffectiveRain=AquaCrop.RepEffectiveRain(
            method=:USDA, #1,
            PercentEffRain=70,
            ShowersInDecade=2,
            RootNrEvap=5
        ),
        SaltDiff=20,
        SaltSolub=100,
        ConstGwt=true,
        RootNrDF=16,
        IniAbstract=5
    )

    total_water_content = AquaCrop.RepContent(
        BeginDay=360,
        EndDay=AquaCrop.undef_double, #0,
        ErrorDay=AquaCrop.undef_double, #0
    )

    crop = AquaCrop.RepCrop(
        subkind=:Grain, #1,
        ModeCycle=:CalendarDays, #1,
        Planting=:Seed, #0,
        pMethod=:FAOCorrection, #1,
        pdef=0.5,
        pActStom=AquaCrop.undef_double, #0,
        KsShapeFactorLeaf=3,
        KsShapeFactorStomata=3,
        KsShapeFactorSenescence=3,
        pLeafDefUL=0.25,
        pLeafDefLL=0.59999999999999998,
        pLeafAct=AquaCrop.undef_double, #0,
        pSenescence=0.84999999999999998,
        pSenAct=AquaCrop.undef_double, #0,
        pPollination=0.90000000000000002,
        SumEToDelaySenescence=50,
        AnaeroPoint=5,
        StressResponse=AquaCrop.RepShapes(
            Stress=50,
            ShapeCGC=2.1600000000000001,
            ShapeCCX=0.79000000000000004,
            ShapeWP=1.6699999999999999,
            ShapeCDecline=1.6699999999999999,
            Calibrated=true
        ),
        ECemin=2,
        ECemax=12,
        CCsaltDistortion=25,
        ResponseECsw=100,
        SmaxTopQuarter=0.048000000000000001,
        SmaxBotQuarter=0.012,
        SmaxTop=AquaCrop.undef_double, #0,
        SmaxBot=AquaCrop.undef_double, #0,
        KcTop=1.1000000000000001,
        KcDecline=0.14999999999999999,
        CCEffectEvapLate=50,
        Day1=81,
        DayN=205,
        Length=[19, 31, 60, 15],
        RootMin=0.29999999999999999,
        RootMax=1,
        RootShape=15,
        Tbase=5.5,
        Tupper=30,
        Tcold=8,
        Theat=40,
        GDtranspLow=11.1,
        SizeSeedling=6.5,
        SizePlant=6.5,
        PlantingDens=185000,
        CCo=0.012024999999999999,
        CCini=0.012024999999999999,
        CGC=0.14999999999999999,
        GDDCGC=AquaCrop.undef_double, #-9,
        CCx=0.80000000000000004,
        CDC=0.1275,
        GDDCDC=AquaCrop.undef_double, #-9,
        CCxAdjusted=0.80000000000000004,
        CCxWithered=0.80000000000000004,
        CCoAdjusted=0.012024999999999999,
        DaysToCCini=0,
        DaysToGermination=5,
        DaysToFullCanopy=50,
        DaysToFullCanopySF=50,
        DaysToFlowering=70,
        LengthFlowering=10,
        DaysToSenescence=110,
        DaysToHarvest=125,
        DaysToMaxRooting=100,
        DaysToHIo=50,
        GDDaysToCCini=AquaCrop.undef_int,
        GDDaysToGermination=AquaCrop.undef_int,
        GDDaysToFullCanopy=AquaCrop.undef_int,
        GDDaysToFullCanopySF=AquaCrop.undef_int,
        GDDaysToFlowering=AquaCrop.undef_int,
        GDDLengthFlowering=AquaCrop.undef_int,
        GDDaysToSenescence=AquaCrop.undef_int,
        GDDaysToHarvest=AquaCrop.undef_int,
        GDDaysToMaxRooting=AquaCrop.undef_int,
        GDDaysToHIo=AquaCrop.undef_int,
        WP=17,
        WPy=100,
        AdaptedToCO2=100,
        HI=50,
        dHIdt=1,
        HIincrease=5,
        aCoeff=10,
        bCoeff=8,
        DHImax=15,
        DeterminancyLinked=true,
        fExcess=50,
        DryMatter=25,
        RootMinYear1=0.29999999999999999,
        SownYear1=true,
        YearCCx=AquaCrop.undef_int,# -9,
        CCxRoot=AquaCrop.undef_double, #-9,
        Assimilates=AquaCrop.RepAssimilates(
            On=false,
            Period=0,
            Stored=0,
            Mobilized=0
        )
    )

    management = AquaCrop.RepManag(
        Mulch=0,
        SoilCoverBefore=0,
        SoilCoverAfter=0,
        EffectMulchOffS=50,
        EffectMulchInS=50,
        FertilityStress=0,
        BundHeight=0,
        RunoffOn=true,
        CNcorrection=0,
        WeedRC=0,
        WeedDeltaRC=0,
        WeedShape=-0.01,
        WeedAdj=100,
        Cuttings=AquaCrop.RepCuttings(
            Considered=false,
            CCcut=30,
            Day1=1,
            NrDays=AquaCrop.undef_int, #0,
            Generate=false,
            Criterion=:NA, #0
            HarvestEnd=false,
            FirstDayNr=AquaCrop.undef_int #0
        )
    )

    sumwabal = AquaCrop.RepSum(
        Epot=0.0,
        Tpot=0.0,
        Rain=0.0,
        Irrigation=0.0,
        Infiltrated=0.0,
        Runoff=0.0,
        Drain=0.0,
        Eact=0.0,
        Tact=0.0,
        TrW=0.0,
        ECropCycle=0.0,
        CRwater=0.0,
        Biomass=0.0,
        YieldPart=0.0,
        BiomassPot=0.0,
        BiomassUnlim=0.0,
        BiomassTot=0.0,
        SaltIn=0.0,
        SaltOut=0.0,
        CRsalt=0.0
    )

    irri_before_season = AquaCrop.RepDayEventInt[
        AquaCrop.RepDayEventInt(
            DayNr=0,
            param=0
        )
        for _ in 1:5
    ]

    irri_after_season = AquaCrop.RepDayEventInt[
        AquaCrop.RepDayEventInt(
            DayNr=0,
            param=0
        )
        for _ in 1:5
    ]

    irri_ecw = AquaCrop.RepIrriECw(
        PreSeason=0.0,
        PostSeason=0.0
    )

    onset = AquaCrop.RepOnset(
        GenerateOn=false,
        GenerateTempOn=false,
        Criterion=:RainPeriod, #1,
        AirTCriterion=:CumulGDD, #3, 
        StartSearchDayNr=1,
        StopSearchDayNr=0,
        LengthSearchPeriod=0
    )

    fileok = AquaCrop.RepFileOK(
        Climate_Filename=true,
        Temperature_Filename=true,
        ETo_Filename=true,
        Rain_Filename=true,
        CO2_Filename=true,
        Calendar_Filename=true,
        Crop_Filename=true,
        Irrigation_Filename=true,
        Management_Filename=true,
        GroundWater_Filename=true,
        Soil_Filename=true,
        SWCIni_Filename=true,
        OffSeason_Filename=true,
        Observations_Filename=true
    )
    projectinput = AquaCrop.ProjectInputType[
        AquaCrop.ProjectInputType(
            ParentDir=pwd()*"/testcase",
            VersionNr=7.1,
            Description="Ottawa (Canada)",
            Simulation_YearSeason=1,
            Simulation_DayNr1=41414,
            Simulation_DayNrN=41577,
            Crop_Day1=41414,
            Crop_DayN=41577,
            Climate_Info="-- 1. Climate (CLI) file",
            Climate_Filename="Ottawa.CLI",
            Climate_Directory="/DATA/",
            Temperature_Info="1.1 Temperature (Tnx or TMP) file",
            Temperature_Filename="Ottawa.Tnx",
            Temperature_Directory="/DATA/",
            ETo_Info="1.2 Reference ET (ETo) file",
            ETo_Filename="Ottawa.ETo",
            ETo_Directory="/DATA/",
            Rain_Info="1.3 Rain (PLU) file",
            Rain_Filename="Ottawa.PLU",
            Rain_Directory="/DATA/",
            CO2_Info="1.4 Atmospheric CO2 concentration (CO2) file",
            CO2_Filename="MaunaLoa.CO2",
            CO2_Directory="/SIMUL/",
            Calendar_Info="-- 2. Calendar (CAL) file",
            Calendar_Filename="21May.CAL",
            Calendar_Directory="/DATA/",
            Crop_Info="-- 3. Crop (CRO) file",
            Crop_Filename="AlfOttawaGDD.CRO",
            Crop_Directory="/DATA/",
            Irrigation_Info="-- 4. Irrigation management (IRR) file",
            Irrigation_Filename="(None)",
            Irrigation_Directory="(None)",
            Management_Info="-- 5. Field management (MAN) file",
            Management_Filename="Ottawa.MAN",
            Management_Directory="/DATA/",
            GroundWater_Info="-- 7. Groundwater table (GWT) file",
            GroundWater_Filename="(None)",
            GroundWater_Directory="(None)",
            Soil_Info="-- 6. Soil profile (SOL) file",
            Soil_Filename="Ottawa.SOL",
            Soil_Directory="/DATA/",
            SWCIni_Info="-- 8. Initial conditions (SW0) file",
            SWCIni_Filename="(None)",
            SWCIni_Directory="(None)",
            OffSeason_Info="-- 9. Off-season conditions (OFF) file",
            OffSeason_Filename="(None)",
            OffSeason_Directory="(None)",
            Observations_Info="-- 10. Field data (OBS) file",
            Observations_Filename="Ottawa.OBS",
            Observations_Directory="/OBS/"
        )
    ]

    return ComponentArray(
        simulparam=simulparam,
        soil=soil,
        soil_layers=soil_layers,
        compartments=compartments,
        simulation=simulation,
        total_water_content=total_water_content,
        crop=crop,
        management=management,
        sumwabal=sumwabal,
        irri_before_season=irri_before_season,
        irri_after_season=irri_after_season,
        irri_ecw=irri_ecw,
        onset=onset,
        fileok=fileok,
        projectinput=projectinput            
    )
end

@testset "Initialize Settings" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    inse = AquaCrop.initialize_settings(true, true, filepaths)

    ini = declare_initial_variables()

    @test isapprox(inse[:simulparam], ini[:simulparam])
    @test isapprox(inse[:soil], ini[:soil])
    @test isapprox(inse[:soil_layers], ini[:soil_layers])
    @test isapprox(inse[:compartments], ini[:compartments])
    @test isapprox(inse[:simulation], ini[:simulation])
    @test isapprox(inse[:total_water_content], ini[:total_water_content])
    @test isapprox(inse[:crop], ini[:crop])
    @test isapprox(inse[:management], ini[:management])
    @test isapprox(inse[:sumwabal], ini[:sumwabal])
    @test isapprox(inse[:irri_before_season], ini[:irri_before_season])
    @test isapprox(inse[:irri_after_season], ini[:irri_after_season])
    @test isapprox(inse[:irri_ecw], ini[:irri_ecw])
    @test isapprox(inse[:onset], ini[:onset])
end



@testset "Initialize Project" begin
    parentdir = pwd()*"/testcase"
    filepaths, results_parameters = AquaCrop.initialize_the_program(parentdir)
    project_filenames = AquaCrop.initialize_project_filename(filepaths)
    i = 1
    theprojectfile = project_filenames[i]
    theprojecttype = AquaCrop.get_project_type(theprojectfile)
    inse, projectinput, fileok = AquaCrop.initialize_project(i, theprojectfile, theprojecttype, filepaths)


    ini = declare_initial_variables()
    ini[:simulation].MultipleRun = true
    ini[:simulation].NrRuns = 3
    ini[:simulation].MultipleRunWithKeepSWC = true
    ini[:simulation].MultipleRunConstZrx = 3
    # this is incorrect in fortran code, they forget to set the temperature in line startuni.f90:864
    # it should be: call SetSimulParam_Tmin(Tmin_temp)
    # ini[:simulparam].Tmin = 0 

    @test isapprox(inse[:simulation], ini[:simulation])
    @test isapprox(inse[:simulparam], ini[:simulparam])
    @test isapprox(fileok, ini[:fileok])
    @test isequal(length(projectinput),3)
    @test isapprox(projectinput[1], ini[:projectinput][1])
end





