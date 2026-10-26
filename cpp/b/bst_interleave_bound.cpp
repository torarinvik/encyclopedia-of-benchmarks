#include <cstddef>
#include <cstdint>

namespace {
constexpr int kMaxNodes = 8;
constexpr int kMaxAccesses = 16;
constexpr std::size_t kMaxInput = 36;

void store_i64_le(std::uint8_t *output, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (int byte = 0; byte < 8; ++byte) {
        output[byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t bst_interleave_bound(const std::int64_t *input,
                                               std::size_t length,
                                               std::uint8_t *output,
                                               std::size_t capacity)
{
    if (input == nullptr || length < 3 || length > kMaxInput) return -1;
    const auto n_raw = input[0], root_raw = input[1];
    if (n_raw < 1 || n_raw > kMaxNodes || root_raw < 0 || root_raw >= n_raw) return -1;
    const int n = static_cast<int>(n_raw), root = static_cast<int>(root_raw);
    int left[kMaxNodes], right[kMaxNodes], parent[kMaxNodes], parent_count[kMaxNodes]{};
    std::size_t position = 2;
    for (int node = 0; node < n; ++node) {
        if (position + 2 > length) return -1;
        const auto l = input[position++], r = input[position++];
        if (l < -1 || l >= n || r < -1 || r >= n || l == node || r == node || (l >= 0 && l == r)) return -1;
        left[node] = static_cast<int>(l); right[node] = static_cast<int>(r); parent[node] = -1;
        if (l >= 0) { ++parent_count[l]; parent[l] = node; }
        if (r >= 0) { ++parent_count[r]; parent[r] = node; }
    }
    if (parent_count[root] != 0) return -1;
    for (int node = 0; node < n; ++node) if (node != root && parent_count[node] != 1) return -1;
    if (position >= length) return -1;
    const auto m_raw = input[position++];
    if (m_raw < 0 || m_raw > kMaxAccesses || length != position + static_cast<std::size_t>(m_raw)) return -1;
    const int m = static_cast<int>(m_raw);
    int accesses[kMaxAccesses];
    for (int i = 0; i < m; ++i) {
        const auto key = input[position++];
        if (key < 0 || key >= n) return -1;
        accesses[i] = static_cast<int>(key);
    }

    int stack_node[kMaxNodes], stack_low[kMaxNodes], stack_high[kMaxNodes];
    int visited[kMaxNodes]{}, visited_count = 0, stack_size = 1;
    stack_node[0] = root; stack_low[0] = -1; stack_high[0] = n;
    while (stack_size > 0) {
        --stack_size;
        const int node = stack_node[stack_size], low = stack_low[stack_size], high = stack_high[stack_size];
        if (visited[node] || node <= low || node >= high) return -1;
        visited[node] = 1; ++visited_count;
        if (left[node] >= 0) {
            stack_node[stack_size] = left[node]; stack_low[stack_size] = low; stack_high[stack_size] = node; ++stack_size;
        }
        if (right[node] >= 0) {
            stack_node[stack_size] = right[node]; stack_low[stack_size] = node; stack_high[stack_size] = high; ++stack_size;
        }
    }
    if (visited_count != n) return -1;

    std::int64_t bound = 0;
    for (int pivot = 0; pivot < n; ++pivot) {
        int previous = -1;
        for (int i = 0; i < m; ++i) {
            int ancestor = accesses[i];
            while (ancestor >= 0 && ancestor != pivot) ancestor = parent[ancestor];
            if (ancestor == pivot) {
                const int side = accesses[i] <= pivot ? 0 : 1;
                if (previous >= 0 && side != previous) ++bound;
                previous = side;
            }
        }
    }
    if (output == nullptr || capacity < 8) return -2;
    std::uint8_t staged[8];
    store_i64_le(staged, bound);
    for (int byte = 0; byte < 8; ++byte) output[byte] = staged[byte];
    return 8;
}
