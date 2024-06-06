"""
    outputs = start_outputs()

variable with the outputs of the program
"""
function start_outputs()
    logger = String[]
    tcropsim = ComponentArray(
                    tlow = Float64[],
                    thig = Float64[])

    return ComponentArray( 
        logger = logger,
        tcropsim = tcropsim,
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
