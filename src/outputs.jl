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
    # tempdatasim = Dict(
    #                 :tlow => Float64[],
    #                 :thigh => Float64[])

    return Dict( 
        :logger => logger,
        :tcropsim => tcropsim,
        :etodatasim => etodatasim,
        :raindatasim => raindatasim,
        # :tempdatasim => tempdatasim,
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
