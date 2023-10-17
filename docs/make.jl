using MMEvents
using Documenter

DocMeta.setdocmeta!(MMEvents, :DocTestSetup, :(using MMEvents); recursive=true)

makedocs(;
    modules=[MMEvents],
    authors="Tim Knab",
    repo="https://github.com/timknab/MMEvents.jl/blob/{commit}{path}#{line}",
    sitename="MMEvents.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://timknab.github.io/MMEvents.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/timknab/MMEvents.jl",
    devbranch="main",
)
