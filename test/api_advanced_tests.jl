using AquaCrop
using Test

using DataFrames
using Dates
using StableRNGs

rng = StableRNG(42)

# Function to create a mockup climate DataFrame
function create_mock_climate_dataframe(start_date::Date, end_date::Date, tmin, delta_t, eto, rain)
    # Generate the date range
    dates = collect(start_date:end_date)

    # Generate random climate columns (each column has the same number of rows as the date range)
    Tmin = tmin .+ rand(rng, length(dates))
    Tmax = Tmin .+ delta_t .+ rand(rng, length(dates))
    ETo = eto .* abs.(randn(rng, length(dates)))
    Rain = rain .* abs.(randn(rng, length(dates)))

    # Create the DataFrame
    df = DataFrame(
        Date = dates,
        Tmin = Tmin,
        Tmax = Tmax,
        ETo = ETo,
        Rain = Rain
    )

    return df
end

@testset "Cropfield advanced happy path" begin

    # Generate ficticius climate data
    start_date = Date(2023, 1, 1) # January 1 2023
    end_date = Date(2023, 6, 1) # June 1 2023
    tmin = 15
    delta_t = 10
    eto = 1
    rain = 1

    df = create_mock_climate_dataframe(start_date, end_date, tmin, delta_t, eto, rain)

    # Generate the keyword object for the simulation
    kwargs = (

        ## Necessary keywords

        # runtype
        runtype = NoFileRun(),

        # project input
        Simulation_DayNr1 = start_date,
        Simulation_DayNrN = end_date,
        Crop_Day1 = start_date + Week(1),
        Crop_DayN = end_date,

        # soil
        soil_type = "clay",

        # crop
        crop_type = "maize",

        # Climate
        InitialClimDate = start_date,



        ## Optional keyworkds

        # Climate
        Tmin = df.Tmin,
        Tmax = df.Tmax,
        ETo = df.ETo,
        Rain = df.Rain,

        # change soil properties
        soil_layers = Dict("Thickness" => 5.0)


    )

    # start cropfield
    cropfield, all_ok = start_cropfield(; kwargs...)
    @testset "start cropfield" begin
        @test isequal(all_ok.logi, true)
    end

    # daily update cropfield
    ndays = 30
    for _ in 1:ndays
        dailyupdate!(cropfield)
    end
    @testset "daily update cropfield" begin
        @test isequal(size(cropfield.dayout), (ndays, 89))
    end

    # check if harvestable
    logi = isharvestable(cropfield)
    th = timetoharvest(cropfield)
    @testset "non harvestable yet" begin
        @test isequal(logi, false)
        @test isequal(th, 56)
    end

    for i in 1:th
        dailyupdate!(cropfield)
    end
    logi = isharvestable(cropfield)
    @testset "harvestable" begin
        @test isequal(logi, true)
    end


    # harvest cropfield
    harvest!(cropfield)
    @testset "harvest cropfield" begin
        @test isequal(size(cropfield.dayout), (ndays+1+th, 89))
        @test isequal(size(cropfield.harvestsout), (2, 11))
    end



    # change climate data
    daynri_now = cropfield.gvars[:integer_parameters][:daynri]
    day_now, month_now, year_now = AquaCrop.determine_date(daynri_now)
    date_now = Date(year_now, month_now, day_now)
    df_new = create_mock_climate_dataframe(date_now, end_date, tmin, delta_t, eto, rain)
    change_climate_data!(cropfield, df_new; kwargs...)
    @testset "change climate date cropfield" begin
        @test isapprox(cropfield.gvars[:float_parameters][:eto], df_new.ETo[1])
        @test isapprox(cropfield.gvars[:float_parameters][:rain], df_new.Rain[1])
        @test isapprox(cropfield.gvars[:float_parameters][:tmin], df_new.Tmin[1])
        @test isapprox(cropfield.gvars[:float_parameters][:tmax], df_new.Tmax[1])
    end

    # run until end of season
    season_run!(cropfield)
    @testset "season run cropfield" begin
        total_days = length(collect(start_date:end_date))
        @test isequal(size(cropfield.dayout), (total_days, 89))
    end

end
