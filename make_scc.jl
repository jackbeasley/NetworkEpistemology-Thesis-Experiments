using LightGraphs, GraphIO
##
get_scc(graphs, min_sz=5) = vcat([[g.graph[s] for s in filter(scc->(length(scc) > min_sz), strongly_connected_components(g.graph))] for g in graphs]...)
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

