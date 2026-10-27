#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int V = 12, C = 32;
constexpr std::size_t IN = 98, OUT = 96;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
}

extern "C" std::int64_t random_planted_3sat_majority_vote(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > IN || input[0] < 3 || input[0] > V || input[1] < 0 || input[1] > C) return -1;
    int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;
    std::array<int, V> positive{}, negative{};
    for (int c = 0; c < m; ++c) {
        std::array<bool, V> seen{};
        for (int j = 0; j < 3; ++j) {
            auto raw = input[2 + 3 * c + j];
            if (raw == 0 || raw < -n || raw > n) return -1;
            int lit = static_cast<int>(raw), v = (lit > 0 ? lit : -lit) - 1;
            if (seen[v]) return -1;
            seen[v] = true;
            if (lit > 0) ++positive[v]; else ++negative[v];
        }
    }
    const std::size_t bytes = 8 * static_cast<std::size_t>(n);
    if (!output || capacity < bytes) return -2;
    std::array<std::uint8_t, OUT> staged{};
    for (int v = 0; v < n; ++v) put(staged.data(), 8 * static_cast<std::size_t>(v), positive[v] > negative[v] ? 1 : -1);
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
