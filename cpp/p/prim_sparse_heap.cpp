#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_vertices = 64;
constexpr std::size_t max_edges = 4096;
constexpr std::size_t max_arcs = 2 * max_edges;
constexpr std::size_t none = max_vertices;
constexpr std::size_t no_arc = max_arcs;

bool before(const std::array<std::int64_t, max_vertices>& best, std::size_t left, std::size_t right) {
    return best[left] < best[right] || (best[left] == best[right] && left < right);
}

void exchange(std::array<std::size_t, max_vertices>& heap,
              std::array<std::size_t, max_vertices>& position,
              std::size_t first, std::size_t second) {
    const auto saved = heap[first];
    heap[first] = heap[second];
    heap[second] = saved;
    position[heap[first]] = first;
    position[heap[second]] = second;
}

void sift_up(std::array<std::size_t, max_vertices>& heap,
             std::array<std::size_t, max_vertices>& position,
             const std::array<std::int64_t, max_vertices>& best, std::size_t at) {
    while (at > 0) {
        const auto parent = (at - 1) / 2;
        if (!before(best, heap[at], heap[parent])) break;
        exchange(heap, position, at, parent);
        at = parent;
    }
}

std::size_t pop(std::array<std::size_t, max_vertices>& heap,
                std::array<std::size_t, max_vertices>& position,
                std::size_t& count, const std::array<std::int64_t, max_vertices>& best) {
    const auto result = heap[0];
    position[result] = none;
    --count;
    if (count > 0) {
        heap[0] = heap[count];
        position[heap[0]] = 0;
        std::size_t at = 0;
        while (2 * at + 1 < count) {
            auto child = 2 * at + 1;
            if (child + 1 < count && before(best, heap[child + 1], heap[child])) ++child;
            if (!before(best, heap[child], heap[at])) break;
            exchange(heap, position, at, child);
            at = child;
        }
    }
    return result;
}
} // namespace

extern "C" std::int64_t prim_sparse_heap(const std::int64_t* values, std::size_t length) noexcept {
    if (values == nullptr || length < 2 || length > 2 + 3 * max_edges) return -2;
    if (values[0] < 0 || values[0] > static_cast<std::int64_t>(max_vertices) ||
        values[1] < 0 || values[1] > static_cast<std::int64_t>(max_edges)) return -2;
    const auto vertices = static_cast<std::size_t>(values[0]);
    const auto edge_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + 3 * edge_count || (vertices == 0 && edge_count != 0)) return -2;
    if (vertices == 0) return 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = values[2 + 3 * edge];
        const auto destination = values[3 + 3 * edge];
        const auto weight = values[4 + 3 * edge];
        if (origin < 0 || destination < 0 || static_cast<std::uint64_t>(origin) >= vertices ||
            static_cast<std::uint64_t>(destination) >= vertices || weight < 0 || weight > 2147483647) return -2;
    }

    std::array<std::size_t, max_vertices> head{};
    std::array<std::size_t, max_arcs> next{}, to{};
    std::array<std::int64_t, max_arcs> arc_weight{};
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) head[vertex] = no_arc;
    std::size_t arc_count = 0;
    for (std::size_t edge = 0; edge < edge_count; ++edge) {
        const auto origin = static_cast<std::size_t>(values[2 + 3 * edge]);
        const auto destination = static_cast<std::size_t>(values[3 + 3 * edge]);
        const auto weight = values[4 + 3 * edge];
        if (origin == destination) continue;
        to[arc_count] = destination; arc_weight[arc_count] = weight;
        next[arc_count] = head[origin]; head[origin] = arc_count++;
        to[arc_count] = origin; arc_weight[arc_count] = weight;
        next[arc_count] = head[destination]; head[destination] = arc_count++;
    }

    std::array<std::int64_t, max_vertices> best{};
    std::array<bool, max_vertices> has_best{}, selected{};
    std::array<std::size_t, max_vertices> heap{}, position{};
    for (std::size_t vertex = 0; vertex < vertices; ++vertex) position[vertex] = none;
    std::size_t heap_count = 1, selected_count = 0;
    heap[0] = 0; position[0] = 0; has_best[0] = true;
    std::int64_t total = 0;
    while (heap_count > 0) {
        const auto origin = pop(heap, position, heap_count, best);
        selected[origin] = true;
        ++selected_count;
        total += best[origin];
        for (auto arc = head[origin]; arc != no_arc; arc = next[arc]) {
            const auto destination = to[arc];
            if (selected[destination] || (has_best[destination] && arc_weight[arc] >= best[destination])) continue;
            best[destination] = arc_weight[arc];
            has_best[destination] = true;
            if (position[destination] == none) {
                const auto at = heap_count++;
                heap[at] = destination;
                position[destination] = at;
            }
            sift_up(heap, position, best, position[destination]);
        }
    }
    return selected_count == vertices ? total : -1;
}
