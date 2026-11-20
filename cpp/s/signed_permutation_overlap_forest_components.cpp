#include <array>
#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <utility>

namespace {
constexpr int kN = 8;
constexpr int kVertices = 2 * kN + 2;
constexpr int kCycles = kN + 1;
constexpr std::size_t kMaxInput = kN + 2;
constexpr std::size_t kMaxOutput = 8 * (1 + 3 * kCycles);

void store_word(std::array<std::uint8_t, kMaxOutput>& bytes, int word,
                std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte) {
        bytes[static_cast<std::size_t>(word * 8 + byte)] =
            static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8U;
    }
}
}

extern "C" std::int64_t signed_permutation_overlap_forest_components(
    const std::int64_t* input, std::size_t length, std::uint8_t* output,
    std::size_t capacity) noexcept {
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto n64 = input[0];
    if (n64 < 1 || n64 > kN || length != static_cast<std::size_t>(n64 + 1)) return -1;
    const int n = static_cast<int>(n64), vertex_count = 2 * n + 2;

    std::array<int, kVertices> pi{};
    pi[vertex_count - 1] = vertex_count - 1;
    unsigned seen = 0;
    for (int position = 0; position < n; ++position) {
        const auto gene = input[position + 1];
        if (gene == 0 || gene < -n || gene > n) return -1;
        const int absolute = static_cast<int>(gene < 0 ? -gene : gene);
        const unsigned bit = 1U << (absolute - 1);
        if ((seen & bit) != 0) return -1;
        seen |= bit;
        int left = 2 * absolute - 1, right = 2 * absolute;
        if (gene < 0) std::swap(left, right);
        pi[2 * position + 1] = left;
        pi[2 * position + 2] = right;
    }
    std::array<int, kVertices> gray{};
    for (int pair = 0; pair <= n; ++pair) {
        const int left = pi[2 * pair], right = pi[2 * pair + 1];
        gray[left] = right;
        gray[right] = left;
    }
    std::array<int, kVertices> cycle_of{};
    cycle_of.fill(-1);
    std::array<int, kCycles> begin{}, end{};
    int cycle_count = 0;
    for (int seed = 0; seed < vertex_count; ++seed) {
        if (cycle_of[seed] >= 0) continue;
        const int cid = cycle_count++;
        int vertex = seed, low = seed, high = seed;
        while (cycle_of[vertex] < 0) {
            cycle_of[vertex] = cid;
            low = std::min(low, vertex);
            high = std::max(high, vertex);
            vertex = gray[vertex ^ 1];
        }
        begin[cid] = low;
        end[cid] = high;
    }

    std::array<int, kCycles> parent{};
    for (int cid = 0; cid < cycle_count; ++cid) parent[cid] = cid;
    std::array<int, kCycles> stack_id{}, stack_begin{}, stack_end{};
    int top = 0;
    for (int vertex = 0; vertex < vertex_count; ++vertex) {
        const int cid = cycle_of[vertex], low = begin[cid], high = end[cid];
        if (vertex == low) {
            stack_id[top] = cid;
            stack_begin[top] = low;
            stack_end[top] = high;
            ++top;
        }
        int extent_begin = low, extent_end = high;
        while (top != 0 && stack_begin[top - 1] > low) {
            --top;
            const int popped = stack_id[top];
            extent_begin = std::min(extent_begin, stack_begin[top]);
            extent_end = std::max(extent_end, stack_end[top]);
            parent[popped] = cid;
        }
        if (top == 0) return -1;
        stack_begin[top - 1] = std::min(stack_begin[top - 1], extent_begin);
        stack_end[top - 1] = std::max(stack_end[top - 1], extent_end);
        if (vertex == stack_end[top - 1]) --top;
    }

    std::array<int, kCycles> component{};
    for (int cid = 0; cid < cycle_count; ++cid)
        component[cid] = parent[cid] == cid ? begin[cid] : component[parent[cid]];
    std::array<std::int64_t, 1 + 3 * kCycles> words{};
    words[0] = cycle_count;
    for (int cid = 0; cid < cycle_count; ++cid) {
        words[1 + 3 * cid] = begin[cid];
        words[2 + 3 * cid] = end[cid];
        words[3 + 3 * cid] = component[cid];
    }
    const std::size_t bytes_needed = static_cast<std::size_t>(1 + 3 * cycle_count) * 8;
    if (output == nullptr || capacity < bytes_needed) return -2;
    std::array<std::uint8_t, kMaxOutput> staged{};
    for (int word = 0; word < 1 + 3 * cycle_count; ++word)
        store_word(staged, word, words[word]);
    for (std::size_t byte = 0; byte < bytes_needed; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(bytes_needed);
}
