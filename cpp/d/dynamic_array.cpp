#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_operations = 128;
constexpr std::size_t max_elements = 64;
constexpr std::size_t max_input_length = 1 + 3 * max_operations;

void write_i64_le(std::uint8_t *output, std::size_t word_index, std::int64_t value) noexcept {
    const auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte)
        output[word_index * 8 + byte] = static_cast<std::uint8_t>(bits >> (byte * 8));
}
}

extern "C" std::int64_t dynamic_array(const std::int64_t *input, std::size_t length,
                                       std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const auto operation_count_value = input[0];
    if (operation_count_value < 0 || operation_count_value > static_cast<std::int64_t>(max_operations)) return -1;

    std::int64_t first[max_elements]{};
    std::int64_t second[max_elements]{};
    std::int64_t query_results[max_operations]{};
    std::size_t active = 0;
    std::size_t size = 0;
    std::size_t capacity = 16;
    std::size_t cursor = 1;
    std::size_t query_count = 0;

    for (std::int64_t operation_index = 0; operation_index < operation_count_value; ++operation_index) {
        if (cursor >= length) return -1;
        const auto operation = input[cursor++];
        if (operation == 0) {
            if (cursor >= length || size >= max_elements) return -1;
            const auto value = input[cursor++];
            if (size == capacity) {
                if (active == 0) {
                    for (std::size_t index = 0; index < size; ++index) second[index] = first[index];
                    active = 1;
                } else {
                    for (std::size_t index = 0; index < size; ++index) first[index] = second[index];
                    active = 0;
                }
                capacity *= 2;
            }
            if (active == 0) first[size] = value;
            else second[size] = value;
            ++size;
        } else if (operation == 1) {
            if (cursor + 1 >= length) return -1;
            const auto index_value = input[cursor++];
            const auto value = input[cursor++];
            if (index_value < 0 || static_cast<std::uint64_t>(index_value) >= size) return -1;
            if (active == 0) first[index_value] = value;
            else second[index_value] = value;
        } else if (operation == 2) {
            if (cursor >= length || query_count >= max_operations) return -1;
            const auto index_value = input[cursor++];
            if (index_value < 0 || static_cast<std::uint64_t>(index_value) >= size) return -1;
            query_results[query_count++] = active == 0 ? first[index_value] : second[index_value];
        } else if (operation == 3) {
            if (query_count >= max_operations) return -1;
            query_results[query_count++] = static_cast<std::int64_t>(size);
        } else {
            return -1;
        }
    }
    if (cursor != length) return -1;

    const std::size_t output_words = 2 + query_count + size;
    const std::size_t output_bytes = output_words * 8;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    write_i64_le(output, 0, static_cast<std::int64_t>(query_count));
    for (std::size_t index = 0; index < query_count; ++index)
        write_i64_le(output, index + 1, query_results[index]);
    write_i64_le(output, query_count + 1, static_cast<std::int64_t>(size));
    for (std::size_t index = 0; index < size; ++index) {
        const auto value = active == 0 ? first[index] : second[index];
        write_i64_le(output, query_count + 2 + index, value);
    }
    return static_cast<std::int64_t>(output_words);
}
