#include <cstddef>
#include <cstdint>

extern "C" int64_t unique_occurrences(const int64_t *values, size_t length) {
    if (length == 0) return 1;
    if (length > 1000 || values == nullptr) return -1;
    uint64_t first = static_cast<uint64_t>(values[0]);
    if (length == 1) return first + 1000 <= 2000 ? 1 : -1;

    uint64_t largest_biased = 0;
    uint64_t different_bits = 0;
    for (size_t index = 0; index < length; ++index) {
        uint64_t value = static_cast<uint64_t>(values[index]);
        uint64_t biased = value + 1000;
        different_bits |= value ^ first;
        largest_biased = biased > largest_biased ? biased : largest_biased;
    }
    if (largest_biased > 2000) return -1;
    if (different_bits == 0) return 1;

    uint16_t counts[2001] = {0};
    uint16_t touched[44] = {0};
    size_t distinct = 0;
    for (size_t index = 0; index < length; ++index) {
        size_t slot = static_cast<size_t>((static_cast<uint64_t>(values[index]) + 1000));
        if (counts[slot]++ == 0) {
            size_t next_distinct = distinct + 1;
            if (next_distinct * (next_distinct + 1) > 2 * length) return 0;
            touched[distinct] = static_cast<uint16_t>(slot);
            distinct = next_distinct;
        }
    }
    uint64_t seen[16] = {0};
    for (size_t index = 0; index < distinct; ++index) {
        size_t frequency = counts[touched[index]];
        size_t word = frequency >> 6;
        uint64_t bit = static_cast<uint64_t>(1) << (frequency & 63);
        if ((seen[word] & bit) != 0) return 0;
        seen[word] |= bit;
    }
    return 1;
}
