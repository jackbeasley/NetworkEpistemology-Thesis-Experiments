from neo4j import GraphDatabase, Node, Record, BoltStatementResult
import networkx as nx
from typing import Tuple, NamedTuple, Set, List
from datetime import datetime


class Author(NamedTuple):
    citationCount: int
    createdDate: datetime
    displayName: str
    paperCount: int
    rank: int
    authorId: int
    normalizedName: str


def node_to_author(node: Node) -> Author:
    return Author(
        node.get("citationCount"),
        node.get("createdDate").to_native(),
        node.get("displayName"),
        node.get("paperCount"),
        node.get("rank"),
        node.get("authorId"),
        node.get("normalizedName"),
    )


def filter_author_results(results: BoltStatementResult) -> Set[Tuple[Author, Author]]:
    results_list: List[Record] = list(results)

    return set(
        [
            (node_to_author(res["a1"]), node_to_author(res["a2"]))
            for res in results_list
            if res["a1"].get("authorId") != res["a2"].get("authorId")
        ]
    )


def author_edges_to_graph(edges: Set[Tuple[Author, Author]]) -> nx.DiGraph:
    authors: Set[Author] = set([a1 for (a1, _) in edges]) | set(
        [a2 for (_, a2) in edges]
    )
    g = nx.DiGraph()

    for author in authors:
        g.add_node(
            author.authorId,
            name=author.normalizedName,
            rank=author.rank,
            paperCount=author.paperCount,
        )

    for (a1, a2) in edges:
        g.add_edge(a1.authorId, a2.authorId)

    return g


def get_author_cites_graph(
    fieldOfStudyName: str,
    driver=GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "mag")),
) -> nx.DiGraph:
    CITED_QUERY = """
        MATCH (p1:Paper)-[:IN_FIELD]->(parent:FieldsOfStudy{normalizedName: $fosName}) 
        WHERE p1.citationCount > 0
        MATCH (p1)-[r:REFERENCES]->(p2:Paper)
        MATCH (p2)-[:IN_FIELD]->(parent:FieldsOfStudy{normalizedName: $fosName}) 
        WHERE p2 <> p1 AND p2.citationCount > 0
        MATCH (p2)-[:AUTHORED_BY]->(a2:Author) 
        MATCH (p1)-[:AUTHORED_BY]->(a1:Author) 
        WHERE a1 <> a2
        RETURN a1, a2
    """
    with driver.session() as session:
        results = filter_author_results(
            session.run(CITED_QUERY, fosName=fieldOfStudyName)
        )
        return author_edges_to_graph(results)


def get_coauthor_graph(
    fieldOfStudyName: str,
    driver=GraphDatabase.driver("bolt://localhost:7687", auth=("neo4j", "mag")),
) -> nx.DiGraph:
    CITED_QUERY = """
        MATCH (p1:Paper)-[:IN_FIELD]->(parent:FieldsOfStudy{normalizedName: $fosName}) 
        WHERE p1.citationCount > 0
        MATCH (a1:Author)<-[:AUTHORED_BY]-(p1)-[:AUTHORED_BY]->(a2:Author)
        WHERE a1 <> a2
        RETURN a1, a2
    """
    with driver.session() as session:
        results = filter_author_results(
            session.run(CITED_QUERY, fosName=fieldOfStudyName)
        )
        return author_edges_to_graph(results)
