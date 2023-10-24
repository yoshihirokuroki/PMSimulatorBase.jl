using PMEvents
using Documenter

DocMeta.setdocmeta!(PMEvents, :DocTestSetup, :(using PMEvents); recursive=true)

makedocs(;
    modules=[PMEvents],
    authors="Tim Knab",
    repo="https://github.com/timknab/PMEvents.jl/blob/{commit}{path}#{line}",
    sitename="PMEvents.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://timknab.github.io/PMEvents.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/timknab/PMEvents.jl",
    devbranch="main",
)
