using NetworkEpistemology
using LightGraphs, GraphIO, TikzGraphs, EzXML, Distributions, JLD2

function TestBench.should_stop(stats::TransientDiversityStepStats)::Bool
    return false
end
##
g = loadgraphs("graphs/phonetics_authorcites.graphml", GraphIO.GraphML.GraphMLFormat())["digraph"]

##

get_scc(graphs, min_sz=5) = vcat([[g[s] for s in filter(scc->(length(scc) > min_sz), strongly_connected_components(g))] for g in graphs]...)
sccs = get_scc([g],5)

##
p = TikzGraphs.plot(sccs[3], Layouts.SimpleNecklace())
##
@load "zollman-results/abstract_algebra_authorcites.jld2" results g scc
##
results[1:10:1000, :]
##
scc