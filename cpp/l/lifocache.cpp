#include <cstddef>
#include <cstdint>

static void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i) output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}

extern "C" std::int64_t lifocache(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > 194) return -1;
    const auto capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64) return -1;
    const auto capacity = static_cast<std::size_t>(capacity_value), operations = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 3 * operations) return -1;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        if (op < 0 || op > 6) return -1;
        if (op <= 2) {
            if (key < INT32_MIN || key > INT32_MAX) return -1;
            if (op == 0) { if (value < INT32_MIN || value > INT32_MAX) return -1; }
            else if (value != 0) return -1;
        } else if (key != 0 || value != 0) return -1;
    }
    const std::size_t required = operations * 16;
    if (output == nullptr || output_capacity < required) return -2;
    std::int64_t keys[16]{}, values[16]{};
    std::size_t count = 0;
    std::int64_t hits = 0, misses = 0;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto op = input[2 + 3 * i], key = input[3 + 3 * i], value = input[4 + 3 * i];
        std::int64_t first = 0, second = 0;
        if (op == 0) {
            std::size_t found = count;
            for (std::size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { for (std::size_t j = found; j + 1 < count; ++j) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } --count; }
            if (count == capacity) --count;
            keys[count] = key; values[count] = value; ++count; first = 1;
        } else if (op == 1) {
            std::size_t found = count;
            for (std::size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { ++hits; first = 1; second = values[found]; } else ++misses;
        } else if (op == 2) {
            std::size_t found = count;
            for (std::size_t j = 0; j < count; ++j) if (keys[j] == key) { found = j; break; }
            if (found < count) { first = 1; second = values[found]; for (std::size_t j = found; j + 1 < count; ++j) { keys[j] = keys[j + 1]; values[j] = values[j + 1]; } --count; }
        } else if (op == 3) first = static_cast<std::int64_t>(count);
        else if (op == 4) first = hits;
        else if (op == 5) first = misses;
        else { count = 0; hits = 0; misses = 0; first = 1; }
        put_i64_le(output, 16 * i, first); put_i64_le(output, 16 * i + 8, second);
    }
    return static_cast<std::int64_t>(2 * operations);
}
