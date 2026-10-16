#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH (4 + 3 * MAX_EDGES)
#define MAX_DEQUE_CAPACITY (MAX_VERTICES * MAX_VERTICES + 1)

int64_t breadth_first_search_zero_one_shortest_path(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -2;
    const int64_t vertex_value = input[0], edge_value = input[1], start_value = input[2], finish_value = input[3];
    if (vertex_value < 1 || vertex_value > MAX_VERTICES || edge_value < 0 || edge_value > MAX_EDGES) return -2;
    const int vertices = (int)vertex_value, edges = (int)edge_value;
    if (length != (size_t)(4 + 3 * edges) || start_value < 0 || start_value >= vertices || finish_value < 0 || finish_value >= vertices) return -2;

    int edge_to[MAX_EDGES], edge_weight[MAX_EDGES], next_edge[MAX_EDGES];
    int head_edge[MAX_VERTICES], tail_edge[MAX_VERTICES];
    for (int vertex = 0; vertex < vertices; ++vertex) head_edge[vertex] = tail_edge[vertex] = -1;
    for (int edge = 0; edge < edges; ++edge) {
        const int64_t from = input[4 + 3 * edge], to = input[5 + 3 * edge], weight = input[6 + 3 * edge];
        if (from < 0 || from >= vertices || to < 0 || to >= vertices || (weight != 0 && weight != 1)) return -2;
        edge_to[edge] = (int)to;
        edge_weight[edge] = (int)weight;
        next_edge[edge] = -1;
        const int source = (int)from;
        if (head_edge[source] < 0) head_edge[source] = edge;
        else next_edge[tail_edge[source]] = edge;
        tail_edge[source] = edge;
    }

    const int start = (int)start_value, finish = (int)finish_value;
    int64_t distance[MAX_VERTICES];
    for (int vertex = 0; vertex < vertices; ++vertex) distance[vertex] = INT64_MAX;
    int deque[MAX_DEQUE_CAPACITY];
    size_t deque_head = 0, deque_count = 0;
    distance[start] = 0;
    deque[0] = start;
    deque_count = 1;
    while (deque_count > 0) {
        const int node = deque[deque_head];
        deque_head = (deque_head + 1) % MAX_DEQUE_CAPACITY;
        --deque_count;
        for (int edge = head_edge[node]; edge >= 0; edge = next_edge[edge]) {
            const int neighbor = edge_to[edge];
            const int64_t candidate = distance[node] + edge_weight[edge];
            if (candidate >= distance[neighbor]) continue;
            distance[neighbor] = candidate;
            if (edge_weight[edge] == 0) {
                deque_head = (deque_head + MAX_DEQUE_CAPACITY - 1) % MAX_DEQUE_CAPACITY;
                deque[deque_head] = neighbor;
            } else {
                deque[(deque_head + deque_count) % MAX_DEQUE_CAPACITY] = neighbor;
            }
            ++deque_count;
        }
    }
    return distance[finish] == INT64_MAX ? -1 : distance[finish];
}
