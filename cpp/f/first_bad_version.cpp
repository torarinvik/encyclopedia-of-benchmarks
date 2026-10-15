/* Find the first bad version with a lower-bound binary search. */
#include <cstdint>

extern "C" std::int64_t first_bad_version(std::uint64_t version_count,
                                           std::uint64_t first_bad) noexcept
{
    if (version_count == 0 || version_count > 2147483647 ||
        first_bad == 0 || first_bad > version_count) return -1;

    std::uint64_t low = 1;
    std::uint64_t high = version_count;
    while (low < high) {
        const std::uint64_t middle = low + (high - low) / 2;
        if (middle >= first_bad) high = middle;
        else low = middle + 1;
    }
    return static_cast<std::int64_t>(low);
}
