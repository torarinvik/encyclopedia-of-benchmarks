module breadth_first_search_shortest_path_distance;

const int MAX_VERTICES = 26;
const int MAX_EDGES = 256;

fn long breadth_first_search_shortest_path_distance(long* input, usz length)
    @export("breadth_first_search_shortest_path_distance") {
    if (input == null || length < 4) return -1;
    long vertices_value = input[0], edges_value = input[1];
    long source_value = input[2], target_value = input[3];
    if (vertices_value < 1 || vertices_value > MAX_VERTICES || edges_value < 0 || edges_value > MAX_EDGES)
        return -1;
    usz vertices = (usz)vertices_value, edges = (usz)edges_value;
    if (source_value < 0 || source_value >= vertices_value || target_value < 0 || target_value >= vertices_value ||
        length != (usz)(4 + 2 * edges)) return -1;

    bool[MAX_VERTICES * MAX_VERTICES] adjacent;
    for (int index = 0; index < MAX_VERTICES * MAX_VERTICES; index++) adjacent[index] = false;
    for (usz edge = 0; edge < edges; edge++) {
        long from = input[4 + 2 * edge], to = input[5 + 2 * edge];
        if (from < 0 || from >= vertices_value || to < 0 || to >= vertices_value) return -1;
        adjacent[(usz)from * vertices + (usz)to] = true;
    }

    usz source = (usz)source_value, target = (usz)target_value;
    long[MAX_VERTICES] distance;
    int[MAX_VERTICES] queue;
    for (usz vertex = 0; vertex < vertices; vertex++) distance[vertex] = -1;
    usz head = 0, tail = 0;
    distance[source] = 0;
    queue[tail++] = (int)source;
    while (head < tail) {
        usz current = (usz)queue[head++];
        for (usz next = 0; next < vertices; next++) {
            if (adjacent[current * vertices + next] && distance[next] < 0) {
                distance[next] = distance[current] + 1;
                queue[tail++] = (int)next;
            }
        }
    }
    return distance[target];
}
