#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INITIAL_VALUES = 64;
constexpr std::size_t MAX_OPERATIONS = 64;
constexpr std::size_t MAX_LIVE_VALUES = 128;
constexpr std::size_t MAX_INPUT_LENGTH = 258;
constexpr std::size_t MAX_PARSEABLE_INPUT_LENGTH = 260;
constexpr std::size_t MAX_OUTPUT_BYTES = 512;
constexpr std::int64_t MAX_VALUE = 1'000'000;
}

extern "C" std::int64_t prefix_aggregate_list(const std::int64_t *input, std::size_t length,
                                              std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const std::int64_t initial_count_value = input[0];
    if (initial_count_value < 1 || initial_count_value > static_cast<std::int64_t>(MAX_INITIAL_VALUES)) return -1;
    const std::size_t initial_count = static_cast<std::size_t>(initial_count_value);
    if (length < initial_count + 2) return -1;

    std::int64_t prefix[MAX_LIVE_VALUES]{};
    for (std::size_t i = 0; i < initial_count; ++i) {
        const std::int64_t value = input[1 + i];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        prefix[i] = value + (i == 0 ? 0 : prefix[i - 1]);
    }

    const std::int64_t operation_count_value = input[1 + initial_count];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const std::size_t operation_count = static_cast<std::size_t>(operation_count_value);
    std::size_t live_count = initial_count;
    std::size_t cursor = initial_count + 2;
    std::size_t query_count = 0;
    std::uint8_t encoded[MAX_OUTPUT_BYTES]{};

    for (std::size_t operation_index = 0; operation_index < operation_count; ++operation_index) {
        if (cursor >= length) return -1;
        const std::int64_t operation = input[cursor++];
        if (operation == 0) {
            if (cursor >= length || live_count >= MAX_LIVE_VALUES) return -1;
            const std::int64_t value = input[cursor++];
            if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
            prefix[live_count] = prefix[live_count - 1] + value;
            ++live_count;
        } else if (operation == 1) {
            if (live_count <= 1) return -1;
            --live_count;
        } else if (operation == 2) {
            if (cursor + 1 >= length) return -1;
            const std::int64_t range_from = input[cursor++];
            const std::int64_t range_to = input[cursor++];
            if (range_from < 1 || range_to < range_from ||
                static_cast<std::uint64_t>(range_to) > live_count) return -1;
            const std::size_t from_index = static_cast<std::size_t>(range_from);
            const std::size_t to_index = static_cast<std::size_t>(range_to);
            const std::int64_t result = prefix[to_index - 1] -
                                        (from_index == 1 ? 0 : prefix[from_index - 2]);
            std::uint64_t bits = static_cast<std::uint64_t>(result);
            for (std::size_t byte = 0; byte < 8; ++byte) {
                encoded[8 * query_count + byte] = static_cast<std::uint8_t>(bits & UINT64_C(255));
                bits >>= 8;
            }
            ++query_count;
        } else {
            return -1;
        }
    }

    if (cursor != length) return -1;
    const std::size_t output_bytes = 8 * query_count;
    if (output == nullptr || capacity < output_bytes) return -2;
    for (std::size_t i = 0; i < output_bytes; ++i) output[i] = encoded[i];
    return static_cast<std::int64_t>(output_bytes);
}
