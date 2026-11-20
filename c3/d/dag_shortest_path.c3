module dag_shortest_path;

const long MAX_VERTICES = 12;
const long MAX_EDGES = 66;
const long MAX_LENGTH = 203;
const long DISTANCE_OFFSET = 100000;
const long INFINITY_DISTANCE = 1L << 60;

fn long dag_shortest_path(long* input, usz length) @export("dag_shortest_path") {
    if (input == null || length < 4 || length > MAX_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    usz vertex_count = (usz)input[0];
    usz edge_count = (usz)input[1];
    if (length != 4 + 3 * edge_count || input[2] < 0 || input[2] >= (long)vertex_count
            || input[3] < 0 || input[3] >= (long)vertex_count) return -1;
    long[MAX_EDGES] from;
    long[MAX_EDGES] to;
    long[MAX_EDGES] weight;
    long[MAX_VERTICES] indegree;
    long[MAX_VERTICES] queue;
    long[MAX_VERTICES] order;
    for (usz vertex = 0; vertex < vertex_count; vertex++) indegree[vertex] = 0;
    for (usz edge = 0; edge < edge_count; edge++) {
        long start = input[4 + 3 * edge];
        long end = input[5 + 3 * edge];
        long cost = input[6 + 3 * edge];
        if (start < 0 || start >= (long)vertex_count || end < 0 || end >= (long)vertex_count
                || start == end || cost < -1000 || cost > 1000) return -1;
        for (usz previous = 0; previous < edge; previous++)
            if (from[previous] == start && to[previous] == end) return -1;
        from[edge] = start; to[edge] = end; weight[edge] = cost;
        indegree[(usz)end]++;
    }
    usz head = 0, tail = 0, order_count = 0;
    for (usz vertex = 0; vertex < vertex_count; vertex++)
        if (indegree[vertex] == 0) { queue[tail] = (long)vertex; tail++; }
    while (head < tail) {
        long vertex = queue[head]; head++;
        order[order_count] = vertex; order_count++;
        for (usz edge = 0; edge < edge_count; edge++) if (from[edge] == vertex) {
            usz end = (usz)to[edge];
            indegree[end]--;
            if (indegree[end] == 0) { queue[tail] = (long)end; tail++; }
        }
    }
    if (order_count != vertex_count) return -1;
    long[MAX_VERTICES] distance;
    for (usz vertex = 0; vertex < vertex_count; vertex++) distance[vertex] = INFINITY_DISTANCE;
    distance[(usz)input[2]] = 0;
    for (usz position = 0; position < vertex_count; position++) {
        long vertex = order[position];
        if (distance[(usz)vertex] == INFINITY_DISTANCE) continue;
        for (usz edge = 0; edge < edge_count; edge++) if (from[edge] == vertex) {
            usz end = (usz)to[edge];
            long candidate = distance[(usz)vertex] + weight[edge];
            if (candidate < distance[end]) distance[end] = candidate;
        }
    }
    long answer = distance[(usz)input[3]];
    if (answer == INFINITY_DISTANCE) return 0;
    return DISTANCE_OFFSET + answer;
}
