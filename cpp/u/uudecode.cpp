#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_bytes = 4096;
constexpr std::size_t max_output_bytes = 2949;
constexpr char header[] = "begin 755 uustart.file \n";

bool scan(const std::int64_t *input, std::size_t length, std::size_t &decoded_length) {
    if (input == nullptr || length > max_input_bytes) return false;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return false;
    const std::size_t header_length = sizeof(header) - 1;
    if (length < header_length + 5) return false;
    for (std::size_t i = 0; i < header_length; ++i)
        if (input[i] != static_cast<unsigned char>(header[i])) return false;

    std::size_t cursor = header_length;
    std::size_t total = 0;
    while (cursor < length) {
        const int marker = static_cast<int>(input[cursor++]);
        if (marker == 32) {
            if (cursor + 4 != length || input[cursor] != 10 || input[cursor + 1] != 'e' ||
                input[cursor + 2] != 'n' || input[cursor + 3] != 'd') return false;
            decoded_length = total;
            return total <= max_output_bytes;
        }
        const int line_count = marker - 32;
        if (line_count < 1 || line_count > 45) return false;
        const std::size_t encoded = 4 * ((static_cast<std::size_t>(line_count) + 2) / 3);
        if (cursor + encoded >= length || input[cursor + encoded] != 10) return false;
        for (std::size_t i = 0; i < encoded; ++i)
            if (input[cursor + i] < 32 || input[cursor + i] > 95) return false;
        total += static_cast<std::size_t>(line_count);
        if (total > max_output_bytes) return false;
        cursor += encoded + 1;
    }
    return false;
}
}

extern "C" std::int64_t uudecode(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) {
    std::size_t decoded_length = 0;
    if (!scan(input, length, decoded_length)) return -1;
    if (output == nullptr || capacity < decoded_length) return -2;

    std::size_t cursor = sizeof(header) - 1;
    std::size_t written = 0;
    while (true) {
        const std::size_t count = static_cast<std::size_t>(input[cursor++] - 32);
        if (count == 0) break;
        const std::size_t encoded = 4 * ((count + 2) / 3);
        std::size_t emitted = 0;
        for (std::size_t group = 0; group < encoded; group += 4) {
            const unsigned a = static_cast<unsigned>(input[cursor++] - 32);
            const unsigned b = static_cast<unsigned>(input[cursor++] - 32);
            const unsigned c = static_cast<unsigned>(input[cursor++] - 32);
            const unsigned d = static_cast<unsigned>(input[cursor++] - 32);
            output[written++] = static_cast<std::uint8_t>((a << 2) | (b >> 4));
            ++emitted;
            if (emitted < count) {
                output[written++] = static_cast<std::uint8_t>((b << 4) | (c >> 2));
                ++emitted;
            }
            if (emitted < count) {
                output[written++] = static_cast<std::uint8_t>((c << 6) | d);
                ++emitted;
            }
        }
        ++cursor;
    }
    return static_cast<std::int64_t>(written);
}
