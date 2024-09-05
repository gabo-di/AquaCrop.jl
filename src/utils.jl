Base.isapprox(a::Symbol, b::Symbol; kwargs...) = isequal(a, b)
Base.isapprox(a::String, b::String; kwargs...) = isequal(a, b)


"""
    day_nr = determine_day_nr(dayi, monthi, yeari) 

global.f90:2387
"""
function determine_day_nr(dayi, monthi, yeari)
    return trunc(Int, (yeari - 1901)*365.25 + ElapsedDays[monthi] + dayi + 0.05)
end

"""
    dayi, monthi, yeari = determine_date(dar_nr)

global.f90:2397
"""
function determine_date(day_nr::Int)
    yeari = trunc(Int, (day_nr-0.05)/365.25)
    sum_day_month = (day_nr - yeari*365.25)
    yeari = 1901 + yeari
    monthi = 1

    while (monthi < 12)
        if (sum_day_month <= ElapsedDays[monthi+1])
            break
        end
        monthi = monthi + 1
    end 
    dayi = round(Int, sum_day_month - ElapsedDays[monthi] + 0.25 + 0.06)
    return dayi, monthi, yeari
end

function determine_date(dd::Date)
    return day(dd), month(dd), year(dd)
end

function determine_date(dd::String)
    return determine_date(Date(dd))
end

"""
    leapyear = isleapyear(year)

global.f90:7100
"""
function isleapyear(year)
    leapyear = false
    if (year/4 - floor(year/4) <= 0.01) 
        leapyear = true
    end 
    return leapyear
end

"""
    ton

metric tonelad 1 ton = 1000 kg
Dimension: 𝐌
"""
@unit ton "ton" ton 1000u"kg" false true

const mm_ = Unit{:Meter, 𝐋}(-3, 1//1)
const m_ = Unit{:Meter, 𝐋}(0, 1//1)
const m_i2 = Unit{:Meter, 𝐋}(0, -2//1)
const m_i3 = Unit{:Meter, 𝐋}(0, -3//1)
const m_i1 = Unit{:Meter, 𝐋}(0, -1//1)
const d_ = Unit{:Day, 𝐓}(0, 1//1)
const K_ = Unit{:Kelvin, 𝚯}(0, 1//1)
const ppm_ = Unit{:Permillion, NoDims}(0, 1//1)
const ha_ = Unit{:Are, 𝐋^2}(2, 1//1)
const ha_i1 = Unit{:Are, 𝐋^2}(2, -1//1)
const dS_ = Unit{:Siemens, 𝐈^2*𝐓^3*𝐋^-2*𝐌^-1}(-1, 1//1)
const kg_ = Unit{:Gram, 𝐌}(3, 1//1)
const g_ = Unit{:Gram, 𝐌}(0, 1//1)
const ton_ = Unit{:ton, 𝐌}(0, 1//1)


const test_toml_dir = joinpath([dirname(@__DIR__), "test/testcase/TOML_FILES"])
const test_dir = joinpath([dirname(@__DIR__), "test/testcase"])
