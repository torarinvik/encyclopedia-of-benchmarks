// Fractionate a fixed-square Bifid cipher over one complete message block.
#include <cstddef>
#include <cstdint>

static std::int64_t letter_index(std::int64_t value, bool merge_j)
{
    if (value >= 97 && value <= 122) value -= 32;
    if (value < 65 || value > 90) return -1;
    std::int64_t index = value - 65;
    if (index == 9) {
        if (!merge_j) return -1;
        index = 8;
    } else if (index > 9) {
        --index;
    }
    return index;
}

static std::uint8_t letter_for_index(std::size_t index)
{
    std::size_t value = static_cast<std::size_t>('a') + index;
    if (index >= 9) ++value;
    return static_cast<std::uint8_t>(value);
}

extern "C" std::int64_t bifid_cipher(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > 258) return -1;
    const std::int64_t mode = input[0];
    const std::int64_t text_length_value = input[1];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || text_length_value > 256)
        return -1;
    const std::size_t text_length = static_cast<std::size_t>(text_length_value);
    if (length != text_length + 2) return -1;

    std::uint8_t rows[256];
    std::uint8_t columns[256];
    std::uint8_t coordinates[512];
    std::uint8_t result[256];
    std::size_t result_length = 0;

    if (mode == 0) {
        for (std::size_t i = 0; i < text_length; ++i) {
            const std::int64_t value = input[i + 2];
            if (value == 32) continue;
            const std::int64_t index = letter_index(value, true);
            if (index < 0) return -1;
            rows[result_length] = static_cast<std::uint8_t>(index / 5 + 1);
            columns[result_length] = static_cast<std::uint8_t>(index % 5 + 1);
            ++result_length;
        }
        for (std::size_t i = 0; i < result_length; ++i) {
            coordinates[i] = rows[i];
            coordinates[result_length + i] = columns[i];
        }
        for (std::size_t i = 0; i < result_length; ++i) {
            const std::size_t position =
                static_cast<std::size_t>(coordinates[2 * i] - 1) * 5
                + (coordinates[2 * i + 1] - 1);
            result[i] = letter_for_index(position);
        }
    } else {
        result_length = text_length;
        for (std::size_t i = 0; i < text_length; ++i) {
            const std::int64_t index = letter_index(input[i + 2], false);
            if (index < 0) return -1;
            coordinates[2 * i] = static_cast<std::uint8_t>(index / 5 + 1);
            coordinates[2 * i + 1] = static_cast<std::uint8_t>(index % 5 + 1);
        }
        for (std::size_t i = 0; i < result_length; ++i) {
            const std::size_t position =
                static_cast<std::size_t>(coordinates[i] - 1) * 5
                + (coordinates[result_length + i] - 1);
            result[i] = letter_for_index(position);
        }
    }

    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(result_length);
}
