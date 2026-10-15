#include <cstddef>
#include <cstdint>

namespace {
bool append_u64(std::uint64_t value, std::uint8_t *output, std::size_t capacity, std::size_t &position) noexcept
{
    std::uint8_t digits[20];
    std::size_t count = 0;
    do { digits[count++] = static_cast<std::uint8_t>('0' + value % 10); value /= 10; } while (value != 0);
    if (count > capacity - position) return false;
    while (count != 0) output[position++] = digits[--count];
    return true;
}
}

extern "C" std::int64_t allocation_number(const std::int64_t *values, std::size_t length,
                                            std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (values == nullptr || length != 2 || values[0] < 1 || values[0] > 1000000 ||
        values[1] < 1 || values[1] > 128 || values[1] > values[0]) return -1;
    const auto total = static_cast<std::uint64_t>(values[0]);
    const auto partitions = static_cast<std::uint64_t>(values[1]);
    const auto block = total / partitions;
    std::size_t position = 0;
    for (std::uint64_t index = 0; index < partitions; ++index) {
        const auto start = index * block + 1;
        const auto end = index + 1 == partitions ? total : (index + 1) * block;
        if (!append_u64(start, output, output_capacity, position)) return -2;
        if (position >= output_capacity) return -2;
        output[position++] = '-';
        if (!append_u64(end, output, output_capacity, position)) return -2;
        if (index + 1 != partitions) {
            if (position >= output_capacity) return -2;
            output[position++] = ',';
        }
    }
    return static_cast<std::int64_t>(position);
}
