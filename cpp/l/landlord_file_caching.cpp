#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxRequests = 7;
constexpr std::size_t kMaxFiles = 8;
constexpr std::size_t kMaxInput = 23;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = static_cast<std::uint8_t>(bits & 255U); bits >>= 8; }
}
}

extern "C" std::int64_t landlord_file_caching(const std::int64_t *input, std::size_t length,
                                                std::uint8_t *output, std::size_t capacity) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > 8 || count_value < 0 || count_value > static_cast<std::int64_t>(kMaxRequests) ||
        length != 2 + 3 * static_cast<std::size_t>(count_value)) return -1;
    std::int64_t known_size[kMaxFiles]{}, known_cost[kMaxFiles]{};
    bool seen[kMaxFiles]{};
    for (std::size_t request = 0; request < static_cast<std::size_t>(count_value); ++request) {
        const auto id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        if (id < 0 || id >= static_cast<std::int64_t>(kMaxFiles) || size < 1 || size > 4 || size > capacity_value || cost < 0 || cost > 20) return -1;
        if (seen[id] && (known_size[id] != size || known_cost[id] != cost)) return -1;
        seen[id] = true; known_size[id] = size; known_cost[id] = cost;
    }
    std::int64_t ids[kMaxFiles]{}, sizes[kMaxFiles]{}, credits[kMaxFiles]{};
    std::size_t resident_count = 0;
    std::int64_t misses = 0, total_cost = 0;
    std::uint64_t hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (std::size_t request = 0; request < static_cast<std::size_t>(count_value); ++request) {
        const auto id = input[2 + 3 * request], size = input[3 + 3 * request], cost = input[4 + 3 * request];
        std::size_t position = 0;
        while (position < resident_count && ids[position] != id) ++position;
        if (position < resident_count) { hit_signature |= std::uint64_t{1} << request; continue; }
        ++misses; total_cost += cost;
        std::uint64_t evicted_mask = 0;
        std::int64_t used = 0;
        for (std::size_t i = 0; i < resident_count; ++i) used += sizes[i];
        while (used + size > capacity_value) {
            auto delta = credits[0] / sizes[0];
            for (std::size_t i = 1; i < resident_count; ++i) {
                const auto ratio = credits[i] / sizes[i];
                if (ratio < delta) delta = ratio;
            }
            std::size_t kept = 0;
            used = 0;
            for (std::size_t i = 0; i < resident_count; ++i) {
                credits[i] -= delta * sizes[i];
                if (credits[i] == 0) evicted_mask |= std::uint64_t{1} << ids[i];
                else { ids[kept] = ids[i]; sizes[kept] = sizes[i]; credits[kept] = credits[i]; used += sizes[kept]; ++kept; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id; sizes[resident_count] = size; credits[resident_count] = cost * 12; ++resident_count;
    }
    for (std::size_t i = 0; i < resident_count; ++i) resident_mask |= std::uint64_t{1} << ids[i];
    if (output == nullptr || capacity < 40) return -2;
    std::uint8_t staged[40]{};
    store_i64_le(staged, 0, misses); store_i64_le(staged, 8, total_cost);
    store_i64_le(staged, 16, static_cast<std::int64_t>(hit_signature));
    store_i64_le(staged, 24, static_cast<std::int64_t>(eviction_signature));
    store_i64_le(staged, 32, static_cast<std::int64_t>(resident_mask));
    for (std::size_t byte = 0; byte < 40; ++byte) output[byte] = staged[byte];
    return 40;
}
