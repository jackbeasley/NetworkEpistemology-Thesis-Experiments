include("load_graphs.jl")

using LightGraphs, DataFrames, HypothesisTests, RCall, Statistics
@rlibrary ggplot2
@rlibrary scales

## Basic comparison of graphs based on nodes and edges
## Conclusion: empirical graphs fall in the huge area between complete and wheel, especially at large sizes
scc_nodes_and_edges = DataFrame(
    Type = String[],
    Nodes = Int[],
    Edges = Int[],
    Density = Float64[]
)
scc_graphs = []
for (type, desc, g) in empirical_graphs
    for set in strongly_connected_components(g)
        if length(set) > 1
            sub_graph = g[set]
            push!(scc_graphs, sub_graph)
            if ne(sub_graph) > (nv(sub_graph)*(nv(sub_graph)-1))
                println("warn")
            end
            push!(scc_nodes_and_edges, (type, nv(sub_graph), ne(sub_graph), density(sub_graph)))
        end
    end
end
scc_nodes_and_edges
##
nodes_and_edges = DataFrame(
    Type = map(t->t.type, empirical_graphs),
    Nodes = map(t->nv(t.graph), empirical_graphs),
    Edges = map(t->ne(t.graph), empirical_graphs),
    Density = map(t->density(t.graph), empirical_graphs)
)

for size in 3:maximum(g->nv(g.graph), empirical_graphs)
    push!(nodes_and_edges, ("cycle", size, size*2, 1 / (size - 1)))
end
for size in 4:maximum(g->nv(g.graph), empirical_graphs)
    push!(nodes_and_edges, ("wheel", size, 4*(size-1), (4*(size-1)) / (size*(size - 1))))
end
for size in 2:maximum(g->nv(g.graph), empirical_graphs)
    push!(nodes_and_edges, ("complete", size, (size*(size - 1)), 1))
end

cycle = filter(row->row.Type == "cycle", nodes_and_edges)
wheel = filter(row->row.Type == "wheel", nodes_and_edges)
complete = filter(row->row.Type == "complete", nodes_and_edges)
authorcites = filter(row->row.Type == "authorcites", nodes_and_edges)
authorcites_scc = filter(row->row.Type == "authorcites", scc_nodes_and_edges)
coauthor = filter(row->row.Type == "coauthor", nodes_and_edges)
coauthor_scc = filter(row->row.Type == "coauthor", scc_nodes_and_edges)
##
node_edge_plt = ggplot() + 
    geom_line(aes(y=cycle.Edges,x=cycle.Nodes, color="Cycle")) +
    geom_line(aes(y=wheel.Edges,x=wheel.Nodes, color="Wheel")) +
    geom_line(aes(y=complete.Edges,x=complete.Nodes, color="Complete")) + 
    geom_point(size=0.2, aes(y=authorcites.Edges,x=authorcites.Nodes, color="AuthorCites")) + 
    geom_point(size=0.2, aes(y=authorcites_scc.Edges,x=authorcites_scc.Nodes, color="AuthorCites SCCs")) + 
    geom_point(size=0.2, aes(y=coauthor.Edges,x=coauthor.Nodes, color="Coauthor")) + 
    geom_point(size=0.2, aes(y=coauthor_scc.Edges,x=coauthor_scc.Nodes, color="Coauthor SCCs")) + 
    scale_x_continuous(trans="log2") +
    scale_y_continuous(trans="log2") +
    ylab("Number Directed Edges") + xlab("Number Nodes") + 
    ggtitle("Node-Edge Counts by Graph Type")

ggsave(filename="node_edge_plot.png", plot=node_edge_plt, width=5, height=4, unit="in")

##
density_node_plt = ggplot() + 
    geom_line(aes(y=cycle.Density,x=cycle.Nodes, color="Cycle")) +
    geom_line(aes(y=wheel.Density,x=wheel.Nodes, color="Wheel")) +
    geom_line(aes(y=complete.Density,x=complete.Nodes, color="Complete")) + 
    geom_point(size=0.2, aes(y=authorcites.Density,x=authorcites.Nodes, color="AuthorCites")) + 
    geom_point(size=0.2, aes(y=authorcites_scc.Density,x=authorcites_scc.Nodes, color="AuthorCites SCCs")) + 
    geom_point(size=0.2, aes(y=coauthor.Density,x=coauthor.Nodes, color="Coauthor")) + 
    geom_point(size=0.2, aes(y=coauthor_scc.Density,x=coauthor_scc.Nodes, color="Coauthor SCCs")) + 
    scale_x_continuous(trans="log2") +
    scale_y_continuous(trans="log2", breaks = breaks_log(6), labels = label_number(accuracy = 0.0001)) +
    ylab("Density") + xlab("Number Nodes") + 
    ggtitle("Density vs. Node Count by Graph Type")

ggsave(filename="node_density_plot.png", plot=density_node_plt, width=5, height=4, unit="in")

## Normalized degree distributions

function get_degree_dist(graphs)
    max_deg = maximum([maximum(degree(g)) for g in graphs])

    deg_counts = zeros(Int, (max_deg, length(graphs)))
    for (i, g) in enumerate(graphs)
        for d in degree(g)
            deg_counts[d, i] += 1
        end
    end
    return collect(zip(sum(deg_counts, dims=2), mean(deg_counts, dims=2)))
end
res = get_degree_dist(scc_graphs)
##
get_scc(graphs, min_sz=5) = vcat([[g.graph[s] for s in filter(scc->(length(scc) > min_sz), strongly_connected_components(g.graph))] for g in graphs]...)
authorcites_scc_graphs = get_scc(filter(t->(t.type == "authorcites"), empirical_graphs))
coauthor_scc_graphs = get_scc(filter(t->(t.type == "coauthor"), empirical_graphs))
##

degree_counts = DataFrame(
    Type = String[],
    Degree = Int[],
    SumCounts = Int[],
    MeanCount = Float64[]
)

for (d, (sum, mean)) in enumerate(get_degree_dist(coauthor_scc_graphs))
    push!(degree_counts, ("Coauthor", d, sum, mean))
end
for (d, (sum, mean)) in enumerate(get_degree_dist(authorcites_scc_graphs))
    push!(degree_counts, ("AuthorCites", d, sum,mean))
end

degree_counts
##

scc_deg_dist = ggplot(degree_counts, aes(x=:Degree, y=:SumCounts, color=:Type, shape=:Type)) +
    geom_point() + 
    scale_x_continuous(trans="log2") +
    scale_y_continuous(trans="log2") +
    ylab("Count for all SCCs") + xlab("Node Degree") + 
    ggtitle("Degree Distributions of SCCs")

ggsave(filename="scc_degree_distribution.png", plot=scc_deg_dist, width=5, height=4, unit="in")
