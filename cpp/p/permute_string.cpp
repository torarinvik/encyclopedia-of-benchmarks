#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_N = 7;
constexpr std::size_t MAX_INPUT_LENGTH = 9;

std::size_t factorial(std::size_t value)
{
    std::size_t result = 1;
    for (std::size_t factor = 2; factor <= value; ++factor) result *= factor;
    return result;
}

std::size_t unique_permutation_count(const std::uint8_t *values, std::size_t length)
{
    if (length == 0) return 0;
    std::size_t frequencies[128] = {};
    for (std::size_t index = 0; index < length; ++index) ++frequencies[values[index]];
    std::size_t count = factorial(length);
    for (std::size_t value = 0; value < 128; ++value) count /= factorial(frequencies[value]);
    return count;
}

bool next_permutation(std::uint8_t *values, std::size_t length)
{
    if (length < 2) return false;
    std::size_t pivot = length - 1;
    while (pivot > 0 && values[pivot - 1] >= values[pivot]) --pivot;
    if (pivot == 0) return false;
    std::size_t successor = length - 1;
    while (values[successor] <= values[pivot - 1]) --successor;
    const std::uint8_t temporary = values[pivot - 1];
    values[pivot - 1] = values[successor];
    values[successor] = temporary;
    for (std::size_t left = pivot, right = length - 1; left < right; ++left, --right) {
        const std::uint8_t value = values[left];
        values[left] = values[right];
        values[right] = value;
    }
    return true;
}
}

extern "C" std::int64_t permute_string(const std::int64_t *input, std::size_t input_length,
                                         std::uint8_t *output, std::size_t output_capacity)
{
    if (input == nullptr || input_length < 1 || input_length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > static_cast<std::int64_t>(MAX_N)) return -1;
    const std::size_t character_count = static_cast<std::size_t>(input[0]);
    if (input_length != character_count + 1) return -1;

    std::uint8_t values[MAX_N] = {};
    for (std::size_t index = 0; index < character_count; ++index) {
        const std::int64_t value = input[index + 1];
        if (value < 0 || value > 127) return -1;
        values[index] = static_cast<std::uint8_t>(value);
    }
    for (std::size_t index = 1; index < character_count; ++index) {
        const std::uint8_t value = values[index];
        std::size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }

    const std::size_t permutation_count = unique_permutation_count(values, character_count);
    const std::size_t output_bytes = permutation_count * character_count;
    if (output == nullptr || output_capacity < output_bytes) return -2;
    for (std::size_t row = 0; row < permutation_count; ++row) {
        for (std::size_t column = 0; column < character_count; ++column)
            output[row * character_count + column] = values[column];
        if (row + 1 < permutation_count) (void)next_permutation(values, character_count);
    }
    return static_cast<std::int64_t>(output_bytes);
}
