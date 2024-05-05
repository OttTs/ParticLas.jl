#=
Creates a standalone app.
During Compilation, ParticLas is started in order to precompile all needed methods.
Thus, please click on everything before exiting!
The destination path can be adjusted with "dst"
=#

using PackageCompiler

pkg_path = string(split(@__DIR__, "scripts")[1])
dst = string(pkg_path, "ParticLasApp") # Adjust to change path of app

PackageCompiler.create_app(pkg_path, dst, 
    precompile_execution_file="precompile.jl",
    include_lazy_artifacts=true,
    force=true
)