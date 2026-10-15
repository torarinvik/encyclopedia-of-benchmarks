/* Encode runs as an unambiguous decimal count followed by an ASCII byte. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t run_length_encoding(const std::int64_t *input, std::size_t length,
                                            std::uint8_t *output,
                                            std::size_t output_capacity) noexcept {
    if (length > 66) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 1 || input[index] > 127 ||
            (input[index] >= 48 && input[index] <= 57)) return -1;

    std::size_t encoded_length = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const std::size_t count = end - index;
        encoded_length += count >= 10 ? 3 : 2;
        index = end;
    }
    if (output_capacity < encoded_length) return -2;

    std::size_t write_index = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const std::size_t count = end - index;
        if (count >= 10) output[write_index++] = static_cast<std::uint8_t>(48 + count / 10);
        output[write_index++] = static_cast<std::uint8_t>(48 + count % 10);
        output[write_index++] = static_cast<std::uint8_t>(input[index]);
        index = end;
    }
    return static_cast<std::int64_t>(write_index);
}
