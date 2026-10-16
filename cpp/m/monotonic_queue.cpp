#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 4096;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
std::uint64_t hash_i32(std::uint64_t hash, std::int64_t value) {
    std::uint32_t bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(value));
    for (unsigned shift = 0; shift < 32; shift += 8) hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}
extern "C" std::int64_t monotonic_queue(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_N + 2) return -1;
    const auto n64 = input[0], window64 = input[1];
    if (n64 < 1 || n64 > static_cast<std::int64_t>(MAX_N) || window64 < 1 || window64 > n64 || length != static_cast<std::size_t>(n64) + 2) return -1;
    const auto n = static_cast<std::size_t>(n64), window = static_cast<std::size_t>(window64);
    for (std::size_t i = 0; i < n; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    std::size_t deque[MAX_N], head = 0, tail = 0;
    std::uint64_t hash = FNV_OFFSET;
    for (std::size_t i = 0; i < n; ++i) {
        while (head < tail && deque[head] + window <= i) ++head;
        while (head < tail && input[2 + deque[tail - 1]] <= input[2 + i]) --tail;
        deque[tail++] = i;
        if (i + 1 >= window) hash = hash_i32(hash, input[2 + deque[head]]);
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
