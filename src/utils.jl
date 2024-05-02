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
function determine_date(day_nr)
    yeari = trunc(Int, (day_nr-0.05)/365.25)
    sum_day_month = (day_nr - yeari*365.25)
    yeari = 1901 + yeari
    monthi = 1

    while (monthi < 12)
        if (sum_day_month <= ElapsedDays[monthi+1]) break
        monthi = monthi + 1
    end 
    dayi = round(Int, sum_day_month - ElapsedDays[monthi] + 0.25 + 0.06)
    return dayi, monthi, yeari
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

