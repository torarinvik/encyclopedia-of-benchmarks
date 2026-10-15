/* Find the greatest h for which at least h citations are >= h. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t h_index(const std::int64_t *citations,
                                 std::size_t length) noexcept
{
    if (length > 5000) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (citations[index] < 0 || citations[index] > 1000) return -1;
    }

    std::size_t low = 0;
    std::size_t high = length < 1000 ? length : 1000;
    while (low < high) {
        const std::size_t middle = low + (high - low + 1) / 2;
        std::size_t qualifying = 0;
        for (std::size_t index = 0; index < length; ++index) {
            if (static_cast<std::uint64_t>(citations[index]) >= middle && ++qualifying >= middle) break;
        }
        if (qualifying >= middle) low = middle;
        else high = middle - 1;
    }
    return static_cast<std::int64_t>(low);
}
