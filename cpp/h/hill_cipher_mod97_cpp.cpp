#include <cstddef>
#include <cstdint>

namespace {
constexpr std::uint8_t alphabet[97] = {65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 126, 33, 64, 35, 36, 37, 94, 38, 42, 40, 41, 95, 43, 96, 45, 61, 91, 93, 123, 125, 124, 59, 39, 34, 58, 44, 46, 47, 60, 62, 63, 92, 13, 10, 32};
constexpr std::int64_t encrypt_key[4] = {2, 5, 1, 6};
constexpr std::int64_t decrypt_key[4] = {84, 27, 83, 28};
int alphabet_index(std::int64_t value) {
    for (int index = 0; index < 97; ++index) if (alphabet[index] == value) return index;
    return -1;
}
}

extern "C" std::int64_t hill_cipher_mod97_cpp(const std::int64_t* values, std::size_t length,
                                                 std::uint8_t* output, std::size_t capacity) noexcept {
    if (values == nullptr || length < 3 || length > 258) return -1;
    const auto operation = values[0], raw_length = values[1];
    if ((operation != 0 && operation != 1) || raw_length < 1 || raw_length > 256 || length != static_cast<std::size_t>(raw_length) + 2) return -1;
    const std::size_t text_length = static_cast<std::size_t>(raw_length);
    std::uint8_t indices[256];
    for (std::size_t index = 0; index < text_length; ++index) {
        const int mapped = alphabet_index(values[index + 2]);
        if (mapped < 0) return -1;
        indices[index] = static_cast<std::uint8_t>(mapped);
    }
    const std::size_t output_length = text_length + (text_length % 2);
    if (output == nullptr || capacity < output_length) return -2;
    const auto* key = operation == 0 ? encrypt_key : decrypt_key;
    for (std::size_t offset = 0; offset < output_length; offset += 2) {
        const std::int64_t first = indices[offset];
        const std::int64_t second = offset + 1 < text_length ? indices[offset + 1] : 0;
        const std::size_t row0 = static_cast<std::size_t>((key[0] * first + key[1] * second) % 97);
        const std::size_t row1 = static_cast<std::size_t>((key[2] * first + key[3] * second) % 97);
        output[offset] = alphabet[row0];
        output[offset + 1] = alphabet[row1];
    }
    return static_cast<std::int64_t>(output_length);
}
