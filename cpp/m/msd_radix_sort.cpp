/* In-place most-significant-bit radix sort for signed 64-bit values. */
#include <cstddef>
#include <cstdint>

static std::uint64_t msd_order_key(std::int64_t value) noexcept
{
    const std::uint64_t sign_bit = std::uint64_t{1} << 63;
    if (value < 0) return sign_bit - 1 - static_cast<std::uint64_t>(-(value + 1));
    return sign_bit + static_cast<std::uint64_t>(value);
}

static void msd_sort_range(std::int64_t *values, std::size_t begin, std::size_t end, int bit) noexcept
{
    if (end - begin < 2 || bit < 0) return;
    std::size_t left = begin;
    std::size_t right = end;
    while (left < right) {
        while (left < right && ((msd_order_key(values[left]) >> static_cast<unsigned>(bit)) & 1U) == 0) ++left;
        while (left < right && ((msd_order_key(values[right - 1]) >> static_cast<unsigned>(bit)) & 1U) != 0) --right;
        if (left < right) {
            const std::int64_t temporary = values[left];
            values[left] = values[right - 1];
            values[right - 1] = temporary;
            ++left;
            --right;
        }
    }
    msd_sort_range(values, begin, left, bit - 1);
    msd_sort_range(values, left, end, bit - 1);
}

extern "C" void msd_radix_sort(std::int64_t *values, std::size_t length) noexcept
{
    if (length > 1) msd_sort_range(values, 0, length, 63);
}
