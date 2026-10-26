#include <array>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MaxK = 8, MaxItems = 64, MaxInput = 2 + MaxItems;
void storeI64LE(std::uint8_t* output, std::size_t offset, std::int64_t value) noexcept {
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t misra_gries_summaries(const std::int64_t* input,
    std::size_t length, std::uint8_t* output, std::size_t capacity) noexcept {
    if (!input || length < 2 || length > MaxInput) return -1;
    const auto k64 = input[0], count64 = input[1];
    if (k64 < 1 || k64 > static_cast<std::int64_t>(MaxK) || count64 < 0 ||
        count64 > static_cast<std::int64_t>(MaxItems) || length != 2 + static_cast<std::size_t>(count64)) return -1;
    const auto k = static_cast<std::size_t>(k64), count = static_cast<std::size_t>(count64);
    std::array<std::int64_t, MaxK> items{}, counts{};
    items.fill(-1);
    for (std::size_t index = 0; index < count; ++index) {
        const auto item = input[index + 2];
        if (item < 0 || item > 15) return -1;
        std::size_t slot = 0;
        while (slot < k && items[slot] != item) ++slot;
        if (slot < k) { ++counts[slot]; continue; }
        slot = 0;
        while (slot < k && counts[slot] != 0) ++slot;
        if (slot < k) { items[slot] = item; counts[slot] = 1; continue; }
        for (slot = 0; slot < k; ++slot) {
            --counts[slot];
            if (counts[slot] == 0) items[slot] = -1;
        }
    }
    std::size_t used = 0;
    for (std::size_t slot = 0; slot < k; ++slot) if (counts[slot] > 0) ++used;
    const auto outputBytes = 8 * (1 + 2 * used);
    if (!output || capacity < outputBytes) return -2;
    std::array<std::int64_t, MaxK> orderedItems{}, orderedCounts{};
    std::size_t at = 0;
    for (std::size_t slot = 0; slot < k; ++slot) {
        if (counts[slot] <= 0) continue;
        auto position = at;
        while (position > 0 && orderedItems[position - 1] > items[slot]) {
            orderedItems[position] = orderedItems[position - 1];
            orderedCounts[position] = orderedCounts[position - 1];
            --position;
        }
        orderedItems[position] = items[slot];
        orderedCounts[position] = counts[slot];
        ++at;
    }
    storeI64LE(output, 0, static_cast<std::int64_t>(used));
    for (std::size_t index = 0; index < used; ++index) {
        storeI64LE(output, 8 * (1 + 2 * index), orderedItems[index]);
        storeI64LE(output, 8 * (2 + 2 * index), orderedCounts[index]);
    }
    return static_cast<std::int64_t>(outputBytes);
}
