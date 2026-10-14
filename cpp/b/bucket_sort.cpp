/* Stable top-byte bucket sort for the full signed 64-bit integer range. */
#include <cstddef>
#include <cstdint>

static std::uint64_t bucket_order_key(std::int64_t value) noexcept
{
    const std::uint64_t sign_bit = std::uint64_t{1} << 63;
    if (value < 0) return sign_bit - 1 - static_cast<std::uint64_t>(-(value + 1));
    return sign_bit + static_cast<std::uint64_t>(value);
}

static void bucket_sort_insertion(std::int64_t *values, std::size_t base, std::size_t low, std::size_t high) noexcept
{
    for (std::size_t index = low + (low < high); index < high; ++index) {
        const std::int64_t key = values[base + index];
        std::size_t position = index;
        while (position > low && values[base + position - 1] > key) {
            values[base + position] = values[base + position - 1];
            --position;
        }
        values[base + position] = key;
    }
}

extern "C" void bucket_sort(std::int64_t *values, std::int64_t *scratch, std::size_t length) noexcept
{
    if (length < 2) return;
    for (std::size_t bucket = 0; bucket < 256; ++bucket) scratch[bucket] = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t bucket = static_cast<std::size_t>(bucket_order_key(values[index]) >> 56);
        ++scratch[bucket];
    }
    std::size_t next = 0;
    for (std::size_t bucket = 0; bucket < 256; ++bucket) {
        const std::size_t count = static_cast<std::size_t>(scratch[bucket]);
        scratch[bucket] = static_cast<std::int64_t>(next);
        next += count;
    }
    for (std::size_t index = 0; index < length; ++index) {
        const std::size_t bucket = static_cast<std::size_t>(bucket_order_key(values[index]) >> 56);
        const std::size_t destination = static_cast<std::size_t>(scratch[bucket]++);
        scratch[256 + destination] = values[index];
    }
    std::size_t low = 0;
    for (std::size_t bucket = 0; bucket < 256; ++bucket) {
        const std::size_t high = static_cast<std::size_t>(scratch[bucket]);
        bucket_sort_insertion(scratch, 256, low, high);
        low = high;
    }
    for (std::size_t index = 0; index < length; ++index) values[index] = scratch[256 + index];
}
