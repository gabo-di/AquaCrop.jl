using AquaCrop
using Documenter

DocMeta.setdocmeta!(AquaCrop, :DocTestSetup, :(using AquaCrop); recursive=true)

makedocs(;
    modules=[AquaCrop],
    authors="Gabriel Diaz <gabriel.diaz.iturry@gmail.com>",
    sitename="AquaCrop.jl",
    format=Documenter.HTML(;
        canonical="https://gabo-di.github.io/AquaCrop.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/gabo-di/AquaCrop.jl",
    devbranch="main",
)