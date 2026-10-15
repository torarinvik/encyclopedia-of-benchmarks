/* Check whether ASCII letters form an isogram, ignoring case and spaces. */
#include <cstddef>
#include <cstdint>

extern "C" int64_t isogram(const int64_t *values, std::size_t length)
{
    if (length > 4096 || (length != 0 && values == nullptr)) return -1;
    bool seen[26]{};
    for (std::size_t index = 0; index < length; ++index) {
        int64_t value = values[index];
        if (value == 32) continue;
        if (value >= 'A' && value <= 'Z') value += 'a' - 'A';
        if (value < 'a' || value > 'z') return -1;
        const std::size_t letter = static_cast<std::size_t>(value - 'a');
        if (seen[letter]) return 0;
        seen[letter] = true;
    }
    return 1;
}
