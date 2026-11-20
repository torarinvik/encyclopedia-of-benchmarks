#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_masks = 64;
constexpr std::size_t max_input_length = 66;
constexpr std::int64_t max_bits = 6;
}

extern "C" std::int64_t sum_over_subsets_zeta_transform(
    const std::int64_t *input, std::size_t length) noexcept
{
    if (input == nullptr || length < 1 || length > max_input_length) return -1;
    const std::int64_t bit_count_value = input[0];
    if (bit_count_value < 0 || bit_count_value > max_bits) return -1;
    const std::size_t bit_count = static_cast<std::size_t>(bit_count_value);
    const std::size_t mask_count = static_cast<std::size_t>(1) << bit_count;
    if (length != mask_count + 1) return -1;

    std::int64_t transformed[max_masks]{};
    for (std::size_t mask = 0; mask < mask_count; ++mask) {
        const std::int64_t value = input[mask + 1];
        if (value < 0 || value > 1'000'000) return -1;
        transformed[mask] = value;
    }

    for (std::size_t bit = 0; bit < bit_count; ++bit) {
        const std::size_t bit_value = static_cast<std::size_t>(1) << bit;
        for (std::size_t mask = 0; mask < mask_count; ++mask) {
            if ((mask & bit_value) != 0)
                transformed[mask] += transformed[mask ^ bit_value];
        }
    }

    std::int64_t checksum = 0;
    for (std::size_t mask = 0; mask < mask_count; ++mask)
        checksum += static_cast<std::int64_t>(mask + 1) * transformed[mask];
    return checksum;
}
