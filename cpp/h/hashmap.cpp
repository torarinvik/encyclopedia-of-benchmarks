/* Bounded trace for the pinned Go separate-chaining hashmap. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 128;
constexpr std::size_t max_entries = 128;
constexpr std::size_t max_initial_capacity = 64;
constexpr std::size_t max_capacity = 256;
constexpr std::size_t max_input_length = 2 + 3 * max_operations;
constexpr std::uint64_t fnv_offset = UINT64_C(14695981039346656037);
constexpr std::uint64_t fnv_prime = UINT64_C(1099511628211);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) noexcept {
    return (hash ^ byte) * fnv_prime;
}

std::uint64_t hash_key(std::int64_t key) noexcept {
    auto hash = fnv_offset;
    auto magnitude = static_cast<std::uint64_t>(key < 0 ? -key : key);
    std::uint8_t digits[10];
    std::size_t count = 0;
    do {
        digits[count++] = static_cast<std::uint8_t>(magnitude % 10);
        magnitude /= 10;
    } while (magnitude != 0);
    if (key < 0) hash = hash_byte(hash, static_cast<std::uint8_t>('-'));
    while (count != 0)
        hash = hash_byte(hash, static_cast<std::uint8_t>('0' + digits[--count]));
    return hash ^ (hash >> 16);
}

std::size_t bucket_for(std::int64_t key, std::size_t capacity) noexcept {
    return static_cast<std::size_t>(hash_key(key) & (capacity - 1));
}

void put_i64_le(std::uint8_t *output, std::size_t word, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t hashmap(const std::int64_t *input, std::size_t length,
                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 2 || length > max_input_length) return -1;
    const auto initial_capacity = input[0];
    const auto operation_count = input[1];
    if (initial_capacity < 1 || initial_capacity > static_cast<std::int64_t>(max_initial_capacity) ||
        (initial_capacity & (initial_capacity - 1)) != 0 || operation_count < 0 ||
        operation_count > static_cast<std::int64_t>(max_operations) ||
        length != 2 + 3 * static_cast<std::size_t>(operation_count)) return -1;
    for (std::size_t i = 0; i < static_cast<std::size_t>(operation_count); ++i) {
        const auto op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        if (op < 0 || op > 2 || key < INT32_MIN || key > INT32_MAX) return -1;
        if (op == 0) {
            if (value < INT32_MIN || value > INT32_MAX) return -1;
        } else if (value != 0) return -1;
    }

    std::int64_t keys[max_entries], values[max_entries];
    std::int64_t results[1 + 3 * max_operations + 2];
    int next[max_entries], heads[max_capacity], tails[max_capacity];
    for (std::size_t i = 0; i < max_entries; ++i) next[i] = -1;
    for (std::size_t i = 0; i < max_capacity; ++i) heads[i] = tails[i] = -1;
    std::size_t size = 0, map_capacity = static_cast<std::size_t>(initial_capacity);
    std::size_t result_words = 1, query_count = 0;

    for (std::size_t operation = 0; operation < static_cast<std::size_t>(operation_count); ++operation) {
        const auto op = input[2 + 3 * operation], key = input[3 + 3 * operation];
        const auto value = input[4 + 3 * operation];
        const auto bucket = bucket_for(key, map_capacity);
        int entry = heads[bucket];
        while (entry >= 0 && keys[entry] != key) entry = next[entry];
        if (op == 0) {
            if (entry >= 0) {
                values[entry] = value;
                continue;
            }
            if (size >= max_entries) return -1;
            entry = static_cast<int>(size++);
            keys[entry] = key;
            values[entry] = value;
            if (heads[bucket] < 0) heads[bucket] = entry;
            else next[tails[bucket]] = entry;
            tails[bucket] = entry;
            if (size * 4 > map_capacity * 3) {
                int order[max_entries];
                std::size_t order_count = 0;
                for (std::size_t old_bucket = 0; old_bucket < map_capacity; ++old_bucket)
                    for (int node = heads[old_bucket]; node >= 0; node = next[node]) order[order_count++] = node;
                map_capacity *= 2;
                for (std::size_t i = 0; i < max_capacity; ++i) heads[i] = tails[i] = -1;
                for (std::size_t i = 0; i < size; ++i) next[i] = -1;
                for (std::size_t i = 0; i < order_count; ++i) {
                    const int node = order[i];
                    const auto new_bucket = bucket_for(keys[node], map_capacity);
                    if (heads[new_bucket] < 0) heads[new_bucket] = node;
                    else next[tails[new_bucket]] = node;
                    tails[new_bucket] = node;
                }
            }
        } else {
            results[result_words++] = op;
            if (op == 1) {
                results[result_words++] = entry >= 0 ? 1 : 0;
                results[result_words++] = entry >= 0 ? values[entry] : 0;
            } else results[result_words++] = entry >= 0 ? 1 : 0;
            ++query_count;
        }
    }
    results[0] = static_cast<std::int64_t>(query_count);
    results[result_words++] = static_cast<std::int64_t>(size);
    results[result_words++] = static_cast<std::int64_t>(map_capacity);
    const auto bytes = result_words * 8;
    if (output == nullptr || output_capacity < bytes) return -2;
    for (std::size_t word = 0; word < result_words; ++word) put_i64_le(output, word, results[word]);
    return static_cast<std::int64_t>(bytes);
}
