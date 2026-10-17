#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_OPERATIONS = 128;
constexpr std::size_t MAX_CAPACITY = 16;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + 3 * MAX_OPERATIONS + 1;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);

std::uint64_t hash_byte(std::uint64_t hash, std::uint8_t byte) {
    return (hash ^ byte) * FNV_PRIME;
}

std::int64_t hash_responses(const std::int32_t *responses, std::size_t count) {
    auto hash = hash_byte(hash_byte(FNV_OFFSET, static_cast<std::uint8_t>(count)),
                          static_cast<std::uint8_t>(count >> 8u));
    for (std::size_t index = 0; index < count; ++index) {
        const auto bits = static_cast<std::uint32_t>(responses[index]);
        for (unsigned shift = 0; shift < 32u; shift += 8u)
            hash = hash_byte(hash, static_cast<std::uint8_t>(bits >> shift));
    }
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
}

extern "C" std::int64_t mrucache(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const auto capacity64 = input[0];
    const auto operation_count64 = input[1];
    if (capacity64 < 1 || capacity64 > static_cast<std::int64_t>(MAX_CAPACITY)
        || operation_count64 < 0 || operation_count64 > static_cast<std::int64_t>(MAX_OPERATIONS)
        || length != 2 + 3 * static_cast<std::size_t>(operation_count64)) return -1;

    const auto capacity = static_cast<std::size_t>(capacity64);
    const auto operation_count = static_cast<std::size_t>(operation_count64);
    std::int32_t keys[MAX_CAPACITY], values[MAX_CAPACITY];
    std::int32_t responses[MAX_OPERATIONS];
    std::size_t cache_count = 0, response_count = 0;

    for (std::size_t step = 0; step < operation_count; ++step) {
        const auto operation = input[2 + 3 * step];
        const auto key64 = input[3 + 3 * step];
        const auto value64 = input[4 + 3 * step];
        if (operation < 0 || operation > 1 || key64 < INT32_MIN || key64 > INT32_MAX
            || value64 < INT32_MIN || value64 > INT32_MAX) return -1;
        const auto key = static_cast<std::int32_t>(key64);
        const auto value = static_cast<std::int32_t>(value64);
        std::size_t position = 0;
        while (position < cache_count && keys[position] != key) ++position;

        if (operation == 0) {
            if (value < 0 || value > 1'000'000) return -1;
            if (position < cache_count) {
                for (std::size_t index = position; index + 1 < cache_count; ++index) {
                    keys[index] = keys[index + 1];
                    values[index] = values[index + 1];
                }
                keys[cache_count - 1] = key;
                values[cache_count - 1] = value;
            } else {
                if (cache_count == capacity) --cache_count; // Evict the MRU tail.
                keys[cache_count] = key;
                values[cache_count] = value;
                ++cache_count;
            }
        } else if (position == cache_count) {
            responses[response_count++] = -1;
        } else {
            const auto response = values[position];
            for (std::size_t index = position; index + 1 < cache_count; ++index) {
                keys[index] = keys[index + 1];
                values[index] = values[index + 1];
            }
            keys[cache_count - 1] = key;
            values[cache_count - 1] = response;
            responses[response_count++] = response;
        }
    }
    return hash_responses(responses, response_count);
}
