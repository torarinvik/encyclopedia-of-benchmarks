/* Fold a list of nonnegative values with overflow-safe Euclidean LCM. */
#include <cstddef>
#include <cstdint>
#include <limits>

extern "C" std::int64_t lcm_of_n_numbers(const std::int64_t *values,
                                          std::size_t length) noexcept
{
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] == 0) return 0;
    }
    std::uint64_t accumulator = 1;
    const auto maximum = static_cast<std::uint64_t>(std::numeric_limits<std::int64_t>::max());
    for (std::size_t index = 0; index < length; ++index) {
        auto left = accumulator;
        auto right = static_cast<std::uint64_t>(values[index]);
        while (right != 0) {
            const auto remainder = left % right;
            left = right;
            right = remainder;
        }
        const auto reduced = accumulator / left;
        const auto value = static_cast<std::uint64_t>(values[index]);
        if (reduced > maximum / value) return -1;
        accumulator = reduced * value;
    }
    return static_cast<std::int64_t>(accumulator);
}
