#include <cstddef>
#include <cstdint>

extern "C" std::int64_t one_bit_difference(const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length != 2) return -1;
    const std::int64_t left = input[0];
    const std::int64_t right = input[1];
    if (left < INT32_MIN || left > INT32_MAX || right < INT32_MIN || right > INT32_MAX) return -1;
    const std::uint32_t difference = static_cast<std::uint32_t>(static_cast<std::int32_t>(left)) ^
                                     static_cast<std::uint32_t>(static_cast<std::int32_t>(right));
    return difference != 0 && (difference & (difference - std::uint32_t{1})) == 0 ? 1 : 0;
}
