module strong_orientation;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 128;
const int MAX_ARCS = 2 * MAX_EDGES;
const usz MAX_INPUT_LENGTH = 259;

struct Graph {
    int[MAX_VERTICES] head;
    int[MAX_VERTICES] tail;
    int[MAX_ARCS] to;
    int[MAX_ARCS] next;
    int[MAX_ARCS] arc_edge;
    int[MAX_EDGES] edge_u;
    int[MAX_EDGES] edge_used;
    int[MAX_EDGES] direction;
    int[MAX_VERTICES] discovery;
    int[MAX_VERTICES] low;
    int timer;
    int bridges;
}

fn void append_arc(Graph* graph, int from, int target, int edge, int* arc_count) {
    int arc = *arc_count;
    *arc_count = *arc_count + 1;
    graph->to[arc] = target;
    graph->arc_edge[arc] = edge;
    graph->next[arc] = -1;
    if (graph->head[from] == -1) graph->head[from] = arc;
    else graph->next[graph->tail[from]] = arc;
    graph->tail[from] = arc;
}

fn void visit(Graph* graph, int vertex) {
    graph->discovery[vertex] = graph->timer;
    graph->low[vertex] = graph->timer;
    graph->timer++;
    int arc = graph->head[vertex];
    while (arc != -1) {
        int next_arc = graph->next[arc];
        int edge = graph->arc_edge[arc];
        if (graph->edge_used[edge] == 0) {
            graph->edge_used[edge] = 1;
            graph->direction[edge] = vertex == graph->edge_u[edge] ? 1 : -1;
            int neighbor = graph->to[arc];
            if (graph->discovery[neighbor] == -1) {
                visit(graph, neighbor);
                if (graph->low[neighbor] < graph->low[vertex]) graph->low[vertex] = graph->low[neighbor];
                if (graph->low[neighbor] > graph->discovery[vertex]) graph->bridges++;
            } else if (graph->discovery[neighbor] < graph->low[vertex]) {
                graph->low[vertex] = graph->discovery[neighbor];
            }
        }
        arc = next_arc;
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 0xff);
        bits >>= 8;
    }
}

fn long strong_orientation(long* input, usz length, char* output, usz output_capacity)
    @export("strong_orientation") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long raw_vertices = input[0], raw_edges = input[1];
    if (raw_vertices < 1 || raw_vertices > MAX_VERTICES || raw_edges < 0 || raw_edges > MAX_EDGES) return -1;
    int vertex_count = (int)raw_vertices;
    int edge_count = (int)raw_edges;
    if (length != (usz)(2 + 2 * edge_count)) return -1;
    for (int edge = 0; edge < edge_count; edge++) {
        long left = input[2 + 2 * edge], right = input[3 + 2 * edge];
        if (left < 0 || right < 0 || left >= raw_vertices || right >= raw_vertices) return -1;
    }
    usz output_bytes = (usz)(edge_count + 1) * 8;
    if (output == null || output_capacity < output_bytes) return -2;

    Graph graph = {};
    for (int vertex = 0; vertex < MAX_VERTICES; vertex++) {
        graph.head[vertex] = -1;
        graph.tail[vertex] = -1;
        graph.discovery[vertex] = -1;
    }
    int arc_count = 0;
    for (int edge = 0; edge < edge_count; edge++) {
        int left = (int)input[2 + 2 * edge];
        int right = (int)input[3 + 2 * edge];
        graph.edge_u[edge] = left;
        append_arc(&graph, left, right, edge, &arc_count);
        append_arc(&graph, right, left, edge, &arc_count);
    }
    int components = 0;
    for (int vertex = 0; vertex < vertex_count; vertex++) {
        if (graph.discovery[vertex] == -1) {
            components++;
            visit(&graph, vertex);
        }
    }
    store_i64_le(output, 0, (long)(components + graph.bridges));
    for (int edge = 0; edge < edge_count; edge++)
        store_i64_le(output, (usz)(edge + 1) * 8, (long)graph.direction[edge]);
    return (long)output_bytes;
}
