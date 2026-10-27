#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t kMaxRequests = 7;
constexpr std::size_t kMaxFiles = 8;
constexpr std::size_t kMaxInput = 16;

void store_i64_le(std::uint8_t *output, std::size_t offset, std::int64_t value)
{
    auto bits = static_cast<std::uint64_t>(value);
    for (std::size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = static_cast<std::uint8_t>(bits & 255U);
        bits >>= 8;
    }
}
}

extern "C" std::int64_t greedy_dual_weighted_caching(const std::int64_t *input,
    std::size_t length, std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length < 2 || length > kMaxInput) return -1;
    const auto cache_capacity = input[0], count_value = input[1];
    if (cache_capacity < 1 || cache_capacity > static_cast<std::int64_t>(kMaxFiles) ||
        count_value < 0 || count_value > static_cast<std::int64_t>(kMaxRequests) ||
        length != 2 + 2 * static_cast<std::size_t>(count_value)) return -1;

    std::int64_t known_cost[kMaxFiles]{};
    bool seen[kMaxFiles]{};
    for (std::size_t request = 0; request < static_cast<std::size_t>(count_value); ++request) {
        const auto id = input[2 + 2 * request], cost = input[3 + 2 * request];
        if (id < 0 || id >= static_cast<std::int64_t>(kMaxFiles) || cost < 0 || cost > 20) return -1;
        const auto slot = static_cast<std::size_t>(id);
        if (seen[slot] && known_cost[slot] != cost) return -1;
        seen[slot] = true;
        known_cost[slot] = cost;
    }

    std::int64_t ids[kMaxFiles]{}, credits[kMaxFiles]{};
    std::size_t resident_count = 0;
    std::int64_t misses = 0, total_cost = 0;
    std::uint64_t hit_signature = 0, eviction_signature = 0, resident_mask = 0;
    for (std::size_t request = 0; request < static_cast<std::size_t>(count_value); ++request) {
        const auto id = input[2 + 2 * request], cost = input[3 + 2 * request];
        std::size_t position = 0;
        while (position < resident_count && ids[position] != id) ++position;
        if (position < resident_count) {
            hit_signature |= std::uint64_t{1} << request;
            credits[position] = cost;
            continue;
        }
        ++misses;
        total_cost += cost;
        std::uint64_t evicted_mask = 0;
        while (resident_count >= static_cast<std::size_t>(cache_capacity)) {
            auto delta = credits[0];
            for (std::size_t i = 1; i < resident_count; ++i) if (credits[i] < delta) delta = credits[i];
            std::size_t kept = 0;
            for (std::size_t i = 0; i < resident_count; ++i) {
                credits[i] -= delta;
                if (credits[i] == 0) evicted_mask |= std::uint64_t{1} << ids[i];
                else { ids[kept] = ids[i]; credits[kept] = credits[i]; ++kept; }
            }
            resident_count = kept;
        }
        eviction_signature |= evicted_mask << (8 * request);
        ids[resident_count] = id;
        credits[resident_count] = cost;
        ++resident_count;
    }
    for (std::size_t i = 0; i < resident_count; ++i) resident_mask |= std::uint64_t{1} << ids[i];
    if (output == nullptr || output_capacity < 40) return -2;
    std::uint8_t staged[40]{};
    store_i64_le(staged, 0, misses);
    store_i64_le(staged, 8, total_cost);
    store_i64_le(staged, 16, static_cast<std::int64_t>(hit_signature));
    store_i64_le(staged, 24, static_cast<std::int64_t>(eviction_signature));
    store_i64_le(staged, 32, static_cast<std::int64_t>(resident_mask));
    for (std::size_t byte = 0; byte < 40; ++byte) output[byte] = staged[byte];
    return 40;
}
