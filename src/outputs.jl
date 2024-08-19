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
        "Rain" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "GD" => Quantity{Float64, 𝚯 *𝐓, FreeUnits{(d, K), 𝚯 *𝐓, nothing}}[],
        "CO2" => Quantity{Float64, NoDims, FreeUnits{(ppm,), NoDims, nothing}}[],
        "Irri" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Infilt" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Runoff" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Drain" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Upflow" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "E" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "E/Ex" => Float64[],
        "Tr" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "TrW" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Tr/TrW" => Float64[],
        "SaltIn" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltOut" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltUp" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltProf" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Cycle" => Quantity{Float64, 𝐓, FreeUnits{(d,), 𝐓, nothing}}[],
        "SaltStr" => Float64[],
        "FertStr" => Float64[],
        "WeedStr" => Float64[],
        "TempStr" => Float64[],
        "ExpStr" => Float64[],
        "StoStr" => Float64[],
        "BioMass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Brelative" => Float64[],
        "HI" => Float64[],
        "Y(dry)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Y(fresh)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "WPet" => Quantity{Float64, 𝐌 /𝐋^3, FreeUnits{(kg, m^-3), 𝐌 /𝐋^3, nothing}}[],
        "Bin" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Bout" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "DateN" => Date[]
    )

    harvestsout = DataFrame(
        "RunNr" => Int[],
        "Nr" => Int[],
        "Date" => Date[],
        "DAP" => Int[],
        "Interval" => Quantity{Float64, 𝐓, FreeUnits{(d,), 𝐓, nothing}}[],
        "Biomass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Sum(B)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Dry-Yield" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Sum(Y)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Fresh-Yield" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Sum(Y)_" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
    )

    dayout = DataFrame(
        "RunNr" => Int[],
        "Date" => Date[],
        "DAP" => Int[],
        "Stage" => Int[],
        "WC()" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Rain" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Irri" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Surf" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Infilt" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "RO" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Drain" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "CR" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Zgwt" => Quantity{Float64, 𝐋, FreeUnits{(m,), 𝐋, nothing}}[],
        "Ex" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "E" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "E/Ex" => Float64[],
        "GD" => {Quantity{Float64, 𝚯 *𝐓, FreeUnits{(d, K), 𝚯 *𝐓, nothing}}}[],
        "Z" => Quantity{Float64, 𝐋, FreeUnits{(m,), 𝐋, nothing}}[],
        "StExp" => Float64[],
        "StSto" => Float64[],
        "StSen" => Float64[],
        "StSalt" => Float64[],
        "StWeed" => Float64[],
        "CC" => Float64[],
        "CCw" => Float64[],
        "StTr" => Float64[],
        "Kc(Tr)" => Float64[],
        "Trx" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Tr" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "TrW" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Tr/TrW" => Float64[],
        "WP" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(g, m^-2), 𝐌 /𝐋^2, nothing}}[],
        "Biomass" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "HI" => Float64[],
        "Y(dry)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Y(fresh)" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Brelative" => Float64[],
        "WPet" => Quantity{Float64, 𝐌 /𝐋^3, FreeUnits{(kg, m^-3), 𝐌 /𝐋^3, nothing}}[],
        "Bin" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Bout" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "WC()_" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr()" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Z" => Quantity{Float64, 𝐋, FreeUnits{(m,), 𝐋, nothing}}[],
        "Wr" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(SAT)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(FC)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(exp)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(sto)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(sen)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Wr(PWP)" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "SaltIn" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltOut" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltUp" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Salt()" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "SaltZ" => Quantity{Float64, 𝐌 /𝐋^2, FreeUnits{(ha^-1, ton), 𝐌 /𝐋^2, nothing}}[],
        "Z_" => Quantity{Float64, 𝐋, FreeUnits{(m,), 𝐋, nothing}}[],
        "ECe" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m^-1, dS), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
        "ECsw" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m^-1, dS), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
        "StSalt" => Float64[],
        "Zgwt" => Quantity{Float64, 𝐋, FreeUnits{(m,), 𝐋, nothing}}[],
        "ECgw" => Quantity{Float64, 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, FreeUnits{(m^-1, dS), 𝐈^2*𝐓^3*𝐋^-3*𝐌 ^-1, nothing}}[],
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
        "Rain_" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "ETo" => Quantity{Float64, 𝐋, FreeUnits{(mm,), 𝐋, nothing}}[],
        "Tmin" => Quantity{Float64, 𝚯, FreeUnits{(K,), 𝚯, nothing}}[],
        "Tavg" => Quantity{Float64, 𝚯, FreeUnits{(K,), 𝚯, nothing}}[],
        "Tmax" => Quantity{Float64, 𝚯, FreeUnits{(K,), 𝚯, nothing}}[],
        "CO2" => Quantity{Float64, NoDims, FreeUnits{(ppm,), NoDims, nothing}}[],
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
