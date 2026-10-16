#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 512;
constexpr std::uint64_t FNV_OFFSET_BASIS = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);

std::uint64_t fnv_word(std::uint64_t hash, std::int64_t value)
{
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}
}

extern "C" std::int64_t kasai_algorithm(const std::int64_t *values, std::size_t length)
{
    if (values == nullptr || length < 1 || values[0] < 0 || values[0] > static_cast<std::int64_t>(MAX_LENGTH)) return -1;
    const std::size_t n = static_cast<std::size_t>(values[0]);
    if (length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < n; ++i)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    std::array<std::size_t, MAX_LENGTH> suffixes{};
    std::array<std::size_t, MAX_LENGTH> rank{};
    std::array<bool, MAX_LENGTH> seen{};
    std::array<std::int64_t, MAX_LENGTH> lcp{};
    for (std::size_t position = 0; position < n; ++position) {
        const std::int64_t suffix_value = values[1 + n + position];
        if (suffix_value < 0 || static_cast<std::uint64_t>(suffix_value) >= n) return -1;
        const std::size_t suffix = static_cast<std::size_t>(suffix_value);
        if (seen[suffix]) return -1;
        seen[suffix] = true;
        suffixes[position] = suffix;
        rank[suffix] = position;
    }

    for (std::size_t position = 1; position < n; ++position) {
        const std::size_t left = suffixes[position - 1];
        const std::size_t right = suffixes[position];
        const std::int64_t left_tail_rank = left + 1 < n ? static_cast<std::int64_t>(rank[left + 1]) : -1;
        const std::int64_t right_tail_rank = right + 1 < n ? static_cast<std::int64_t>(rank[right + 1]) : -1;
        const std::int64_t left_byte = values[1 + left];
        const std::int64_t right_byte = values[1 + right];
        if (left_byte > right_byte ||
            (left_byte == right_byte && left_tail_rank >= right_tail_rank)) return -1;
    }

    std::size_t common = 0;
    for (std::size_t start = 0; start < n; ++start) {
        const std::size_t current_rank = rank[start];
        if (current_rank == n - 1) {
            common = 0;
            continue;
        }
        const std::size_t next_start = suffixes[current_rank + 1];
        while (start + common < n && next_start + common < n &&
               values[1 + start + common] == values[1 + next_start + common]) ++common;
        lcp[current_rank] = static_cast<std::int64_t>(common);
        if (common > 0) --common;
    }

    std::uint64_t hash = fnv_word(FNV_OFFSET_BASIS, static_cast<std::int64_t>(n));
    for (std::size_t i = 0; i < n; ++i) hash = fnv_word(hash, lcp[i]);
    return static_cast<std::int64_t>(hash & static_cast<std::uint64_t>(INT64_MAX));
}
