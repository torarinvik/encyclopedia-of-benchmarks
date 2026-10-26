// Clean-room GBBS Yoshida recursive MIS query; see package LICENSE.txt.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 12, MAX_M = 24, MAX_INPUT = 52, MAX_CUTOFF = 128;

std::uint64_t hash64(std::uint64_t value) {
    std::uint64_t mixed = value * UINT64_C(3935559000370003845) + UINT64_C(2691343689449507681);
    mixed ^= mixed >> 21;
    mixed ^= mixed << 37;
    mixed ^= mixed >> 4;
    mixed *= UINT64_C(4768777513237032717);
    mixed ^= mixed << 20;
    mixed ^= mixed >> 41;
    mixed ^= mixed << 5;
    return mixed;
}

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}

std::int64_t query(std::size_t vertex, const std::size_t* degree,
                   const std::size_t* neighbors, const std::uint64_t* priority,
                   std::size_t& work, std::size_t cutoff) {
    for (std::size_t index = 0; index < degree[vertex]; ++index) {
        if (work == cutoff) return -1;
        const auto neighbor = neighbors[vertex * MAX_N + index];
        ++work;
        if (priority[vertex] < priority[neighbor] ||
            (priority[vertex] == priority[neighbor] && vertex <= neighbor)) break;
        const auto status = query(neighbor, degree, neighbors, priority, work, cutoff);
        if (status == 1) return 0;
        if (status == -1) return -1;
    }
    return 1;
}
} // namespace

extern "C" std::int64_t gbbs_yoshida_query_mis(const std::int64_t* input,
        std::size_t length, std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 4 || length > MAX_INPUT) return -1;
    const auto n64 = input[0], m64 = input[1], root64 = input[2], cutoff64 = input[3];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MAX_M) || root64 < 0 || root64 >= n64 ||
        cutoff64 < 0 || cutoff64 > static_cast<std::int64_t>(MAX_CUTOFF) ||
        length != 4 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64);
    const auto m = static_cast<std::size_t>(m64);
    bool adjacent[MAX_N][MAX_N] = {};
    std::size_t degree[MAX_N] = {};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[4 + 2 * edge], v64 = input[5 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = true;
        ++degree[u]; ++degree[v];
    }
    if (output == nullptr || capacity < 16) return -2;
    std::uint64_t priority[MAX_N];
    std::size_t neighbors[MAX_N][MAX_N] = {};
    for (std::size_t vertex = 0; vertex < n; ++vertex) priority[vertex] = hash64(vertex);
    for (std::size_t vertex = 0; vertex < n; ++vertex) {
        std::size_t inserted = 0;
        for (std::size_t other = 0; other < n; ++other) if (adjacent[vertex][other]) {
            auto position = inserted;
            while (position > 0) {
                const auto previous = neighbors[vertex][position - 1];
                if (priority[previous] < priority[other] ||
                    (priority[previous] == priority[other] && previous < other)) break;
                neighbors[vertex][position] = previous;
                --position;
            }
            neighbors[vertex][position] = other;
            ++inserted;
        }
    }
    std::size_t work = 0;
    const auto status = query(static_cast<std::size_t>(root64), degree,
                              &neighbors[0][0], priority, work,
                              static_cast<std::size_t>(cutoff64));
    store_i64_le(output, 0, status);
    store_i64_le(output, 8, static_cast<std::int64_t>(work));
    return 16;
}
