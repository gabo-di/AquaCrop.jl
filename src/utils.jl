Base.isapprox(a::Symbol, b::Symbol; kwargs...) = isequal(a, b)
Base.isapprox(a::String, b::String; kwargs...) = isequal(a, b)
