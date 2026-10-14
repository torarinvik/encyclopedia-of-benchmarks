// One-pass two-sum with portable open addressing and first-pair ordering.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_values = 256;
constexpr std::size_t table_size = 512;
constexpr std::size_t index_base = 256;

std::size_t hash_slot(std::int64_t key, std::size_t capacity) noexcept
{
    constexpr std::int64_t prime = INT64_C(2147483647);
    std::int64_t normalized = key % prime;
    if (normalized < 0) normalized += prime;
    const std::int64_t mixed = (normalized * INT64_C(48271)) % prime;
    return static_cast<std::size_t>(mixed) % capacity;
}
}

extern "C" std::int64_t two_sum(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > max_values + 1) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < INT64_C(-2147483648) || values[index] > INT64_C(2147483647)) return -2;
    }
    const std::int64_t target = values[0];
    const std::size_t value_count = length - 1;
    std::size_t capacity = 1;
    while (capacity < value_count * 2) capacity *= 2;
    std::int64_t keys[table_size];
    std::size_t first_indices[table_size];
    bool occupied[table_size] = {};

    for (std::size_t index = 0; index < value_count; ++index) {
        const std::int64_t current = values[index + 1];
        const std::int64_t complement = target - current;
        std::size_t slot = hash_slot(complement, capacity);
        while (occupied[slot] && keys[slot] != complement) slot = (slot + 1) % capacity;
        if (occupied[slot]) return static_cast<std::int64_t>(first_indices[slot] * index_base + index);

        slot = hash_slot(current, capacity);
        while (occupied[slot] && keys[slot] != current) slot = (slot + 1) % capacity;
        if (!occupied[slot]) {
            occupied[slot] = true;
            keys[slot] = current;
            first_indices[slot] = index;
        }
    }
    return -1;
}
