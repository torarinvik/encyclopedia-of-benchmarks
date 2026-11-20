#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t set_limit = 8, cell_count = 48, max_peels = 16;
std::uint64_t checksum(std::int64_t key) {
    const auto x = static_cast<std::uint64_t>(key);
    return x * x + 3 * x + 7;
}
std::array<std::size_t, 3> locations(std::int64_t key) {
    const auto x = static_cast<std::uint64_t>(key);
    return {static_cast<std::size_t>(x % 16), 16 + static_cast<std::size_t>((3 * x + 5) % 16),
            32 + static_cast<std::size_t>((5 * x + 9) % 16)};
}
void write_i64(std::uint8_t *output, std::size_t index, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t b = 0; b < 8; ++b) output[index * 8 + b] = static_cast<std::uint8_t>(bits >> (8 * b));
}
}

extern "C" std::int64_t invertible_bloom_lookup_table_reconciliation(
        const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2 || length > 19) return -1;
    const auto a_raw = input[0], b_raw = input[1];
    if (a_raw < 0 || a_raw > 8 || b_raw < 0 || b_raw > 8) return -1;
    const auto a_count = static_cast<std::size_t>(a_raw), b_count = static_cast<std::size_t>(b_raw);
    if (length != 2 + a_count + b_count) return -1;
    for (std::size_t side = 0; side < 2; ++side) {
        const auto n = side == 0 ? a_count : b_count;
        const auto start = side == 0 ? 2 : 2 + a_count;
        std::int64_t previous = -1;
        for (std::size_t i = 0; i < n; ++i) {
            const auto key = input[start + i];
            if (key < 0 || key > 63 || key <= previous) return -1;
            previous = key;
        }
    }

    std::array<std::int64_t, cell_count> counts{}, sums{}, checks{};
    for (std::size_t side = 0; side < 2; ++side) {
        const auto n = side == 0 ? a_count : b_count;
        const std::int64_t sign = side == 0 ? 1 : -1;
        const auto start = side == 0 ? 2 : 2 + a_count;
        for (std::size_t i = 0; i < n; ++i) {
            const auto key = input[start + i];
            for (const auto slot : locations(key)) {
                counts[slot] += sign; sums[slot] += sign * key;
                checks[slot] += sign * static_cast<std::int64_t>(checksum(key));
            }
        }
    }

    std::array<std::int64_t, max_peels> positive{}, negative{};
    std::size_t positive_count = 0, negative_count = 0;
    bool repeated = false;
    for (std::size_t peel = 0; peel < max_peels; ++peel) {
        bool zero = true;
        for (std::size_t i = 0; i < cell_count; ++i)
            if (counts[i] || sums[i] || checks[i]) { zero = false; break; }
        if (zero) break;
        bool found = false;
        std::int64_t sign = 0, key = 0;
        for (std::size_t i = 0; i < cell_count; ++i) {
            if (counts[i] != 1 && counts[i] != -1) continue;
            const auto candidate_sign = counts[i];
            const auto candidate = candidate_sign * sums[i];
            if (candidate < 0 || candidate > 63 || checks[i] != candidate_sign * static_cast<std::int64_t>(checksum(candidate))) continue;
            sign = candidate_sign; key = candidate; found = true; break;
        }
        if (!found) break;
        for (std::size_t i = 0; i < positive_count; ++i) if (positive[i] == key) repeated = true;
        for (std::size_t i = 0; i < negative_count; ++i) if (negative[i] == key) repeated = true;
        if (repeated) break;
        if (sign > 0) positive[positive_count++] = key; else negative[negative_count++] = key;
        for (const auto slot : locations(key)) {
            counts[slot] -= sign; sums[slot] -= sign * key;
            checks[slot] -= sign * static_cast<std::int64_t>(checksum(key));
        }
    }

    bool zero = true;
    for (std::size_t i = 0; i < cell_count; ++i) if (counts[i] || sums[i] || checks[i]) { zero = false; break; }
    auto sort_prefix = [](auto &values, std::size_t n) {
        for (std::size_t i = 1; i < n; ++i) {
            const auto value = values[i]; std::size_t j = i;
            while (j && values[j - 1] > value) { values[j] = values[j - 1]; --j; }
            values[j] = value;
        }
    };
    sort_prefix(positive, positive_count); sort_prefix(negative, negative_count);
    std::array<std::int64_t, 3 + 2 * max_peels> staged{};
    std::size_t words = 0;
    staged[words++] = (!repeated && zero) ? 1 : 0;
    staged[words++] = static_cast<std::int64_t>(positive_count);
    staged[words++] = static_cast<std::int64_t>(negative_count);
    for (std::size_t i = 0; i < positive_count; ++i) staged[words++] = positive[i];
    for (std::size_t i = 0; i < negative_count; ++i) staged[words++] = negative[i];
    const auto required = words * 8;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t i = 0; i < words; ++i) write_i64(output, i, staged[i]);
    return static_cast<std::int64_t>(required);
}
