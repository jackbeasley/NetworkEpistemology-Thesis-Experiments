using LightGraphs, JLD, HypothesisTests, Statistics, DataFrames, RCall
@rlibrary ggplot2
##
results_dir = "scc-results"


authorcites_regex = r"^(.*)_authorcites-scc(\d*).jld$"
result_files = [file for file in readdir(results_dir) if match(authorcites_regex, file) !== nothing]

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
function probability_convergence(t::Trial)::DataFrame
    converged_by_run = vec(sum(t.results[:, end, :], dims=2) .== nv(t.graph))

    (min, max) = confint(BinomialTest(converged_by_run))

    return DataFrame(
        Parent = [t.parent],
        Density = [density(t.graph)],
        Nodes = [nv(t.graph)],
        GraphType = [nv(t.graph) > 150 ? "$(t.parent)-large" : t.parent],
        MinProb = [min],
        MeanProb = [mean(converged_by_run)],
        MaxProb = [max]
    )
end

function plot_probability_convergence(d::DataFrame)
    return ggplot(d, aes(x=:Density, y=:MeanProb, color=:GraphType)) + 
        geom_point() + 
        geom_errorbar(aes(ymin=:MinProb, ymax=:MaxProb)) + 
        xlab("Graph density (e/(v(v-1)))") + ylab("Successful Convergence Probability") + 
        ggtitle("Convergence vs. Density of SCCs")
end

data = reduce(vcat, map(probability_convergence, authorcites_data))
##
prb_density_plt = plot_probability_convergence(data)
prb_density_plt = ggsave(filename="converge_prb_density.png", plot=prb_density_plt, width=5, height=4, unit="in")
##

function typename(t::Trial) 
    if nv(t.graph) > 150
        return "$(t.parent)-large"
    elseif nv(t.graph) < 50
        "$(t.parent)-small"
    end
end

function convergence(t::Trial)::DataFrame
    convergence_fractions = dropdims(mean(t.results, dims=3), dims=3)

    means = vec(mean(convergence_fractions, dims=1)[1:10000])
    res = map(col->confint(OneSampleTTest(col)), collect(eachcol(convergence_fractions))[1:10000])
    mins = vec(map(t->t[1], res))
    maxes = vec(map(t->t[2], res))



    return DataFrame(
        Type = repeat([typename(t)], length(means)),
        Nodes = repeat([nv(t.graph)], length(means)),
        Step = 1:length(means),
        MinConverged = mins,
        MeanConverged = means,
        MaxConverged = maxes
    )
end
function plot_convergence(d::DataFrame)
    return ggplot(d, aes(x=:Step, y=:MeanConverged, color=:Type)) + 
        geom_line() + 
        geom_smooth(
            aes(ymin=:MinConverged, ymax=:MaxConverged, fill=:Type, color=:Type),
            stat = "identity") +
        xlab("Model Step") + ylab("Ratio of agents converged") + 
        ggtitle("Convergence Speed of SCCs")
end
##

unique(map(t->nv(t.graph), authorcites_data))
##

large_graphs = filter(t->nv(t.graph) > 150, authorcites_data)
small_graphs = unique(t->t.parent, filter(t->nv(t.graph) < 50, authorcites_data))
results = reduce(vcat, map(convergence, vcat(large_graphs, small_graphs)))
##
converge_speed_plt = plot_convergence(results)
ggsave(filename="converge_speed.png", plot=converge_speed_plt, width=5, height=4, unit="in")

