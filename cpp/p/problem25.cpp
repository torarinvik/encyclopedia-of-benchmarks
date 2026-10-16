#include <cstdint>

extern "C" std::int64_t problem25(std::int64_t requested_digits) noexcept
{
    if (requested_digits < 2 || requested_digits > 1000) return -1;
    std::uint8_t previous[1000] = {};
    std::uint8_t current[1000] = {};
    std::uint8_t next[1000] = {};
    previous[0] = current[0] = 1;
    int active_digits = 1;
    std::int64_t index = 2;
    while (active_digits < requested_digits) {
        int carry = 0;
        for (int position = 0; position < active_digits; ++position) {
            const int sum = previous[position] + current[position] + carry;
            next[position] = static_cast<std::uint8_t>(sum % 10);
            carry = sum / 10;
        }
        if (carry != 0) next[active_digits++] = static_cast<std::uint8_t>(carry);
        for (int position = 0; position < active_digits; ++position) {
            previous[position] = current[position];
            current[position] = next[position];
        }
        ++index;
    }
    return index;
}
