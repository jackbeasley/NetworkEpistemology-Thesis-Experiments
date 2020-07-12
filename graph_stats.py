import networkx as nx
from typing import NamedTuple, List, Set


class GraphStats(NamedTuple):
    nodes: int
    edges: int
    sccNumber: int
    largestSccSize: int
    wccNumber: int
    largestWccSize: int


def graph_stats(g: nx.DiGraph) -> GraphStats:
    strongly_connected_components: List[Set[int]] = list(
        nx.strongly_connected_components(g)
    )
    weakly_connected_components: List[Set[int]] = list(
        nx.weakly_connected_components(g)
    )
    return GraphStats(
        g.number_of_nodes(),
        g.number_of_edges(),
        len(strongly_connected_components),
        max([len(comp) for comp in strongly_connected_components]),
        len(weakly_connected_components),
        max([len(comp) for comp in weakly_connected_components]),
    )
