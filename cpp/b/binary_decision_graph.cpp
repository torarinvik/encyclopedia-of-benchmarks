#include <cstddef>
#include <cstdint>

namespace {
void put_i64(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) out[at * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t binary_decision_graph(const std::int64_t *input, std::size_t length,
                                               std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > 65) return -1;
    const auto nv = input[0];
    if (nv < 1 || nv > 6 || length != 1 + (std::size_t{1} << nv)) return -1;
    const auto n = static_cast<std::size_t>(nv), count = std::size_t{1} << nv;
    std::int64_t ids[64]{}, next[64]{}, vars[63]{}, lows[63]{}, highs[63]{};
    for (std::size_t i = 0; i < count; ++i) {
        if (input[i + 1] != 0 && input[i + 1] != 1) return -1;
        ids[i] = input[i + 1];
    }
    std::size_t nodes = 0, current_count = count;
    for (std::size_t step = 0; step < n; ++step) {
        const auto var = n - 1 - step, next_count = current_count / 2;
        for (std::size_t p = 0; p < next_count; ++p) {
            const auto lo = ids[2 * p], hi = ids[2 * p + 1];
            if (lo == hi) { next[p] = lo; continue; }
            std::size_t found = nodes;
            for (std::size_t j = nodes; j > 0; --j) {
                const auto k = j - 1;
                if (static_cast<std::size_t>(vars[k]) != var) break;
                if (lows[k] == lo && highs[k] == hi) { found = k; break; }
            }
            if (found == nodes) {
                vars[nodes] = static_cast<std::int64_t>(var); lows[nodes] = lo; highs[nodes] = hi;
                next[p] = static_cast<std::int64_t>(2 + nodes++);
            } else next[p] = static_cast<std::int64_t>(2 + found);
        }
        for (std::size_t p = 0; p < next_count; ++p) ids[p] = next[p];
        current_count = next_count;
    }
    const auto bytes = 8 * (2 + 3 * nodes);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, static_cast<std::int64_t>(nodes));
    for (std::size_t i = 0; i < nodes; ++i) {
        put_i64(output, 2 + 3 * i, vars[i]); put_i64(output, 3 + 3 * i, lows[i]); put_i64(output, 4 + 3 * i, highs[i]);
    }
    return static_cast<std::int64_t>(bytes);
}
