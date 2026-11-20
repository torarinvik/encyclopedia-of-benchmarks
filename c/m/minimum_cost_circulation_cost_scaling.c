#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 8, MAX_EDGES = 10, MAX_ARCS = 2 * MAX_EDGES, MAX_INPUT_LENGTH = 43 };
enum { COST_OFFSET = 81 };

typedef struct {
    size_t from;
    size_t to;
    size_t reverse;
    int64_t capacity;
    int64_t cost;
} ResidualArc;

int64_t minimum_cost_circulation_cost_scaling(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES
        || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t n = (size_t)input[0];
    const size_t m = (size_t)input[1];
    if (length != 2 + 4 * m) return -1;

    ResidualArc edges[MAX_ARCS] = {{0}};
    int64_t max_scaled_cost = 0;
    for (size_t index = 0; index < m; ++index) {
        const size_t offset = 2 + 4 * index;
        const int64_t from_value = input[offset];
        const int64_t to_value = input[offset + 1];
        const int64_t capacity = input[offset + 2];
        const int64_t cost = input[offset + 3];
        if (from_value < 0 || from_value >= (int64_t)n
            || to_value < 0 || to_value >= (int64_t)n
            || capacity < 0 || capacity > 2 || cost < -4 || cost > 4) return -1;
        const size_t from = (size_t)from_value;
        const size_t to = (size_t)to_value;
        const int64_t scaled_cost = cost * (int64_t)(n + 1);
        const size_t forward = 2 * index;
        const size_t reverse = forward + 1;
        edges[forward] = (ResidualArc){from, to, reverse, capacity, scaled_cost};
        edges[reverse] = (ResidualArc){to, from, forward, 0, -scaled_cost};
        const int64_t magnitude = scaled_cost < 0 ? -scaled_cost : scaled_cost;
        if (magnitude > max_scaled_cost) max_scaled_cost = magnitude;
    }

    int64_t epsilon = 1;
    while (epsilon < max_scaled_cost) epsilon *= 2;
    int64_t price[MAX_VERTICES] = {0};
    const size_t arc_count = 2 * m;
    while (epsilon > 1) {
        epsilon /= 2;
        int64_t excess[MAX_VERTICES] = {0};

        for (size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
            if (edges[edge_index].capacity <= 0) continue;
            const size_t from = edges[edge_index].from;
            const size_t to = edges[edge_index].to;
            const int64_t reduced_cost = edges[edge_index].cost + price[from] - price[to];
            if (reduced_cost < 0) {
                const int64_t amount = edges[edge_index].capacity;
                edges[edge_index].capacity = 0;
                edges[edges[edge_index].reverse].capacity += amount;
                excess[from] -= amount;
                excess[to] += amount;
            }
        }

        size_t queue[MAX_VERTICES] = {0};
        bool queued[MAX_VERTICES] = {false};
        size_t head = 0;
        size_t tail = 0;
        size_t queue_count = 0;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (excess[vertex] > 0) {
                queue[tail] = vertex;
                tail = (tail + 1) % n;
                ++queue_count;
                queued[vertex] = true;
            }
        }

        while (queue_count > 0) {
            const size_t vertex = queue[head];
            head = (head + 1) % n;
            --queue_count;
            queued[vertex] = false;
            while (excess[vertex] > 0) {
                size_t admissible = MAX_ARCS;
                for (size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
                    const ResidualArc edge = edges[edge_index];
                    if (edge.from != vertex || edge.to == vertex || edge.capacity <= 0) continue;
                    if (edge.cost + price[vertex] - price[edge.to] < 0) {
                        admissible = edge_index;
                        break;
                    }
                }

                if (admissible < MAX_ARCS) {
                    const size_t to = edges[admissible].to;
                    const size_t reverse = edges[admissible].reverse;
                    const int64_t amount = excess[vertex] < edges[admissible].capacity
                        ? excess[vertex] : edges[admissible].capacity;
                    edges[admissible].capacity -= amount;
                    edges[reverse].capacity += amount;
                    const int64_t old_excess = excess[to];
                    excess[vertex] -= amount;
                    excess[to] += amount;
                    if (old_excess <= 0 && excess[to] > 0 && !queued[to]) {
                        queue[tail] = to;
                        tail = (tail + 1) % n;
                        ++queue_count;
                        queued[to] = true;
                    }
                } else {
                    bool has_exit = false;
                    int64_t best_price = 0;
                    for (size_t edge_index = 0; edge_index < arc_count; ++edge_index) {
                        const ResidualArc edge = edges[edge_index];
                        if (edge.from != vertex || edge.capacity <= 0) continue;
                        const int64_t candidate = price[edge.to] - edge.cost - epsilon;
                        if (!has_exit || candidate > best_price) {
                            has_exit = true;
                            best_price = candidate;
                        }
                    }
                    if (!has_exit) return -1;
                    price[vertex] = best_price;
                }
            }
        }
        for (size_t vertex = 0; vertex < n; ++vertex) {
            if (excess[vertex] != 0) return -1;
        }
    }

    int64_t total_cost = 0;
    for (size_t index = 0; index < m; ++index) {
        const int64_t capacity = input[2 + 4 * index + 2];
        const int64_t cost = input[2 + 4 * index + 3];
        const int64_t flow = capacity - edges[2 * index].capacity;
        total_cost += flow * cost;
    }
    return total_cost + COST_OFFSET;
}
