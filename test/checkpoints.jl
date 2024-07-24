using AquaCrop 
using ComponentArrays

function checkpoint1()
    # Local variables

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
            Theta=0.29999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
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

    previoussum = AquaCrop.RepSum(
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
            Param=0
        )
        for _ in 1:5
    ]

    irri_after_season = AquaCrop.RepDayEventInt[
        AquaCrop.RepDayEventInt(
            DayNr=0,
            Param=0
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

    rain_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol,
        FromD=AquaCrop.undef_int,
        FromM=AquaCrop.undef_int,
        FromY=AquaCrop.undef_int,
        ToD=AquaCrop.undef_int,
        ToM=AquaCrop.undef_int,
        ToY=AquaCrop.undef_int,
        FromDayNr=AquaCrop.undef_int,
        ToDayNr=AquaCrop.undef_int,
        FromString=AquaCrop.undef_str,
        ToString=AquaCrop.undef_str,
        NrObs=AquaCrop.undef_int
    )

    eto_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol,
        FromD=AquaCrop.undef_int,
        FromM=AquaCrop.undef_int,
        FromY=AquaCrop.undef_int,
        ToD=AquaCrop.undef_int,
        ToM=AquaCrop.undef_int,
        ToY=AquaCrop.undef_int,
        FromDayNr=AquaCrop.undef_int,
        ToDayNr=AquaCrop.undef_int,
        FromString=AquaCrop.undef_str,
        ToString=AquaCrop.undef_str,
        NrObs=AquaCrop.undef_int
    )

    clim_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol,
        FromD=AquaCrop.undef_int,
        FromM=AquaCrop.undef_int,
        FromY=AquaCrop.undef_int,
        ToD=AquaCrop.undef_int,
        ToM=AquaCrop.undef_int,
        ToY=AquaCrop.undef_int,
        FromDayNr=AquaCrop.undef_int,
        ToDayNr=AquaCrop.undef_int,
        FromString=AquaCrop.undef_str,
        ToString=AquaCrop.undef_str,
        NrObs=AquaCrop.undef_int
    )

    temperature_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol,
        FromD=AquaCrop.undef_int,
        FromM=AquaCrop.undef_int,
        FromY=AquaCrop.undef_int,
        ToD=AquaCrop.undef_int,
        ToM=AquaCrop.undef_int,
        ToY=AquaCrop.undef_int,
        FromDayNr=AquaCrop.undef_int,
        ToDayNr=AquaCrop.undef_int,
        FromString=AquaCrop.undef_str,
        ToString=AquaCrop.undef_str,
        NrObs=AquaCrop.undef_int
    )

    perennial_period = AquaCrop.RepPerennialPeriod( 
        GenerateOnset=AquaCrop.undef_bool,
        OnsetCriterion=AquaCrop.undef_symbol,
        OnsetFirstDay=AquaCrop.undef_int,
        OnsetFirstMonth=AquaCrop.undef_int,
        OnsetStartSearchDayNr=AquaCrop.undef_int,
        OnsetStopSearchDayNr=AquaCrop.undef_int,
        OnsetLengthSearchPeriod=AquaCrop.undef_int,
        OnsetThresholdValue=AquaCrop.undef_double,
        OnsetPeriodValue=AquaCrop.undef_int,
        OnsetOccurrence=AquaCrop.undef_int,
        GenerateEnd=AquaCrop.undef_bool,
        EndCriterion=AquaCrop.undef_symbol,
        EndLastDay=AquaCrop.undef_int,
        EndLastMonth=AquaCrop.undef_int,
        ExtraYears=AquaCrop.undef_int,
        EndStartSearchDayNr=AquaCrop.undef_int,
        EndStopSearchDayNr=AquaCrop.undef_int,
        EndLengthSearchPeriod=AquaCrop.undef_int,
        EndThresholdValue=AquaCrop.undef_double,
        EndPeriodValue=AquaCrop.undef_int,
        EndOccurrence=AquaCrop.undef_int,
        GeneratedDayNrOnset=AquaCrop.undef_int,
        GeneratedDayNrEnd=AquaCrop.undef_int
    )

    crop_file_set = AquaCrop.RepCropFileSet(
        DaysFromSenescenceToEnd=AquaCrop.undef_int,
        DaysToHarvest=AquaCrop.undef_int,
        GDDaysFromSenescenceToEnd=AquaCrop.undef_int,
        GDDaysToHarvest=AquaCrop.undef_int
    )

    gwtable = AquaCrop.RepGwTable()
    stresstot = AquaCrop.RepStressTot()
    irri_info_record1 = AquaCrop.RepIrriInfoRecord()
    irri_info_record2 = AquaCrop.RepIrriInfoRecord()
    transfer = AquaCrop.RepTransfer()
    cut_info_record1 = AquaCrop.RepCutInfoRecord()
    cut_info_record2 = AquaCrop.RepCutInfoRecord()
    root_zone_salt = AquaCrop.RepRootZoneSalt()

    float_parameters = AquaCrop.ParametersContainer(Float64)
    AquaCrop.setparameter!(float_parameters, :eto, 5.0)
    AquaCrop.setparameter!(float_parameters, :rain, 0.0)
    AquaCrop.setparameter!(float_parameters, :tmin, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :tmax, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :irrigation, 0.0)
    AquaCrop.setparameter!(float_parameters, :surfacestorage, 0.0)
    AquaCrop.setparameter!(float_parameters, :ecstorage, 0.0)
    AquaCrop.setparameter!(float_parameters, :drain, 0.0)
    AquaCrop.setparameter!(float_parameters, :runoff, 0.0)
    AquaCrop.setparameter!(float_parameters, :infiltrated, 0.0)
    AquaCrop.setparameter!(float_parameters, :crwater, 0.0)
    AquaCrop.setparameter!(float_parameters, :crsalt, 0.0)
    AquaCrop.setparameter!(float_parameters, :eciaqua, AquaCrop.undef_double) #undef_int
    AquaCrop.setparameter!(float_parameters, :sumeto, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumgdd, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :previoussumeto, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :previoussumgdd, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :previousbmob, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :previousbsto, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :ccxwitheredtpotnos, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :co2i, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :fracbiomasspotsf, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb0, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb1, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb2, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb0salt, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb1salt, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :coeffb2salt, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumkctop, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumkctop_stress, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumkci, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :fweednos, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :ccxcrop_weednosf_stress, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :ccxtotal, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :cdctotal, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :gddcdctotal, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :ccototal, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumgddprev, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :gddayi, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :dayfraction, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :gddayfraction, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :cciprev, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :cciactual, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :timesenescence, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :ziprev, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :rooting_depth, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :sumgddcuts, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :bprevsum, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :yprevsum, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :cgcref, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :gddcgcref, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :hi_times_bef, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :hi_times_at1, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :hi_times_at2, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :hi_times_at, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :alfa_hi, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :alfa_hi_adj, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :scor_at1, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :scor_at2, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :stressleaf, AquaCrop.undef_double)
    AquaCrop.setparameter!(float_parameters, :stresssenescence, AquaCrop.undef_double)

    symbol_parameters = AquaCrop.ParametersContainer(Symbol)
    AquaCrop.setparameter!(symbol_parameters, :irrimode, :NoIrri) # 0
    AquaCrop.setparameter!(symbol_parameters, :irrimethod, :MSprinkler) # 4
    AquaCrop.setparameter!(symbol_parameters, :timemode, :AllRAW) # 2
    AquaCrop.setparameter!(symbol_parameters, :depthmode, :ToFC) # 0
    AquaCrop.setparameter!(symbol_parameters, :outputaggregate, AquaCrop.undef_symbol) 
    AquaCrop.setparameter!(symbol_parameters, :theprojecttype, AquaCrop.undef_symbol) 

    integer_parameters = AquaCrop.ParametersContainer(Int)
    AquaCrop.setparameter!(integer_parameters, :iniperctaw, 50)
    AquaCrop.setparameter!(integer_parameters, :daysubmerged, 0)
    AquaCrop.setparameter!(integer_parameters, :maxplotnew, 50)
    AquaCrop.setparameter!(integer_parameters, :maxplottr, 10)
    AquaCrop.setparameter!(integer_parameters, :irri_first_daynr, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :ziaqua, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :nextsim_from_daynr, 0)
    AquaCrop.setparameter!(integer_parameters, :previous_stress_level, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :stress_sf_adj_new, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :daynri, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :irri_interval, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :tadj, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :gddtadj, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :nrcut, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :suminterval, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :daylastcut, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :stagecode, AquaCrop.undef_int)

    bool_parameters = AquaCrop.ParametersContainer(Bool)
    AquaCrop.setparameter!(bool_parameters, :preday, false)
    AquaCrop.setparameter!(bool_parameters, :temperature_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :eto_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :rain_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :evapo_entire_soil_surface, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :startmode, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :noyear, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :global_irri_ecw, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :nomorecrop, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :out1Wabal, false)
    AquaCrop.setparameter!(bool_parameters, :out2Crop, false)
    AquaCrop.setparameter!(bool_parameters, :out3Prof, false)
    AquaCrop.setparameter!(bool_parameters, :out4Salt, false)
    AquaCrop.setparameter!(bool_parameters, :out5CompWC, false)
    AquaCrop.setparameter!(bool_parameters, :out6CompEC, false)
    AquaCrop.setparameter!(bool_parameters, :out7Clim, false)
    AquaCrop.setparameter!(bool_parameters, :outdaily, false)
    AquaCrop.setparameter!(bool_parameters, :part1Mult, false)
    AquaCrop.setparameter!(bool_parameters, :part2Eval, false)

    array_parameters = AquaCrop.ParametersContainer(Vector{Float64})
    AquaCrop.setparameter!(array_parameters, :Tmin, Float64[])
    AquaCrop.setparameter!(array_parameters, :Tmax, Float64[])
    AquaCrop.setparameter!(array_parameters, :ETo, Float64[])
    AquaCrop.setparameter!(array_parameters, :Rain, Float64[])
    AquaCrop.setparameter!(array_parameters, :Man, Float64[])
    AquaCrop.setparameter!(array_parameters, :Man_info, Float64[])

    string_parameters = AquaCrop.ParametersContainer(String)
    AquaCrop.setparameter!(string_parameters, :clim_file, AquaCrop.undef_str)
    AquaCrop.setparameter!(string_parameters, :climate_file,   "(None)")
    AquaCrop.setparameter!(string_parameters, :temperature_file,  "(None)")
    AquaCrop.setparameter!(string_parameters, :eto_file,  "(None)")
    AquaCrop.setparameter!(string_parameters, :rain_file,  "(None)")
    AquaCrop.setparameter!(string_parameters, :groundwater_file, "(None)")
    AquaCrop.setparameter!(string_parameters, :prof_file, "DEFAULT.SOL")
    AquaCrop.setparameter!(string_parameters, :crop_file, "DEFAULT.CRO")
    AquaCrop.setparameter!(string_parameters, :CO2_file, "MaunaLoa.CO2")
    AquaCrop.setparameter!(string_parameters, :man_file, "(None)")
    AquaCrop.setparameter!(string_parameters, :irri_file, "(None)")
    AquaCrop.setparameter!(string_parameters, :offseason_file, "(None)")
    AquaCrop.setparameter!(string_parameters, :swcini_file, AquaCrop.undef_str)


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
        previoussum=previoussum,
        irri_before_season=irri_before_season,
        irri_after_season=irri_after_season,
        irri_ecw=irri_ecw,
        onset=onset,
        rain_record=rain_record,
        eto_record=eto_record,
        clim_record=clim_record,
        temperature_record=temperature_record,
        perennial_period=perennial_period,
        crop_file_set=crop_file_set, 
        gwtable = gwtable,
        stresstot = stresstot,
        irri_info_record1 = irri_info_record1,
        irri_info_record2 = irri_info_record2,
        transfer = transfer,
        cut_info_record1 = cut_info_record1,
        cut_info_record2 = cut_info_record2,
        root_zone_salt = root_zone_salt,
        float_parameters = float_parameters,
        symbol_parameters = symbol_parameters,
        integer_parameters = integer_parameters,
        bool_parameters = bool_parameters,
        array_parameters = array_parameters,
        string_parameters = string_parameters,
    )
end

function checkpoint2()
    gvars = checkpoint1()    

    gvars[:simulation].MultipleRun = true
    gvars[:simulation].NrRuns = 3
    gvars[:simulation].MultipleRunWithKeepSWC = true
    gvars[:simulation].MultipleRunConstZrx = 3
    # OJO this is incorrect in fortran code, they forget to set the temperature in line startuni.f90:864
    # it should be: call SetSimulParam_Tmin(Tmin_temp)
    # gvars[:simulparam].Tmin = 0 
    
    AquaCrop.setparameter!(gvars[:symbol_parameters], :outputaggregate, :none)
    AquaCrop.setparameter!(gvars[:symbol_parameters], :theprojecttype, :typeprm)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out1Wabal, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out2Crop, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out3Prof, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out4Salt, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out5CompWC, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out6CompEC, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :out7Clim, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :outdaily, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :part1Mult, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :part2Eval, true)

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
            Climate_Directory="DATA",
            Temperature_Info="1.1 Temperature (Tnx or TMP) file",
            Temperature_Filename="Ottawa.Tnx",
            Temperature_Directory="DATA",
            ETo_Info="1.2 Reference ET (ETo) file",
            ETo_Filename="Ottawa.ETo",
            ETo_Directory="DATA",
            Rain_Info="1.3 Rain (PLU) file",
            Rain_Filename="Ottawa.PLU",
            Rain_Directory="DATA",
            CO2_Info="1.4 Atmospheric CO2 concentration (CO2) file",
            CO2_Filename="MaunaLoa.CO2",
            CO2_Directory="SIMUL",
            Calendar_Info="-- 2. Calendar (CAL) file",
            Calendar_Filename="21May.CAL",
            Calendar_Directory="DATA",
            Crop_Info="-- 3. Crop (CRO) file",
            Crop_Filename="AlfOttawaGDD.CRO",
            Crop_Directory="DATA",
            Irrigation_Info="-- 4. Irrigation management (IRR) file",
            Irrigation_Filename="(None)",
            Irrigation_Directory="(None)",
            Management_Info="-- 5. Field management (MAN) file",
            Management_Filename="Ottawa.MAN",
            Management_Directory="DATA",
            GroundWater_Info="-- 7. Groundwater table (GWT) file",
            GroundWater_Filename="(None)",
            GroundWater_Directory="(None)",
            Soil_Info="-- 6. Soil profile (SOL) file",
            Soil_Filename="Ottawa.SOL",
            Soil_Directory="DATA",
            SWCIni_Info="-- 8. Initial conditions (SW0) file",
            SWCIni_Filename="(None)",
            SWCIni_Directory="(None)",
            OffSeason_Info="-- 9. Off-season conditions (OFF) file",
            OffSeason_Filename="(None)",
            OffSeason_Directory="(None)",
            Observations_Info="-- 10. Field data (OBS) file",
            Observations_Filename="Ottawa.OBS",
            Observations_Directory="OBS"
        ),

        AquaCrop.ProjectInputType(
            ParentDir=pwd()*"/testcase",
            VersionNr=7.1,
            Description="Ottawa (Canada)",
            Simulation_YearSeason=2,
            Simulation_DayNr1=41578,
            Simulation_DayNrN=41935,
            Crop_Day1=41759,
            Crop_DayN=41935,
            Climate_Info="-- 1. Climate (CLI) file",
            Climate_Filename="Ottawa.CLI",
            Climate_Directory="DATA",
            Temperature_Info="1.1 Temperature (Tnx or TMP) file",
            Temperature_Filename="Ottawa.Tnx",
            Temperature_Directory="DATA",
            ETo_Info="1.2 Reference ET (ETo) file",
            ETo_Filename="Ottawa.ETo",
            ETo_Directory="DATA",
            Rain_Info="1.3 Rain (PLU) file",
            Rain_Filename="Ottawa.PLU",
            Rain_Directory="DATA",
            CO2_Info="1.4 Atmospheric CO2 concentration (CO2) file",
            CO2_Filename="MaunaLoa.CO2",
            CO2_Directory="SIMUL",
            Calendar_Info="-- 2. Calendar (CAL) file",
            Calendar_Filename="21May.CAL",
            Calendar_Directory="DATA",
            Crop_Info="-- 3. Crop (CRO) file",
            Crop_Filename="AlfOttawaGDD.CRO",
            Crop_Directory="DATA",
            Irrigation_Info="-- 4. Irrigation management (IRR) file",
            Irrigation_Filename="(None)",
            Irrigation_Directory="(None)",
            Management_Info="-- 5. Field management (MAN) file",
            Management_Filename="Ottawa.MAN",
            Management_Directory="DATA",
            GroundWater_Info="-- 7. Groundwater table (GWT) file",
            GroundWater_Filename="(None)",
            GroundWater_Directory="(None)",
            Soil_Info="-- 6. Soil profile (SOL) file",
            Soil_Filename="Ottawa.SOL",
            Soil_Directory="DATA",
            SWCIni_Info="-- 8. Initial conditions (SW0) file",
            SWCIni_Filename="KeepSWC",
            SWCIni_Directory="Keep soil water profile of previous run",
            OffSeason_Info="-- 9. Off-season conditions (OFF) file",
            OffSeason_Filename="(None)",
            OffSeason_Directory="(None)",
            Observations_Info="-- 10. Field data (OBS) file",
            Observations_Filename="Ottawa.OBS",
            Observations_Directory="OBS"
        ),

        AquaCrop.ProjectInputType(
            ParentDir=pwd()*"/testcase",
            VersionNr=7.1,
            Description="Ottawa (Canada)",
            Simulation_YearSeason=3,
            Simulation_DayNr1=41936,
            Simulation_DayNrN=42305,
            Crop_Day1=42131,
            Crop_DayN=42305,
            Climate_Info="-- 1. Climate (CLI) file",
            Climate_Filename="Ottawa.CLI",
            Climate_Directory="DATA",
            Temperature_Info="1.1 Temperature (Tnx or TMP) file",
            Temperature_Filename="Ottawa.Tnx",
            Temperature_Directory="DATA",
            ETo_Info="1.2 Reference ET (ETo) file",
            ETo_Filename="Ottawa.ETo",
            ETo_Directory="DATA",
            Rain_Info="1.3 Rain (PLU) file",
            Rain_Filename="Ottawa.PLU",
            Rain_Directory="DATA",
            CO2_Info="1.4 Atmospheric CO2 concentration (CO2) file",
            CO2_Filename="MaunaLoa.CO2",
            CO2_Directory="SIMUL",
            Calendar_Info="-- 2. Calendar (CAL) file",
            Calendar_Filename="21May.CAL",
            Calendar_Directory="DATA",
            Crop_Info="-- 3. Crop (CRO) file",
            Crop_Filename="AlfOttawaGDD.CRO",
            Crop_Directory="DATA",
            Irrigation_Info="-- 4. Irrigation management (IRR) file",
            Irrigation_Filename="(None)",
            Irrigation_Directory="(None)",
            Management_Info="-- 5. Field management (MAN) file",
            Management_Filename="Ottawa.MAN",
            Management_Directory="DATA",
            GroundWater_Info="-- 7. Groundwater table (GWT) file",
            GroundWater_Filename="(None)",
            GroundWater_Directory="(None)",
            Soil_Info="-- 6. Soil profile (SOL) file",
            Soil_Filename="Ottawa.SOL",
            Soil_Directory="DATA",
            SWCIni_Info="-- 8. Initial conditions (SW0) file",
            SWCIni_Filename="KeepSWC",
            SWCIni_Directory="Keep soil water profile of previous run",
            OffSeason_Info="-- 9. Off-season conditions (OFF) file",
            OffSeason_Filename="(None)",
            OffSeason_Directory="(None)",
            Observations_Info="-- 10. Field data (OBS) file",
            Observations_Filename="Ottawa.OBS",
            Observations_Directory="OBS"
        )
    ]

    return gvars, projectinput, fileok
end

function checkpoint3()
    gvars, projectinput, fileok = checkpoint2()

    gvars[:soil].REW = 7
    gvars[:soil].CNValue = 46
    gvars[:soil].RootMax = 3


    soil_layers = AquaCrop.SoilLayerIndividual[
        AquaCrop.SoilLayerIndividual(
            Description="sandy",
            Thickness=3.0000000447034836,
            SAT=46,
            FC=29,
            WP=13,
            tau=1,
            InfRate=1200,
            Penetrability=100,
            GravelMass=0,
            GravelVol=0,
            WaterContent=870.00001296401012,
            Macro=29,
            #OJO note that the last two positions of "1" are set to undef since they seem to be a byproduct from default loading, key variable seems to be SCP1 as length of actuall stuff
            SaltMobility=[0.99999999999999989, 1, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double], # [1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
            SC=1,
            SCP1=2,
            UL=0.15333333333333332,
            Dx=0.15333333333333332,
            SoilClass=2,
            CRa=-0.3906,
            CRb=1.2556389999999999
        )
    ]
    gvars[:soil_layers] = soil_layers


    compartments = AquaCrop.CompartmentIndividual[
        AquaCrop.CompartmentIndividual(
            Thickness=0.10000000149011612,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15000000223517418,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15000000223517418,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.20000000298023224,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.20000000298023224,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.30000000447034836,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.30000000447034836,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.35000000521540642,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.35000000521540642,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.40000000596046448,
            Theta=0.28999999999999999,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=29,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        )
    ]
    gvars[:compartments] = compartments


    gvars[:simulation].FromDayNr = 41414
    gvars[:simulation].ToDayNr = 41577
    gvars[:simulation].IniSWC.Loc[1] = 3.0000000447034836
    gvars[:simulation].IniSWC.VolProc[1] = 29
    gvars[:simulation].ThetaIni = [0.29 for _ in 1:12]
    gvars[:simulation].EffectStress.RedCGC = 24
    gvars[:simulation].EffectStress.RedCCX = 40
    gvars[:simulation].EffectStress.RedWP = 52
    gvars[:simulation].EffectStress.CDecline = 0.04188660705779268


    gvars[:total_water_content].BeginDay = 870.00001296401012


    crop = AquaCrop.RepCrop(
        subkind=:Forage, #3,
        ModeCycle=:GDDays, #0,
        Planting=:Seed, #0,
        pMethod=:FAOCorrection, #1,
        pdef=0.60,
        pActStom=AquaCrop.undef_double, #0,
        KsShapeFactorLeaf=3,
        KsShapeFactorStomata=3,
        KsShapeFactorSenescence=3,
        pLeafDefUL=0.15,
        pLeafDefLL=0.55,
        pLeafAct=AquaCrop.undef_double, #0,
        pSenescence=0.70,
        pSenAct=AquaCrop.undef_double, #0,
        pPollination=0.90000000000000002,
        SumEToDelaySenescence=600,
        AnaeroPoint=2,
        StressResponse=AquaCrop.RepShapes(
            Stress=50,
            ShapeCGC=2.35,
            ShapeCCX=0.79000000000000004,
            ShapeWP=-0.16,
            ShapeCDecline=6.26,
            Calibrated=true
        ),
        ECemin=2,
        ECemax=16,
        CCsaltDistortion=25,
        ResponseECsw=100,
        SmaxTopQuarter=0.02,
        SmaxBotQuarter=0.01,
        SmaxTop=0.02166666666666, 
        SmaxBot=0.008333333333, 
        KcTop=1.15,
        KcDecline=0.05,
        CCEffectEvapLate=60,
        Day1=41414,
        DayN=41577,
        Length=[6, 33, 125, 0],
        RootMin=0.29999999999999999,
        RootMax=3,
        RootShape=15,
        Tbase=5,
        Tupper=30,
        Tcold=8,
        Theat=40,
        GDtranspLow=8,
        SizeSeedling=2.5,
        SizePlant=19.38,
        PlantingDens=2000000,
        CCo=0.05,
        CCini=0.3876,
        CGC=0.14184615384615384,
        GDDCGC=0.012,
        CCx=0.95,
        CDC=0.0027272727272727696,
        GDDCDC=0.006,
        CCxAdjusted=0.95,
        CCxWithered=0.95,
        CCoAdjusted=0.05,
        DaysToCCini=0,
        DaysToGermination=1,
        DaysToFullCanopy=39,
        DaysToFullCanopySF=47,
        DaysToFlowering=0,
        LengthFlowering=0,
        DaysToSenescence=164,
        DaysToHarvest=164,
        DaysToMaxRooting=351,
        DaysToHIo=12,
        GDDaysToCCini=0,
        GDDaysToGermination=5,
        GDDaysToFullCanopy=461,
        GDDaysToFullCanopySF=AquaCrop.undef_int,
        GDDaysToFlowering=0,
        GDDLengthFlowering=0,
        GDDaysToSenescence=1803,
        GDDaysToHarvest=1803,
        GDDaysToMaxRooting=1920,
        GDDaysToHIo=118,
        WP=15,
        WPy=100,
        AdaptedToCO2=50,
        HI=100,
        dHIdt=8.33333333333,
        HIincrease=AquaCrop.undef_int,
        aCoeff=AquaCrop.undef_int,
        bCoeff=AquaCrop.undef_int,
        DHImax=AquaCrop.undef_int,
        DeterminancyLinked=false,
        fExcess=AquaCrop.undef_int,
        DryMatter=20,
        RootMinYear1=0.29999999999999999,
        SownYear1=true,
        YearCCx=9,# -9,
        CCxRoot=0.5, #-9,
        Assimilates=AquaCrop.RepAssimilates(
            On=true,
            Period=100,
            Stored=65,
            Mobilized=60
        )
    )
    gvars[:crop] = crop

    
    gvars[:management].FertilityStress = 50
    gvars[:management].WeedShape = 100
    gvars[:management].Cuttings.Considered = true
    gvars[:management].Cuttings.CCcut = 25
    gvars[:management].Cuttings.FirstDayNr = 41274

    gvars[:onset].StartSearchDayNr = 41274
    gvars[:onset].StopSearchDayNr = 41273


    rain_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=2014,
        ToD=31,
        ToM=12,
        ToY=2016,
        FromDayNr=41274,
        ToDayNr=42369,
        FromString="",
        ToString="",
        NrObs=1096
    )
    gvars[:rain_record] = rain_record


    eto_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=2014,
        ToD=31,
        ToM=12,
        ToY=2016,
        FromDayNr=41274,
        ToDayNr=42369,
        FromString="",
        ToString="",
        NrObs=1096
    )
    gvars[:eto_record] = eto_record


    clim_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol, #0 note that this is 0 from undefined and not from actuall setting it
        FromD=1,
        FromM=1,
        FromY=2014,
        ToD=31,
        ToM=12,
        ToY=2016,
        FromDayNr=41274,
        ToDayNr=42369,
        FromString="",
        ToString="",
        NrObs=1096
    )
    gvars[:clim_record] = clim_record


    temperature_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=2014,
        ToD=31,
        ToM=12,
        ToY=2016,
        FromDayNr=41274,
        ToDayNr=42369,
        FromString="",
        ToString="",
        NrObs=1096
    )
    gvars[:temperature_record] = temperature_record


    perennial_period = AquaCrop.RepPerennialPeriod( 
        GenerateOnset=true,
        OnsetCriterion=:GDDPeriod, #2
        OnsetFirstDay=1,
        OnsetFirstMonth=4,
        OnsetStartSearchDayNr=AquaCrop.undef_int, #0,
        OnsetStopSearchDayNr=AquaCrop.undef_int, #0,
        OnsetLengthSearchPeriod=120,
        OnsetThresholdValue=20,
        OnsetPeriodValue=8,
        OnsetOccurrence=2,
        GenerateEnd=true,
        EndCriterion=:GDDPeriod, #2,
        EndLastDay=31,
        EndLastMonth=10,
        ExtraYears=0,
        EndStartSearchDayNr=AquaCrop.undef_int, #0,
        EndStopSearchDayNr=AquaCrop.undef_int, #0,
        EndLengthSearchPeriod=60,
        EndThresholdValue=10,
        EndPeriodValue=8,
        EndOccurrence=1,
        GeneratedDayNrOnset=AquaCrop.undef_int, #0,
        GeneratedDayNrEnd=AquaCrop.undef_int, #0
    )
    gvars[:perennial_period] = perennial_period


    crop_file_set = AquaCrop.RepCropFileSet(
        DaysFromSenescenceToEnd=0,
        DaysToHarvest=180,
        GDDaysFromSenescenceToEnd=0,
        GDDaysToHarvest=1920
    )
    gvars[:crop_file_set] = crop_file_set


    AquaCrop.setparameter!(gvars[:bool_parameters], :temperature_file_exists, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :eto_file_exists, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :rain_file_exists, true) 

    return gvars, projectinput
end

function checkpoint4()
    gvars, projectinput = checkpoint3()
    outputs = AquaCrop.start_outputs()

    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapWCsurf = 0
    gvars[:simulation].SalinityConsidered = true
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].RCadj = 0

    gvars[:crop].pActStom = 0.6
    gvars[:crop].pSenAct = 0.7
    gvars[:crop].pLeafAct = 0.15
    gvars[:crop].GDDaysToFullCanopySF = 590

    gvars[:gwtable] = AquaCrop.RepGwTable()

    gvars[:stresstot].NrD = AquaCrop.undef_int
    gvars[:stresstot].Salt = 0
    gvars[:stresstot].Temp = 0
    gvars[:stresstot].Exp = 0
    gvars[:stresstot].Sto = 0
    gvars[:stresstot].Weed = 0

    AquaCrop.setparameter!(gvars[:integer_parameters], :nextsim_from_daynr, AquaCrop.undef_int)
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 50)
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 50)
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41414)

    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, false)
    AquaCrop.setparameter!(gvars[:bool_parameters], :noyear, false)

    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumeto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumgdd, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbmob, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbsto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :co2i, 398.81)
    AquaCrop.setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 0.50819993030339949)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0, 86.318499948012658)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1, -0.56684310202237487)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2, -0.0029082706116472321)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0salt, 0.70209879230240801)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1salt, 0.33362709367525073)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2salt, 0.0054910290873667863)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop, 144.33651012061804)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 73.351804383534002)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :fweednos, 1.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, 0.95)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxtotal, 0.95)
    AquaCrop.setparameter!(gvars[:float_parameters], :cdctotal, 0.0027272727272727696)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcdctotal, 0.006)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccototal, 0.05)

    open(pwd()*"/testcase/OUTPUTS/TCropsim_1") do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tcropsim!(outputs, tlow, thigh)
        end
    end

    return outputs, gvars, projectinput
end


