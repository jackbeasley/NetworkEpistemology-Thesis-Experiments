using LightGraphs, JLD, DataFrames, GraphPlot, Colors, Cairo, Fontconfig, Compose
##
results_dir = "scc-results"

pictures_dir = "scc-pictures"

if !isdir(pictures_dir)
    mkdir(pictures_dir)
end

authorcites_regex = r"^(.*)_authorcites-scc(\d*).jld$"

result_files = [filename for filename in  readdir(results_dir) if match(authorcites_regex, filename) != nothing]

##
const Trial = NamedTuple{(:parent, :number, :results, :graph),Tuple{String, Int, BitArray{3}, SimpleDiGraph}}

function parse_and_open(filename::String, dir=results_dir)::Trial
    m = match(authorcites_regex, filename)
    if m === nothing
        error("file not results file")
    else
        jldopen(joinpath(dir, m.match), "r") do data
        return (parent=m[1], number=parse(Int, m[2]), results=read(data, "results"), graph=read(data, "graph"))
        end 
    end
end
##
authorcites_data = [parse_and_open(filename) for filename in result_files]
##
function plotgraph(t::Trial, trial_num, step, xlocs, ylocs)
    node_color = [colorant"red", colorant"green"]
    membership = t.results[trial_num, step, :] .+ 1
    nodefillc = node_color[membership]
    return gplot(t.graph, xlocs, ylocs, nodefillc=nodefillc, NODESIZE=0.005, arrowlengthfrac=0)
end

function make_graph(t::Trial, trial_num::Int, steps::Vector{Int}, layout=nothing)
    (xlocs, ylocs) = layout === nothing ? spring_layout(t.graph) : layout

    return vec([
        plotgraph(t, trial_num, step, xlocs, ylocs) 
        for step in steps])
end

function make_grid(plots::Vector{Compose.Context}, cols=2)
    print(typeof(plots))
    plt = vstack(
        [hstack(plots[i:min(i+cols-1, length(plots))]...)
         for i in 1:cols:length(plots)]...
    )
    return plt
end
##
trials_by_size = sort(authorcites_data, by=t->nv(t.graph))
##
second_largest = trials_by_size[end]
##
layout = spring_layout(second_largest.graph, C=4.0)
##
steps = vec([1, 5, 10, 50, 100, 500])
##
plts = make_graph(second_largest, 1, steps, layout)
##
draw(PNG(joinpath(pictures_dir, "peptic_ulcer_1-5-10-50-100-500.png"), 15cm, 15cm, dpi=300), make_grid(plts, 3))