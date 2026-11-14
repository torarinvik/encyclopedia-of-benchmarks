#include <algorithm>
#include <array>
#include <cstddef>
#include <cstdint>

struct Entry { int64_t item, estimate, error; };

extern "C" int64_t space_saving_frequent_items(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 67) return -1;
    const auto kr = input[0], nr = input[1];
    if (kr < 1 || kr > 8 || nr < 0 || nr > 64 || length != 2+static_cast<size_t>(nr)) return -1;
    const size_t k = static_cast<size_t>(kr), n = static_cast<size_t>(nr);
    for (size_t i = 0; i < n; ++i) if (input[2+i] < -1000 || input[2+i] > 1000) return -1;
    std::array<Entry, 8> entries{};
    size_t used = 0;
    for (size_t i = 0; i < n; ++i) {
        const auto item = input[2+i];
        size_t slot = 0;
        while (slot < used && entries[slot].item != item) ++slot;
        if (slot < used) { ++entries[slot].estimate; continue; }
        if (used < k) { entries[used++] = {item,1,0}; continue; }
        size_t victim = 0;
        for (size_t j = 1; j < used; ++j)
            if (entries[j].estimate < entries[victim].estimate ||
                (entries[j].estimate == entries[victim].estimate && entries[j].item < entries[victim].item)) victim = j;
        const auto minimum = entries[victim].estimate;
        entries[victim] = {item,minimum+1,minimum};
    }
    std::sort(entries.begin(), entries.begin()+used, [](const Entry& a, const Entry& b) { return a.item < b.item; });
    const size_t words = 1+3*used, bytes = 8*words;
    if (!output || capacity < bytes) return -2;
    std::array<int64_t, 25> fields{}; fields[0] = static_cast<int64_t>(used);
    for (size_t i = 0; i < used; ++i) {
        fields[1+3*i] = entries[i].item;
        fields[2+3*i] = entries[i].estimate;
        fields[3+3*i] = entries[i].error;
    }
    std::array<uint8_t, 200> staged{};
    for (size_t i = 0; i < words; ++i) {
        const auto bits = static_cast<uint64_t>(fields[i]);
        for (size_t b = 0; b < 8; ++b) staged[8*i+b] = static_cast<uint8_t>(bits >> (8*b));
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return static_cast<int64_t>(bytes);
}
