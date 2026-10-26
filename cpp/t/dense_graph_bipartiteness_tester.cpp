#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 64, MaxQ = 16, MaxInput = 82;
bool has_edge(std::int64_t row, std::size_t vertex) {
    return ((static_cast<std::uint64_t>(row) >> vertex) & UINT64_C(1)) != 0;
}
void put_i64(std::uint8_t *out, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = static_cast<std::uint8_t>(bits & 255); bits >>= 8; }
}
}

extern "C" std::int64_t dense_graph_bipartiteness_tester(const std::int64_t *values, std::size_t length,
                                                           std::uint8_t *output, std::size_t capacity) {
    if (values == nullptr || length < 4 || length > MaxInput || values[0] < 1 || values[0] > 64 ||
        values[1] < 1 || values[1] > 16) return -1;
    const auto n = static_cast<std::size_t>(values[0]), q = static_cast<std::size_t>(values[1]);
    if (q > n || length != 2 + n + q) return -1;
    const auto *rows = values + 2, *draws = rows + n;
    for (std::size_t i = 0; i < n; ++i) {
        if ((n < 64 && (rows[i] < 0 || (static_cast<std::uint64_t>(rows[i]) >> n) != 0)) || has_edge(rows[i], i)) return -1;
        for (std::size_t j = i + 1; j < n; ++j)
            if (has_edge(rows[i], j) != has_edge(rows[j], i)) return -1;
    }
    std::size_t remaining[MaxN], sample[MaxQ];
    for (std::size_t i = 0; i < n; ++i) remaining[i] = i;
    for (std::size_t i = 0; i < q; ++i) {
        if (draws[i] < 0 || static_cast<std::uint64_t>(draws[i]) >= n - i) return -1;
        const auto selected = i + static_cast<std::size_t>(draws[i]);
        const auto temp = remaining[i]; remaining[i] = remaining[selected]; remaining[selected] = temp;
        sample[i] = remaining[i];
    }
    bool adjacent[MaxQ][MaxQ]{};
    for (std::size_t i = 0; i < q; ++i)
        for (std::size_t j = i + 1; j < q; ++j)
            adjacent[i][j] = adjacent[j][i] = has_edge(rows[sample[i]], sample[j]);
    int color[MaxQ];
    for (std::size_t i = 0; i < q; ++i) color[i] = -1;
    int accepted = 1;
    for (std::size_t start = 0; start < q; ++start) {
        if (color[start] != -1) continue;
        std::size_t queue[MaxQ], head = 0, tail = 0;
        queue[tail++] = start; color[start] = 0;
        while (head < tail) {
            const auto vertex = queue[head++];
            for (std::size_t neighbor = 0; neighbor < q; ++neighbor) {
                if (!adjacent[vertex][neighbor]) continue;
                if (color[neighbor] == -1) { color[neighbor] = color[vertex] ^ 1; queue[tail++] = neighbor; }
                else if (color[neighbor] == color[vertex]) accepted = 0;
            }
        }
    }
    if (output == nullptr || capacity < 16) return -2;
    std::uint8_t staged[16];
    put_i64(staged, 0, accepted); put_i64(staged, 8, static_cast<std::int64_t>(q * (q - 1) / 2));
    for (std::size_t i = 0; i < 16; ++i) output[i] = staged[i];
    return 16;
}
