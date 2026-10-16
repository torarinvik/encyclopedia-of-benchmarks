module breadth_first_search_zero_one_shortest_path;

const int MAX_VERTICES = 64;
const int MAX_EDGES = 256;
const int MAX_INPUT_LENGTH = 4 + 3 * MAX_EDGES;
const int MAX_DEQUE_CAPACITY = MAX_VERTICES * MAX_VERTICES + 1;

fn long breadth_first_search_zero_one_shortest_path(long* input, usz length)
    @export("breadth_first_search_zero_one_shortest_path") {
    if (input == null || length < 4 || length > (usz)MAX_INPUT_LENGTH) return -2;
    long vertex_value = input[0], edge_value = input[1];
    long start_value = input[2], finish_value = input[3];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES)
        return -2;
    usz vertices = (usz)vertex_value, edges = (usz)edge_value;
    if (length != (usz)(4 + 3 * edges) || start_value < 0 || start_value >= vertex_value ||
        finish_value < 0 || finish_value >= vertex_value) return -2;

    int[MAX_EDGES] edge_to;
    int[MAX_EDGES] edge_weight;
    int[MAX_EDGES] next_edge;
    int[MAX_VERTICES] head_edge;
    int[MAX_VERTICES] tail_edge;
    for (usz vertex = 0; vertex < vertices; vertex++) head_edge[vertex] = tail_edge[vertex] = -1;
    for (usz edge = 0; edge < edges; edge++) {
        long from_value = input[4 + 3 * edge], to_value = input[5 + 3 * edge];
        long weight_value = input[6 + 3 * edge];
        if (from_value < 0 || from_value >= vertex_value || to_value < 0 || to_value >= vertex_value ||
            (weight_value != 0 && weight_value != 1)) return -2;
        int source = (int)from_value;
        edge_to[edge] = (int)to_value;
        edge_weight[edge] = (int)weight_value;
        next_edge[edge] = -1;
        if (head_edge[source] < 0) head_edge[source] = (int)edge;
        else next_edge[tail_edge[source]] = (int)edge;
        tail_edge[source] = (int)edge;
    }

    usz start = (usz)start_value, finish = (usz)finish_value;
    long[MAX_VERTICES] distance;
    for (usz vertex = 0; vertex < vertices; vertex++) distance[vertex] = 1000000000;
    int[MAX_DEQUE_CAPACITY] deque;
    usz deque_capacity = (usz)MAX_DEQUE_CAPACITY;
    usz deque_head = 0, deque_count = 1;
    distance[start] = 0;
    deque[0] = (int)start;
    while (deque_count > 0) {
        int node = deque[deque_head];
        deque_head = (deque_head + 1) % deque_capacity;
        deque_count--;
        int edge = head_edge[node];
        while (edge >= 0) {
            int neighbor = edge_to[edge];
            long candidate = distance[node] + edge_weight[edge];
            if (candidate < distance[neighbor]) {
                distance[neighbor] = candidate;
                if (edge_weight[edge] == 0) {
                    deque_head = (deque_head + deque_capacity - 1) % deque_capacity;
                    deque[deque_head] = neighbor;
                } else {
                    deque[(deque_head + deque_count) % deque_capacity] = neighbor;
                }
                deque_count++;
            }
            edge = next_edge[edge];
        }
    }
    return distance[finish] == 1000000000 ? -1 : distance[finish];
}
