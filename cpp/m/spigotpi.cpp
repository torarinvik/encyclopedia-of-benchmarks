/* Generate leading decimal digits with the pinned spigot recurrence. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t spigotpi(const std::int64_t* input, std::size_t length,
                                  std::uint8_t* output,
                                  std::size_t output_capacity) noexcept {
    if (length != 1 || input == nullptr || input[0] < 0 || input[0] > 256) return -1;
    const auto digit_count = static_cast<std::size_t>(input[0]);
    if (output == nullptr || output_capacity < digit_count) return -2;
    if (digit_count == 0) return 0;

    const std::size_t boxes = digit_count * 10 / 3;
    std::int64_t remainders[854];
    for (std::size_t index = 0; index < boxes; ++index) remainders[index] = 2;
    std::size_t digits_held = 0;
    for (std::size_t index = 0; index < digit_count; ++index) {
        std::int64_t carried_over = 0, sum = 0;
        for (std::size_t cursor = boxes; cursor > 0;) {
            const std::size_t j = --cursor;
            remainders[j] *= 10;
            sum = remainders[j] + carried_over;
            const std::int64_t quotient = sum / (static_cast<std::int64_t>(j) * 2 + 1);
            remainders[j] = sum % (static_cast<std::int64_t>(j) * 2 + 1);
            carried_over = quotient * static_cast<std::int64_t>(j);
        }
        remainders[0] = sum % 10;
        auto q = sum / 10;
        if (q == 9) {
            ++digits_held;
        } else if (q == 10) {
            q = 0;
            for (std::size_t offset = 1; offset <= digits_held; ++offset) {
                const std::size_t position = index - offset;
                output[position] = output[position] == '9' ? '0'
                    : static_cast<std::uint8_t>(output[position] + 1);
            }
            digits_held = 1;
        } else {
            digits_held = 1;
        }
        output[index] = static_cast<std::uint8_t>('0' + q);
    }
    return static_cast<std::int64_t>(digit_count);
}
