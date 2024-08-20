"""
    outputs = start_outputs()

variable with the outputs of the program
"""
function start_outputs()
    logger = String[]
    tcropsim = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])
    etodatasim = Float64[]
    raindatasim = Float64[]
    tempdatasim = Dict(
                    :tlow => Float64[],
                    :thigh => Float64[])

    seasonout = DataFrame(
        "RunNr" => Int[],
        "Date1" => Date[],
        "Rain" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "GD" => Float64[],
        "CO2" => Quantity{Float64, NoDims, FreeUnits{(ppm_,), NoDims, nothing}}[],
        "Irri" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Infilt" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Runoff" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Drain" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Upflow" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "E" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "E/Ex" => Float64[],
        "Tr" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "TrW" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Tr/TrW" => Float64[],
        "SaltIn" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltOut" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltUp" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltProf" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Cycle" => Quantity{Float64, 𝐓, FreeUnits{(d_,), 𝐓, nothing}}[],
        "SaltStr" => Float64[],
        "FertStr" => Float64[],
        "WeedStr" => Float64[],
        "TempStr" => Float64[],
        "ExpStr" => Float64[],
        "StoStr" => Float64[],
        "BioMass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Brelative" => Float64[],
        "HI" => Float64[],
        "Y(dry)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Y(fresh)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "WPet" => Quantity{Float64, 𝐌 /𝐋^3, FreeUnits{(kg_, m_i3), 𝐌 /𝐋^3, nothing}}[],
        "Bin" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Bout" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "DateN" => Date[]
    )

    harvestsout = DataFrame(
        "RunNr" => Int[],
        "Nr" => Int[],
        "Date" => Date[],
        "DAP" => Int[],
        "Interval" => Quantity{Float64, 𝐓, FreeUnits{(d_,), 𝐓, nothing}}[],
        "Biomass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Sum(B)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Dry-Yield" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Sum(Y)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Fresh-Yield" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Sum(Y)_" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
    )

    dayout = DataFrame(
        "RunNr" => Int[],
        "Date" => Date[],
        "DAP" => Int[],
        "Stage" => Int[],
        "WC()" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Rain" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Irri" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Surf" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Infilt" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "RO" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Drain" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "CR" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Zgwt" => Quantity{Float64, 𝐋, FreeUnits{(m_,), 𝐋, nothing}}[],
        "Ex" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "E" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "E/Ex" => Float64[],
        "GD" => Float64[],
        "Z" => Quantity{Float64, 𝐋, FreeUnits{(m_,), 𝐋, nothing}}[],
        "StExp" => Float64[],
        "StSto" => Float64[],
        "StSen" => Float64[],
        "StSalt" => Float64[],
        "StWeed" => Float64[],
        "CC" => Float64[],
        "CCw" => Float64[],
        "StTr" => Float64[],
        "Kc(Tr)" => Float64[],
        "Trx" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Tr" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "TrW" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Tr/TrW" => Float64[],
        "WP" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(g_, m_i2), 𝐌 /𝐋^2, nothing}}[],
        "Biomass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "HI" => Float64[],
        "Y(dry)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Y(fresh)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Brelative" => Float64[],
        "WPet" => Quantity{Float64, 𝐌 /𝐋^3, FreeUnits{(kg_, m_i3), 𝐌 /𝐋^3, nothing}}[],
        "Bin" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Bout" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "WC()_" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr()" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Z" => Quantity{Float64, 𝐋, FreeUnits{(m_,), 𝐋, nothing}}[],
        "Wr" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(SAT)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(FC)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(exp)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(sto)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(sen)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Wr(PWP)" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "SaltIn" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltOut" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltUp" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Salt()" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "SaltZ" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha_i1, ton_), 𝐌 /𝐋^2, nothing}}[],
        "Z_" => Quantity{Float64, 𝐋, FreeUnits{(m_,), 𝐋, nothing}}[],
        "ECe" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m_i1, dS_), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
        "ECsw" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m_i1, dS_), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
        "StSalt" => Float64[],
        "Zgwt" => Quantity{Float64, 𝐋, FreeUnits{(m_,), 𝐋, nothing}}[],
        "ECgw" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m_i1, dS_), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
        "WC_1" => Float64[],
        "WC_2" => Float64[],
        "WC_3" => Float64[],
        "WC_4" => Float64[],
        "WC_5" => Float64[],
        "WC_6" => Float64[],
        "WC_7" => Float64[],
        "WC_8" => Float64[],
        "WC_9" => Float64[],
        "WC_10" => Float64[],
        "WC_11" => Float64[],
        "WC_12" => Float64[],
        "ECe_1" => Float64[],
        "ECe_2" => Float64[],
        "ECe_3" => Float64[],
        "ECe_4" => Float64[],
        "ECe_5" => Float64[],
        "ECe_6" => Float64[],
        "ECe_7" => Float64[],
        "ECe_8" => Float64[],
        "ECe_9" => Float64[],
        "ECe_10" => Float64[],
        "ECe_11" => Float64[],
        "ECe_12" => Float64[],
        "Rain_" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "ETo" => Quantity{Float64, 𝐋, FreeUnits{(mm_,), 𝐋, nothing}}[],
        "Tmin" => Quantity{Float64, 𝚯, FreeUnits{(K_,), 𝚯, nothing}}[],
        "Tavg" => Quantity{Float64, 𝚯, FreeUnits{(K_,), 𝚯, nothing}}[],
        "Tmax" => Quantity{Float64, 𝚯, FreeUnits{(K_,), 𝚯, nothing}}[],
        "CO2" => Quantity{Float64, NoDims, FreeUnits{(ppm_,), NoDims, nothing}}[],
    )

    return Dict( 
        :logger => logger,
        :tcropsim => tcropsim,
        :etodatasim => etodatasim,
        :raindatasim => raindatasim,
        :tempdatasim => tempdatasim,
        :seasonout => seasonout,
        :harvestsout => harvestsout,
        :dayout => dayout
    )
end


"""
    add_output_in_logger!(outputs, aux::String)
"""
function add_output_in_logger!(outputs, aux::String)
    push!(outputs[:logger], aux)
    return nothing
end

"""
    str = read_output_from_logger(outputs, i::Int)
"""
function read_output_from_logger(outputs, i::Int)
    return outputs[:logger][i]
end

"""
    flush_output_logger!(outputs)
"""
function flush_output_logger!(outputs)
    outputs[:logger] = String[]
    return nothing
end


"""
    add_output_in_tcropsim!(outputs, tlow::T, thigh::T) where T<:Number
"""
function add_output_in_tcropsim!(outputs, tlow::T, thigh::T) where T<:Number
    push!(outputs[:tcropsim][:tlow], tlow)
    push!(outputs[:tcropsim][:thigh], thigh) 
    return nothing
end

"""
    tlow, thigh = read_output_from_tcropsim(outputs, i::Int)
"""
function read_output_from_tcropsim(outputs, i::Int)
    return outputs[:tcropsim][:tlow][i], outputs[:tcropsim][:thigh][i]
end

"""
    flush_output_tcropsim!(outputs)
"""
function flush_output_tcropsim!(outputs)
    outputs[:tcropsim] = Dict(
                            :tlow => Float64[],
                            :thigh => Float64[])
    return nothing
end


"""
    add_output_in_etodatasim!(outputs, eto::T) where T<:Number
"""
function add_output_in_etodatasim!(outputs, eto::T) where T<:Number
    push!(outputs[:etodatasim], eto)
    return nothing
end

"""
    tlow, thigh = read_output_from_etodatasim(outputs, i::Int)
"""
function read_output_from_etodatasim(outputs, i::Int)
    return outputs[:etodatasim][i]
end

"""
    flush_output_etodatasim!(outputs)
"""
function flush_output_etodatasim!(outputs)
    outputs[:etodatasim] = Float64[]
    return nothing
end


"""
    add_output_in_raindatasim!(outputs, rain::T) where T<:Number
"""
function add_output_in_raindatasim!(outputs, rain::T) where T<:Number
    push!(outputs[:raindatasim], rain)
    return nothing
end

"""
    tlow, thigh = read_output_from_raindatasim(outputs, i::Int)
"""
function read_output_from_raindatasim(outputs, i::Int)
    return outputs[:raindatasim][i]
end

"""
    flush_output_raindatasim!(outputs)
"""
function flush_output_raindatasim!(outputs)
    outputs[:raindatasim] = Float64[]
    return nothing
end


"""
    add_output_in_tempdatasim!(outputs, tlow::T, thigh::T) where T<:Number
"""
function add_output_in_tempdatasim!(outputs, tlow::T, thigh::T) where T<:Number
    push!(outputs[:tempdatasim][:tlow], tlow)
    push!(outputs[:tempdatasim][:thigh], thigh) 
    return nothing
end

"""
    tlow, thigh = read_output_from_tempdatasim(outputs, i::Int)
"""
function read_output_from_tempdatasim(outputs, i::Int)
    return outputs[:tempdatasim][:tlow][i], outputs[:tempdatasim][:thigh][i]
end

"""
    flush_output_tempdatasim!(outputs)
"""
function flush_output_tempdatasim!(outputs)
    outputs[:tempdatasim] = Dict(
                            :tlow => Float64[],
                            :thigh => Float64[])
    return nothing
end

"""
    add_output_in_seasonout!(outputs, arr)
"""
function add_output_in_seasonout!(outputs, arr)
    if length(arr) == 39
        new_row = Dict(
            "RunNr" => arr[1],
            "Date1" => Date(arr[2], arr[3], arr[4]),
            "Rain" => arr[5]*u"mm",
            "GD" => arr[6],
            "CO2" => arr[7]*u"ppm",
            "Irri" => arr[8]*u"mm",
            "Infilt" => arr[9]*u"mm",
            "Runoff" => arr[10]*u"mm",
            "Drain" => arr[11]*u"mm",
            "Upflow" => arr[12]*u"mm",
            "E" => arr[13]*u"mm",
            "E/Ex" => arr[14],
            "Tr" => arr[15]*u"mm",
            "TrW" => arr[16]*u"mm",
            "Tr/TrW" => arr[17],
            "SaltIn" => arr[18]*ton*u"ha^-1",
            "SaltOut" => arr[19]*ton*u"ha^-1",
            "SaltUp" => arr[20]*ton*u"ha^-1",
            "SaltProf" => arr[21]*ton*u"ha^-1",
            "Cycle" => arr[22]*u"d",
            "SaltStr" => arr[23],
            "FertStr" => arr[24],
            "WeedStr" => arr[25],
            "TempStr" => arr[26],
            "ExpStr" => arr[27],
            "StoStr" => arr[28],
            "BioMass" => arr[29]*ton*u"ha^-1",
            "Brelative" => arr[30],
            "HI" => arr[31],
            "Y(dry)" => arr[32]*ton*u"ha^-1",
            "Y(fresh)" => arr[33]*ton*u"ha^-1",
            "WPet" => arr[34]*u"kg/m^3",
            "Bin" => arr[35]*ton*u"ha^-1",
            "Bout" => arr[36]*ton*u"ha^-1",
            "DateN" => Date(arr[37], arr[38], arr[39])
        )
        push!(outputs[:seasonout], new_row)
    end
    return nothing
end

"""
    read_output_from_seasonout(outputs, i::Int)
"""
function read_output_from_seasonout(outputs, i::Int)
    return outputs[:seasonout, i]
end

"""
    flush_output_seasonout!(outputs)
"""
function flush_output_seasonout!(outputs)
    empty!(outputs[:seasonout])
    return nothing
end

"""
    add_output_in_harvestsout!(outputs, arr)
"""
function add_output_in_harvestsout!(outputs, arr)
    if length(arr) == 13
        new_row = Dict(
            "RunNr" => arr[1],
            "Nr" => arr[2],
            "Date" => Date(arr[3], arr[4], arr[5]),
            "DAP" => arr[6],
            "Interval" => arr[7]*u"d",
            "Biomass" => arr[8]*ton*u"ha^-1",
            "Sum(B)" => arr[9]*ton*u"ha^-1",
            "Dry-Yield" => arr[10]*ton*u"ha^-1",
            "Sum(Y)" => arr[11]*ton*u"ha^-1",
            "Fresh-Yield" => arr[12]*ton*u"ha^-1",
            "Sum(Y)_" => arr[13]*ton*u"ha^-1",
        )
        push!(outputs[:harvestsout], new_row)
    end
    return nothing
end

"""
    read_output_from_harvestsout(outputs, i::Int)
"""
function read_output_from_harvestsout(outputs, i::Int)
    return outputs[:harvestsout, i]
end

"""
    flush_output_harvestsout!(outputs)
"""
function flush_output_harvestsout!(outputs)
    empty!(outputs[:harvestsout])
    return nothing
end

"""
    add_output_in_dayout(outputs, arr)
"""
function add_output_in_dayout(outputs, arr)
    if length(arr) == 93
        new_row = Dict(
            "RunNr" => arr[1],
            "Date" => Date(arr[2], arr[3], arr[4]),
            "DAP" => arr[5],
            "Stage" => arr[6],
            "WC()" => arr[7]*u"mm",
            "Rain" => arr[8]*u"mm",
            "Irri" => arr[9]*u"mm",
            "Surf" => arr[10]*u"mm",
            "Infilt" => arr[11]*u"mm",
            "RO" => arr[12]*u"mm",
            "Drain" => arr[13]*u"mm",
            "CR" => arr[14]*u"mm",
            "Zgwt" => arr[15]*u"m",
            "Ex" => arr[16]*u"mm",
            "E" => arr[17]*u"mm",
            "E/Ex" => arr[18],
            "GD" => arr[19],
            "Z" => arr[20]*u"m",
            "StExp" => arr[21],
            "StSto" => arr[22],
            "StSen" => arr[23],
            "StSalt" => arr[24],
            "StWeed" => arr[25],
            "CC" => arr[26],
            "CCw" => arr[27],
            "StTr" => arr[28],
            "Kc(Tr)" => arr[29],
            "Trx" => arr[30]*u"mm",
            "Tr" => arr[31]*u"mm",
            "TrW" => arr[32]*u"mm",
            "Tr/TrW" => arr[33],
            "WP" => arr[34]*u"g/m^2",
            "Biomass" => arr[35]*ton*"ha^-1",
            "HI" => arr[36],
            "Y(dry)" => arr[37]*ton*"ha^-1",
            "Y(fresh)" => arr[38]*ton*"ha^-1",
            "Brelative" => arr[39],
            "WPet" => arr[40]*u"kg/m^3",
            "Bin" => arr[41]*ton*"ha^-1",
            "Bout" => arr[42]*ton*"ha^-1",
            "WC()_" => arr[43]*u"mm",
            "Wr()" => arr[44]*u"mm",
            "Z" => arr[45]*u"m",
            "Wr" => arr[46]*u"mm",
            "Wr(SAT)" => arr[47]*u"mm",
            "Wr(FC)" => arr[48]*u"mm",
            "Wr(exp)" => arr[49]*u"mm",
            "Wr(sto)" => arr[50]*u"mm",
            "Wr(sen)" => arr[51]*u"mm",
            "Wr(PWP)" => arr[52]*u"mm",
            "SaltIn" => arr[53]*ton*"ha^-1",
            "SaltOut" => arr[54]*ton*"ha^-1",
            "SaltUp" => arr[55]*ton*"ha^-1",
            "Salt()" => arr[56]*ton*"ha^-1",
            "SaltZ" => arr[57]*ton*"ha^-1",
            "Z_" => arr[58]*u"m",
            "ECe" => arr[59]*u"dS/m",
            "ECsw" => arr[60]*u"dS/m",
            "StSalt" => arr[61],
            "Zgwt" => arr[62]*u"m",
            "ECgw" => arr[63]*u"dS/m",
            "WC_1" => arr[64],
            "WC_2" => arr[65],
            "WC_3" => arr[66],
            "WC_4" => arr[67],
            "WC_5" => arr[68],
            "WC_6" => arr[69],
            "WC_7" => arr[70],
            "WC_8" => arr[71],
            "WC_9" => arr[72],
            "WC_10" => arr[73],
            "WC_11" => arr[74],
            "WC_12" => arr[75],
            "ECe_1" => arr[76],
            "ECe_2" => arr[77],
            "ECe_3" => arr[78],
            "ECe_4" => arr[79],
            "ECe_5" => arr[80],
            "ECe_6" => arr[81],
            "ECe_7" => arr[82],
            "ECe_8" => arr[83],
            "ECe_9" => arr[84],
            "ECe_10" => arr[85],
            "ECe_11" => arr[86],
            "ECe_12" => arr[87],
            "Rain_" => arr[88]*u"mm",
            "ETo" => arr[89]*u"mm",
            "Tmin" => arr[90]*u"C",
            "Tavg" => arr[91]*u"C",
            "Tmax" => arr[92]*u"C",
            "CO2" => arr[93]*u"ppm",
        )
        push!(outputs[:dayout], new_row)
    end
    return nothing
end

"""
    read_output_from_dayout(outputs, i::Int)
"""
function read_output_from_dayout(outputs, i::Int)
    return outputs[:dayout, i]
end

"""
    flush_output_dayout!(outputs)
"""
function flush_output_dayout!(outputs)
    empty!(outputs[:dayout])
    return nothing
end
