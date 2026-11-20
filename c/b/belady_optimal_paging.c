#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_CAPACITY 8
#define MAX_REQUESTS 64
#define PAGE_COUNT 16
#define MAX_INPUT_LENGTH 67
#define CHECKSUM_RADIX INT64_C(33281)

int64_t belady_optimal_paging(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t capacity_value = input[0], count_value = input[1];
    if (capacity_value < 1 || capacity_value > MAX_CAPACITY ||
        count_value < 0 || count_value > MAX_REQUESTS || length != (size_t)(2 + count_value)) return -1;
    const size_t capacity = (size_t)capacity_value, count = (size_t)count_value;
    int64_t requests[MAX_REQUESTS] = {0};
    for (size_t time = 0; time < count; ++time) {
        requests[time] = input[2 + time];
        if (requests[time] < 0 || requests[time] >= PAGE_COUNT) return -1;
    }
    int64_t next_after[MAX_REQUESTS][PAGE_COUNT] = {{0}};
    int64_t next_position[PAGE_COUNT];
    for (size_t page = 0; page < PAGE_COUNT; ++page) next_position[page] = (int64_t)count;
    for (size_t time = count; time > 0; --time) {
        const size_t index = time - 1;
        for (size_t page = 0; page < PAGE_COUNT; ++page)
            next_after[index][page] = next_position[page];
        next_position[requests[index]] = (int64_t)index;
    }

    bool resident[PAGE_COUNT] = {false};
    size_t resident_count = 0;
    int64_t misses = 0, eviction_checksum = 0;
    for (size_t time = 0; time < count; ++time) {
        const size_t requested = (size_t)requests[time];
        if (resident[requested]) continue;
        ++misses;
        if (resident_count == capacity) {
            size_t victim = PAGE_COUNT;
            int64_t farthest = -1;
            for (size_t page = 0; page < PAGE_COUNT; ++page) {
                if (!resident[page]) continue;
                const int64_t following = next_after[time][page];
                if (following > farthest) { victim = page; farthest = following; }
            }
            resident[victim] = false;
            --resident_count;
            eviction_checksum += (int64_t)(time + 1) * (int64_t)(victim + 1);
        }
        resident[requested] = true;
        ++resident_count;
    }
    return misses * CHECKSUM_RADIX + eviction_checksum;
}
