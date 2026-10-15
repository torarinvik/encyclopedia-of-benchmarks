/* Emit fixed-size index combinations as little-endian subset masks. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t subset_combinations(const std::int64_t *input,
                                             std::size_t length,
                                             std::uint8_t *output,
                                             std::size_t output_capacity) noexcept
{
    if (length == 0 || length > 13 || input[0] < 0) return -1;
    const std::size_t item_count = length - 1;
    if (item_count > 12) return -1;
    if (input[0] > static_cast<std::int64_t>(item_count)) return 0;
    const auto choose = static_cast<std::size_t>(input[0]);
    std::size_t count = 1;
    for (std::size_t index = 1; index <= choose; ++index)
        count = count * (item_count - choose + index) / index;
    const std::size_t required = 2 * count;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;

    std::size_t indices[12]{};
    for (std::size_t index = 0; index < choose; ++index) indices[index] = index;
    for (std::size_t combination = 0; combination < count; ++combination) {
        std::size_t mask = 0;
        for (std::size_t index = 0; index < choose; ++index) mask |= std::size_t{1} << indices[index];
        output[2 * combination] = static_cast<std::uint8_t>(mask & 255u);
        output[2 * combination + 1] = static_cast<std::uint8_t>(mask >> 8);
        if (combination + 1 == count) break;
        std::size_t position = choose;
        while (position > 0) {
            --position;
            if (indices[position] < item_count - choose + position) break;
        }
        ++indices[position];
        for (std::size_t index = position + 1; index < choose; ++index)
            indices[index] = indices[index - 1] + 1;
    }
    return static_cast<std::int64_t>(count);
}
