/* Lazy-heap Dijkstra; the graph contract is in the package README. */
#include <stddef.h>
#include <stdint.h>

#define DLH_MAX_VERTICES 64
#define DLH_MAX_EDGES 256
#define DLH_MAX_HEAP (DLH_MAX_EDGES + 1)
#define DLH_NONE DLH_MAX_EDGES

static int dlh_before(int64_t left_distance, size_t left_vertex,
                      int64_t right_distance, size_t right_vertex)
{
    return left_distance < right_distance ||
           (left_distance == right_distance && left_vertex < right_vertex);
}

int64_t dijkstra_lazy_heap(const int64_t *edges, size_t vertices, size_t edge_count,
                           size_t source, int64_t *distances, uint8_t *reachable)
{
    if (vertices > DLH_MAX_VERTICES || edge_count > DLH_MAX_EDGES) return -3;
    if (vertices == 0) return source == 0 && edge_count == 0 ? 0 : -3;
    if (source >= vertices) return -3;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin = edges[3 * edge];
        const int64_t destination = edges[3 * edge + 1];
        const int64_t weight = edges[3 * edge + 2];
        if (origin < 0 || destination < 0 || (uint64_t)origin >= vertices ||
            (uint64_t)destination >= vertices) return -3;
        if (weight < 0) return -4;
    }

    size_t head[DLH_MAX_VERTICES], tail[DLH_MAX_VERTICES];
    size_t next[DLH_MAX_EDGES];
    for (size_t vertex = 0; vertex < vertices; ++vertex) head[vertex] = tail[vertex] = DLH_NONE;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t origin = (size_t)edges[3 * edge];
        next[edge] = DLH_NONE;
        if (head[origin] == DLH_NONE) head[origin] = edge;
        else next[tail[origin]] = edge;
        tail[origin] = edge;
    }

    for (size_t vertex = 0; vertex < vertices; ++vertex) {
        distances[vertex] = 0;
        reachable[vertex] = 0;
    }
    int64_t heap_distance[DLH_MAX_HEAP];
    size_t heap_vertex[DLH_MAX_HEAP];
    size_t heap_count = 1;
    heap_distance[0] = 0;
    heap_vertex[0] = source;
    distances[source] = 0;
    reachable[source] = 1;

    while (heap_count > 0) {
        const int64_t current = heap_distance[0];
        const size_t origin = heap_vertex[0];
        --heap_count;
        if (heap_count > 0) {
            const int64_t last_distance = heap_distance[heap_count];
            const size_t last_vertex = heap_vertex[heap_count];
            size_t position = 0;
            while (2 * position + 1 < heap_count) {
                size_t child = 2 * position + 1;
                if (child + 1 < heap_count && dlh_before(heap_distance[child + 1], heap_vertex[child + 1],
                                                         heap_distance[child], heap_vertex[child])) ++child;
                if (!dlh_before(heap_distance[child], heap_vertex[child], last_distance, last_vertex)) break;
                heap_distance[position] = heap_distance[child];
                heap_vertex[position] = heap_vertex[child];
                position = child;
            }
            heap_distance[position] = last_distance;
            heap_vertex[position] = last_vertex;
        }
        if (current != distances[origin] || reachable[origin] == 2) continue;
        reachable[origin] = 2;

        for (size_t edge = head[origin]; edge != DLH_NONE; edge = next[edge]) {
            const size_t destination = (size_t)edges[3 * edge + 1];
            const int64_t weight = edges[3 * edge + 2];
            if (current > INT64_MAX - weight) return -2;
            const int64_t candidate = current + weight;
            if (reachable[destination] != 2 &&
                (reachable[destination] == 0 || candidate < distances[destination])) {
                distances[destination] = candidate;
                reachable[destination] = 1;
                size_t position = heap_count++;
                while (position > 0) {
                    const size_t parent = (position - 1) / 2;
                    if (!dlh_before(candidate, destination, heap_distance[parent], heap_vertex[parent])) break;
                    heap_distance[position] = heap_distance[parent];
                    heap_vertex[position] = heap_vertex[parent];
                    position = parent;
                }
                heap_distance[position] = candidate;
                heap_vertex[position] = destination;
            }
        }
    }
    for (size_t vertex = 0; vertex < vertices; ++vertex)
        if (reachable[vertex] == 2) reachable[vertex] = 1;
    return 0;
}
