module kahns_algorithm_long;

const long MAX_VERTICES = 32;
const long MAX_EDGES = 128;
const long EDGE_TABLE_SIZE = MAX_VERTICES * MAX_VERTICES;
const long MAX_INPUT_LENGTH = 2 + 2 * MAX_EDGES;

fn long kahns_algorithm_long(long* values, usz length) @export("kahns_algorithm_long") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long vertex_count = values[0], edge_count = values[1];
    if (vertex_count < 1 || vertex_count > MAX_VERTICES || edge_count < 0 || edge_count > MAX_EDGES ||
        length != (usz)(2 + 2 * edge_count)) return -1;

    long[EDGE_TABLE_SIZE] edge_multiplicity = {0};
    long[MAX_VERTICES] indegree = {0};
    long[MAX_VERTICES] distance = {0};
    long[MAX_VERTICES] queue = {0};
    for (long vertex = 0; vertex < vertex_count; vertex++) distance[vertex] = 1;
    for (long edge = 0; edge < edge_count; edge++) {
        long source = values[2 + 2 * edge], destination = values[3 + 2 * edge];
        if (source < 0 || source >= vertex_count || destination < 0 || destination >= vertex_count) return -1;
        edge_multiplicity[source * MAX_VERTICES + destination]++;
        indegree[destination]++;
    }

    usz head = 0, tail = 0;
    for (long vertex = 0; vertex < vertex_count; vertex++)
        if (indegree[vertex] == 0) { queue[tail] = vertex; tail++; }
    long processed = 0, maximum = 1;
    while (head < tail) {
        long source = queue[head]; head++;
        processed++;
        if (distance[source] > maximum) maximum = distance[source];
        for (long destination = 0; destination < vertex_count; destination++) {
            long copies = edge_multiplicity[source * MAX_VERTICES + destination];
            if (copies == 0) continue;
            long candidate = distance[source] + 1;
            if (candidate > distance[destination]) distance[destination] = candidate;
            for (long copy = 0; copy < copies; copy++) {
                indegree[destination]--;
                if (indegree[destination] == 0) { queue[tail] = destination; tail++; }
            }
        }
    }
    if (processed != vertex_count) return -1;
    for (long vertex = 0; vertex < vertex_count; vertex++)
        if (distance[vertex] > maximum) maximum = distance[vertex];
    return maximum;
}
