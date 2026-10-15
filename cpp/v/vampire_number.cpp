/* Match the product's decimal digits against the combined factor digits. */
#include <array>
#include <cstdint>

namespace {
unsigned decimal_length(std::uint64_t value) noexcept
{
    unsigned length = 0;
    do { ++length; value /= 10; } while (value != 0);
    return length;
}
}

extern "C" std::int64_t vampire_number(std::uint64_t left, std::uint64_t right) noexcept
{
    if (left < 1 || left > 9999 || right < 1 || right > 9999) return -1;
    if (decimal_length(left) != decimal_length(right)) return 0;
    std::array<int, 10> counts{};
    auto product = left * right;
    while (product != 0) { ++counts[product % 10]; product /= 10; }
    while (left != 0) { --counts[left % 10]; left /= 10; }
    while (right != 0) { --counts[right % 10]; right /= 10; }
    for (int count : counts) if (count != 0) return 0;
    return 1;
}
