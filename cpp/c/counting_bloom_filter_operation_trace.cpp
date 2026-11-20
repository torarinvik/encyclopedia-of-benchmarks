#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 64;
constexpr std::size_t max_parseable_length = 130;
constexpr std::size_t counter_count = 67;
constexpr std::size_t hash_count = 4;

void hash_positions(std::int64_t key, std::size_t (&positions)[hash_count]) {
    const std::int64_t first = (17 * key + 3) % static_cast<std::int64_t>(counter_count);
    const std::int64_t step = 1 + ((5 * key + 3) % static_cast<std::int64_t>(counter_count - 1));
    for (std::size_t index = 0; index < hash_count; ++index)
        positions[index] = static_cast<std::size_t>(
            (first + static_cast<std::int64_t>(index) * step) % static_cast<std::int64_t>(counter_count));
}
}

extern "C" std::int64_t counting_bloom_filter_operation_trace(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 1 || length > max_parseable_length) return -1;
    const std::int64_t q_value = input[0];
    if (q_value < 0 || q_value > static_cast<std::int64_t>(max_operations)) return -1;
    const std::size_t q = static_cast<std::size_t>(q_value);
    if (length != 1 + 2 * q) return -1;

    for (std::size_t operation_index = 0; operation_index < q; ++operation_index) {
        const std::int64_t opcode = input[1 + 2 * operation_index];
        const std::int64_t key = input[2 + 2 * operation_index];
        if (opcode < 0 || opcode > 2 || key < 0 || key > 65535) return -1;
    }
    if (output == nullptr || output_capacity < q) return -2;

    std::uint8_t counters[counter_count] = {};
    for (std::size_t operation_index = 0; operation_index < q; ++operation_index) {
        const std::int64_t opcode = input[1 + 2 * operation_index];
        const std::int64_t key = input[2 + 2 * operation_index];
        std::size_t positions[hash_count];
        hash_positions(key, positions);

        if (opcode == 0) {
            for (std::size_t hash = 0; hash < hash_count; ++hash)
                ++counters[positions[hash]];
            output[operation_index] = 1;
        } else if (opcode == 1) {
            // A delete is valid only when its key is currently represented.
            for (std::size_t hash = 0; hash < hash_count; ++hash)
                --counters[positions[hash]];
            output[operation_index] = 1;
        } else {
            std::uint8_t present = 1;
            for (std::size_t hash = 0; hash < hash_count; ++hash)
                if (counters[positions[hash]] == 0) present = 0;
            output[operation_index] = present;
        }
    }
    return static_cast<std::int64_t>(q);
}
