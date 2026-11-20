// Clean-room Dulmage--Mendelsohn decomposition of a bipartite graph.
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int kSide = 6;
constexpr int kVertices = 12;
constexpr int kEdges = 36;
using LeftAdj = std::array<std::uint16_t, kSide>;
using GlobalAdj = std::array<std::uint16_t, kVertices>;

bool augment(const LeftAdj& adjacency, int left, int right_count,
             std::array<bool, kSide>& seen, std::array<int, kSide>& match_right) {
    for (int right = 0; right < right_count; ++right) {
        const auto bit = static_cast<std::uint16_t>(1u << right);
        if (!(adjacency[left] & bit) || seen[right]) continue;
        seen[right] = true;
        const int mate = match_right[right];
        if (mate < 0 || augment(adjacency, mate, right_count, seen, match_right)) {
            match_right[right] = left;
            return true;
        }
    }
    return false;
}

int maximum_matching(const LeftAdj& adjacency, int left_count, int right_count,
                     std::array<int, kSide>& match_left,
                     std::array<int, kSide>& match_right) {
    match_right.fill(-1);
    int size = 0;
    for (int left = 0; left < left_count; ++left) {
        std::array<bool, kSide> seen{};
        if (augment(adjacency, left, right_count, seen, match_right)) ++size;
    }
    match_left.fill(-1);
    for (int right = 0; right < right_count; ++right)
        if (match_right[right] >= 0) match_left[match_right[right]] = right;
    return size;
}
} // namespace

extern "C" std::int64_t dulmage_mendelsohn_decomposition(const std::int64_t* input,
                                                           std::size_t length) {
    if (input == nullptr || length < 3 || length > 76) return -1;
    const auto left64 = input[0], right64 = input[1], edges64 = input[2];
    if (left64 < 0 || left64 > kSide || right64 < 0 || right64 > kSide ||
        left64 + right64 < 1 || edges64 < 0 || edges64 > kEdges ||
        edges64 > left64 * right64 || length != 3 + 2 * static_cast<std::size_t>(edges64)) return -1;
    const int left_count = static_cast<int>(left64), right_count = static_cast<int>(right64);
    const int total = left_count + right_count, edge_count = static_cast<int>(edges64);
    LeftAdj adjacency{};
    GlobalAdj global{};
    for (int edge = 0; edge < edge_count; ++edge) {
        const auto u64 = input[3 + 2 * edge], v64 = input[4 + 2 * edge];
        if (u64 < 0 || u64 >= left_count || v64 < 0 || v64 >= right_count) return -1;
        const int u = static_cast<int>(u64), v = static_cast<int>(v64);
        const int right_vertex = left_count + v;
        const auto right_bit = static_cast<std::uint16_t>(1u << v);
        if (adjacency[u] & right_bit) return -1;
        adjacency[u] |= right_bit;
        global[u] |= static_cast<std::uint16_t>(1u << right_vertex);
        global[right_vertex] |= static_cast<std::uint16_t>(1u << u);
    }

    std::array<int, kSide> match_left{}, match_right{};
    const int matching_size = maximum_matching(adjacency, left_count, right_count,
                                                match_left, match_right);
    std::array<bool, 2 * kVertices> seen{};
    std::array<int, 2 * kVertices> queue{};
    int head = 0, tail = 0;
    for (int left = 0; left < left_count; ++left) if (match_left[left] < 0) {
        const int state = 2 * left; seen[state] = true; queue[tail++] = state;
    }
    for (int right = 0; right < right_count; ++right) if (match_right[right] < 0) {
        const int state = 2 * (left_count + right); seen[state] = true; queue[tail++] = state;
    }
    while (head < tail) {
        const int state = queue[head++], vertex = state / 2, parity = state & 1;
        for (int neighbor = 0; neighbor < total; ++neighbor) {
            if (!(global[vertex] & (1u << neighbor))) continue;
            const bool matched = vertex < left_count
                ? match_left[vertex] == neighbor - left_count
                : match_right[vertex - left_count] == neighbor;
            if ((parity == 0 && matched) || (parity == 1 && !matched)) continue;
            const int next_state = 2 * neighbor + 1 - parity;
            if (!seen[next_state]) { seen[next_state] = true; queue[tail++] = next_state; }
        }
    }

    std::uint64_t packed = static_cast<std::uint64_t>(matching_size) << 32;
    for (int vertex = 0; vertex < total; ++vertex) {
        const int code = seen[2 * vertex] ? 0 : seen[2 * vertex + 1] ? 1 : 2;
        packed |= static_cast<std::uint64_t>(code) << (2 * vertex);
    }
    return static_cast<std::int64_t>(packed);
}
