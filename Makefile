
FIELDS_DIR = fields
GRAPH_DIR = graphs

FIELDS = $(wildcard ${FIELDS_DIR}/*)
AUTHORCITES_GRAPHS = $(FIELDS:${FIELDS_DIR}/%=${GRAPH_DIR}/%_authorcites.graphml)
COAUTHOR_GRAPHS = $(FIELDS:${FIELDS_DIR}/%=${GRAPH_DIR}/%_coauthor.graphml)
GRAPHS = $(AUTHORCITES_GRAPHS) $(COAUTHOR_GRAPHS)

$(GRAPH_DIR)/%_authorcites.graphml: $(FIELDS_DIR)/%
	python query_subfield.py -ac -o $(FIELDS_DIR) '$(shell cat $<)'

$(GRAPH_DIR)/%_coauthor.graphml: $(FIELDS_DIR)/%
	python query_subfield.py -co -o $(FIELDS_DIR) '$(shell cat $<)'

# TODO: Summary statistics

ZOLLMAN_RESULTS_DIR = zollman-results
ZOLLMAN_RESULTS= $(GRAPHS:${GRAPH_DIR}/%.graphml=${ZOLLMAN_RESULTS_DIR}/%.jld2)

$(ZOLLMAN_RESULTS_DIR)/%.jld2: $(GRAPH_DIR)/%.graphml
	./run_sim.sh zollman-simulation.jl $< ${ZOLLMAN_RESULTS_DIR}

SCC_ZOLLMAN_RESULTS_DIR = zollman-results-scc
SCC_ZOLLMAN_RESULTS= $(GRAPHS:${GRAPH_DIR}/%.graphml=${ZOLLMAN_RESULTS_DIR}/%.jld2)

$(SCC_ZOLLMAN_RESULTS_DIR)/%.jld2: $(GRAPH_DIR)/%.graphml
	./run_sim.sh zollman-simulation-scc.jl $< ${SCC_ZOLLMAN_RESULTS_DIR}



.PHONY: all
all: $(GRAPHS) $(ZOLLMAN_RESULTS)

.PHONY: clean
clean:
	rm -r graphs



