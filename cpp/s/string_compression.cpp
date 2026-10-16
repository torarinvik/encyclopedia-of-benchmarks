#include <cstddef>
#include <cstdint>

extern "C" std::int64_t string_compression(const std::int64_t* input, std::size_t length,
                                           std::uint8_t* output,
                                           std::size_t output_capacity) noexcept {
    if (length > 64 || (length != 0 && input == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index)
        if (input[index] < 0 || input[index] > 127) return -1;

    std::size_t encoded_length = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const std::size_t count = end - index;
        encoded_length += 1 + (count > 1 ? (count >= 10 ? 2 : 1) : 0);
        index = end;
    }
    if (output_capacity < encoded_length || (encoded_length != 0 && output == nullptr)) return -2;

    std::size_t write_index = 0;
    for (std::size_t index = 0; index < length;) {
        std::size_t end = index + 1;
        while (end < length && input[end] == input[index]) ++end;
        const std::size_t count = end - index;
        output[write_index++] = static_cast<std::uint8_t>(input[index]);
        if (count > 1) {
            if (count >= 10) output[write_index++] = static_cast<std::uint8_t>(48 + count / 10);
            output[write_index++] = static_cast<std::uint8_t>(48 + count % 10);
        }
        index = end;
    }
    return static_cast<std::int64_t>(write_index);
}
