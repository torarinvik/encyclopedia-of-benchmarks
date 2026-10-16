/* Portable linked-list multiset port of TheAlgorithms Bag contracts. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_inserts = 128;
constexpr std::size_t max_queries = 64;

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned byte = 0; byte < 8; ++byte)
        output[offset + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t bag(const std::int64_t *input, std::size_t length,
                             std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 2) return -1;
    const auto insert_count_value = input[0];
    if (insert_count_value < 0 || insert_count_value > static_cast<std::int64_t>(max_inserts)) return -1;
    const auto insert_count = static_cast<std::size_t>(insert_count_value);
    if (length < insert_count + 2) return -1;
    const auto query_count_value = input[insert_count + 1];
    if (query_count_value < 0 || query_count_value > static_cast<std::int64_t>(max_queries)) return -1;
    const auto query_count = static_cast<std::size_t>(query_count_value);
    if (length != insert_count + query_count + 2) return -1;

    for (std::size_t index = 0; index < insert_count; ++index) {
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
    }
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto value = input[insert_count + query + 2];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
    }
    const auto output_length = (query_count + 2) * 8;
    if (output == nullptr || capacity < output_length) return -2;

    std::int64_t values[max_inserts];
    std::size_t distinct_count = 0;
    for (std::size_t index = 0; index < insert_count; ++index) {
        const auto value = input[index + 1];
        std::size_t node = 0;
        while (node < distinct_count && values[node] != value) ++node;
        if (node == distinct_count) {
            values[node] = value;
            ++distinct_count;
        }
    }

    put_i64_le(output, 0, insert_count_value);
    put_i64_le(output, 8, insert_count_value == 0 ? 1 : 0);
    for (std::size_t query = 0; query < query_count; ++query) {
        const auto target = input[insert_count + query + 2];
        std::int64_t contains = 0;
        for (std::size_t node = 0; node < distinct_count; ++node)
            if (values[node] == target) { contains = 1; break; }
        put_i64_le(output, (query + 2) * 8, contains);
    }
    return static_cast<std::int64_t>(output_length);
}
