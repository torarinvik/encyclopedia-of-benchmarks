#include <stddef.h>
#include <stdint.h>

#define MAX_REQUESTS 4096
#define MAX_TRACK 256
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_i64(uint64_t hash, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (unsigned shift = 0; shift < 64; shift += 8) hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    return hash;
}

int64_t look_scheduling(const int64_t *input, size_t length) {
    if (input == NULL || length < 4 || length > MAX_REQUESTS + 4) return -1;
    const int64_t max_track64 = input[0], start64 = input[1], direction = input[2], count64 = input[3];
    if (max_track64 < 1 || max_track64 > MAX_TRACK || start64 < 0 || start64 >= max_track64 ||
        (direction != 0 && direction != 1) || count64 < 0 || count64 > MAX_REQUESTS ||
        length != (size_t)count64 + 4) return -1;
    const size_t max_track = (size_t)max_track64, start = (size_t)start64, count = (size_t)count64;
    size_t lower_counts[MAX_TRACK] = {0}, upper_counts[MAX_TRACK] = {0};
    int64_t farthest = 0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t request = input[4 + i];
        if (request < INT32_MIN || request > INT32_MAX) return -1;
        if (request >= 0 && request < max_track64) {
            if ((size_t)request < start) ++lower_counts[request];
            else ++upper_counts[request];
            if (request > farthest) farthest = request;
        }
    }

    int64_t route[MAX_REQUESTS];
    size_t route_count = 0;
    if (direction == 1) {
        for (size_t track = start; track < max_track; ++track)
            for (size_t repeat = 0; repeat < upper_counts[track]; ++repeat) route[route_count++] = (int64_t)track;
        size_t track = start;
        while (track > 0) {
            --track;
            for (size_t repeat = 0; repeat < lower_counts[track]; ++repeat) route[route_count++] = (int64_t)track;
        }
    } else {
        size_t track = start;
        while (track > 0) {
            --track;
            for (size_t repeat = 0; repeat < lower_counts[track]; ++repeat) route[route_count++] = (int64_t)track;
        }
        for (track = start; track < max_track; ++track)
            for (size_t repeat = 0; repeat < upper_counts[track]; ++repeat) route[route_count++] = (int64_t)track;
    }

    uint64_t hash = hash_i64(FNV_OFFSET, (int64_t)route_count);
    for (size_t i = 0; i < route_count; ++i) hash = hash_i64(hash, route[i]);
    hash = hash_i64(hash, direction == 1 ? 0 : 1);
    hash = hash_i64(hash, farthest);
    hash = hash_i64(hash, start64);
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
