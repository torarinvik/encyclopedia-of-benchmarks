#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 32;
constexpr std::size_t max_input_length = 3 + 3 * max_operations;
constexpr std::size_t max_output_bytes = 8 * max_operations;

std::uint32_t java_next_bits(std::uint64_t& state, unsigned bits) {
    constexpr std::uint64_t mask = (UINT64_C(1) << 48) - 1;
    state = (state * UINT64_C(0x5DEECE66D) + UINT64_C(0xB)) & mask;
    return static_cast<std::uint32_t>(state >> (48 - bits));
}

std::uint32_t java_next_int(std::uint64_t& state, std::uint32_t bound) {
    if ((bound & (bound - 1)) == 0)
        return static_cast<std::uint32_t>((static_cast<std::uint64_t>(bound) * java_next_bits(state, 31)) >> 31);
    for (;;) {
        const auto bits = java_next_bits(state, 31);
        const auto value = bits % bound;
        if (static_cast<std::uint64_t>(bits) - value + (bound - 1) <= INT32_MAX) return value;
    }
}

void put_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t rrcache(const std::int64_t* input, std::size_t length,
                                std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > max_input_length) return -1;
    if (input[0] < 1 || input[0] > 8 || input[2] < 0 || input[2] > static_cast<std::int64_t>(max_operations)) return -1;
    const auto cache_capacity = static_cast<std::size_t>(input[0]);
    const auto operation_count = static_cast<std::size_t>(input[2]);
    if (length != 3 + 3 * operation_count) return -1;

    std::int64_t keys[8] = {};
    std::int64_t values[8] = {};
    std::int64_t results[max_operations] = {};
    std::size_t size = 0;
    std::uint64_t random_state = (static_cast<std::uint64_t>(input[1]) ^ UINT64_C(0x5DEECE66D)) & ((UINT64_C(1) << 48) - 1);

    for (std::size_t operation = 0; operation < operation_count; ++operation) {
        const auto offset = 3 + 3 * operation;
        const auto opcode = input[offset];
        const auto key = input[offset + 1];
        const auto value = input[offset + 2];
        if (opcode == 0) {
            if (key < 1 || key > 1024 || value < 100 || value > 1000000) return -1;
            std::size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            if (index < size) {
                values[index] = value;
            } else {
                if (size == cache_capacity) {
                    const auto evicted = java_next_int(random_state, static_cast<std::uint32_t>(size));
                    for (std::size_t move = evicted; move + 1 < size; ++move) {
                        keys[move] = keys[move + 1];
                        values[move] = values[move + 1];
                    }
                    --size;
                }
                keys[size] = key;
                values[size] = value;
                ++size;
            }
            results[operation] = -2;
        } else if (opcode == 1) {
            if (key < 1 || key > 1024 || value != 0) return -1;
            std::size_t index = 0;
            while (index < size && keys[index] != key) ++index;
            results[operation] = index < size ? values[index] : -1;
        } else if (opcode == 2) {
            if (key != 0 || value != 0) return -1;
            results[operation] = static_cast<std::int64_t>(size);
        } else return -1;
    }

    const auto output_bytes = operation_count * 8;
    if (output == nullptr || capacity < output_bytes) return -2;
    std::uint8_t staged[max_output_bytes];
    for (std::size_t operation = 0; operation < operation_count; ++operation)
        put_i64_le(staged, operation * 8, results[operation]);
    for (std::size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return static_cast<std::int64_t>(output_bytes);
}
