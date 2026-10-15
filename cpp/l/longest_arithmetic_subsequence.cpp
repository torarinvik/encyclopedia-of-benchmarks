// Length of the longest arithmetic subsequence.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t longest_arithmetic_subsequence(const std::int64_t *values, std::size_t length)
{
    if (length > 64 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (values[i] < -1000000 || values[i] > 1000000) return -1;
    if (length <= 1) return static_cast<std::int64_t>(length);
    std::int64_t keys[64][127]{};
    std::int64_t sizes[64][127]{};
    std::int64_t maximum = 2;
    for (std::size_t right = 0; right < length; ++right) {
        for (std::size_t left = 0; left < right; ++left) {
            const std::int64_t difference = values[right] - values[left];
            std::size_t slot = static_cast<std::size_t>((difference % 127 + 127) % 127);
            while (sizes[left][slot] != 0 && keys[left][slot] != difference) slot = (slot + 1) % 127;
            const std::int64_t candidate = (sizes[left][slot] == 0 ? 1 : sizes[left][slot]) + 1;
            slot = static_cast<std::size_t>((difference % 127 + 127) % 127);
            while (sizes[right][slot] != 0 && keys[right][slot] != difference) slot = (slot + 1) % 127;
            if (sizes[right][slot] == 0 || candidate > sizes[right][slot]) {
                keys[right][slot] = difference;
                sizes[right][slot] = candidate;
            }
            if (candidate > maximum) maximum = candidate;
        }
    }
    return maximum;
}
