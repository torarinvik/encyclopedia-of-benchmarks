#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t MAX_PLAINTEXT = 256, MAX_CIPHERTEXT = 512, MAX_KEY = 16, MAX_ROWS = 512;
constexpr unsigned char LABELS[6] = {'A', 'D', 'F', 'G', 'V', 'X'};
constexpr unsigned char SQUARE[36] = {
    'N','A','1','C','3','H', '8','T','B','2','O','M',
    'E','5','W','R','P','D', '4','F','6','G','7','I',
    '9','J','0','K','L','Q', 'S','U','V','X','Y','Z'
};
int polybius_cell(unsigned char value) {
    for (int cell = 0; cell < 36; ++cell) if (SQUARE[cell] == value) return cell;
    return -1;
}
int label_index(unsigned char value) {
    for (int i = 0; i < 6; ++i) if (LABELS[i] == value) return i;
    return -1;
}
void sort_key_order(const std::int64_t *input, std::size_t key_start,
                    std::size_t key_length, std::size_t order[MAX_KEY]) {
    for (std::size_t i = 0; i < key_length; ++i) order[i] = i;
    for (std::size_t i = 1; i < key_length; ++i) {
        const std::size_t current = order[i];
        std::size_t j = i;
        while (j > 0 && input[key_start + order[j - 1]] > input[key_start + current]) {
            order[j] = order[j - 1];
            --j;
        }
        order[j] = current;
    }
}
}

extern "C" std::int64_t adfgvxcipher(const std::int64_t *input, std::size_t length,
                                     std::uint8_t *output, std::size_t output_capacity) noexcept {
    if (input == nullptr || length < 3) return -1;
    const auto mode = input[0], text_length_value = input[1], key_length_value = input[2];
    if ((mode != 0 && mode != 1) || text_length_value < 0 || key_length_value < 1 || key_length_value > MAX_KEY) return -1;
    const auto text_length = static_cast<std::size_t>(text_length_value);
    const auto key_length = static_cast<std::size_t>(key_length_value);
    if ((mode == 0 && text_length > MAX_PLAINTEXT) || (mode == 1 && text_length > MAX_CIPHERTEXT) ||
        length != 3 + text_length + key_length) return -1;
    for (std::size_t i = 0; i < text_length; ++i) {
        if (input[3 + i] < 0 || input[3 + i] > 127) return -1;
        if (mode == 1 && label_index(static_cast<unsigned char>(input[3 + i])) < 0) return -1;
    }
    if (mode == 1 && (text_length & 1u) != 0) return -1;
    const std::size_t key_start = 3 + text_length;
    for (std::size_t i = 0; i < key_length; ++i) {
        if (input[key_start + i] < 'A' || input[key_start + i] > 'Z') return -1;
        for (std::size_t j = 0; j < i; ++j) if (input[key_start + i] == input[key_start + j]) return -1;
    }
    std::size_t order[MAX_KEY];
    sort_key_order(input, key_start, key_length, order);
    unsigned char result[MAX_CIPHERTEXT];
    std::size_t result_length = 0;
    if (mode == 0) {
        unsigned char fractionated[MAX_CIPHERTEXT];
        std::size_t fractionated_length = 0;
        for (std::size_t i = 0; i < text_length; ++i) {
            auto value = static_cast<unsigned char>(input[3 + i]);
            if (value >= 'a' && value <= 'z') value = static_cast<unsigned char>(value - 'a' + 'A');
            if (!((value >= 'A' && value <= 'Z') || (value >= '0' && value <= '9'))) continue;
            const int cell = polybius_cell(value);
            if (cell < 0) return -1;
            fractionated[fractionated_length++] = LABELS[cell / 6];
            fractionated[fractionated_length++] = LABELS[cell % 6];
        }
        const auto rows = (fractionated_length + key_length - 1) / key_length;
        unsigned char table[MAX_ROWS][MAX_KEY];
        std::memset(table, '_', sizeof table);
        for (std::size_t i = 0; i < fractionated_length; ++i) table[i / key_length][i % key_length] = fractionated[i];
        for (std::size_t position = 0; position < key_length; ++position) {
            const auto column = order[position];
            for (std::size_t row = 0; row < rows; ++row)
                if (table[row][column] != '_') result[result_length++] = table[row][column];
        }
    } else {
        const auto rows = (text_length + key_length - 1) / key_length;
        unsigned char table[MAX_ROWS][MAX_KEY];
        std::size_t source_index = 0;
        for (std::size_t position = 0; position < key_length; ++position) {
            const auto column = order[position];
            for (std::size_t row = 0; row < rows; ++row)
                table[row][column] = source_index < text_length ? static_cast<unsigned char>(input[3 + source_index++]) : '_';
        }
        unsigned char fractionated[MAX_CIPHERTEXT];
        std::size_t fractionated_length = 0;
        for (std::size_t row = 0; row < rows; ++row)
            for (std::size_t column = 0; column < key_length; ++column)
                if (table[row][column] != '_') fractionated[fractionated_length++] = table[row][column];
        for (std::size_t i = 0; i < fractionated_length; i += 2) {
            const int row = label_index(fractionated[i]), column = label_index(fractionated[i + 1]);
            if (row < 0 || column < 0) return -1;
            result[result_length++] = SQUARE[row * 6 + column];
        }
    }
    if (output_capacity < result_length || (result_length != 0 && output == nullptr)) return -2;
    if (result_length != 0) std::memcpy(output, result, result_length);
    return static_cast<std::int64_t>(result_length);
}
