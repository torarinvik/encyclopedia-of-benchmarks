#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_text = 256;
constexpr std::size_t max_key = 32;
}

extern "C" std::int64_t columnar_transposition(const std::int64_t *input, std::size_t length,
                                                 std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length < 3) return -1;
    const auto operation = input[0], text_value = input[1], raw_key_value = input[2];
    if ((operation != 0 && operation != 1) || text_value < 0 || text_value > static_cast<std::int64_t>(max_text) ||
        raw_key_value < 1 || raw_key_value > static_cast<std::int64_t>(max_key)) return -1;
    const auto text_length = static_cast<std::size_t>(text_value);
    const auto raw_key_length = static_cast<std::size_t>(raw_key_value);
    if (length != 3 + text_length + raw_key_length) return -1;
    std::uint8_t key[max_key], order[max_key];
    std::size_t key_length = 0;
    for (std::size_t i = 0; i < text_length; ++i)
        if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
    for (std::size_t i = 0; i < raw_key_length; ++i) {
        const auto value = input[3 + text_length + i];
        if (value < 0 || value > 127) return -1;
        if (value >= 'A' && value <= 'Z') key[key_length++] = static_cast<std::uint8_t>(value);
        else if (value >= 'a' && value <= 'z') key[key_length++] = static_cast<std::uint8_t>(value - 32);
    }
    if (key_length == 0) return -1;
    for (std::size_t i = 0; i < key_length; ++i) {
        order[i] = static_cast<std::uint8_t>(i);
        std::size_t position = i;
        while (position > 0 && key[order[position - 1]] > key[i]) {
            order[position] = order[position - 1];
            --position;
        }
        order[position] = static_cast<std::uint8_t>(i);
    }
    if (text_length == 0) return 0;
    if (output == nullptr || capacity < text_length) return -2;
    const std::size_t rows = (text_length + key_length - 1) / key_length;
    if (operation == 0) {
        std::size_t written = 0;
        for (std::size_t rank = 0; rank < key_length; ++rank) {
            const std::size_t column = order[rank];
            for (std::size_t row = 0; row < rows; ++row) {
                const std::size_t index = row * key_length + column;
                if (index < text_length) output[written++] = static_cast<std::uint8_t>(input[3 + index]);
            }
        }
        return static_cast<std::int64_t>(written);
    }
    std::uint8_t column_data[max_key][max_text];
    std::size_t column_lengths[max_key], offset = 0;
    const std::size_t short_columns = text_length % key_length;
    for (std::size_t column = 0; column < key_length; ++column)
        column_lengths[column] = short_columns == 0 || column < short_columns ? rows : rows - 1;
    for (std::size_t rank = 0; rank < key_length; ++rank) {
        const std::size_t column = order[rank];
        for (std::size_t row = 0; row < column_lengths[column]; ++row)
            column_data[column][row] = static_cast<std::uint8_t>(input[3 + offset++]);
    }
    std::size_t written = 0;
    for (std::size_t row = 0; row < rows; ++row)
        for (std::size_t column = 0; column < key_length; ++column)
            if (row < column_lengths[column]) output[written++] = column_data[column][row];
    return static_cast<std::int64_t>(written);
}
