/* Emit the index masks of all signed subsets matching the target. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t subset_sum_enumerate(const std::int64_t *input,
                                              std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 9) return -1;
    const auto target = input[0];
    if (target < -512 || target > 512) return -1;
    const auto items = length - 1;
    for (std::size_t index = 0; index < items; ++index)
        if (input[index + 1] < -64 || input[index + 1] > 64) return -1;

    std::uint8_t masks[256]{};
    std::size_t count = 0;
    const std::size_t limit = std::size_t{1} << items;
    for (std::size_t mask = 0; mask < limit; ++mask) {
        std::int64_t sum = 0;
        for (std::size_t index = 0; index < items; ++index)
            if ((mask >> index) & 1u) sum += input[index + 1];
        if (sum == target) masks[count++] = static_cast<std::uint8_t>(mask);
    }
    if (output_capacity < count) return -2;
    for (std::size_t index = 0; index < count; ++index) output[index] = masks[index];
    return static_cast<std::int64_t>(count);
}
