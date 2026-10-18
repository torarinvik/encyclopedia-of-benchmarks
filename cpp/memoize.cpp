/* Replay bounded calls through a memoized fixed-arity integer callback. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t min_argument = -100;
constexpr std::int64_t max_argument = 100;
constexpr std::size_t max_arity = 4;
constexpr std::size_t max_calls = 64;
constexpr std::size_t max_parseable_input_length = 259;
constexpr std::size_t max_output_bytes = 520;
constexpr std::int64_t encoding_base = 201;

void store_i64_le(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (8 * byte));
}
}

extern "C" std::int64_t memoize(const std::int64_t* input, std::size_t input_length,
                                std::uint8_t* output, std::size_t output_capacity) noexcept {
    if (input == nullptr || input_length < 2 || input_length > max_parseable_input_length) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(max_arity) ||
        input[1] < 0 || input[1] > static_cast<std::int64_t>(max_calls)) return -1;

    const auto arity = static_cast<std::size_t>(input[0]);
    const auto call_count = static_cast<std::size_t>(input[1]);
    if (input_length != 2 + arity * call_count) return -1;
    for (std::size_t index = 2; index < input_length; ++index)
        if (input[index] < min_argument || input[index] > max_argument) return -1;

    std::uint8_t staged[max_output_bytes]{};
    std::int64_t cached_callback_results[max_calls]{};
    std::size_t miss_count = 0;
    for (std::size_t call = 0; call < call_count; ++call) {
        std::int64_t result = 0;
        for (std::size_t argument = 0; argument < arity; ++argument) {
            const auto value = input[2 + call * arity + argument];
            result = result * encoding_base + (value - min_argument);
        }

        // For fixed arity this injective encoding distinguishes JSON-array keys.
        std::size_t prior = 0;
        while (prior < miss_count && cached_callback_results[prior] != result) ++prior;
        if (prior == miss_count) cached_callback_results[miss_count++] = result;
        store_i64_le(staged, call * 8, result);
    }

    const std::size_t output_bytes = 8 * (call_count + 1);
    store_i64_le(staged, call_count * 8, static_cast<std::int64_t>(miss_count));
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t index = 0; index < output_bytes; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(output_bytes);
}
