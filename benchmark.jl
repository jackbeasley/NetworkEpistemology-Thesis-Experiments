using NetworkEpistemology

using LightGraphs, Distributions, DataFrames, HypothesisTests, RCall
@rlibrary ggplot2

function TestBench.should_stop(stats::TransientDiversityStepStats)::Bool
    return false
end

function test_params(graph::LightGraphs.SimpleDiGraph)
    binomial_probs = [0.5, 0.499]
    return TransientDiversityModelState(
            SimpleDiGraph(graph),
            BinomialActionFacts{2}(binomial_probs, 1000),
            [BetaIndividual{2}(BetaBeliefs{2}(
                [rand(Uniform(0, 4)) for _ = 1:length(binomial_probs)], 
                [rand(Uniform(0, 4)) for _ = 1:length(binomial_probs)]
                )) for i in 1:nv(graph)]
        )
end

function time_for_sim(g::LightGraphs.SimpleDiGraph, steps::Int = 100)
    return 1000 * @elapsed NetworkEpistemology.run_trial(test_params(g), TransientDiversityStepStats, steps)
end

function timing_experiment(g::LightGraphs.SimpleDiGraph, name::String, trials::Int, steps::Int = 100)
    data = [time_for_sim(g, steps) for _ in 1:trials]
    (low, high) = confint(OneSampleTTest(data); level=0.95)
    return (name, nv(g), ne(g), mean(data), low, high)
end

##

function valdiate_graph(graph, name::String, sizes::AbstractVector{Int}, trials::Integer, steps::Integer)
    return [timing_experiment(SimpleDiGraph(graph(size)), name, trials, steps) for size in sizes]
end

range = vcat([10], collect(100:100:1000))
##
cycle_results = valdiate_graph(cycle_graph, "Cycle", range, 5, 100)
##
wheel_results = valdiate_graph(wheel_graph, "Wheel", range, 5, 100)
##
complete_results = valdiate_graph(complete_graph, "Complete", range, 5, 100)
##

benchmarks = DataFrame(
    GraphType = String[],
    Nodes = Int[],
    Edges = Int[],
    MeanRuntime = Float64[],
    MinRuntime = Float64[],
    MaxRuntime = Float64[]
)

for res in vcat(cycle_results, wheel_results, complete_results)
    push!(benchmarks, res)
end
benchmarks
##
nv_bench_plt = ggplot(benchmarks, aes(y=:MeanRuntime,x=:Nodes, color=:GraphType)) + 
    geom_smooth(aes(ymin=:MinRuntime, ymax=:MaxRuntime, fill=:GraphType, color=:GraphType, stat = "identity")) +
    xlab("Number of nodes") + ylab("Runtime for 100 steps (ms)") + labs(color="Graph Type", fill="Graph Type") + 
    ggtitle("Runtime for 100 Simulation Steps by Graph Node Count")

ggsave("node_count_benchmarks.png", plot=nv_bench_plt, width=5, height=4, unit="in")
##
ne_bench_plt = ggplot(benchmarks, aes(y=:MeanRuntime,x=:Edges, color=:GraphType)) + 
    geom_smooth(aes(ymin=:MinRuntime, ymax=:MaxRuntime, fill=:GraphType, stat = "identity")) +
    xlab("Number of edges") + ylab("Runtime for 100 steps (ms)") + labs(color="Graph Type", fill="Graph Type") + 
    ggtitle("Runtime for 100 Simulation Steps by Graph Edge Count")

ggsave("edge_count_benchmarks.png", plot=ne_bench_plt, width=5, height=4, unit="in")
##



graphs = DataFrame(
    GraphType = String[],
    NumberNodes = Int[],
    NumberEdges = Int[],
)
for size in range
    g = cycle_graph(size)
    push!(graphs, ("Cycle", nv(g), ne(g)))
end
for size in range
    g = wheel_graph(size)
    push!(graphs, ("Wheel", nv(g), ne(g)))
end
for size in range
    g = complete_graph(size)
    push!(graphs, ("Complete", nv(g), ne(g)))
end
graphs
##
ggplot(graphs, aes(y=:NumberEdges,x=:NumberNodes, color=:GraphType)) +
    geom_point() +
    xlab("Number of nodes") + ylab("Number of edges") + 
    ggtitle(""
ggsave("graphs.png")
