#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 32, MAX_INPUT = 67, MAX_OUTPUT = 16;
void put_u64(std::uint8_t *out, std::size_t word, std::uint64_t value) {
    for (std::size_t b = 0; b < 8; ++b) out[word * 8 + b] = static_cast<std::uint8_t>(value >> (8 * b));
}
}

extern "C" std::int64_t psi_suffix_array_access(const std::int64_t *input, std::size_t length,
                                                  std::uint8_t *output, std::size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT) return -1;
    const auto n0 = input[0], query0 = input[1], stride0 = input[2];
    if (n0 < 1 || n0 > static_cast<std::int64_t>(MAX_N) || query0 < 0 || query0 >= n0 ||
        stride0 < 1 || stride0 > n0 || length != 3 + 2 * static_cast<std::size_t>(n0)) return -1;
    const auto n = static_cast<std::size_t>(n0), query = static_cast<std::size_t>(query0), stride = static_cast<std::size_t>(stride0);
    bool destinations[MAX_N] = {}, visited[MAX_N] = {};
    for (std::size_t i = 0; i < n; ++i) {
        const auto next = input[3 + i], sample = input[3 + n + i];
        if (next < 0 || static_cast<std::uint64_t>(next) >= n || destinations[next] || sample < 0 || sample > n0) return -1;
        destinations[next] = true;
    }
    std::size_t anchor = n;
    for (std::size_t i = 0; i < n; ++i) if (input[3 + n + i] != 0) { anchor = i; break; }
    if (anchor == n) return -1;
    const auto anchor_value = input[3 + n + anchor];
    if ((anchor_value - 1) % stride0 != 0) return -1;
    std::uint64_t full_sa[MAX_N] = {};
    std::size_t rank = anchor;
    std::int64_t value = anchor_value;
    for (std::size_t step = 0; step < n; ++step) {
        if (visited[rank]) return -1;
        visited[rank] = true; full_sa[rank] = static_cast<std::uint64_t>(value);
        rank = static_cast<std::size_t>(input[3 + rank]);
        value = value == n0 ? 1 : value + 1;
    }
    if (rank != anchor || value != anchor_value) return -1;
    for (std::size_t i = 0; i < n; ++i) {
        const auto expected = (full_sa[i] - 1) % stride == 0 ? static_cast<std::int64_t>(full_sa[i]) : 0;
        if (input[3 + n + i] != expected) return -1;
    }
    rank = query;
    std::size_t hops = 0;
    while (input[3 + n + rank] == 0) {
        rank = static_cast<std::size_t>(input[3 + rank]);
        if (++hops >= stride) return -1;
    }
    auto position0 = input[3 + n + rank] - 1 - static_cast<std::int64_t>(hops);
    position0 %= n0; if (position0 < 0) position0 += n0;
    if (!output || capacity < MAX_OUTPUT) return -2;
    put_u64(output, 0, static_cast<std::uint64_t>(position0 + 1));
    put_u64(output, 1, hops);
    return MAX_OUTPUT;
}
