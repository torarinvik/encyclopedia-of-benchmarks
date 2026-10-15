/* General s-gonal number formula from the pinned Python source. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t polygonal_numbers(const std::int64_t *packed, std::size_t length) noexcept
{
    if (packed == nullptr || length != 2) return -1;
    const std::int64_t num = packed[0];
    const std::int64_t sides = packed[1];
    if (num < 0 || num > 100000000 || sides < 3 || sides > 64) return -1;
    const std::int64_t square = num * num;
    const std::int64_t leading = (sides - 2) * square;
    const std::int64_t trailing = (sides - 4) * num;
    return (leading - trailing) / 2;
}
