#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr int V = 12, C = 32;
constexpr std::size_t IN = 98, OUT = 104;
void put(std::uint8_t *out, std::size_t at, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) { out[at + i] = static_cast<std::uint8_t>(bits & 255u); bits >>= 8; }
}
std::uint32_t sat_set(const std::array<int, 3 * C> &clauses, int m, int n, unsigned code) {
    std::uint32_t set = 0;
    for (int c = 0; c < m; ++c) {
        bool satisfied = false;
        for (int j = 0; j < 3; ++j) {
            int lit = clauses[3 * c + j], v = (lit > 0 ? lit : -lit) - 1;
            bool truth = ((code >> (n - 1 - v)) & 1u) != 0;
            if (truth == (lit > 0)) satisfied = true;
        }
        if (satisfied) set |= std::uint32_t{1} << c;
    }
    return set;
}
}

extern "C" std::int64_t random_planted_3sat_k_opt(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 2 || length > IN || input[0] < 3 || input[0] > V || input[1] < 0 || input[1] > C) return -1;
    int n = static_cast<int>(input[0]), m = static_cast<int>(input[1]);
    if (length != static_cast<std::size_t>(2 + 3 * m)) return -1;
    std::array<int, 3 * C> clauses{};
    std::array<int, V> positive{}, negative{};
    for (int c = 0; c < m; ++c) {
        std::array<bool, V> seen{};
        for (int j = 0; j < 3; ++j) {
            auto raw = input[2 + 3 * c + j];
            if (raw == 0 || raw < -n || raw > n) return -1;
            int lit = static_cast<int>(raw), v = (lit > 0 ? lit : -lit) - 1;
            if (seen[v]) return -1;
            seen[v] = true; clauses[3 * c + j] = lit;
            if (lit > 0) ++positive[v]; else ++negative[v];
        }
    }
    unsigned current = 0;
    for (int v = 0; v < n; ++v) if (positive[v] > negative[v]) current |= 1u << (n - 1 - v);
    const std::uint32_t full = m == 32 ? ~std::uint32_t{0} : (m == 0 ? 0u : ((std::uint32_t{1} << m) - 1u));
    int status = 0, k = 1;
    while (true) {
        std::uint32_t before = sat_set(clauses, m, n, current);
        if (before == full) { status = 1; break; }
        bool found = false;
        for (unsigned candidate = 0; candidate < (1u << n); ++candidate) {
            unsigned diff = current ^ candidate;
            int distance = 0;
            for (unsigned x = diff; x != 0; x &= x - 1u) ++distance;
            if (distance == 0 || distance > k) continue;
            std::uint32_t after = sat_set(clauses, m, n, candidate);
            if (after != before && (after & before) == before) { current = candidate; found = true; break; }
        }
        if (found) continue;
        if (k == n) { status = 0; break; }
        ++k;
    }
    const std::size_t bytes = 8 * static_cast<std::size_t>(n + 1);
    if (!output || capacity < bytes) return -2;
    std::array<std::uint8_t, OUT> staged{};
    put(staged.data(), 0, status);
    for (int v = 0; v < n; ++v) {
        bool truth = ((current >> (n - 1 - v)) & 1u) != 0;
        put(staged.data(), 8 * static_cast<std::size_t>(v + 1), truth ? 1 : -1);
    }
    for (std::size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<std::int64_t>(bytes);
}
