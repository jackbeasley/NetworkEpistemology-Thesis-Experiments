include("setup.jl")

using NetworkEpistemology
using LightGraphs, GraphIO, EzXML, Distributions, JLD2

function TestBench.should_stop(stats::TransientDiversityStepStats)::Bool
    return false
end

jobDesc = parseJobDescription(ARGS)

g = loadgraphs(jobDesc.graphIn, GraphIO.GraphML.GraphMLFormat())["digraph"]
scc_list = strongly_connected_components(g)
scc = g[scc_list[argmax(map(length, scc_list))]]

println("graph:'$(jobDesc.graphIn)', output: $(jobDesc.outFile), threads: $(Threads.nthreads())")

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

@time begin
    results = run_experiments([test_params(scc) for _ in 1:1000], TransientDiversityStepStats, 10000)
end

@save jobDesc.outFile results[1:10:1000, :] g scc
