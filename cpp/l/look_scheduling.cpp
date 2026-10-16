#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_REQUESTS = 4096;
constexpr std::size_t MAX_TRACK = 256;
constexpr std::uint64_t FNV_OFFSET = UINT64_C(14695981039346656037);
constexpr std::uint64_t FNV_PRIME = UINT64_C(1099511628211);
std::uint64_t hash_i64(std::uint64_t hash, std::int64_t value) {
    const auto bits = static_cast<std::uint64_t>(value);
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ static_cast<std::uint8_t>(bits >> shift)) * FNV_PRIME;
    return hash;
}
}

extern "C" std::int64_t look_scheduling(const std::int64_t *input, std::size_t length) {
    if (input == nullptr || length < 4 || length > MAX_REQUESTS + 4) return -1;
    const auto max_track64 = input[0], start64 = input[1], direction = input[2], count64 = input[3];
    if (max_track64 < 1 || max_track64 > static_cast<std::int64_t>(MAX_TRACK) || start64 < 0 || start64 >= max_track64 ||
        (direction != 0 && direction != 1) || count64 < 0 || count64 > static_cast<std::int64_t>(MAX_REQUESTS) ||
        length != static_cast<std::size_t>(count64) + 4) return -1;
    const auto max_track = static_cast<std::size_t>(max_track64), start = static_cast<std::size_t>(start64), count = static_cast<std::size_t>(count64);
    std::size_t lower_counts[MAX_TRACK]{}, upper_counts[MAX_TRACK]{};
    std::int64_t farthest = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto request = input[4 + i];
        if (request < INT32_MIN || request > INT32_MAX) return -1;
        if (request >= 0 && request < max_track64) {
            if (static_cast<std::size_t>(request) < start) ++lower_counts[request];
            else ++upper_counts[request];
            if (request > farthest) farthest = request;
        }
    }
    std::int64_t route[MAX_REQUESTS];
    std::size_t route_count = 0;
    if (direction == 1) {
        for (std::size_t track = start; track < max_track; ++track)
            for (std::size_t repeat = 0; repeat < upper_counts[track]; ++repeat) route[route_count++] = static_cast<std::int64_t>(track);
        auto track = start;
        while (track > 0) {
            --track;
            for (std::size_t repeat = 0; repeat < lower_counts[track]; ++repeat) route[route_count++] = static_cast<std::int64_t>(track);
        }
    } else {
        auto track = start;
        while (track > 0) {
            --track;
            for (std::size_t repeat = 0; repeat < lower_counts[track]; ++repeat) route[route_count++] = static_cast<std::int64_t>(track);
        }
        for (track = start; track < max_track; ++track)
            for (std::size_t repeat = 0; repeat < upper_counts[track]; ++repeat) route[route_count++] = static_cast<std::int64_t>(track);
    }
    auto hash = hash_i64(FNV_OFFSET, static_cast<std::int64_t>(route_count));
    for (std::size_t i = 0; i < route_count; ++i) hash = hash_i64(hash, route[i]);
    hash = hash_i64(hash, direction == 1 ? 0 : 1);
    hash = hash_i64(hash, farthest);
    hash = hash_i64(hash, start64);
    return static_cast<std::int64_t>(hash & UINT64_C(0x7fffffffffffffff));
}
