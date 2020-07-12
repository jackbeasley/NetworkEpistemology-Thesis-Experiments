import argparse
import string
import networkx as nx
from pathlib import Path
from graph_queries import get_author_cites_graph, get_coauthor_graph

parser = argparse.ArgumentParser(description="Query neo4j and output graphml")

parser.add_argument("-ac", "--author-cited", action="store_true", default=False)

parser.add_argument("-co", "--coauthor", action="store_true", default=False)

parser.add_argument("-v", "--verbose", action="store_true", default=False)

parser.add_argument("-o", "--out-folder", type=str, default=str(Path() / "graphs"))


parser.add_argument("field_of_study", type=str, help="field of study to query for")


def sanitize_name(name: str) -> str:
    return name.lower().strip().translate(str.maketrans("", "", string.punctuation))


def output_file(fos: str, query_type: str, out_folder: Path) -> Path:
    return out_folder / "{}_{}.graphml".format(fos.replace(" ", "_"), query_type)


if __name__ == "__main__":
    args = parser.parse_args()

    out_folder = Path(args.out_folder)
    out_folder.mkdir(parents=True, exist_ok=True)

    field_of_study = sanitize_name(args.field_of_study)
    if args.verbose:
        print("Field of study: '{}'".format(field_of_study))

    if args.author_cited:
        if args.verbose:
            print("querying for coauthors")

        graph = get_author_cites_graph(field_of_study)
        out_file = output_file(field_of_study, "authorcites", out_folder)
        nx.write_graphml(graph, str(out_file))

    if args.coauthor:
        if args.verbose:
            print("querying for coauthors")

        graph = get_coauthor_graph(field_of_study)
        out_file = output_file(field_of_study, "coauthor", out_folder)
        nx.write_graphml(graph, str(out_file))
