include("setup.jl")

using NetworkEpistemology
using LightGraphs, GraphIO, EzXML, Distributions, JLD

function TestBench.should_stop(stats::TransientDiversityStepStats)::Bool
    return false
end

jobDesc = parseJobDescription(ARGS)

graph = loadgraphs(jobDesc.graphIn, GraphIO.GraphML.GraphMLFormat())["digraph"]
get_scc(graphs, min_sz=5) = vcat([[g[s] for s in filter(scc->(length(scc) > min_sz), strongly_connected_components(g))] for g in graphs]...)
sccs = get_scc([graph], 4)

println("graph:'$(jobDesc.graphIn)', threads: $(Threads.nthreads())")

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
##
function results_to_bitmatrix(results::Matrix{TransientDiversityStepStats}, g::SimpleDiGraph)::BitArray{3}
    (numRuns, numSteps) = size(results)
    node_stats = trues(numRuns, numSteps, nv(g))
    for runNum in 1:numRuns, stepNum in 1:numSteps
        for n in results[runNum, stepNum].incorrectNodes
            node_stats[runNum, stepNum, n] = false
        end
    end
    return node_stats
end

##
for (i, g) in enumerate(sort(sccs, by=ne))
    results = results_to_bitmatrix(run_experiments([test_params(g) for _ in 1:1000], TransientDiversityStepStats, 10000), g)
    JLD.save(joinpath("scc-results", "$(jobDesc.graphName)-scc$(i).jld"), "results", results, "graph", g)
end

