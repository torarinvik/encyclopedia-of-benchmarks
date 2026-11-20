#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define PSH_MAX_VERTICES 64
#define PSH_MAX_EDGES 4096
#define PSH_MAX_ARCS (2 * PSH_MAX_EDGES)
#define PSH_NONE PSH_MAX_VERTICES

static bool psh_before(const int64_t *best, size_t left, size_t right)
{
    return best[left] < best[right] || (best[left] == best[right] && left < right);
}

static void psh_exchange(size_t *heap, size_t *position, size_t first, size_t second)
{
    const size_t saved = heap[first];
    heap[first] = heap[second];
    heap[second] = saved;
    position[heap[first]] = first;
    position[heap[second]] = second;
}

static void psh_sift_up(size_t *heap, size_t *position, const int64_t *best, size_t at)
{
    while (at > 0) {
        const size_t parent = (at - 1) / 2;
        if (!psh_before(best, heap[at], heap[parent])) break;
        psh_exchange(heap, position, at, parent);
        at = parent;
    }
}

static size_t psh_pop(size_t *heap, size_t *position, size_t *count, const int64_t *best)
{
    const size_t result = heap[0];
    position[result] = PSH_NONE;
    --*count;
    if (*count > 0) {
        heap[0] = heap[*count];
        position[heap[0]] = 0;
        size_t at = 0;
        while (2 * at + 1 < *count) {
            size_t child = 2 * at + 1;
            if (child + 1 < *count && psh_before(best, heap[child + 1], heap[child])) ++child;
            if (!psh_before(best, heap[child], heap[at])) break;
            psh_exchange(heap, position, at, child);
            at = child;
        }
    }
    return result;
}

int64_t prim_sparse_heap(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 2 + 3 * PSH_MAX_EDGES) return -2;
    if (values[0] < 0 || values[0] > PSH_MAX_VERTICES || values[1] < 0 || values[1] > PSH_MAX_EDGES) return -2;
    const size_t vertices = (size_t)values[0], edge_count = (size_t)values[1];
    if (length != 2 + 3 * edge_count || (vertices == 0 && edge_count != 0)) return -2;
    if (vertices == 0) return 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t origin = values[2 + 3 * edge];
        const int64_t destination = values[3 + 3 * edge];
        const int64_t weight = values[4 + 3 * edge];
        if (origin < 0 || destination < 0 || (uint64_t)origin >= vertices || (uint64_t)destination >= vertices ||
            weight < 0 || weight > INT64_C(2147483647)) return -2;
    }

    size_t head[PSH_MAX_VERTICES], next[PSH_MAX_ARCS], to[PSH_MAX_ARCS];
    int64_t arc_weight[PSH_MAX_ARCS];
    for (size_t vertex = 0; vertex < vertices; ++vertex) head[vertex] = PSH_MAX_ARCS;
    size_t arc_count = 0;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const size_t origin = (size_t)values[2 + 3 * edge];
        const size_t destination = (size_t)values[3 + 3 * edge];
        const int64_t weight = values[4 + 3 * edge];
        if (origin == destination) continue;
        to[arc_count] = destination;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[origin];
        head[origin] = arc_count++;
        to[arc_count] = origin;
        arc_weight[arc_count] = weight;
        next[arc_count] = head[destination];
        head[destination] = arc_count++;
    }

    int64_t best[PSH_MAX_VERTICES] = {0};
    bool has_best[PSH_MAX_VERTICES] = {false};
    bool selected[PSH_MAX_VERTICES] = {false};
    size_t heap[PSH_MAX_VERTICES], position[PSH_MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertices; ++vertex) position[vertex] = PSH_NONE;
    size_t heap_count = 1;
    heap[0] = 0;
    position[0] = 0;
    has_best[0] = true;
    int64_t total = 0;
    size_t selected_count = 0;

    while (heap_count > 0) {
        const size_t origin = psh_pop(heap, position, &heap_count, best);
        selected[origin] = true;
        ++selected_count;
        total += best[origin];
        for (size_t arc = head[origin]; arc != PSH_MAX_ARCS; arc = next[arc]) {
            const size_t destination = to[arc];
            if (selected[destination] || (has_best[destination] && arc_weight[arc] >= best[destination])) continue;
            best[destination] = arc_weight[arc];
            has_best[destination] = true;
            if (position[destination] == PSH_NONE) {
                const size_t at = heap_count++;
                heap[at] = destination;
                position[destination] = at;
            }
            psh_sift_up(heap, position, best, position[destination]);
        }
    }
    return selected_count == vertices ? total : -1;
}
