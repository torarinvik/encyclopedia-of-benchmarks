#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_CAPACITY = 16;
constexpr std::size_t MAX_OPERATIONS = 64;
constexpr std::size_t MAX_INPUT_LENGTH = 2 + 2 * MAX_OPERATIONS;
constexpr std::size_t MAX_OUTPUT_WORDS = 65;

void selection_sort(std::uint64_t *items, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i) {
        std::size_t minimum = i;
        for (std::size_t j = i + 1; j < count; ++j) {
            if (items[j] < items[minimum]) minimum = j;
        }
        const auto value = items[minimum];
        items[minimum] = items[i];
        items[i] = value;
    }
}

std::int64_t binary_search(const std::uint64_t *items, std::size_t first,
                           std::size_t last, std::uint64_t value) {
    if (last < first) return -1;
    const std::size_t middle = (first + last) / 2;
    if (items[middle] == value) return static_cast<std::int64_t>(middle);
    if (value < items[middle]) return binary_search(items, first, middle - 1, value);
    return binary_search(items, middle + 1, last, value);
}

void put_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value) {
    const std::uint64_t bits = static_cast<std::uint64_t>(value);
    for (std::size_t i = 0; i < 8; ++i)
        output[offset + i] = static_cast<std::uint8_t>(bits >> (8 * i));
}
}  // namespace

extern "C" std::int64_t list_array(const std::int64_t *input, std::size_t length,
                                    std::uint8_t *output, std::size_t output_capacity) {
    if (input == nullptr || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const std::int64_t capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > static_cast<std::int64_t>(MAX_CAPACITY) ||
        operation_count_value < 1 || operation_count_value > static_cast<std::int64_t>(MAX_OPERATIONS)) return -1;
    const auto capacity = static_cast<std::size_t>(capacity_value);
    const auto operations = static_cast<std::size_t>(operation_count_value);
    if (length != 2 + 2 * operations) return -1;

    std::int64_t opcodes[MAX_OPERATIONS]{}, arguments[MAX_OPERATIONS]{};
    bool sorted = false;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto opcode = input[2 + 2 * i], argument = input[3 + 2 * i];
        if (opcode == 0) {
            if (sorted || argument < 0) return -1;
        } else if (opcode == 1) {
            if (sorted || argument != 0) return -1;
            sorted = true;
        } else if (opcode == 2 || opcode == 3) {
            if (!sorted || argument < 0) return -1;
        } else return -1;
        opcodes[i] = opcode;
        arguments[i] = argument;
    }
    if (!sorted) return -1;

    std::uint64_t items[MAX_CAPACITY]{};
    std::int64_t results[MAX_OPERATIONS]{};
    std::int64_t output_words[MAX_OUTPUT_WORDS]{};
    std::size_t count = 0, result_count = 0;
    for (std::size_t i = 0; i < operations; ++i) {
        const auto opcode = opcodes[i], argument = arguments[i];
        if (opcode == 0) {
            if (count == capacity) return -1;
            items[count++] = static_cast<std::uint64_t>(argument);
        } else if (opcode == 1) {
            selection_sort(items, count);
        } else {
            if (count == 0 || static_cast<std::uint64_t>(argument) < items[0]) return -1;
            if (opcode == 3 && count >= capacity) return -1;
            const auto position = binary_search(items, 0, count - 1,
                                                static_cast<std::uint64_t>(argument));
            results[result_count++] = position;
            if (opcode == 3 && position >= 0) {
                for (std::size_t j = static_cast<std::size_t>(position); j < count; ++j)
                    items[j] = items[j + 1];
                --count;
            }
        }
    }

    std::size_t word_count = 0;
    output_words[word_count++] = static_cast<std::int64_t>(result_count);
    for (std::size_t i = 0; i < result_count; ++i) output_words[word_count++] = results[i];
    output_words[word_count++] = static_cast<std::int64_t>(count);
    for (std::size_t i = 0; i < count; ++i) output_words[word_count++] = static_cast<std::int64_t>(items[i]);
    const std::size_t required = word_count * 8;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t i = 0; i < word_count; ++i) put_i64_le(output, i * 8, output_words[i]);
    return static_cast<std::int64_t>(required);
}
