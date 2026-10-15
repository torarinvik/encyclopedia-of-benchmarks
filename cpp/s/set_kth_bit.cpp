#include <cstddef>
#include <cstdint>

extern "C" std::int64_t set_kth_bit(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 2) return -1;
    const std::int64_t number = input[0];
    const std::int64_t bit = input[1];
    if (number < 0 || number > 2147483647 || bit < 0 || bit > 30) return -1;
    return number | (std::int64_t{1} << bit);
}
