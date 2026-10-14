/* Stable LSD radix sort for the full signed 64-bit integer range. */
#include <cstddef>
#include <cstdint>

static std::uint64_t radix_order_key(std::int64_t value) noexcept
{
    const std::uint64_t sign_bit = std::uint64_t{1} << 63;
    if (value < 0) return sign_bit - 1 - static_cast<std::uint64_t>(-(value + 1));
    return sign_bit + static_cast<std::uint64_t>(value);
}

extern "C" void radix_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    if (length < 2) return;
    std::int64_t *counts = scratch;
    std::int64_t *output = scratch + 256;
    for (unsigned pass = 0; pass < 8; ++pass) {
        for (std::size_t bucket = 0; bucket < 256; ++bucket) counts[bucket] = 0;
        const unsigned shift = pass * 8;
        for (std::size_t index = 0; index < length; ++index) {
            const std::size_t bucket = static_cast<std::size_t>((radix_order_key(values[index]) >> shift) & 255U);
            ++counts[bucket];
        }
        std::size_t next = 0;
        for (std::size_t bucket = 0; bucket < 256; ++bucket) {
            const std::size_t count = static_cast<std::size_t>(counts[bucket]);
            counts[bucket] = static_cast<std::int64_t>(next);
            next += count;
        }
        for (std::size_t index = 0; index < length; ++index) {
            const std::size_t bucket = static_cast<std::size_t>((radix_order_key(values[index]) >> shift) & 255U);
            const std::size_t destination = static_cast<std::size_t>(counts[bucket]++);
            output[destination] = values[index];
        }
        for (std::size_t index = 0; index < length; ++index) values[index] = output[index];
    }
}
