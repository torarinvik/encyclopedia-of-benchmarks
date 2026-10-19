#include <array>
#include <cstddef>
#include <cstdint>
#include <vector>

namespace {
constexpr std::int64_t max_n = 3'500'000;
constexpr std::array<std::uint32_t, 28> bucket_primes = {
    53U, 97U, 193U, 389U, 769U, 1543U, 3079U, 6151U, 12289U, 24593U,
    49157U, 98317U, 196613U, 393241U, 786433U, 1572869U, 3145739U,
    6291469U, 12582917U, 25165843U, 50331653U, 100663319U, 201326611U,
    402653189U, 805306457U, 1610612741U, 3221225473U, 4294967291U
};

std::size_t bucket_count_for(std::uint32_t n) {
    std::size_t index = 0;
    while (bucket_primes[index] < n) ++index;
    return bucket_primes[index];
}

std::size_t hash_key(std::uint32_t value, std::uint32_t base, std::size_t buckets) {
    std::array<std::uint8_t, 16> reverse{};
    std::size_t length = 0;
    do {
        const std::uint32_t digit = value % base;
        reverse[length++] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'a' + digit - 10);
        value /= base;
    } while (value != 0);
    std::uint64_t hash = 0;
    while (length != 0) hash = 5 * hash + reverse[--length];
    return static_cast<std::size_t>(hash % buckets);
}

bool hex_key_matches_decimal(std::uint32_t hex_value, std::uint32_t decimal_value) {
    while (hex_value != 0 && decimal_value != 0) {
        const std::uint32_t digit = hex_value & 15U;
        if (digit >= 10U || digit != decimal_value % 10U) return false;
        hex_value >>= 4;
        decimal_value /= 10U;
    }
    return hex_value == 0 && decimal_value == 0;
}
}

extern "C" std::int64_t shootout_hash(std::int64_t n) noexcept {
    if (n < 0 || n > max_n) return -1;
    const auto bound = static_cast<std::uint32_t>(n);
    const auto bucket_count = bucket_count_for(bound);
    std::vector<std::uint32_t> heads(bucket_count, 0);
    std::vector<std::uint32_t> next(static_cast<std::size_t>(bound) + 1, 0);

    for (std::uint32_t value = 1; value <= bound; ++value) {
        const auto bucket = hash_key(value, 16U, bucket_count);
        std::uint32_t node = heads[bucket];
        std::uint32_t previous = 0;
        while (node != 0) {
            if (node == value) break;
            previous = node;
            node = next[node];
        }
        if (node == 0) {
            if (previous == 0) heads[bucket] = value;
            else next[previous] = value;
        }
    }

    std::int64_t found = 0;
    for (std::uint32_t value = bound; value > 0; --value) {
        const auto bucket = hash_key(value, 10U, bucket_count);
        std::uint32_t node = heads[bucket];
        while (node != 0) {
            if (hex_key_matches_decimal(node, value)) {
                ++found;
                break;
            }
            node = next[node];
        }
    }
    return found;
}
