#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_call_count = 1'000'000;
constexpr std::int64_t modulus = 139'968;
constexpr std::int64_t fraction_scale = 1'000'000'000;
constexpr std::size_t max_output_bytes = 13;
}

extern "C" std::int64_t shootout_random(std::int64_t call_count,
                                         std::uint8_t *output,
                                         std::size_t output_capacity) noexcept {
    if (call_count < 1 || call_count > max_call_count) return -1;

    std::int64_t state = 42;
    for (std::int64_t call = 0; call < call_count; ++call)
        state = (state * 3877 + 29573) % modulus;

    const std::int64_t scaled = (100 * state * fraction_scale + modulus / 2) / modulus;
    std::int64_t whole = scaled / fraction_scale;
    std::int64_t fraction = scaled % fraction_scale;
    std::uint8_t staged[max_output_bytes];
    std::uint8_t reversed_digits[3];
    std::size_t digit_count = 0;
    do {
        reversed_digits[digit_count++] = static_cast<std::uint8_t>('0' + whole % 10);
        whole /= 10;
    } while (whole != 0);

    std::size_t used = 0;
    while (digit_count > 0) staged[used++] = reversed_digits[--digit_count];
    staged[used++] = static_cast<std::uint8_t>('.');
    for (std::int64_t place = 100'000'000; place > 0; place /= 10) {
        staged[used++] = static_cast<std::uint8_t>('0' + fraction / place);
        fraction %= place;
    }
    staged[used++] = static_cast<std::uint8_t>('\n');

    if (output == nullptr || output_capacity < used) return -2;
    for (std::size_t index = 0; index < used; ++index) output[index] = staged[index];
    return static_cast<std::int64_t>(used);
}
