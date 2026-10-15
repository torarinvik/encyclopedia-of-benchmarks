/* Return twice the statistical median using a local insertion-sorted copy. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t median(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > 1024) return 0;
    std::int64_t ordered[1024];
    for (std::size_t index = 0; index < length; ++index) ordered[index] = values[index];
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t value = ordered[index];
        std::size_t cursor = index;
        while (cursor > 0 && ordered[cursor - 1] > value) {
            ordered[cursor] = ordered[cursor - 1];
            --cursor;
        }
        ordered[cursor] = value;
    }
    if (length % 2 != 0) return ordered[length / 2] * 2;
    return ordered[length / 2 - 1] + ordered[length / 2];
}
