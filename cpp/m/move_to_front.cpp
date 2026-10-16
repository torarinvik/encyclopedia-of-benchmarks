#include <cstddef>
#include <cstdint>

extern "C" std::int64_t move_to_front(const std::int64_t* values, std::size_t length,
                                      std::uint8_t* output, std::size_t capacity) {
    if (values == nullptr || length < 3 || length > 164) return -1;
    const auto mode = values[0], alphabet_length = values[1], text_length = values[2];
    if ((mode != 0 && mode != 1) || alphabet_length < 0 || alphabet_length > 32 ||
        text_length < 0 || text_length > 128 ||
        length != 3 + static_cast<std::size_t>(alphabet_length + text_length)) return -1;
    std::int64_t alphabet[32]{};
    std::uint8_t result[128]{};
    for (std::size_t i = 0; i < static_cast<std::size_t>(alphabet_length); ++i) {
        const auto symbol = values[3 + i];
        if (symbol < 0 || symbol > 127) return -1;
        for (std::size_t j = 0; j < i; ++j) if (alphabet[j] == symbol) return -1;
        alphabet[i] = symbol;
    }
    std::size_t result_length = 0;
    if (mode == 0) {
        if (text_length > 0 && alphabet_length == 0) return -1;
        for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i) {
            const auto symbol = values[3 + static_cast<std::size_t>(alphabet_length) + i];
            if (symbol < 0 || symbol > 127) return -1;
            std::size_t position = 0;
            while (position < static_cast<std::size_t>(alphabet_length) && alphabet[position] != symbol) ++position;
            if (position == static_cast<std::size_t>(alphabet_length)) return -1;
            result[result_length++] = static_cast<std::uint8_t>(position);
            while (position > 0) { alphabet[position] = alphabet[position - 1]; --position; }
            alphabet[0] = symbol;
        }
    } else if (alphabet_length > 0) {
        for (std::size_t i = 0; i < static_cast<std::size_t>(text_length); ++i) {
            const auto index = values[3 + static_cast<std::size_t>(alphabet_length) + i];
            if (index < 0 || index >= alphabet_length) return -1;
            const auto symbol = alphabet[static_cast<std::size_t>(index)];
            result[result_length++] = static_cast<std::uint8_t>(symbol);
            for (std::size_t j = static_cast<std::size_t>(index); j > 0; --j) alphabet[j] = alphabet[j - 1];
            alphabet[0] = symbol;
        }
    }
    if (capacity < result_length || (result_length > 0 && output == nullptr)) return -2;
    for (std::size_t i = 0; i < result_length; ++i) output[i] = result[i];
    return static_cast<std::int64_t>(result_length);
}
