// Enumerate narcissistic numbers below limit, memoizing digit powers.
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t narcissistic_number(std::int64_t limit, std::uint8_t *output,
        std::size_t output_capacity) noexcept
{
    if (limit > 100000) return -1;
    if (limit <= 0) return 0;
    std::array<std::int64_t, 32> numbers{};
    std::array<std::int64_t, 60> powers{};
    std::array<bool, 60> cached{};
    std::size_t count = 0;
    for (std::int64_t number = 0; number < limit; ++number) {
        std::size_t digits = 1;
        for (auto remaining = number; remaining >= 10; remaining /= 10) ++digits;
        std::int64_t sum = 0;
        for (auto remaining = number; remaining > 0; remaining /= 10) {
            const auto digit = static_cast<std::size_t>(remaining % 10);
            const auto key = digits * 10 + digit;
            if (!cached[key]) {
                std::int64_t power = 1;
                for (std::size_t exponent = 0; exponent < digits; ++exponent)
                    power *= static_cast<std::int64_t>(digit);
                powers[key] = power;
                cached[key] = true;
            }
            sum += powers[key];
        }
        if (sum == number) {
            if (count == numbers.size()) return -1;
            numbers[count++] = number;
        }
    }
    const std::size_t required = count * 8;
    if (required == 0) return 0;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t item = 0; item < count; ++item) {
        const auto value = static_cast<std::uint64_t>(numbers[item]);
        for (std::size_t byte = 0; byte < 8; ++byte)
            output[item * 8 + byte] = static_cast<std::uint8_t>(value >> ((7 - byte) * 8));
    }
    return static_cast<std::int64_t>(required);
}
