using LightGraphs, EzXML, GraphIO

to_named_tuple(tuples) = map(t->(; zip((:type, :description, :graph), t)...), tuples)

size_range = 4:12
cycle_graphs = to_named_tuple(zip(
    ["cycle" for _ in size_range],
    map(string, size_range),
    [SimpleDiGraph(cycle_graph(size)) for size in size_range]
))
wheel_graphs = to_named_tuple(zip(
    ["wheel" for _ in size_range],
    map(string, size_range),
    [SimpleDiGraph(wheel_graph(size)) for size in size_range]
))
complete_graphs = to_named_tuple(zip(
    ["complete" for _ in size_range],
    map(string, size_range),
    [SimpleDiGraph(complete_graph(size)) for size in size_range]
))

zollman_graphs = vcat(cycle_graphs, wheel_graphs, complete_graphs)

##
graphs_folder = "graphs"

authorcites_regex = r"^(.*)_authorcites.graphml$"
authorcites_filenames = filter(f->occursin(authorcites_regex, f), readdir(graphs_folder))
authorcites_graphs = to_named_tuple(zip(
    [ "authorcites" for _ in authorcites_filenames ],
    [match(authorcites_regex, filename).captures[1] for filename in authorcites_filenames],
    [loadgraphs(joinpath(graphs_folder, filename), GraphIO.GraphML.GraphMLFormat())["digraph"] for filename in authorcites_filenames]
))
##

coauthor_regex = r"^(.*_coauthor).graphml$"
coauthor_filenames = filter(f->occursin(coauthor_regex, f), readdir(graphs_folder))
coauthor_graphs = to_named_tuple(zip(
    [ "coauthor" for _ in authorcites_filenames ],
    map(filename->match(coauthor_regex, filename).captures[1], coauthor_filenames),
    [loadgraphs(joinpath(graphs_folder, filename), GraphIO.GraphML.GraphMLFormat())["digraph"] for filename in coauthor_filenames]
))

empirical_graphs = vcat(authorcites_graphs, coauthor_graphs)

##
all_graphs = vcat(zollman_graphs, empirical_graphs)