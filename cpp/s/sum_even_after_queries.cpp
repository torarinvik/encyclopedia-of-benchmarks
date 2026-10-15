// Apply each point update, then emit the running sum of even values.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::size_t max_numbers = 1000, max_queries = 1000; }

extern "C" std::int64_t sum_even_after_queries(const std::int64_t *values, std::size_t length,
                                                std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (length < 5 || length > 2 + max_numbers + 2 * max_queries || values == nullptr) return -1;
    if (values[0] < 1 || values[0] > static_cast<std::int64_t>(max_numbers) ||
        values[1] < 1 || values[1] > static_cast<std::int64_t>(max_queries)) return -1;
    const auto number_count = static_cast<std::size_t>(values[0]);
    const auto query_count = static_cast<std::size_t>(values[1]);
    if (length != 2 + number_count + 2 * query_count) return -1;

    std::int64_t working[max_numbers];
    std::int64_t even_sum = 0;
    for (std::size_t index = 0; index < number_count; ++index) {
        const auto value = values[2 + index];
        if (value < 1 || value > 1000) return -1;
        working[index] = value;
        if (value % 2 == 0) even_sum += value;
    }
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto offset = 2 + number_count + 2 * query;
        if (values[offset] < -1000 || values[offset] > 1000 ||
            values[offset + 1] < 0 || values[offset + 1] >= static_cast<std::int64_t>(number_count)) return -1;
    }
    const auto output_bytes = query_count * 4;
    if (output_capacity < output_bytes || output == nullptr) return -2;

    for (std::size_t query = 0; query < query_count; ++query) {
        const auto offset = 2 + number_count + 2 * query;
        const auto delta = values[offset];
        const auto index = static_cast<std::size_t>(values[offset + 1]);
        if (working[index] % 2 == 0) even_sum -= working[index];
        working[index] += delta;
        if (working[index] % 2 == 0) even_sum += working[index];
        const auto bits = static_cast<std::uint32_t>(static_cast<std::int32_t>(even_sum));
        for (std::size_t byte = 0; byte < 4; ++byte)
            output[query * 4 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
    }
    return static_cast<std::int64_t>(query_count);
}
