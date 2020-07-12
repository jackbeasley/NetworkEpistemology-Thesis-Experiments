using Pkg

Pkg.activate(pwd())

struct JobDescription
    graphIn::String
    graphName::String
    outFolder::String
    outFilename::String
    outFile::String
end

function parseJobDescription(args::AbstractVector{String})::JobDescription
    graph_in = args[1]
    graphname = splitext(basename(graph_in))[1]
    out_folder = length(ARGS) >= 2 ? args[2] : "."
    out_filename = "$(graphname).jld2"
    outfile = joinpath(out_folder, out_filename)

    return JobDescription(graph_in, graphname, out_folder, out_filename, outfile)
end
