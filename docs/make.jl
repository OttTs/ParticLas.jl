using Documenter#, ParticLas

makedocs(
    sitename="ParticLas",
    pages = [
        "Home" => "index.md",
    ]
)

deploydocs(
    repo = "github.com/OttTs/ParticLas.jl.git"
)