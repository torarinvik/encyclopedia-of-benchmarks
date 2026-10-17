#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxParseableInputLength = 292;
constexpr std::size_t kMaxMessageBytes = 32;
}

extern "C" std::int64_t lsb_image_steganography(const std::int64_t* input, std::size_t length,
                                                  std::uint8_t* output, std::size_t capacity) {
    if (input == nullptr || length < 3 || length > kMaxParseableInputLength) return -1;
    if (input[0] < 1 || input[0] > 16 || input[1] < 1 || input[1] > 16 || input[2] < 0 || input[2] > static_cast<std::int64_t>(kMaxMessageBytes)) return -1;
    const auto rows = static_cast<std::size_t>(input[0]);
    const auto columns = static_cast<std::size_t>(input[1]);
    const auto message_length = static_cast<std::size_t>(input[2]);
    const auto pixel_count = rows * columns;
    if (message_length * 8 > pixel_count || length != 3 + pixel_count + message_length) return -1;
    for (std::size_t i = 0; i < pixel_count; ++i) if (input[3 + i] < 0 || input[3 + i] > 254) return -1;
    for (std::size_t i = 0; i < message_length; ++i) if (input[3 + pixel_count + i] < 0 || input[3 + pixel_count + i] > 127) return -1;
    if (output == nullptr || capacity < pixel_count) return -2;
    for (std::size_t i = 0; i < pixel_count; ++i) output[i] = static_cast<std::uint8_t>(input[3 + i]);
    std::size_t bit_index = 0;
    for (std::size_t i = 0; i < message_length; ++i) {
        const auto byte = static_cast<unsigned int>(input[3 + pixel_count + i]);
        for (int shift = 7; shift >= 0; --shift) {
            const auto bit = (byte >> shift) & 1U;
            const auto pixel = static_cast<unsigned int>(output[bit_index]);
            output[bit_index] = static_cast<std::uint8_t>(pixel + ((pixel & 1U) ^ bit));
            ++bit_index;
        }
    }
    return static_cast<std::int64_t>(pixel_count);
}
