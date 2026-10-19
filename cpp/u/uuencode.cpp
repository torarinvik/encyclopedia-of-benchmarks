#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_input_bytes = 4096;
constexpr char prefix[] = "begin 640 uuencode.c \n";
constexpr char suffix[] = " \nend";

void append_quartet(const std::int64_t *input, std::size_t index, std::size_t stop,
                    std::uint8_t *output, std::size_t &cursor) {
    const unsigned a = static_cast<unsigned>(input[index]);
    const bool has_b = index + 1 < stop;
    const bool has_c = index + 2 < stop;
    const unsigned b = has_b ? static_cast<unsigned>(input[index + 1]) : 0u;
    const unsigned c = has_c ? static_cast<unsigned>(input[index + 2]) : 0u;
    const auto symbol = [](unsigned value) { return static_cast<std::uint8_t>(32u + (value & 63u)); };
    output[cursor++] = symbol(a >> 2);
    output[cursor++] = symbol((a << 4) | (b >> 4));
    output[cursor++] = has_b ? symbol((b << 2) | (c >> 6)) : static_cast<std::uint8_t>('=');
    output[cursor++] = has_c ? symbol(c) : static_cast<std::uint8_t>('=');
}
}

extern "C" std::int64_t uuencode(const std::int64_t *input, std::size_t length,
                                  std::uint8_t *output, std::size_t capacity) {
    if (input == nullptr || length > max_input_bytes) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    const std::size_t chunks = (length + 44) / 45;
    const std::size_t needed = (sizeof(prefix) - 1) + 4 * ((length + 2) / 3) + 2 * chunks + (sizeof(suffix) - 1);
    if (output == nullptr || capacity < needed) return -2;

    std::size_t cursor = 0;
    for (char byte : prefix) if (byte != '\0') output[cursor++] = static_cast<std::uint8_t>(byte);
    for (std::size_t start = 0; start < length;) {
        const std::size_t stop = start + ((length - start < 45) ? length - start : 45);
        output[cursor++] = static_cast<std::uint8_t>(32 + (stop - start));
        for (std::size_t index = start; index < stop; index += 3)
            append_quartet(input, index, stop, output, cursor);
        output[cursor++] = static_cast<std::uint8_t>('\n');
        start = stop;
    }
    for (char byte : suffix) if (byte != '\0') output[cursor++] = static_cast<std::uint8_t>(byte);
    return static_cast<std::int64_t>(cursor);
}
