#include <cstddef>
#include <cstdint>

static void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t least_recently_used(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 66) return -1;
    const auto capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > 16 || count_value < 0 || count_value > 64) return -1;
    const auto cache_capacity = static_cast<std::size_t>(capacity_value);
    const auto references = static_cast<std::size_t>(count_value);
    if (length != 2 + references) return -1;
    for (std::size_t i = 0; i < references; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;

    std::int64_t keys[16]{};
    std::size_t count = 0;
    for (std::size_t i = 0; i < references; ++i) {
        const auto key = input[2 + i];
        std::size_t found = count;
        for (std::size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
        if (found < count) {
            for (std::size_t j = found; j + 1 < count; ++j) keys[j] = keys[j + 1];
            --count;
        } else if (count == cache_capacity) --count;
        for (std::size_t j = count; j > 0; --j) keys[j] = keys[j - 1];
        keys[0] = key;
        ++count;
    }

    const std::size_t elements = count + 1, required = elements * 8;
    if (output == nullptr || output_capacity < required) return -2;
    put_i64_le(output, 0, static_cast<std::int64_t>(count));
    for (std::size_t i = 0; i < count; ++i) put_i64_le(output, 8 * (i + 1), keys[i]);
    return static_cast<std::int64_t>(elements);
}
