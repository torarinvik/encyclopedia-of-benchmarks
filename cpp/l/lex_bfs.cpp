#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxN = 16, MaxM = 120, MaxInput = 3 + 2 * MaxM;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t lex_bfs(const std::int64_t* input, std::size_t length,
    std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 3 || length > MaxInput) return -1;
    const auto n64 = input[0], m64 = input[1], start64 = input[2];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MaxN) || m64 < 0 ||
        m64 > static_cast<std::int64_t>(MaxM) || start64 < 0 || start64 >= n64 ||
        length != 3 + 2 * static_cast<std::size_t>(m64)) return -1;
    const auto n = static_cast<std::size_t>(n64), m = static_cast<std::size_t>(m64);
    const auto start = static_cast<std::size_t>(start64);
    std::array<std::array<bool, MaxN>, MaxN> adjacency{};
    for (std::size_t edge = 0; edge < m; ++edge) {
        const auto u64 = input[3 + 2 * edge], v64 = input[4 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const auto u = static_cast<std::size_t>(u64), v = static_cast<std::size_t>(v64);
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = true;
    }
    const auto outputBytes = 8 * n;
    if (!output || capacity < outputBytes) return -2;
    std::array<std::array<std::int64_t, MaxN>, MaxN> labels{};
    std::array<std::size_t, MaxN> labelLen{};
    std::array<std::int64_t, MaxN> order{};
    std::array<bool, MaxN> selected{};
    auto current = start;
    for (std::size_t step = 0; step < n; ++step) {
        if (step > 0) {
            bool haveBest = false;
            for (std::size_t vertex = 0; vertex < n; ++vertex) {
                if (selected[vertex]) continue;
                if (!haveBest) { current = vertex; haveBest = true; continue; }
                const auto shared = labelLen[vertex] < labelLen[current]
                    ? labelLen[vertex] : labelLen[current];
                std::size_t position = 0;
                bool decided = false;
                while (position < shared) {
                    if (labels[vertex][position] != labels[current][position]) {
                        if (labels[vertex][position] > labels[current][position]) current = vertex;
                        decided = true;
                        break;
                    }
                    ++position;
                }
                if (!decided && (labelLen[vertex] > labelLen[current] ||
                    (labelLen[vertex] == labelLen[current] && vertex < current))) current = vertex;
            }
        }
        selected[current] = true;
        order[step] = static_cast<std::int64_t>(current);
        for (std::size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacency[current][neighbor] || selected[neighbor]) continue;
            for (auto position = labelLen[neighbor]; position > 0; --position)
                labels[neighbor][position] = labels[neighbor][position - 1];
            labels[neighbor][0] = static_cast<std::int64_t>(step);
            ++labelLen[neighbor];
        }
    }
    for (std::size_t index = 0; index < n; ++index) storeI64LE(output, 8 * index, order[index]);
    return static_cast<std::int64_t>(outputBytes);
}
