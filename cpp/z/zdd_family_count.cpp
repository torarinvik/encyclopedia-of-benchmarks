#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t zdd_family_count(const std::int64_t *input, std::size_t length,
                                         std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 34) return -1;
    const auto n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 6 || m0 < 0 || m0 > 32 || length != static_cast<std::size_t>(m0) + 2) return -1;
    const auto n = static_cast<std::size_t>(n0), limit = std::size_t{1} << n, m = static_cast<std::size_t>(m0);
    std::int64_t ids[64]{}, next[64]{}, vars[63]{}, lows[63]{}, highs[63]{}, counts[65]{};
    std::uint8_t seen[64]{}; counts[1] = 1;
    for (std::size_t i = 0; i < m; ++i) {
        const auto mask = input[2 + i];
        if (mask < 0 || static_cast<std::uint64_t>(mask) >= limit || seen[mask]) return -1;
        seen[mask] = 1; ids[mask] = 1;
    }
    std::size_t nodes = 0, current_count = limit;
    for (std::size_t variable = 0; variable < n; ++variable) {
        const auto next_count = current_count / 2;
        for (std::size_t p = 0; p < next_count; ++p) {
            const auto low = ids[2 * p], high = ids[2 * p + 1];
            if (high == 0) { next[p] = low; continue; }
            std::size_t found = nodes;
            for (std::size_t j = nodes; j > 0; --j) {
                const auto k = j - 1;
                if (static_cast<std::size_t>(vars[k]) != variable) break;
                if (lows[k] == low && highs[k] == high) { found = k; break; }
            }
            if (found == nodes) {
                vars[nodes] = static_cast<std::int64_t>(variable); lows[nodes] = low; highs[nodes] = high;
                counts[2 + nodes] = counts[low] + counts[high]; next[p] = static_cast<std::int64_t>(2 + nodes++);
            } else next[p] = static_cast<std::int64_t>(2 + found);
        }
        for (std::size_t p = 0; p < next_count; ++p) ids[p] = next[p];
        current_count = next_count;
    }
    const auto bytes = 8 * (3 + 3 * nodes);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, static_cast<std::int64_t>(nodes)); put_i64(output, 2, counts[ids[0]]);
    for (std::size_t i = 0; i < nodes; ++i) {
        put_i64(output, 3 + 3 * i, vars[i]); put_i64(output, 4 + 3 * i, lows[i]); put_i64(output, 5 + 3 * i, highs[i]);
    }
    return static_cast<std::int64_t>(bytes);
}
