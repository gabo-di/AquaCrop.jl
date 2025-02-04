using AquaCrop 

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
        Description="Loamy soil horizon",
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
    projectinput = AquaCrop.ProjectInputType[]

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
    AquaCrop.setparameter!(integer_parameters, :tnxreferenceyear, 2000)
    AquaCrop.setparameter!(integer_parameters, :last_irri_dap, AquaCrop.undef_int)

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
    AquaCrop.setparameter!(bool_parameters, :out8Irri, false)

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
    AquaCrop.setparameter!(string_parameters, :clim_file, "(None)")
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
    AquaCrop.setparameter!(string_parameters, :swcini_file,  "(None)")


    return Dict{Symbol, Union{AquaCrop.AbstractParametersContainer,Vector{<:AquaCrop.AbstractParametersContainer}}}(
         :simulparam => simulparam,
         :soil => soil,
         :soil_layers => soil_layers,
         :compartments => compartments,
         :simulation => simulation,
         :total_water_content => total_water_content,
         :crop => crop,
         :management => management,
         :sumwabal => sumwabal,
         :previoussum => previoussum,
         :irri_before_season => irri_before_season,
         :irri_after_season => irri_after_season,
         :irri_ecw => irri_ecw,
         :onset => onset,
         :rain_record => rain_record,
         :eto_record => eto_record,
         :clim_record => clim_record,
         :temperature_record => temperature_record,
         :perennial_period => perennial_period,
         :crop_file_set => crop_file_set, 
         :gwtable => gwtable,
         :stresstot => stresstot,
         :irri_info_record1 => irri_info_record1,
         :irri_info_record2 => irri_info_record2,
         :transfer => transfer,
         :cut_info_record1 => cut_info_record1,
         :cut_info_record2 => cut_info_record2,
         :root_zone_salt => root_zone_salt,
         :root_zone_wc => root_zone_wc,
         :plotvarcrop => plotvarcrop,
         :total_salt_content => total_salt_content,
         :float_parameters => float_parameters,
         :symbol_parameters => symbol_parameters,
         :integer_parameters => integer_parameters,
         :bool_parameters => bool_parameters,
         :array_parameters => array_parameters,
         :string_parameters => string_parameters,
         :projectinput => projectinput
    )
end

function checkpoint_project1_2()
    gvars = checkpoint1()    

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

    gvars[:projectinput] = AquaCrop.ProjectInputType[
        AquaCrop.ProjectInputType(
            ParentDir=pwd()*"/extended_test/fortranrun",
            VersionNr=7.1,
            Description="UHK (Germany)",
            Simulation_YearSeason=1,
            Simulation_DayNr1=41750,
            Simulation_DayNrN=42299,
            Crop_Day1=41757,
            Crop_DayN=42158,
            Climate_Info="-- 1. Climate (CLI) file",
            Climate_Filename="uhk.CLI",
            Climate_Directory="DATA",
            Temperature_Info="1.1 Temperature (Tnx or TMP) file",
            Temperature_Filename="uhk.Tnx",
            Temperature_Directory="DATA",
            ETo_Info="1.2 Reference ET (ETo) file",
            ETo_Filename="uhk.ETo",
            ETo_Directory="DATA",
            Rain_Info="1.3 Rain (PLU) file",
            Rain_Filename="uhk.PLU",
            Rain_Directory="DATA",
            CO2_Info="1.4 Atmospheric CO2 concentration (CO2) file",
            CO2_Filename="MaunaLoa.CO2",
            CO2_Directory="SIMUL",
            Calendar_Info="-- 2. Calendar (CAL) file",
            Calendar_Filename="(None)",
            Calendar_Directory="(None)",
            Crop_Info="-- 3. Crop (CRO) file",
            Crop_Filename="MaizeGDD.CRO",
            Crop_Directory="DATA",
            Irrigation_Info="-- 4. Irrigation management (IRR) file",
            Irrigation_Filename="(None)",
            Irrigation_Directory="(None)",
            Management_Info="-- 5. Field management (MAN) file",
            Management_Filename="(None)",
            Management_Directory="(None)",
            GroundWater_Info="-- 7. Groundwater table (GWT) file",
            GroundWater_Filename="(None)",
            GroundWater_Directory="(None)",
            Soil_Info="-- 6. Soil profile (SOL) file",
            Soil_Filename="Loam.SOL",
            Soil_Directory="DATA",
            SWCIni_Info="-- 8. Initial conditions (SW0) file",
            SWCIni_Filename="(None)",
            SWCIni_Directory="(None)",
            OffSeason_Info="-- 9. Off-season conditions (OFF) file",
            OffSeason_Filename="(None)",
            OffSeason_Directory="(None)",
            Observations_Info="-- 10. Field data (OBS) file",
            Observations_Filename="(None)",
            Observations_Directory="(None)"
        ),
    ]

    return gvars 
end

function checkpoint_project1_3()
    gvars = checkpoint_project1_2()
    outputs = AquaCrop.start_outputs()

    gvars[:soil].REW = 9
    gvars[:soil].CNValue = 61
    gvars[:soil].RootMax = 2.3


    soil_layers = AquaCrop.SoilLayerIndividual[
        AquaCrop.SoilLayerIndividual(
            Description="loam",
            Thickness=4.0,
            SAT=46,
            FC=31,
            WP=15,
            tau=0.76,
            InfRate=500,
            Penetrability=100,
            GravelMass=0,
            GravelVol=0,
            WaterContent=713.0000106,
            Macro=31,
            #OJO note that the last two positions of "1" are set to undef since they seem to be a byproduct from default loading, key variable seems to be SCP1 as length of actuall stuff
            SaltMobility=[0.009009009009009004, 0.09909909909909906, 0.9999999999999999, 1.0, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double, AquaCrop.undef_double], # [1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
            SC=3,
            SCP1=4,
            UL=0.276,
            Dx=0.092,
            SoilClass=2,
            CRa=-0.4536,
            CRb=0.83733999999999997
        )
    ]
    gvars[:soil_layers] = soil_layers


    compartments = AquaCrop.CompartmentIndividual[
        AquaCrop.CompartmentIndividual(
            Thickness=0.10000000149011612,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15000000223517418,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15000000223517418,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.15,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.20,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.20,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.20000000298023224,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        ),
        AquaCrop.CompartmentIndividual(
            Thickness=0.2500000037252903,
            Theta=0.31,
            Fluxout=AquaCrop.undef_double,#0,
            Layer=1,
            Smax=AquaCrop.undef_double,#0,
            FCadj=31,
            DayAnaero=0,
            WFactor=0,
            Salt=zeros(Float64, 11),
            Depo=zeros(Float64, 11),
        )
    ]
    gvars[:compartments] = compartments


    gvars[:simulation].FromDayNr = 41750 
    gvars[:simulation].ToDayNr = 42299
    gvars[:simulation].IniSWC.Loc[1] = 4.0
    gvars[:simulation].IniSWC.VolProc[1] = 31
    gvars[:simulation].ThetaIni = [0.31 for _ in 1:12]
    gvars[:simulation].LinkCropToSimPeriod = false
    gvars[:simulation].EffectStress.RedCGC = 0
    gvars[:simulation].EffectStress.RedCCX = 0
    gvars[:simulation].EffectStress.RedWP = 0
    gvars[:simulation].EffectStress.CDecline = 0
    gvars[:simulation].EvapWCsurf = 0
    gvars[:simulation].EvapZ = 0.15
    gvars[:simulation].HIfinal = 48
    gvars[:simulation].DelayedDays = 0
    gvars[:simulation].SumEToStress = 0
    gvars[:simulation].SumGDD = 0
    gvars[:simulation].SumGDDfromDay1 = 0
    gvars[:simulation].SCor = 1
    gvars[:simulation].SalinityConsidered = true
    gvars[:simulation].RCadj = 0 
    gvars[:simulation].Storage.Btotal = 0 
    gvars[:simulation].Storage.CropString = "DEFAULT.CRO" 
    gvars[:simulation].Storage.Season = 1 


    gvars[:total_water_content].BeginDay = 713.00001062452793


    crop = AquaCrop.RepCrop(
        subkind=:Grain, 
        ModeCycle=:GDDays, 
        Planting=:Seed, 
        pMethod=:FAOCorrection, 
        pdef=0.69,
        pActStom=0.69, 
        KsShapeFactorLeaf=2.9,
        KsShapeFactorStomata=6,
        KsShapeFactorSenescence=2.7,
        pLeafDefUL=0.14,
        pLeafDefLL=0.72,
        pLeafAct=0.14,
        pSenescence=0.69,
        pSenAct=0.69, 
        pPollination=0.80000000000000002,
        SumEToDelaySenescence=50,
        AnaeroPoint=5,
        StressResponse=AquaCrop.RepShapes(
            Stress=50,
            ShapeCGC=25,
            ShapeCCX=25,
            ShapeWP=25,
            ShapeCDecline=25,
            Calibrated=false
        ),
        ECemin=2,
        ECemax=10,
        CCsaltDistortion=25,
        ResponseECsw=100,
        SmaxTopQuarter=0.045,
        SmaxBotQuarter=0.011,
        SmaxTop=0.050666666666, 
        SmaxBot=0.005333333333, 
        KcTop=1.05,
        KcDecline=0.3,
        CCEffectEvapLate=50,
        Day1=41757,
        DayN=42158,
        Length=[43, 42, 111, 206],
        RootMin=0.29999999999999999,
        RootMax=2.3,
        RootShape=13,
        Tbase=8,
        Tupper=30,
        Tcold=10,
        Theat=40,
        GDtranspLow=12,
        SizeSeedling=6.5,
        SizePlant=6.5,
        PlantingDens=117000,
        CCo=0.007605,
        CCini=0.007605,
        CGC=0.0983351294117647,
        GDDCGC=0.012494,
        CCx=0.96,
        CDC=0.01442417843464988,
        GDDCDC=0.01,
        CCxAdjusted=0.96,
        CCxWithered=0,
        CCoAdjusted=0.007605,
        DaysToCCini=0,
        DaysToGermination=17,
        DaysToFullCanopy=85,
        DaysToFullCanopySF=85,
        DaysToFlowering=103,
        LengthFlowering=16,
        DaysToSenescence=196,
        DaysToHarvest=402,
        DaysToMaxRooting=197,
        DaysToHIo=291,
        GDDaysToCCini=0,
        GDDaysToGermination=80,
        GDDaysToFullCanopy=669,
        GDDaysToFullCanopySF=669,
        GDDaysToFlowering=880,
        GDDLengthFlowering=180,
        GDDaysToSenescence=1400,
        GDDaysToHarvest=1700,
        GDDaysToMaxRooting=1409,
        GDDaysToHIo=750,
        WP=33.7,
        WPy=100,
        AdaptedToCO2=50,
        HI=48,
        dHIdt=0.16494845360824742,
        HIincrease=0,
        aCoeff=7,
        bCoeff=3,
        DHImax=15,
        DeterminancyLinked=true,
        fExcess=50,
        DryMatter=90,
        RootMinYear1=0,
        SownYear1=false,
        YearCCx=-9,
        CCxRoot=-9,
        Assimilates=AquaCrop.RepAssimilates(
            On=false,
            Period=0,
            Stored=0,
            Mobilized=0
        )
    )
    gvars[:crop] = crop

    
    gvars[:management].FertilityStress = 0
    gvars[:management].WeedShape = -0.01 
    gvars[:management].Cuttings.Considered = false 
    gvars[:management].Cuttings.CCcut = 30

    gvars[:onset].StartSearchDayNr = 33238 
    gvars[:onset].StopSearchDayNr = 33237 


    rain_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=1992,
        ToD=31,
        ToM=12,
        ToY=2023,
        FromDayNr=33238,
        ToDayNr=44925,
        FromString="",
        ToString="",
        NrObs=11688
    )
    gvars[:rain_record] = rain_record


    eto_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=1992,
        ToD=31,
        ToM=12,
        ToY=2023,
        FromDayNr=33238,
        ToDayNr=44925,
        FromString="",
        ToString="",
        NrObs=11688
    )
    gvars[:eto_record] = eto_record


    clim_record = AquaCrop.RepClim(
        Datatype=AquaCrop.undef_symbol, #0 note that this is 0 from undefined and not from actuall setting it
        FromD=1,
        FromM=1,
        FromY=1992,
        ToD=31,
        ToM=12,
        ToY=2023,
        FromDayNr=33238,
        ToDayNr=44925,
        FromString="",
        ToString="",
        NrObs=11688
    )
    gvars[:clim_record] = clim_record


    temperature_record = AquaCrop.RepClim(
        Datatype=:Daily, #0
        FromD=1,
        FromM=1,
        FromY=1992,
        ToD=31,
        ToM=12,
        ToY=2023,
        FromDayNr=33238,
        ToDayNr=44925,
        FromString="",
        ToString="",
        NrObs=11688
    )
    gvars[:temperature_record] = temperature_record


    crop_file_set = AquaCrop.RepCropFileSet(
        DaysFromSenescenceToEnd=25,
        DaysToHarvest=132,
        GDDaysFromSenescenceToEnd=300,
        GDDaysToHarvest=1700
    )
    gvars[:crop_file_set] = crop_file_set


    stresstot = AquaCrop.RepStressTot(
        Salt = 0,
        Temp = 0,
        Exp = 0,
        Sto = 0,
        Weed = 0,
        NrD = AquaCrop.undef_int
    )
    gvars[:stresstot] = stresstot


    gvars[:cut_info_record1].IntervalInfo = 0 
    gvars[:cut_info_record1].MassInfo = 0 

    gvars[:cut_info_record2].IntervalInfo = 0 
    gvars[:cut_info_record2].MassInfo = 0 


    AquaCrop.setparameter!(gvars[:bool_parameters], :temperature_file_exists, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :eto_file_exists, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :rain_file_exists, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :startmode, true) 
    AquaCrop.setparameter!(gvars[:bool_parameters], :evapo_entire_soil_surface, true) 

    
    AquaCrop.setparameter!(gvars[:integer_parameters], :daylastcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :last_irri_dap, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stagecode, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :suminterval, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :stress_sf_adj_new, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :previous_stress_level, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :daynri, 41750) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nextsim_from_daynr, AquaCrop.undef_int) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :tadj, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :nrcut, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :tnxreferenceyear, 2008) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :gddtadj, 0) 
    AquaCrop.setparameter!(gvars[:integer_parameters], :irri_interval, 1) 


    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop, 87.323737161553666) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkctop_stress, 87.323737161553666) 
    AquaCrop.setparameter!(gvars[:float_parameters], :co2i, 402.715) 

    AquaCrop.setparameter!(gvars[:float_parameters], :ccxtotal, 0.96) 
    AquaCrop.setparameter!(gvars[:float_parameters], :alfa_hi_adj, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddayi, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumeto, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddprev, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgddcuts, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxwitheredtpotnos, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumgdd, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb0salt, 0.43091894342471093) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccxcrop_weednosf_stress, 0.96) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmax, 11.1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb2salt, 0.004750558490899194) 
    AquaCrop.setparameter!(gvars[:float_parameters], :fweednos, 1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :yprevsum, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :rain, 1.1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :fracbiomasspotsf, 1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :tmin, 0.1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :eto, 1.5) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at2, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at2, 1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :scor_at1, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcdctotal, 0.01) 
    AquaCrop.setparameter!(gvars[:float_parameters], :coeffb1salt, 0.4160095549178092) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciprev, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbmob, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :timesenescence, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at, 1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previousbsto, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cciactual, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :ccototal, 0.007605) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumeto, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cgcref, 0.0983351294117647) 
    AquaCrop.setparameter!(gvars[:float_parameters], :rooting_depth, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :sumkci, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :bprevsum, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :hi_times_at1, 1) 
    AquaCrop.setparameter!(gvars[:float_parameters], :gddcgcref, 0.012494) 
    AquaCrop.setparameter!(gvars[:float_parameters], :previoussumgdd, 0) 
    AquaCrop.setparameter!(gvars[:float_parameters], :cdctotal, 0.01442417843464988) 


    Tmin = Float64[]
    Tmax = Float64[]
    open(joinpath(pwd(), "extended_test/fortranrun/DATA/uhk.Tnx")) do file
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
    open(joinpath(pwd(), "extended_test/fortranrun/DATA/uhk.ETo")) do file
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
    open(joinpath(pwd(), "extended_test/fortranrun/DATA/uhk.PLU")) do file
        for _ in 1:8
            readline(file)
        end
        for line in eachline(file)
            rain = parse(Float64, line)
            push!(Rain, rain)
        end
    end
    AquaCrop.setparameter!(gvars[:array_parameters], :Rain, Rain)



    open(joinpath(pwd(), "extended_test/fortranrun/SIMUL/EToData_proj1.SIM")) do file
        for line in eachline(file)
            eto = parse(Float64, line)
            AquaCrop.add_output_in_etodatasim!(outputs, eto)
        end
    end

    open(joinpath(pwd(), "extended_test/fortranrun/SIMUL/RainData_proj1.SIM")) do file
        for line in eachline(file)
            rain = parse(Float64, line)
            AquaCrop.add_output_in_raindatasim!(outputs, rain)
        end
    end

    open(joinpath(pwd(), "extended_test/fortranrun/SIMUL/TempData_proj1.SIM")) do file
        for line in eachline(file)
            splitedline = split(line)
            tlow = parse(Float64, popfirst!(splitedline))
            thigh = parse(Float64, popfirst!(splitedline))
            AquaCrop.add_output_in_tempdatasim!(outputs, tlow, thigh)
        end
    end

    return outputs, gvars
end

function checkpoint_project1_4()
    outputs, gvars = checkpoint_project1_3()

    # only check sumwabal since it has info about the final output
    sumwabal = AquaCrop.RepSum(
        Epot = 747.05971698428266,
        Tpot = 288.98065507497904,
        Rain = 722.90000000000055,
        Irrigation = 0,
        Infiltrated = 699.6397698920938,
        Runoff = 23.260230107906921,
        Drain = 136.15139188831836,
        Eact = 282.68593981505745,
        Tact = 288.98065507497904,
        TrW = 288.98065507497904,
        ECropCycle = 102.01291637570041,
        CRwater = 0,
        Biomass = 27.989140022304369,
        YieldPart = 13.442076960538923,
        BiomassPot = 28.246931690970094,
        BiomassUnlim = 28.246931690970094,
        BiomassTot = 27.989140022304369,
        SaltIn = 0,
        SaltOut = 0,
        CRsalt = 0
    )
    gvars[:sumwabal] = sumwabal

    return outputs, gvars
end

