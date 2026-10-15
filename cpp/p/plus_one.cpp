#include <cstddef>
#include <cstdint>

extern "C" std::int64_t plus_one(const std::int64_t *digits, std::size_t length,
                                  std::uint8_t *output, std::size_t output_capacity) {
    if (length > 256 || (length != 0 && digits == nullptr)) return -1;
    bool all_nines = true;
    for (std::size_t index = 0; index < length; ++index) {
        if (digits[index] < 0 || digits[index] > 9) return -1;
        if (digits[index] != 9) all_nines = false;
    }
    if (length > 1 && digits[0] == 0) return -1;
    const std::size_t output_length = length == 0 || all_nines ? length + 1 : length;
    if (output_capacity < output_length) return -2;
    if (length == 0 || all_nines) {
        output[0] = static_cast<std::uint8_t>('1');
        for (std::size_t index = 1; index < output_length; ++index)
            output[index] = static_cast<std::uint8_t>('0');
        return static_cast<std::int64_t>(output_length);
    }
    for (std::size_t index = 0; index < length; ++index)
        output[index] = static_cast<std::uint8_t>('0' + digits[index]);
    for (std::size_t index = length; index > 0; --index) {
        if (digits[index - 1] == 9) output[index - 1] = static_cast<std::uint8_t>('0');
        else {
            output[index - 1] = static_cast<std::uint8_t>(output[index - 1] + 1);
            break;
        }
    }
    return static_cast<std::int64_t>(output_length);
}
