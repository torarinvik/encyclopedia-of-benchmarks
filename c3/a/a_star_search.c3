module a_star_search;

const usz MAX_VERTICES = 256;
const usz MAX_EDGES = 4096;
const long INF = 2305843009213693951;

fn long a_star_search(long* input, usz length, char* output, usz output_capacity)
    @export("a_star_search")
{
    if (input == null || length < 5 || length > 4 + MAX_VERTICES + 2 * MAX_EDGES) return -1;
    long vertex_value = input[0];
    long edge_value = input[1];
    long source_value = input[2];
    long target_value = input[3];
    if (vertex_value < 1 || vertex_value > (long)MAX_VERTICES || edge_value < 0 ||
        edge_value > (long)MAX_EDGES || source_value < 0 || source_value >= vertex_value ||
        target_value < 0 || target_value >= vertex_value) return -1;
    usz vertices = (usz)vertex_value;
    usz edges = (usz)edge_value;
    usz source = (usz)source_value;
    usz target = (usz)target_value;
    if (length != 4 + vertices + 2 * edges) return -1;

    long[MAX_VERTICES] heuristic;
    long[MAX_EDGES] from;
    long[MAX_EDGES] to;
    long[MAX_VERTICES] distance;
    long[MAX_VERTICES] parent;
    long[MAX_VERTICES] reversed;
    bool[MAX_VERTICES] opened;
    bool[MAX_VERTICES] closed;
    for (usz vertex = 0; vertex < vertices; vertex++) {
        heuristic[vertex] = input[4 + vertex];
        if (heuristic[vertex] < 0 || heuristic[vertex] > 1000000000) return -1;
        distance[vertex] = INF;
        parent[vertex] = -1;
        opened[vertex] = false;
        closed[vertex] = false;
    }
    if (heuristic[target] != 0) return -1;
    usz edge_offset = 4 + vertices;
    for (usz edge = 0; edge < edges; edge++) {
        long u = input[edge_offset + 2 * edge];
        long v = input[edge_offset + 2 * edge + 1];
        if (u < 0 || u >= vertex_value || v < 0 || v >= vertex_value ||
            heuristic[(usz)u] > heuristic[(usz)v] + 1) return -1;
        from[edge] = u;
        to[edge] = v;
    }

    distance[source] = 0;
    opened[source] = true;
    while (true) {
        usz best = vertices;
        for (usz vertex = 0; vertex < vertices; vertex++) {
            if (!opened[vertex]) continue;
            if (best == vertices || distance[vertex] + heuristic[vertex] < distance[best] + heuristic[best] ||
                (distance[vertex] + heuristic[vertex] == distance[best] + heuristic[best] &&
                 (distance[vertex] < distance[best] ||
                  (distance[vertex] == distance[best] && vertex < best)))) best = vertex;
        }
        if (best == vertices) break;
        opened[best] = false;
        closed[best] = true;
        if (best == target) break;
        for (usz edge = 0; edge < edges; edge++) {
            if ((usz)from[edge] != best) continue;
            usz neighbor = (usz)to[edge];
            if (closed[neighbor]) continue;
            long candidate = distance[best] + 1;
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                parent[neighbor] = (long)best;
                opened[neighbor] = true;
            }
        }
    }
    if (distance[target] == INF) return 0;
    usz path_length = 0;
    long current = (long)target;
    while (current >= 0 && path_length < vertices) {
        reversed[path_length] = current;
        path_length++;
        if ((usz)current == source) break;
        current = parent[(usz)current];
    }
    if (path_length == 0 || (usz)reversed[path_length - 1] != source || path_length - 1 > 30) return -1;
    if (output_capacity < path_length || output == null) return -2;
    for (usz index = 0; index < path_length; index++) {
        output[index] = (char)reversed[path_length - 1 - index];
    }
    return (long)path_length;
}
