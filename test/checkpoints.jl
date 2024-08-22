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
    root_zone_wc = AquaCrop.RepRootZoneWC()
    plotvarcrop = AquaCrop.RepPlotPar()
    total_salt_content = AquaCrop.RepContent()

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
    AquaCrop.setparameter!(float_parameters, :tact, 0.0) 
    AquaCrop.setparameter!(float_parameters, :tpot, 0.0) 
    AquaCrop.setparameter!(float_parameters, :bin, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :bout, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :surf0, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :ecdrain, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :eact, 0.0) 
    AquaCrop.setparameter!(float_parameters, :epot, 0.0) 
    AquaCrop.setparameter!(float_parameters, :tactweedinfested, 0.0) 
    AquaCrop.setparameter!(float_parameters, :saltinfiltr, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :ccitopearlysen, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :weedrci, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :cciactualweedinfested, AquaCrop.undef_double) 
    AquaCrop.setparameter!(float_parameters, :zeval, AquaCrop.undef_double) 

    symbol_parameters = AquaCrop.ParametersContainer(Symbol)
    AquaCrop.setparameter!(symbol_parameters, :irrimode, :NoIrri) # 0
    AquaCrop.setparameter!(symbol_parameters, :irrimethod, :MSprinkler) # 4
    AquaCrop.setparameter!(symbol_parameters, :timemode, :AllRAW) # 2
    AquaCrop.setparameter!(symbol_parameters, :depthmode, :ToFC) # 0
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
    AquaCrop.setparameter!(integer_parameters, :previoussdaynr, AquaCrop.undef_int)
    AquaCrop.setparameter!(integer_parameters, :outputaggregate, AquaCrop.undef_int) 

    bool_parameters = AquaCrop.ParametersContainer(Bool)
    AquaCrop.setparameter!(bool_parameters, :preday, false)
    AquaCrop.setparameter!(bool_parameters, :temperature_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :eto_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :rain_file_exists, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :evapo_entire_soil_surface, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :startmode, AquaCrop.undef_bool)
    AquaCrop.setparameter!(bool_parameters, :noyear, AquaCrop.undef_bool)
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
    AquaCrop.setparameter!(array_parameters, :Irri_1, Float64[])
    AquaCrop.setparameter!(array_parameters, :Irri_2, Float64[])
    AquaCrop.setparameter!(array_parameters, :Irri_3, Float64[])
    AquaCrop.setparameter!(array_parameters, :Irri_4, Float64[])
    AquaCrop.setparameter!(array_parameters, :DaynrEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :CCmeanEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :CCstdEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :BmeanEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :BstdEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :SWCmeanEval, Float64[])
    AquaCrop.setparameter!(array_parameters, :SWCstdEval, Float64[])

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
    AquaCrop.setparameter!(string_parameters, :observations_file, "(None)")
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
        root_zone_wc = root_zone_wc,
        plotvarcrop = plotvarcrop,
        total_salt_content = total_salt_content,
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
    
    AquaCrop.setparameter!(gvars[:integer_parameters], :outputaggregate, 0)

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
    AquaCrop.setparameter!(gvars[:bool_parameters], :part2Eval, true)

    AquaCrop.setparameter!(gvars[:string_parameters], :man_file, 
            joinpath(pwd(), "testcase/DATA/Ottawa.MAN"))
    AquaCrop.setparameter!(gvars[:string_parameters], :observations_file, 
            joinpath(pwd(), "testcase/OBS/Ottawa.OBS"))
    AquaCrop.setparameter!(gvars[:string_parameters], :rain_file, 
            joinpath(pwd(), "testcase/DATA/Ottawa.PLU"))
    AquaCrop.setparameter!(gvars[:string_parameters], :temperature_file, 
            joinpath(pwd(), "testcase/DATA/Ottawa.Tnx"))
    AquaCrop.setparameter!(gvars[:string_parameters], :eto_file, 
            joinpath(pwd(), "testcase/DATA/Ottawa.ETo"))
    AquaCrop.setparameter!(gvars[:string_parameters], :prof_file, 
            joinpath(pwd(), "testcase/DATA/Ottawa.SOL"))
    AquaCrop.setparameter!(gvars[:string_parameters], :CO2_file, 
            joinpath(pwd(), "testcase/SIMUL/MaunaLoa.CO2"))
    AquaCrop.setparameter!(gvars[:string_parameters], :clim_file,  "EToRainTempFile")
    AquaCrop.setparameter!(gvars[:string_parameters], :swcini_file,  "(None)")

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


    Tmin = Float64[]
    Tmax = Float64[]
    open(joinpath(pwd(), "testcase/DATA/Ottawa.Tnx")) do file
        for _ in 1:8
            readline(file)
        end
        for line in eachline(file)
            splitedline = split(line)
            tmin = parse(Float64,popfirst!(splitedline))
            tmax = parse(Float64,popfirst!(splitedline))
            push!(Tmin, tmin)
            push!(Tmax, tmax)
        end
    end
    AquaCrop.setparameter!(gvars[:array_parameters], :Tmin, Tmin)
    AquaCrop.setparameter!(gvars[:array_parameters], :Tmax, Tmax)

    ETo = Float64[]
    open(joinpath(pwd(), "testcase/DATA/Ottawa.ETo")) do file
        for _ in 1:8
            readline(file)
        end
        for line in eachline(file)
            eto = parse(Float64, line)
            push!(ETo, eto)
        end
    end
    AquaCrop.setparameter!(gvars[:array_parameters], :ETo, ETo)

    Rain = Float64[]
    open(joinpath(pwd(), "testcase/DATA/Ottawa.PLU")) do file
        for _ in 1:8
            readline(file)
        end
        for line in eachline(file)
            rain = parse(Float64, line)
            push!(Rain, rain)
        end
    end
    AquaCrop.setparameter!(gvars[:array_parameters], :Rain, Rain)
    
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

    open(joinpath(pwd(), "testcase/OUTPUTS/TCropsim_1")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tcropsim!(outputs, tlow, thigh)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/EToDatasim_1")) do file
        for line in eachline(file)
            eto = parse(Float64, line)
            AquaCrop.add_output_in_etodatasim!(outputs, eto)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/RainDatasim_1")) do file
        for line in eachline(file)
            rain = parse(Float64, line)
            AquaCrop.add_output_in_raindatasim!(outputs, rain)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/TempDatasim_1")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tempdatasim!(outputs, tlow, thigh)
        end
    end

    return outputs, gvars, projectinput
end

function checkpoint5()
    outputs, gvars, projectinput = checkpoint4()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 3.9)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 0.1)
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 10.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 22.7)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 11.35) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :dayfraction, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayfraction, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 0.3) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cgcref, 0.14184615384615384) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcgcref, 0.012) 
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_bef, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at1, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at2, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi_adj, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at1, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at2, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :zeval, 1.0) 

    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 1) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :tadj, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :gddtadj, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 1) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :global_irri_ecw, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :nomorecrop, false) 

    gvars[:simulation].SumGDD = 11.35
    gvars[:simulation].SumGDDfromDay1 = 11.35
    gvars[:simulation].Storage.Btotal = 0 
    gvars[:simulation].Storage.Season = 1 
    gvars[:simulation].Storage.CropString = "DEFAULT.CRO" 
    gvars[:simulation].SCor = 1 
    gvars[:simulation].HIfinal = 100

    gvars[:crop].CCxAdjusted = 0.95
    gvars[:crop].CCoAdjusted = 0.05
    gvars[:crop].CCxWithered = 0

    gvars[:stresstot].Salt = 0

    gvars[:cut_info_record1].NoMoreInfo = false
    gvars[:cut_info_record1].FromDay = 194
    gvars[:cut_info_record1].MassInfo = 0 
    gvars[:cut_info_record1].IntervalInfo = 0 

    gvars[:cut_info_record2].NoMoreInfo = false
    gvars[:cut_info_record2].MassInfo = 0 
    gvars[:cut_info_record2].IntervalInfo = 0 

    gvars[:root_zone_salt].KsSalt = 1
    gvars[:root_zone_salt].ECe = 0
    gvars[:root_zone_salt].ECsw = 0
    gvars[:root_zone_salt].ECswFC = 0

    #Man
    Man = Float64[]
    open(joinpath(pwd(), "testcase/DATA/Ottawa.MAN")) do file
        for _ in 1:24
            readline(file)
        end
        for line in eachline(file)
            man = parse(Float64, line)
            push!(Man,  man)
        end
    end
    popfirst!(Man) # done in open_harvest_info -> get_next_harvest 
    AquaCrop.setparameter!(gvars[:array_parameters], :Man, Man)

    #Obs
    DaynrEval = Float64[]
    CCmeanEval = Float64[]
    CCstdEval = Float64[]
    BmeanEval = Float64[]
    BstdEval = Float64[]
    SWCmeanEval = Float64[]
    SWCstdEval = Float64[]
    # open input file with field data
    observations_file = joinpath(pwd(), "testcase/OBS/Ottawa.OBS")
    open(observations_file, "r") do file
        readline(file)
        readline(file)
        zeval = parse(Float64, strip(readline(file))[1:6])
        dayi = parse(Int, strip(readline(file))[1:6])
        monthi = parse(Int, strip(readline(file))[1:6])
        yeari = parse(Int, strip(readline(file))[1:6])
        readline(file)
        readline(file)
        readline(file)
        readline(file)
        daynr1evaleval = AquaCrop.determine_day_nr(dayi, monthi, yeari)
        for line in eachline(file)
            splitedline = split(line)
            daynreval = parse(Int, popfirst!(splitedline))
            daynreval += daynr1evaleval - 1  
            if daynreval >= gvars[:simulation].FromDayNr
                push!(DaynrEval, daynreval)
                push!(CCmeanEval, parse(Float64, popfirst!(splitedline)))
                push!(CCstdEval, parse(Float64, popfirst!(splitedline)))
                push!(BmeanEval, parse(Float64, popfirst!(splitedline)))
                push!(BstdEval, parse(Float64, popfirst!(splitedline)))
                push!(SWCmeanEval, parse(Float64, popfirst!(splitedline)))
                push!(SWCstdEval, parse(Float64, popfirst!(splitedline)))
            end
        end
    end

    AquaCrop.setparameter!(gvars[:array_parameters], :DaynrEval, DaynrEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :CCmeanEval, CCmeanEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :CCstdEval, CCstdEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :BmeanEval, BmeanEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :BstdEval, BstdEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :SWCmeanEval, SWCmeanEval)
    AquaCrop.setparameter!(gvars[:array_parameters], :SWCstdEval, SWCstdEval)

    return outputs, gvars, projectinput
end

function checkpoint6()
    # break run.f90:7772

    outputs, gvars, projectinput = checkpoint5()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 3.9)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 0.1)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 0.3)
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 0.40011921792801869)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 0.1)
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.053958919412640277)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.053958919412640277)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.40011921792801869)
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 3.9041363452133968)
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 3.2087533516688618) 
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.053958919412640277) 
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.053958919412640277) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.40011921792801869) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 11.35)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 3.9)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 11.35)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 11.35)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 0.10259467126359453) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 72.168255060309022)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 10.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 22.7) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 11.35) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, 0.3) 

    AquaCrop.setparameter!(gvars[:integer_parameters], :ziaqua, AquaCrop.undef_int) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daysubmerged, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 1) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41413) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41415) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 50) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 50) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true) 

    gvars[:crop].DaysToFullCanopySF = 39
    gvars[:crop].GDDaysToFullCanopySF = 461
    gvars[:crop].pLeafAct = 0.19122870872845182
    gvars[:crop].pSenAct = 0.72500087585894779
    gvars[:crop].CCxAdjusted = 0.053958919412640277
    gvars[:crop].CCoAdjusted = 0.05
    gvars[:crop].CCxWithered = 0.053958919412640277
    gvars[:crop].pActStom = 0.6291613445939892
    
    gvars[:simulation].IrriECw = 0
    gvars[:simulation].EffectStress.RedCGC = 0
    gvars[:simulation].EffectStress.RedCCX = 0
    gvars[:simulation].EffectStress.RedWP = 0
    gvars[:simulation].EffectStress.CDecline = 0
    gvars[:simulation].EffectStress.RedKsSto = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SWCtopSoilConsidered = false
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumGDD = 11.35
    gvars[:simulation].SumGDDfromDay1 = 11.35 
    gvars[:simulation].Germinate = true
    gvars[:simulation].ProtectedSeedling = true 
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapStartStg2 = 22
    gvars[:simulation].DayAnaero = 0
    gvars[:simulation].HIfinal = 100
    gvars[:simulation].Storage.Btotal = 0.0 
    
    
    gvars[:soil_layers][1].WaterContent = 990.07975803387228


    gvars[:compartments][1].Theta = 0.25491127482689369
    gvars[:compartments][1].Fluxout = 0 
    gvars[:compartments][1].Smax = 0.019444444411330752
    gvars[:compartments][1].WFactor = 1 
    gvars[:compartments][2].Fluxout = 0 
    gvars[:compartments][2].Smax =  0.013888888772990968 
    gvars[:compartments][2].WFactor = 1 
    gvars[:compartments][3].Fluxout = 0 
    gvars[:compartments][3].Smax = 0.0094444443616602154
    gvars[:compartments][3].WFactor = 0.33333330353101132
    for i in 4:length(gvars[:compartments])
        gvars[:compartments][i].Fluxout = 0 
        gvars[:compartments][i].Smax = 0
    end


    gvars[:total_water_content].BeginDay = 870.00001296401024
    gvars[:total_water_content].EndDay = 866.49114039441338
    gvars[:total_water_content].ErrorDay = 0 


    gvars[:total_salt_content].BeginDay = 0 
    gvars[:total_salt_content].EndDay = 0 
    gvars[:total_salt_content].ErrorDay = 0 


    gvars[:stresstot].NrD = 1


    gvars[:sumwabal].Epot = 3.9041363452133968
    gvars[:sumwabal].Tpot = 0.40011921792801869
    gvars[:sumwabal].Rain = 0.10000000000000001 
    gvars[:sumwabal].Infiltrated = 0.10000000000000001
    gvars[:sumwabal].Eact = 3.2087533516688618
    gvars[:sumwabal].Tact = 0.40011921792801869
    gvars[:sumwabal].ECropCycle = 3.2087533516688618
    gvars[:sumwabal].Biomass = 0.016506432342811034
    gvars[:sumwabal].BiomassPot = 0.0083885677661743475
    gvars[:sumwabal].BiomassUnlim = 0.016506432342811034
    gvars[:sumwabal].BiomassTot = 0.016506432342811034

    
    gvars[:root_zone_wc].Actual = 83.491127430403097
    gvars[:root_zone_wc].FC = 87
    gvars[:root_zone_wc].WP = 39
    gvars[:root_zone_wc].SAT = 138
    gvars[:root_zone_wc].Leaf = 77.821021981034306
    gvars[:root_zone_wc].Thresh = 56.800255459488511
    gvars[:root_zone_wc].Sen = 52.199957958770504
    gvars[:root_zone_wc].ZtopAct = 25.491127482689368
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 18.933418486496173 


    gvars[:plotvarcrop].PotVal = 5.6798862539621338
    gvars[:plotvarcrop].ActVal = 5.6798862539621346

    return outputs, gvars, projectinput
end

function checkpoint7()
    # break run.f90:7772

    outputs, gvars, projectinput = checkpoint5()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 1.9)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 17.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double) #-9
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 0.95924771352550575)
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 1.4608760574252797)
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 1.1834135711751885)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 1.2407825046611656) 
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 16.216586428824812) 
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.42414769943608926) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.42414769943608926) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double) #0
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 1.2407825046611656)
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.8934244530339831) 
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.8934244530339831) 
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.76087529682528598) 
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.42414769943608926) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 1.2407825046611656) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 269.35000000000002) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 77.199999999999989)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 269.35000000000002)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 269.35000000000002)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 100.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 7.7977256854929413) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 72.168255060309022)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 15.1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 21.7) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 13.4) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, 0.95924771352550575) 

    AquaCrop.setparameter!(gvars[:integer_parameters], :ziaqua, AquaCrop.undef_int)  #-9
    AquaCrop.setparameter!(gvars[:integer_parameters], :daysubmerged, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 24) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 25) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41413) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41438) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 50) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 50) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true) 

    gvars[:crop].DaysToFullCanopySF = 47 
    gvars[:crop].GDDaysToFullCanopySF = 590 
    gvars[:crop].pLeafAct = 0.26618999732563697
    gvars[:crop].pSenAct = 0.77045701378430731 
    gvars[:crop].CCxAdjusted = 0.42414769943608926 
    gvars[:crop].CCoAdjusted = 0.05
    gvars[:crop].CCxWithered = 0.42414769943608926 
    gvars[:crop].pActStom = 0.6821819711285152 
    
    gvars[:simulation].IrriECw = 0
    gvars[:simulation].EffectStress.RedCGC = 24
    gvars[:simulation].EffectStress.RedCCX = 40
    gvars[:simulation].EffectStress.RedWP = 52
    gvars[:simulation].EffectStress.CDecline = 0.04188660705779268 
    gvars[:simulation].EffectStress.RedKsSto = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SWCtopSoilConsidered = true 
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumGDD = 269.35000000000002
    gvars[:simulation].SumGDDfromDay1 = 269.35000000000002 
    gvars[:simulation].Germinate = true
    gvars[:simulation].ProtectedSeedling = false 
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapStartStg2 = AquaCrop.undef_int
    gvars[:simulation].DayAnaero = 0
    gvars[:simulation].HIfinal = 100
    gvars[:simulation].Storage.Btotal = 0.0 
    gvars[:simulation].EvapWCsurf = 6.1065755469660168

    
    
    gvars[:soil_layers][1].WaterContent = 1113.4967169948866



    gvars[:compartments][1].Theta = 0.4314274334597068
    gvars[:compartments][1].Fluxout = 13.522758635680136 
    gvars[:compartments][1].Smax = 0.020971677596376796
    gvars[:compartments][1].WFactor = 1 
    gvars[:compartments][1].DayAnaero = 1 

    gvars[:compartments][2].Theta = 0.29127477265228668
    gvars[:compartments][2].Fluxout = 2.0080792364923021
    gvars[:compartments][2].Smax =  0.019234204920652122 
    gvars[:compartments][2].WFactor = 1 

    gvars[:compartments][3].Theta = 0.29100875508231477
    gvars[:compartments][3].Fluxout = 1.8567659718903404
    gvars[:compartments][3].Smax =  0.017149237709782515 
    gvars[:compartments][3].WFactor = 1 
    
    gvars[:compartments][4].Theta = 0.29045545425305946
    gvars[:compartments][4].Fluxout = 1.7656751199210874
    gvars[:compartments][4].Smax = 0.014716775963767973
    gvars[:compartments][4].WFactor = 1 

    gvars[:compartments][5].Theta = 0.29038136419496297
    gvars[:compartments][5].Fluxout = 1.6894022797919317
    gvars[:compartments][5].Smax = 0.011936819682608495
    gvars[:compartments][5].WFactor = 1 

    gvars[:compartments][6].Theta = 0.29019031607230478
    gvars[:compartments][6].Fluxout = 1.6418232610067482
    gvars[:compartments][6].Smax = 0.0094400874376810457
    gvars[:compartments][6].WFactor = 0.63699079692640459

    gvars[:compartments][7].Theta = 0.29018201047081305
    gvars[:compartments][7].Fluxout = 1.5963206426254355
    gvars[:compartments][7].Smax = 0

    gvars[:compartments][8].Theta = 0.29010972093491499
    gvars[:compartments][8].Fluxout = 1.5634043616604452
    gvars[:compartments][8].Smax = 0

    gvars[:compartments][9].Theta = 0.2901074057246778
    gvars[:compartments][9].Fluxout = 1.5311826437769547
    gvars[:compartments][9].Smax = 0
    
    gvars[:compartments][10].Theta = 0.29007184096573579
    gvars[:compartments][10].Fluxout = 1.5060383053947386
    gvars[:compartments][10].Smax = 0
    
    gvars[:compartments][11].Theta = 0.29007101761758292
    gvars[:compartments][11].Fluxout = 1.4811821388703306
    gvars[:compartments][11].Smax = 0
    
    gvars[:compartments][12].Theta = 0.29005076520285616
    gvars[:compartments][12].Fluxout = 1.4608760574252797
    gvars[:compartments][12].Smax = 0



    gvars[:total_water_content].BeginDay = 872.2596721867792
    gvars[:total_water_content].EndDay = 884.8811756004834
    gvars[:total_water_content].ErrorDay = 2.2737367544323206e-13 


    gvars[:total_salt_content].BeginDay = 0 
    gvars[:total_salt_content].EndDay = 0 
    gvars[:total_salt_content].ErrorDay = 0 


    gvars[:stresstot].Temp = 0.24549857357286284
    gvars[:stresstot].Exp = 0.018299915008233861
    gvars[:stresstot].Sto = -9.2518585385429718e-16 
    gvars[:stresstot].NrD = 24


    gvars[:sumwabal].Epot = 61.289869880798179
    gvars[:sumwabal].Tpot = 24.480837501472465
    gvars[:sumwabal].Rain =  79.900000000000006
    gvars[:sumwabal].Infiltrated = 78.310283994799335
    gvars[:sumwabal].Runoff = 1.5897160052006705
    gvars[:sumwabal].Drain = 1.4608760574252797
    gvars[:sumwabal].Eact = 37.487407799428176
    gvars[:sumwabal].Tact = 24.480837501472465
    gvars[:sumwabal].TrW = 23.240054996811299
    gvars[:sumwabal].ECropCycle = 37.487407799428176
    gvars[:sumwabal].Biomass = 1.2517750517515114
    gvars[:sumwabal].YieldPart = 1.0937253877066988
    gvars[:sumwabal].BiomassPot = 0.91195326864060511
    gvars[:sumwabal].BiomassUnlim = 1.7944773587358849
    gvars[:sumwabal].BiomassTot = 1.2517750517515114

    
    gvars[:root_zone_wc].Actual = 292.86478073359626 
    gvars[:root_zone_wc].FC = 278.18183692239666 
    gvars[:root_zone_wc].WP = 124.70220275831575
    gvars[:root_zone_wc].SAT = 441.25394822173263
    gvars[:root_zone_wc].Leaf = 237.32709351472025
    gvars[:root_zone_wc].Thresh = 173.48079756026053
    gvars[:root_zone_wc].Sen = 159.9323763076309
    gvars[:root_zone_wc].ZtopAct = 43.142743345970679
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 18.085088461943755


    gvars[:plotvarcrop].PotVal = 80.092136507924835
    gvars[:plotvarcrop].ActVal = 44.647126256430454 

    return outputs, gvars, projectinput
end

function checkpoint8()
    # break run.f90:7772

    outputs, gvars, projectinput = checkpoint5()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 1.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 3.7)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double) #-9
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 2.6103245071754047)
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.023251265912542812)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tact,  0.83919632073143413)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 3.7) 
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.5054757642085389) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.5054757642085389) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double) #0
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.83919632073143413) 
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.53490644093635065) 
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.53490644093635065) 
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos,  0.94999995068061738)
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.5054757642085389) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.83919632073143413) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd,  1532.6499999999992)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 380.5)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 183.74999999999997)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 1532.6499999999992) 
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 100.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 73.013989759755475) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 73.611620161515205)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 8.0065472916213789) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum,  7.8484976275765659)
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 5.1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 15.9) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 5.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev,  2.6103245071754047)

    AquaCrop.setparameter!(gvars[:integer_parameters], :ziaqua, AquaCrop.undef_int)  #-9
    AquaCrop.setparameter!(gvars[:integer_parameters], :daysubmerged, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 17) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 121) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41413) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 103) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41534) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 49) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 49) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true) 

    gvars[:crop].DaysToFullCanopySF = 47 
    gvars[:crop].GDDaysToFullCanopySF = 590 
    gvars[:crop].pLeafAct = 0.28493031947493325 
    gvars[:crop].pSenAct = 0.78182104826564724 
    gvars[:crop].CCxAdjusted = 0.5054757642085389 
    gvars[:crop].CCoAdjusted = 0.05
    gvars[:crop].CCxWithered = 0.5054757642085389 
    gvars[:crop].pActStom = 0.69543712776214661 
    
    gvars[:simulation].IrriECw = 0
    gvars[:simulation].EffectStress.RedCGC = 23
    gvars[:simulation].EffectStress.RedCCX = 39
    gvars[:simulation].EffectStress.RedWP = 51
    gvars[:simulation].EffectStress.CDecline = 0.039228692992979708 
    gvars[:simulation].EffectStress.RedKsSto = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SWCtopSoilConsidered = true 
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumGDD = 1532.6499999999992
    gvars[:simulation].SumGDDfromDay1 = 1532.6499999999992 
    gvars[:simulation].Germinate = true
    gvars[:simulation].ProtectedSeedling = false 
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapStartStg2 = AquaCrop.undef_int
    gvars[:simulation].DayAnaero = 0
    gvars[:simulation].HIfinal = 100
    gvars[:simulation].Storage.Btotal = 1.4615342303009733 
    gvars[:simulation].EvapWCsurf = 3.1650935590636493

 
    
    gvars[:soil_layers][1].WaterContent = 948.9898051364604


    gvars[:compartments][1].Theta = 0.28863748253843891
    gvars[:compartments][1].Fluxout = 0 
    gvars[:compartments][1].Smax = 0.021411270575196734
    gvars[:compartments][1].WFactor = 1 

    gvars[:compartments][2].Theta = 0.28976912694991402
    gvars[:compartments][2].Fluxout = 0 
    gvars[:compartments][2].Smax =  0.020772780346521906 
    gvars[:compartments][2].WFactor = 1 

    gvars[:compartments][3].Theta = 0.16871683095235379
    gvars[:compartments][3].Fluxout = 0 
    gvars[:compartments][3].Smax =  0.020006592072112112 
    gvars[:compartments][3].WFactor = 1 
    
    gvars[:compartments][4].Theta = 0.28363126208232431
    gvars[:compartments][4].Fluxout = 0
    gvars[:compartments][4].Smax = 0.01911270575196735
    gvars[:compartments][4].WFactor = 1 

    gvars[:compartments][5].Theta = 0.29
    gvars[:compartments][5].Fluxout = 0 
    gvars[:compartments][5].Smax = 0.018091121386087622
    gvars[:compartments][5].WFactor = 1 

    gvars[:compartments][6].Theta = 0.29
    gvars[:compartments][6].Fluxout = 0 
    gvars[:compartments][6].Smax = 0.01694183897447293
    gvars[:compartments][6].WFactor = 1 

    gvars[:compartments][7].Theta = 0.29
    gvars[:compartments][7].Fluxout = 0 
    gvars[:compartments][7].Smax = 0.015664858517123272
    gvars[:compartments][7].WFactor = 1 

    gvars[:compartments][8].Theta = 0.29
    gvars[:compartments][8].Fluxout = 0 
    gvars[:compartments][8].Smax = 0.014260180014038646
    gvars[:compartments][8].WFactor = 1 

    gvars[:compartments][9].Theta = 0.29
    gvars[:compartments][9].Fluxout = 0
    gvars[:compartments][9].Smax = 0.012727803465219057
    gvars[:compartments][9].WFactor = 1 
    
    gvars[:compartments][10].Theta = 0.28999999999999998
    gvars[:compartments][10].Fluxout = 0
    gvars[:compartments][10].Smax = 0.011067728870664499
    gvars[:compartments][10].WFactor = 1 
    
    gvars[:compartments][11].Theta = 0.28999999999999998
    gvars[:compartments][11].Fluxout = 0
    gvars[:compartments][11].Smax = 0.0092799562303749784
    gvars[:compartments][11].WFactor = 1 
    
    gvars[:compartments][12].Theta = 0.28999999999999998
    gvars[:compartments][12].Fluxout = 0 
    gvars[:compartments][12].Smax = 0.008359701621781776
    gvars[:compartments][12].WFactor = 0.025811170696347453


    gvars[:total_water_content].BeginDay = 848.03700978871132 
    gvars[:total_water_content].EndDay = 850.36290702704355
    gvars[:total_water_content].ErrorDay = 1.1368683772161603e-13 



    gvars[:total_salt_content].BeginDay = 0 
    gvars[:total_salt_content].EndDay = 0 
    gvars[:total_salt_content].ErrorDay = 0 



    gvars[:cut_info_record1].FromDay = 536



    gvars[:transfer].Store = true 



    gvars[:stresstot].Temp = 1.0034186854568179 
    gvars[:stresstot].Exp = 0.0057831890497611789
    gvars[:stresstot].Sto = -9.2518585385429718e-16 
    gvars[:stresstot].NrD = 120


    
    gvars[:sumwabal].Epot = 176.94324453714765
    gvars[:sumwabal].Tpot = 248.9634314075472
    gvars[:sumwabal].Rain = 382.40000000000003
    gvars[:sumwabal].Infiltrated = 380.13978969442394
    gvars[:sumwabal].Runoff = 2.2602103055761256
    gvars[:sumwabal].Drain = 24.668076636773641
    gvars[:sumwabal].Eact = 126.14538758706982
    gvars[:sumwabal].Tact = 248.9634314075472
    gvars[:sumwabal].TrW = 248.12423508681576
    gvars[:sumwabal].ECropCycle = 126.14538758706982
    gvars[:sumwabal].Biomass = 8.5657622187306668
    gvars[:sumwabal].YieldPart = 8.4077125546858529
    gvars[:sumwabal].BiomassPot = 8.7335440554033514
    gvars[:sumwabal].BiomassUnlim = 17.185252367487248
    gvars[:sumwabal].BiomassTot = 8.5657622187306668

    
    gvars[:root_zone_wc].Actual = 737.35700114390067
    gvars[:root_zone_wc].FC = 756.99410708086737
    gvars[:root_zone_wc].WP = 339.34218593280258
    gvars[:root_zone_wc].SAT = 1200.7492733006861
    gvars[:root_zone_wc].Leaf = 637.99241175882958
    gvars[:root_zone_wc].Thresh = 466.54345463331464
    gvars[:root_zone_wc].Sen = 430.46504427872588
    gvars[:root_zone_wc].ZtopAct = 28.863748253843891
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 17.873005955805652 


    gvars[:plotvarcrop].PotVal = 99.999994808486036
    gvars[:plotvarcrop].ActVal = 53.207975179846201 

    return outputs, gvars, projectinput
end

function checkpoint9()
    # break run.f90:7800
    outputs, gvars, projectinput = checkpoint5()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 0.5)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 0.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 2.8849256144259785)
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.730842826877532330)
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 0.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.576077117149770720)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.576077117149770720)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.55)
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.54699252493568706)
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.95)
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.576077117149770720)
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 1802.6) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 431.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 453.7)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 1802.6)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 100.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 79.490730680188847) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 79.385080566339937)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 8.0065472916213789) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 7.8484976275765659) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, -0.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 7.3) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, 2.8849256144259785)


    AquaCrop.setparameter!(gvars[:integer_parameters], :ziaqua, AquaCrop.undef_int) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daysubmerged, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 61) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 165) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41413) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 2) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 103) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41578)
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 45) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 45) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true) 

    gvars[:crop].DaysToFullCanopySF = 45
    gvars[:crop].GDDaysToFullCanopySF = 562
    gvars[:crop].pLeafAct = 0.31866289934366654
    gvars[:crop].pSenAct = 0.80227631033205904
    gvars[:crop].CCxAdjusted = 0.57607711714977072
    gvars[:crop].CCoAdjusted = 0.05
    gvars[:crop].CCxWithered = 0.57607711714977072
    gvars[:crop].pActStom = 0.71929640970268327
    
    gvars[:simulation].IrriECw = 0
    gvars[:simulation].EffectStress.RedCGC = 20
    gvars[:simulation].EffectStress.RedCCX = 35
    gvars[:simulation].EffectStress.RedWP = 47
    gvars[:simulation].EffectStress.CDecline = 0.030114946687417765
    gvars[:simulation].EffectStress.RedKsSto = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SWCtopSoilConsidered = false
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumGDD = 1802.6
    gvars[:simulation].SumGDDfromDay1 = 1802.6
    gvars[:simulation].Germinate = true
    gvars[:simulation].ProtectedSeedling = false
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapStartStg2 = 22
    gvars[:simulation].DayAnaero = 0
    gvars[:simulation].HIfinal = 100
    gvars[:simulation].Storage.Btotal = 2.3975455313466778


    gvars[:soil_layers][1].WaterContent = 1009.1557018884808

        
    gvars[:compartments][1].Theta = 0.28888071115790098
    gvars[:compartments][1].Fluxout = 0.55756742461396558
    gvars[:compartments][1].Smax = 0.021435246510529159
    gvars[:compartments][1].WFactor = 0.76209455325384923


    gvars[:compartments][2].Theta = 0.29032788423393802
    gvars[:compartments][2].Fluxout = 0.57233138429815822
    gvars[:compartments][2].Smax = 0.020856696120185387
    gvars[:compartments][2].WFactor = 0.22218498638893547

    
    gvars[:compartments][3].Theta = 0.29019870962556377
    gvars[:compartments][3].Fluxout = 0.58388092523273205
    gvars[:compartments][3].Smax = 0.020162435651772861
    gvars[:compartments][3].WFactor = 0.015863181510512692


    gvars[:compartments][4].Theta = 0.29012744148121866
    gvars[:compartments][4].Fluxout = 0.6020824854801996
    gvars[:compartments][4].Smax = 0.01935246510529158
    gvars[:compartments][4].WFactor = 0

    
    gvars[:compartments][5].Theta = 0.29008792636992675
    gvars[:compartments][5].Fluxout = 0.6194312387260279
    gvars[:compartments][5].Smax = 0.018426784480741545
    gvars[:compartments][5].WFactor = 0


    gvars[:compartments][6].Theta = 0.29006798537616635
    gvars[:compartments][6].Fluxout = 0.63978833219415554
    gvars[:compartments][6].Smax = 0.017385393778122753
    gvars[:compartments][6].WFactor = 0

    
    gvars[:compartments][7].Theta = 0.29005359230987582
    gvars[:compartments][7].Fluxout = 0.65682781341949981
    gvars[:compartments][7].Smax = 0.016228292997435209
    gvars[:compartments][7].WFactor = 0

    
    gvars[:compartments][8].Theta = 0.29004457836760383
    gvars[:compartments][8].Fluxout = 0.67491128201553541
    gvars[:compartments][8].Smax = 0.014955482138678911
    gvars[:compartments][8].WFactor = 0

    
    gvars[:compartments][9].Theta = 0.29004448362231922
    gvars[:compartments][9].Fluxout = 0.68814487336478536
    gvars[:compartments][9].Smax = 0.013566961201853855
    gvars[:compartments][9].WFactor = 0

    
    gvars[:compartments][10].Theta = 0.2900320546496038
    gvars[:compartments][10].Fluxout = 0.70409087594683706
    gvars[:compartments][10].Smax = 0.012062730186960049
    gvars[:compartments][10].WFactor = 0

    
    gvars[:compartments][11].Theta = 0.29003131002431454
    gvars[:compartments][11].Fluxout = 0.71668686262650461
    gvars[:compartments][11].Smax = 0.010442789093997488
    gvars[:compartments][11].WFactor = 0

    
    gvars[:compartments][12].Theta = 0.29002446769251361
    gvars[:compartments][12].Fluxout = 0.73084282687753233
    gvars[:compartments][12].Smax = 0.0089830759404247694
    gvars[:compartments][12].WFactor = 0




    gvars[:total_water_content].BeginDay = 870.977059813610710
    gvars[:total_water_content].EndDay = 870.09922446179735
    gvars[:total_water_content].ErrorDay = 1.1368683772161603e-13
    

    gvars[:total_salt_content].BeginDay = 0
    gvars[:total_salt_content].EndDay = 0
    gvars[:total_salt_content].ErrorDay = 0

    
    gvars[:stresstot].Salt = 0
    gvars[:stresstot].Temp = 11.497152813109741
    gvars[:stresstot].Exp = 0.0043185524644892221
    gvars[:stresstot].Sto = -6.9414627017820649e-17
    gvars[:stresstot].Weed = 0
    gvars[:stresstot].NrD = 164 

    
    gvars[:sumwabal].Epot = 195.09540663475843
    gvars[:sumwabal].Tpot = 276.24802977578918
    gvars[:sumwabal].Rain = 487.50000000000011
    gvars[:sumwabal].Irrigation = 0
    gvars[:sumwabal].Infiltrated = 484.09143552451582
    gvars[:sumwabal].Runoff = 3.4085644754843547
    gvars[:sumwabal].Drain = 65.023086034139581
    gvars[:sumwabal].Eact = 142.72110821679951
    gvars[:sumwabal].Tact = 276.24802977578918
    gvars[:sumwabal].TrW = 276.24802977578918 
    gvars[:sumwabal].ECropCycle = 142.72110821679951
    gvars[:sumwabal].CRwater = 0
    gvars[:sumwabal].Biomass = 9.3194942852625839
    gvars[:sumwabal].YieldPart = 9.1614446212177718
    gvars[:sumwabal].BiomassPot = 10.544812389509518
    gvars[:sumwabal].BiomassUnlim = 20.749338519614081
    gvars[:sumwabal].BiomassTot = 9.3194942852625839
    gvars[:sumwabal].SaltIn = 0
    gvars[:sumwabal].SaltOut = 0
    gvars[:sumwabal].CRsalt = 0 
 

    gvars[:cut_info_record1].NoMoreInfo = false
    gvars[:cut_info_record1].FromDay = 536


    gvars[:root_zone_wc].Actual = 836.72482407554469
    gvars[:root_zone_wc].FC = 836.62842818353374
    gvars[:root_zone_wc].WP = 375.04032987537721
    gvars[:root_zone_wc].SAT = 1327.0657826359502
    gvars[:root_zone_wc].Leaf = 689.5374264741273
    gvars[:root_zone_wc].Thresh = 504.6097663089875
    gvars[:root_zone_wc].Sen = 466.30723177967423
    gvars[:root_zone_wc].ZtopAct = 28.888071115790098
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 17.491257444757068 


    gvars[:transfer].Store = true
    gvars[:transfer].Mobilize = false 

    gvars[:plotvarcrop].PotVal = 99.999999796558043
    gvars[:plotvarcrop].ActVal = 60.639696542081133 

    return outputs, gvars, projectinput
end

function checkpoint10()
    outputs, gvars, projectinput = checkpoint9()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 0.5)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 0.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, -0.2) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 4.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.73084282687753233)
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 0.4)
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double) #undef_int
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumeto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumgdd, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbmob, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbsto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :co2i, 401.01) 
    AquaCrop.setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 0.50779690544596179) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0, 86.084090961833354)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1, -0.56134037826198147) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2, -0.0029391774899306783)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0salt, 0.79636344922211677)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1salt, 0.33631348098536523)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2salt, 0.0054243004180416082)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop, 170.65447289377104)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 86.657813235968703) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :fweednos, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, 0.95) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxtotal, 0.94851562500000008)
    AquaCrop.setparameter!(gvars[:float_parameters], :cdctotal, 0.006)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcdctotal, 0.006) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccototal, 0.048023576462394767)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :dayfraction, 0.88079470198675491)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayfraction, 0.90017016449234255) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cgcref, 0.12572727272727272)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcgcref, 0.012) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_bef, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at1, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at2, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at, 1.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi_adj, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at1, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at2, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.54699252493568706) 
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.55000000000000004) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.57607711714977072) 


    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 0)
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 0)
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 50)
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 50)
    AquaCrop.setparameter!(gvars[:integer_parameters], :tadj, 16)
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 0)
    AquaCrop.setparameter!(gvars[:integer_parameters], :gddtadj, 171)
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 1)

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, true)
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, false)

    gvars[:crop].GDDaysToHarvest = 2048
    gvars[:crop].GDDaysToSenescence = 2048
    gvars[:crop].GDDaysToFullCanopySF = 554 
    gvars[:crop].GDDaysToCCini = 171 
    gvars[:crop].DaysToMaxRooting = 149 
    gvars[:crop].DaysToHarvest = 177 
    gvars[:crop].DaysToSenescence = 177 
    gvars[:crop].DaysToFullCanopySF = 54 
    gvars[:crop].DaysToFullCanopy = 44 
    gvars[:crop].DaysToGermination = 2 
    gvars[:crop].DaysToCCini = 16 
    gvars[:crop].CCxAdjusted = 0.94851562500000008
    gvars[:crop].CCxWithered = 0
    gvars[:crop].CCoAdjusted = 0.048023576462394767
    gvars[:crop].CDC = 0.006 
    gvars[:crop].CGC = 0.12572727272727272 
    gvars[:crop].RootMin = 3 
    gvars[:crop].Length = [0, 26, 151, 0] 
    gvars[:crop].Day1 = 41759
    gvars[:crop].DayN = 41935
    gvars[:crop].pActStom = 0.6 
    gvars[:crop].pLeafAct = 0.15 
    gvars[:crop].pSenAct = 0.7 
    gvars[:crop].Planting = :Regrowth

    gvars[:simulation].Storage.Btotal = 0.0
    gvars[:simulation].Storage.Season = 2
    gvars[:simulation].YearSeason = 2
    gvars[:simulation].EffectStress.RedCGC = 24
    gvars[:simulation].EffectStress.RedCCX = 40
    gvars[:simulation].EffectStress.RedWP = 52
    gvars[:simulation].EffectStress.CDecline = 0.04188660705779268
    gvars[:simulation].SumGDD = 0
    gvars[:simulation].SumGDDfromDay1 = 0
    gvars[:simulation].LinkCropToSimPeriod = false
    gvars[:simulation].ToDayNr = 41935
    gvars[:simulation].FromDayNr = 41578

    gvars[:stresstot].Salt = 0 
    gvars[:stresstot].Temp = 0 
    gvars[:stresstot].Exp = 0 
    gvars[:stresstot].Sto = 0 
    gvars[:stresstot].Weed = 0 
    gvars[:stresstot].NrD = AquaCrop.undef_int 

    gvars[:sumwabal] = AquaCrop.RepSum()

    gvars[:transfer].Store = false
    gvars[:transfer].Mobilize = true 
    gvars[:transfer].ToMobilize = 0.2877054680487468
    gvars[:transfer].Bmobilized = 0

    gvars[:cut_info_record1].NoMoreInfo = false
    gvars[:cut_info_record1].FromDay = 536 


    outputs[:tcropsim] = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])
    outputs[:etodatasim] = Float64[]
    outputs[:raindatasim] = Float64[]
    outputs[:tempdatasim] = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])
    open(joinpath(pwd(), "testcase/OUTPUTS/TCropsim_2")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tcropsim!(outputs, tlow, thigh)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/EToDatasim_2")) do file
        for line in eachline(file)
            eto = parse(Float64, line)
            AquaCrop.add_output_in_etodatasim!(outputs, eto)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/RainDatasim_2")) do file
        for line in eachline(file)
            rain = parse(Float64, line)
            AquaCrop.add_output_in_raindatasim!(outputs, rain)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/TempDatasim_2")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tempdatasim!(outputs, tlow, thigh)
        end
    end

    popfirst!(gvars[:array_parameters][:Man])
    popfirst!(gvars[:array_parameters][:Man])

    for _ in 1:15
        popfirst!(gvars[:array_parameters][:DaynrEval])
        popfirst!(gvars[:array_parameters][:CCmeanEval])
        popfirst!(gvars[:array_parameters][:CCstdEval])
        popfirst!(gvars[:array_parameters][:BmeanEval])
        popfirst!(gvars[:array_parameters][:BstdEval])
        popfirst!(gvars[:array_parameters][:SWCmeanEval])
        popfirst!(gvars[:array_parameters][:SWCstdEval])
    end

    return outputs, gvars, projectinput
end

function checkpoint11()
    # break run.f90:7800
    outputs, gvars, projectinput = checkpoint10()

    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 0.6)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 3.6)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 3.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, -33.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, AquaCrop.undef_double) #-9
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 3.6)
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.56025172572431414)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.56025172572431414)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.19634547828829069)
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.19634547828829069)
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.95)
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.56025172572431414)
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 2118.5999999999999) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 617.60000000000002) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 495.19999999999987)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 2048.0500000000002)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 100.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 92.172746116416576) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 92.153415362636366)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 10.643070189506627) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 10.643070189506631) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 0.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 8.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, 3.0)

    AquaCrop.setparameter!(gvars[:integer_parameters], :ziaqua, AquaCrop.undef_int) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daysubmerged, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 55) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 178) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41577) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 3) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 122) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41936)
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 46) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 46) 

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true) 

    gvars[:crop].DaysToFullCanopySF = 53
    gvars[:crop].GDDaysToFullCanopySF = 538
    gvars[:crop].pLeafAct = 0.31491483491380734
    gvars[:crop].pSenAct = 0.80000350343579107
    gvars[:crop].CCxAdjusted = 0.56026036836354065
    gvars[:crop].CCoAdjusted = 0.048023576462394767
    gvars[:crop].CCxWithered = 0.56026036836354065
    gvars[:crop].pActStom = 0.71664537837595699


    gvars[:simulation].IrriECw = 0
    gvars[:simulation].EffectStress.RedCGC = 21
    gvars[:simulation].EffectStress.RedCCX = 36
    gvars[:simulation].EffectStress.RedWP = 48
    gvars[:simulation].EffectStress.CDecline = 0.032184104413785386
    gvars[:simulation].EffectStress.RedKsSto = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SWCtopSoilConsidered = true 
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumGDD = 2048.0500000000002
    gvars[:simulation].SumGDDfromDay1 = 2048.0500000000002
    gvars[:simulation].Germinate = true
    gvars[:simulation].ProtectedSeedling = false
    gvars[:simulation].EvapLimitON = false
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].EvapStartStg2 = AquaCrop.undef_int
    gvars[:simulation].DayAnaero = 0
    gvars[:simulation].HIfinal = 100
    gvars[:simulation].Storage.Btotal = 2.2868156335990366
    gvars[:simulation].EvapWCsurf = 3.4036545217117093



    gvars[:soil_layers][1].WaterContent = 976.5956104446841



    gvars[:compartments][1].Theta = 0.32405069474860621
    gvars[:compartments][1].Fluxout = 0.015733615056915326
    gvars[:compartments][1].Smax = 0.021444444441133075
    gvars[:compartments][1].WFactor = 0.76209455325384923


    gvars[:compartments][2].Theta = 0.29029171471901183
    gvars[:compartments][2].Fluxout = 0.51260546661508022
    gvars[:compartments][2].Smax = 0.020888888877299096
    gvars[:compartments][2].WFactor = 0.22218498638893547

    
    gvars[:compartments][3].Theta = 0.23875482657223857
    gvars[:compartments][3].Fluxout = 0
    gvars[:compartments][3].Smax = 0.020222222200698324
    gvars[:compartments][3].WFactor = 0.015863181510512692


    gvars[:compartments][4].Theta = 0.23981995503207343
    gvars[:compartments][4].Fluxout = 0 
    gvars[:compartments][4].Smax = 0.019444444411330752
    gvars[:compartments][4].WFactor = 0

    
    gvars[:compartments][5].Theta = 0.28999999999999998
    gvars[:compartments][5].Fluxout =  0
    gvars[:compartments][5].Smax = 0.018555555509196388
    gvars[:compartments][5].WFactor = 0


    gvars[:compartments][6].Theta = 0.29000000000000004
    gvars[:compartments][6].Fluxout = 0
    gvars[:compartments][6].Smax = 0.017555555494295227
    gvars[:compartments][6].WFactor = 0

    
    gvars[:compartments][7].Theta = 0.29000000000000004
    gvars[:compartments][7].Fluxout = 0
    gvars[:compartments][7].Smax = 0.016444444366627269
    gvars[:compartments][7].WFactor = 0

    
    gvars[:compartments][8].Theta = 0.28999999999999998
    gvars[:compartments][8].Fluxout = 0
    gvars[:compartments][8].Smax = 0.015222222126192517
    gvars[:compartments][8].WFactor = 0

    
    gvars[:compartments][9].Theta = 0.29
    gvars[:compartments][9].Fluxout = 0
    gvars[:compartments][9].Smax = 0.013888888772990968
    gvars[:compartments][9].WFactor = 0

    
    gvars[:compartments][10].Theta = 0.29
    gvars[:compartments][10].Fluxout = 0
    gvars[:compartments][10].Smax = 0.012444444307022625
    gvars[:compartments][10].WFactor = 0

    
    gvars[:compartments][11].Theta = 0.29
    gvars[:compartments][11].Fluxout = 0
    gvars[:compartments][11].Smax = 0.010888888728287485
    gvars[:compartments][11].WFactor = 0

    
    gvars[:compartments][12].Theta = 0.29
    gvars[:compartments][12].Fluxout = 0
    gvars[:compartments][12].Smax = 0.0092222221361266243
    gvars[:compartments][12].WFactor = 0


    gvars[:total_water_content].BeginDay = 852.32239990456287
    gvars[:total_water_content].EndDay = 855.72605442627457
    gvars[:total_water_content].ErrorDay = 0 
    

    gvars[:total_salt_content].BeginDay = 0
    gvars[:total_salt_content].EndDay = 0
    gvars[:total_salt_content].ErrorDay = 0

    
    gvars[:stresstot].Salt = 0
    gvars[:stresstot].Temp = 10.810686515053268
    gvars[:stresstot].Exp = 0
    gvars[:stresstot].Sto = -6.9414627017820649e-17
    gvars[:stresstot].Weed = 0
    gvars[:stresstot].NrD = 177 


    gvars[:sumwabal].Epot = 323.47992499293639
    gvars[:sumwabal].Tpot = 348.81350702612167
    gvars[:sumwabal].Rain = 782.10000000000048
    gvars[:sumwabal].Irrigation = 0
    gvars[:sumwabal].Infiltrated = 777.75806042423528
    gvars[:sumwabal].Runoff = 4.3419395757654566
    gvars[:sumwabal].Drain = 194.45159905397986
    gvars[:sumwabal].Eact = 248.8661243796555
    gvars[:sumwabal].Tact = 348.81350702612167
    gvars[:sumwabal].TrW = 348.81350702612167
    gvars[:sumwabal].ECropCycle = 135.90818125717061
    gvars[:sumwabal].CRwater = 0
    gvars[:sumwabal].Biomass = 11.841291271983982
    gvars[:sumwabal].YieldPart = 11.841291271983993
    gvars[:sumwabal].BiomassPot = 13.013656919065257
    gvars[:sumwabal].BiomassUnlim = 25.627680632744877
    gvars[:sumwabal].BiomassTot = 11.841291271983982
    gvars[:sumwabal].SaltIn = 0
    gvars[:sumwabal].SaltOut = 0
    gvars[:sumwabal].CRsalt = 0 
 

    gvars[:cut_info_record1].NoMoreInfo = false
    gvars[:cut_info_record1].FromDay = 897


    gvars[:root_zone_wc].Actual = 855.72604146226433
    gvars[:root_zone_wc].FC = 870 
    gvars[:root_zone_wc].WP = 390
    gvars[:root_zone_wc].SAT = 1380 
    gvars[:root_zone_wc].Leaf = 718.84087924137236
    gvars[:root_zone_wc].Thresh = 526.01021837954056
    gvars[:root_zone_wc].Sen = 485.99831835082034
    gvars[:root_zone_wc].ZtopAct = 32.405069474860618
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 17.533673945984688 


    gvars[:transfer].Store = true
    gvars[:transfer].Mobilize = false 
    gvars[:transfer].ToMobilize = 0.2877054680487468
    gvars[:transfer].Bmobilized = 0.2877054680487468


    gvars[:plotvarcrop].PotVal = 99.998458084931841
    gvars[:plotvarcrop].ActVal = 58.973865865717279 

    popfirst!(gvars[:array_parameters][:Man])
    popfirst!(gvars[:array_parameters][:Man])
    popfirst!(gvars[:array_parameters][:Man])

    for _ in 1:15
        popfirst!(gvars[:array_parameters][:DaynrEval])
        popfirst!(gvars[:array_parameters][:CCmeanEval])
        popfirst!(gvars[:array_parameters][:CCstdEval])
        popfirst!(gvars[:array_parameters][:BmeanEval])
        popfirst!(gvars[:array_parameters][:BstdEval])
        popfirst!(gvars[:array_parameters][:SWCmeanEval])
        popfirst!(gvars[:array_parameters][:SWCstdEval])
    end

    return outputs, gvars, projectinput
end

function checkpoint12()
    outputs, gvars, projectinput = checkpoint11()


    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 0.5)
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 2.7)
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, -0.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 6.9) 
    AquaCrop.setparameter!(gvars[:float_parameters], :irrigation, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surfacestorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecstorage, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :drain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :runoff, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :infiltrated, 2.7)
    AquaCrop.setparameter!(gvars[:float_parameters], :crwater, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :crsalt, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :eciaqua, AquaCrop.undef_double) #undef_int
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 653.69999999999936) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 2213.1000000000004)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumeto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumgdd, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbmob, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbsto, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0.94999999994807116) 
    AquaCrop.setparameter!(gvars[:float_parameters], :co2i, 404.41000000000003) 
    AquaCrop.setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 0.50752025859269856) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0, 86.072397622864784)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1, -0.5620753844179871) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2, -0.0029293735004094052)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0salt, 0.76992028518908029)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1salt, 0.33196286966676114)
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2salt, 0.005472515397255304)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop, 167.09517835752234)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 88.560444529486844) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 88.370484933315353)
    AquaCrop.setparameter!(gvars[:float_parameters], :fweednos, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, 0.95) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxtotal, 0.94406250000000003)
    AquaCrop.setparameter!(gvars[:float_parameters], :cdctotal, 0.005)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcdctotal, 0.006) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccototal, 0.046047152924789531)
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 2103.6999999999998) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :dayfraction, 0.87248322147651003)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayfraction, 0.90324354040681698) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0.54216324731593235)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0.54216324731593235)
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ziprev, 3.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 3.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 540.5500000000003)
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 11.058376807968642) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 11.05837680796866)
    AquaCrop.setparameter!(gvars[:float_parameters], :cgcref, 0.12293333333333333)
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcgcref, 0.012) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_bef, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at1, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at2, 1.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at, 1.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi, 100) 
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi_adj, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at1, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at2, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :stressleaf, -33.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :stresssenescence, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :tact, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tpot, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :bin, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :bout, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :surf0, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :ecdrain, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :eact, 0.55) 
    AquaCrop.setparameter!(gvars[:float_parameters], :epot, 0.55000000000000004) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tactweedinfested, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :saltinfiltr, 0.0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccitopearlysen, AquaCrop.undef_double)
    AquaCrop.setparameter!(gvars[:float_parameters], :weedrci, 0.0)
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactualweedinfested, 0.54216324731593235) 


    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 115)
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 60)
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 47)
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 47)
    AquaCrop.setparameter!(gvars[:integer_parameters], :tadj, 17)
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 3)
    AquaCrop.setparameter!(gvars[:integer_parameters], :gddtadj, 171)
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 176)
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 42306)
    AquaCrop.setparameter!(gvars[:integer_parameters], :previoussdaynr, 41935)

    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, false)
    AquaCrop.setparameter!(gvars[:bool_parameters], :preday, true)

   
    gvars[:crop].GDDaysToHarvest = 2104
    gvars[:crop].GDDaysToSenescence = 2104
    gvars[:crop].GDDaysToFullCanopySF = 572 
    gvars[:crop].GDDaysToCCini = 171 
    gvars[:crop].DaysToMaxRooting = 143 
    gvars[:crop].DaysToHarvest = 175 
    gvars[:crop].DaysToSenescence = 175 
    gvars[:crop].DaysToFullCanopySF = 54 
    gvars[:crop].DaysToFullCanopy = 45 
    gvars[:crop].DaysToGermination = 2 
    gvars[:crop].DaysToCCini = 17 
    gvars[:crop].DaysToHIo = 19 
    gvars[:crop].CCxAdjusted = 0.54216324731593235
    gvars[:crop].CCxWithered = 0.54216324731593235
    gvars[:crop].CCoAdjusted = 0.046047152924789531
    gvars[:crop].CDC = 0.005 
    gvars[:crop].CGC = 0.12293333333333333 
    gvars[:crop].RootMin = 3 
    gvars[:crop].Length = [0, 26, 149, 0] 
    gvars[:crop].Day1 = 42131
    gvars[:crop].DayN = 42305
    gvars[:crop].pActStom = 0.71929640970268327 
    gvars[:crop].pLeafAct = 0.31866289934366654 
    gvars[:crop].pSenAct = 0.80227631033205904 
    gvars[:crop].dHIdt = 5.2631578947368425
    gvars[:crop].Planting = :Regrowth


    gvars[:simulation].Storage.Btotal = 2.4425391569245685
    gvars[:simulation].Storage.Season = 3
    gvars[:simulation].YearSeason = 3
    gvars[:simulation].EffectStress.RedCGC = 21
    gvars[:simulation].EffectStress.RedCCX = 37
    gvars[:simulation].EffectStress.RedWP = 49
    gvars[:simulation].EffectStress.CDecline = 0.034386931619837524
    gvars[:simulation].SumGDD = 2103.7
    gvars[:simulation].SumGDDfromDay1 = 2103.7
    gvars[:simulation].ToDayNr = 42305
    gvars[:simulation].FromDayNr = 41936 
    gvars[:simulation].EvapWCsurf = 2.15
    gvars[:simulation].EvapStartStg2 = AquaCrop.undef_int
    gvars[:simulation].EvapZ = 0.15




    gvars[:compartments][1].Theta = 0.31350599913390109
    gvars[:compartments][1].Fluxout = 5.206474364482971
    gvars[:compartments][1].Smax = 0.021444444441133075
    gvars[:compartments][1].WFactor = 0.76209455325384923
    gvars[:compartments][1].DayAnaero = 1


    gvars[:compartments][2].Theta = 0.29227085480537851
    gvars[:compartments][2].Fluxout = 4.8659124788508503
    gvars[:compartments][2].Smax = 0.020888888877299096
    gvars[:compartments][2].WFactor = 0.22218498638893547

    
    gvars[:compartments][3].Theta = 0.29150075618956817
    gvars[:compartments][3].Fluxout = 4.6408439827564409
    gvars[:compartments][3].Smax = 0.020222222200698324
    gvars[:compartments][3].WFactor = 0.015863181510512692


    gvars[:compartments][4].Theta = 0.26747583255660218

    
    gvars[:compartments][5].Theta = 0.13000000000000014


    gvars[:compartments][6].Theta = 0.17083185432599887


    gvars[:total_water_content].BeginDay = 804.46948367501909
    gvars[:total_water_content].EndDay = 806.61948367501907
    gvars[:total_water_content].ErrorDay = 1.1368683772161603e-13 


    gvars[:soil_layers][1].WaterContent = 890.90779837500918


    gvars[:stresstot].Salt = 0 
    gvars[:stresstot].Temp = 11.554330894561998
    gvars[:stresstot].Exp =  0.99256568949777868
    gvars[:stresstot].Sto =  -6.608470384673552e-17
    gvars[:stresstot].Weed = 0 
    gvars[:stresstot].NrD = 175 


    gvars[:sumwabal].Epot = 364.98711714861338
    gvars[:sumwabal].Tpot = 352.10439980283957
    gvars[:sumwabal].Rain = 926.1999999999997
    gvars[:sumwabal].Irrigation = 0
    gvars[:sumwabal].Infiltrated = 906.18883216180711
    gvars[:sumwabal].Runoff = 20.01116783819274
    gvars[:sumwabal].Drain = 359.94335589735635
    gvars[:sumwabal].Eact = 243.24764721286687
    gvars[:sumwabal].Tact = 352.10439980283957
    gvars[:sumwabal].TrW = 352.10439980283957
    gvars[:sumwabal].ECropCycle = 118.45293585040912
    gvars[:sumwabal].CRwater = 0
    gvars[:sumwabal].Biomass = 12.466405794835991
    gvars[:sumwabal].YieldPart = 12.466405794836
    gvars[:sumwabal].BiomassPot = 13.291211566470444
    gvars[:sumwabal].BiomassUnlim = 26.188534036701522
    gvars[:sumwabal].BiomassTot = 12.466405794835991
    gvars[:sumwabal].SaltIn = 0
    gvars[:sumwabal].SaltOut = 0
    gvars[:sumwabal].CRsalt = 0 


    gvars[:cut_info_record1].NoMoreInfo = true 
    gvars[:cut_info_record1].FromDay = 972 


    gvars[:root_zone_wc].Actual = 806.61947071100883
    gvars[:root_zone_wc].FC = 870 
    gvars[:root_zone_wc].WP = 390
    gvars[:root_zone_wc].SAT = 1380 
    gvars[:root_zone_wc].Leaf = 717.04180831504016
    gvars[:root_zone_wc].Thresh = 524.737723342712
    gvars[:root_zone_wc].Sen = 484.90737104061168
    gvars[:root_zone_wc].ZtopAct = 31.350599913390109
    gvars[:root_zone_wc].ZtopFC = 29
    gvars[:root_zone_wc].ZtopWP = 13
    gvars[:root_zone_wc].ZtopThresh = 17.491257444757068 


    gvars[:transfer].Store = true
    gvars[:transfer].Mobilize = false 
    gvars[:transfer].ToMobilize = 1.3720893801594221
    gvars[:transfer].Bmobilized = 1.3716249335738133


    gvars[:plotvarcrop].PotVal = 99.999999994533795
    gvars[:plotvarcrop].ActVal = 57.069815506940245 


    outputs[:tcropsim] = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])
    outputs[:etodatasim] = Float64[]
    outputs[:raindatasim] = Float64[]
    outputs[:tempdatasim] = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])

    open(joinpath(pwd(), "testcase/OUTPUTS/TCropsim_3")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tcropsim!(outputs, tlow, thigh)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/EToDatasim_3")) do file
        for line in eachline(file)
            eto = parse(Float64, line)
            AquaCrop.add_output_in_etodatasim!(outputs, eto)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/RainDatasim_3")) do file
        for line in eachline(file)
            rain = parse(Float64, line)
            AquaCrop.add_output_in_raindatasim!(outputs, rain)
        end
    end

    open(joinpath(pwd(), "testcase/OUTPUTS/TempDatasim_3")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tempdatasim!(outputs, tlow, thigh)
        end
    end

    popfirst!(gvars[:array_parameters][:Man])
    popfirst!(gvars[:array_parameters][:Man])

    for _ in 1:14
        popfirst!(gvars[:array_parameters][:DaynrEval])
        popfirst!(gvars[:array_parameters][:CCmeanEval])
        popfirst!(gvars[:array_parameters][:CCstdEval])
        popfirst!(gvars[:array_parameters][:BmeanEval])
        popfirst!(gvars[:array_parameters][:BstdEval])
        popfirst!(gvars[:array_parameters][:SWCmeanEval])
        popfirst!(gvars[:array_parameters][:SWCstdEval])
    end

    return outputs, gvars, projectinput
end
