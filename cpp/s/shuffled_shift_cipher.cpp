#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t passcode_max = 20;
constexpr std::size_t plaintext_max = 256;
constexpr std::size_t input_max_parseable = 279;
constexpr std::size_t alphabet_length = 97;
constexpr char alphabet[] =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~ \t\n";
}

extern "C" std::int64_t shuffled_shift_cipher(const std::int64_t *input,
                                               std::size_t input_length,
                                               char *output,
                                               std::size_t output_capacity)
{
    if (input == nullptr || input_length < 2 || input_length > input_max_parseable) return -1;

    const std::int64_t passcode_length_value = input[0];
    const std::int64_t plaintext_length_value = input[1];
    if (passcode_length_value < 1 || passcode_length_value > static_cast<std::int64_t>(passcode_max) ||
        plaintext_length_value < 0 || plaintext_length_value > static_cast<std::int64_t>(plaintext_max)) return -1;

    const std::size_t passcode_length = static_cast<std::size_t>(passcode_length_value);
    const std::size_t plaintext_length = static_cast<std::size_t>(plaintext_length_value);
    if (input_length != 2 + passcode_length + plaintext_length) return -1;

    bool breakpoint[128]{};
    for (std::size_t i = 0; i < passcode_length; ++i) {
        const std::int64_t value = input[2 + i];
        if (!((value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z') ||
              (value >= '0' && value <= '9'))) return -1;
        breakpoint[static_cast<int>(value)] = true;
    }
    for (std::size_t i = 0; i < plaintext_length; ++i) {
        const std::int64_t value = input[2 + passcode_length + i];
        if (value < 0 || value >= 128) return -1;
        bool found = false;
        for (std::size_t j = 0; j < alphabet_length; ++j) {
            if (static_cast<unsigned char>(alphabet[j]) == static_cast<unsigned char>(value)) {
                found = true;
                break;
            }
        }
        if (!found) return -1;
    }

    int key[alphabet_length];
    int key_index[128];
    int segment[alphabet_length];
    for (int &index : key_index) index = -1;
    std::size_t key_length = 0;
    std::size_t segment_length = 0;
    for (std::size_t i = 0; i < alphabet_length; ++i) {
        const int value = static_cast<unsigned char>(alphabet[i]);
        segment[segment_length++] = value;
        if (breakpoint[value] || i + 1 == alphabet_length) {
            while (segment_length > 0) key[key_length++] = segment[--segment_length];
        }
    }
    for (std::size_t i = 0; i < alphabet_length; ++i) key_index[key[i]] = static_cast<int>(i);

    int shift = 0;
    for (std::size_t i = 0; i < passcode_length; ++i) {
        const int value = static_cast<int>(input[2 + i]);
        shift += (i % 2 == 0) ? value : -value;
    }
    if (shift <= 0) shift = static_cast<int>(passcode_length);
    shift %= static_cast<int>(alphabet_length);

    if (output == nullptr || output_capacity < plaintext_length) return -2;
    for (std::size_t i = 0; i < plaintext_length; ++i) {
        const int value = static_cast<int>(input[2 + passcode_length + i]);
        const int index = key_index[value];
        output[i] = static_cast<char>(key[(index + shift) % static_cast<int>(alphabet_length)]);
    }
    return static_cast<std::int64_t>(plaintext_length);
}
