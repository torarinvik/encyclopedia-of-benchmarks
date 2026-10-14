/* Portable bounded all-pairs shortest paths; returns the requested source row. */
#include <stddef.h>
#include <stdint.h>

#define FLOYD_MAX_VERTICES 64

int64_t floyd_warshall(const int64_t *edges, size_t vertices, size_t edge_count,
                       size_t source, int64_t *distances, uint8_t *reachable)
{
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (vertices > FLOYD_MAX_VERTICES || source >= vertices) return -3;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin = edges[3 * edge], destination = edges[3 * edge + 1];
        if (origin < 0 || destination < 0 || (uint64_t)origin >= vertices ||
            (uint64_t)destination >= vertices) return -3;
    }

    int64_t all_distances[FLOYD_MAX_VERTICES * FLOYD_MAX_VERTICES] = {0};
    uint8_t present[FLOYD_MAX_VERTICES * FLOYD_MAX_VERTICES] = {0};
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        present[vertex * vertices + vertex] = 1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t origin = (size_t)edges[3 * edge], destination = (size_t)edges[3 * edge + 1];
        const size_t index = origin * vertices + destination;
        const int64_t weight = edges[3 * edge + 2];
        if (!present[index] || weight < all_distances[index]) {
            all_distances[index] = weight;
            present[index] = 1;
        }
    }

    for (size_t middle = 0; middle < vertices; ++middle) {
        for (size_t origin = 0; origin < vertices; ++origin) {
            const size_t left_index = origin * vertices + middle;
            if (!present[left_index]) continue;
            for (size_t destination = 0; destination < vertices; ++destination) {
                const size_t right_index = middle * vertices + destination;
                if (!present[right_index]) continue;
                const int64_t left = all_distances[left_index], right = all_distances[right_index];
                if ((right > 0 && left > INT64_MAX - right) ||
                    (right < 0 && left < INT64_MIN - right)) return -2;
                const int64_t candidate = left + right;
                const size_t output_index = origin * vertices + destination;
                if (!present[output_index] || candidate < all_distances[output_index]) {
                    all_distances[output_index] = candidate;
                    present[output_index] = 1;
                }
            }
        }
    }

    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        if (present[source * vertices + vertex] &&
            present[vertex * vertices + vertex] && all_distances[vertex * vertices + vertex] < 0) return -1;
    }
    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        const size_t index = source * vertices + vertex;
        reachable[vertex] = present[index];
        distances[vertex] = present[index] ? all_distances[index] : 0;
    }
    return 0;
}
