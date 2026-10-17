#include <cstddef>
#include <cstdint>

static void write_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}

extern "C" std::int64_t sort_population(const std::int64_t *input, std::size_t length,
                                          std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > 129 || input[0] < 1 || input[0] > 64) return -1;
    const std::size_t count = static_cast<std::size_t>(input[0]);
    if (length != 1 + 2 * count) return -1;
    std::int64_t costs[64], identifiers[64];
    bool seen[64] = {};
    for (std::size_t i = 0; i < count; ++i) {
        const std::int64_t cost = input[1 + 2 * i], identifier = input[2 + 2 * i];
        if (cost < -1000000 || cost > 1000000 || identifier < 0 || identifier >= static_cast<std::int64_t>(count)) return -1;
        if (seen[identifier]) return -1;
        seen[identifier] = true;
        costs[i] = cost;
        identifiers[i] = identifier;
    }
    for (std::size_t i = 1; i < count; ++i) {
        const std::int64_t key_cost = costs[i], key_identifier = identifiers[i];
        std::size_t j = i;
        while (j > 0 && costs[j - 1] > key_cost) {
            costs[j] = costs[j - 1];
            identifiers[j] = identifiers[j - 1];
            --j;
        }
        costs[j] = key_cost;
        identifiers[j] = key_identifier;
    }
    for (std::size_t i = 1; i < count; ++i) if (costs[i - 1] == costs[i]) return -1;
    const std::size_t output_length = count * 16;
    if (output == nullptr || capacity < output_length) return -2;
    for (std::size_t i = 0; i < count; ++i) {
        write_i64_le(output, i * 16, costs[i]);
        write_i64_le(output, i * 16 + 8, identifiers[i]);
    }
    return static_cast<std::int64_t>(output_length);
}
