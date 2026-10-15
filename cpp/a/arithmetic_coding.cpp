/* Return the exact scaled lower bound produced by arithmetic coding. */
#include <array>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t arithmetic_coding(const std::int64_t *input,
                                           std::size_t length) noexcept
{
    if (length < 2) return -1;
    const auto count = input[0];
    if (count < 1 || count > 12 || length != static_cast<std::size_t>(count + 1)) return -1;

    std::array<std::int64_t, 256> frequency{};
    std::array<std::int64_t, 257> cumulative{};
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const auto symbol = input[index + 1];
        if (symbol < 0 || symbol > 255) return -1;
        ++frequency[static_cast<std::size_t>(symbol)];
    }
    for (std::size_t symbol = 0; symbol < 256; ++symbol)
        cumulative[symbol + 1] = cumulative[symbol] + frequency[symbol];

    std::int64_t low = 0;
    std::int64_t high = 1;
    for (std::size_t index = 0; index < static_cast<std::size_t>(count); ++index) {
        const auto symbol = static_cast<std::size_t>(input[index + 1]);
        const auto range = high - low;
        const auto base = low * count;
        high = base + range * cumulative[symbol + 1];
        low = base + range * cumulative[symbol];
    }
    return low;
}
