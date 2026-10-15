/* Enumerate amicable pairs whose two members are below the exclusive limit. */
#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_limit = 8000;

void write_u32_le(std::uint8_t *output, std::size_t &position, std::int64_t value) noexcept {
    const auto encoded = static_cast<std::uint32_t>(value);
    for (unsigned byte = 0; byte < 4; ++byte)
        output[position++] = static_cast<std::uint8_t>(encoded >> (8U * byte));
}
}

extern "C" std::int64_t amicable_pairs_below(const std::int64_t *values, std::size_t length,
                                              std::uint8_t *output,
                                              std::size_t output_capacity) noexcept {
    if (values == nullptr || length != 1 || values[0] < 1 ||
        values[0] > static_cast<std::int64_t>(max_limit)) return -1;
    const auto limit = static_cast<std::size_t>(values[0]);
    std::array<std::int64_t, max_limit> divisor_sums{};
    for (std::size_t divisor = 1; divisor < limit; ++divisor)
        for (std::size_t multiple = divisor * 2; multiple < limit; multiple += divisor)
            divisor_sums[multiple] += static_cast<std::int64_t>(divisor);

    std::size_t pair_count = 0;
    for (std::size_t smaller = 2; smaller < limit; ++smaller) {
        const auto larger = divisor_sums[smaller];
        if (larger > static_cast<std::int64_t>(smaller) &&
            larger < static_cast<std::int64_t>(limit) &&
            divisor_sums[static_cast<std::size_t>(larger)] == static_cast<std::int64_t>(smaller))
            ++pair_count;
    }
    const std::size_t required = pair_count * 8;
    if (output_capacity < required || (required != 0 && output == nullptr)) return -2;

    std::size_t position = 0;
    for (std::size_t smaller = 2; smaller < limit; ++smaller) {
        const auto larger = divisor_sums[smaller];
        if (larger > static_cast<std::int64_t>(smaller) &&
            larger < static_cast<std::int64_t>(limit) &&
            divisor_sums[static_cast<std::size_t>(larger)] == static_cast<std::int64_t>(smaller)) {
            write_u32_le(output, position, static_cast<std::int64_t>(smaller));
            write_u32_le(output, position, larger);
        }
    }
    return static_cast<std::int64_t>(pair_count);
}
