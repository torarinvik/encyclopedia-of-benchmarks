#include <stddef.h>
#include <stdint.h>

enum { MAX_REQUESTS = 32, MAX_PAGES = 16, MAX_INPUT = 67, MAX_OUTPUT_BYTES = 536 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

extern "C" int64_t randomized_marking_page_caching(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == nullptr || length < 3 || length > MAX_INPUT) return -1;
    const int64_t cache_raw = input[0], requests_raw = input[1];
    if (cache_raw < 1 || cache_raw > 8 || requests_raw < 0 || requests_raw > MAX_REQUESTS) return -1;
    const size_t cache_size = (size_t)cache_raw, requests = (size_t)requests_raw;
    if (length < 3 + requests) return -1;
    const int64_t choices_raw = input[2 + requests];
    if (choices_raw < 0 || choices_raw > requests_raw || length != 3 + requests + (size_t)choices_raw) return -1;
    const size_t choice_count = (size_t)choices_raw;
    int pages[MAX_REQUESTS], choices[MAX_REQUESTS];
    for (size_t i = 0; i < requests; ++i) {
        const int64_t page = input[2 + i];
        if (page < 0 || page >= MAX_PAGES) return -1;
        pages[i] = (int)page;
    }
    for (size_t i = 0; i < choice_count; ++i) {
        const int64_t choice = input[3 + requests + i];
        if (choice < 0 || choice > MAX_PAGES) return -1;
        choices[i] = (int)choice;
    }
    uint8_t resident[MAX_PAGES] = {0}, marked[MAX_PAGES] = {0};
    int64_t hits[MAX_REQUESTS] = {0}, victims[MAX_REQUESTS];
    size_t resident_count = 0, choice_at = 0;
    int64_t misses = 0;
    for (size_t request = 0; request < requests; ++request) {
        const int page = pages[request];
        if (resident[page]) { hits[request] = 1; marked[page] = 1; victims[request] = -1; continue; }
        ++misses; hits[request] = 0; victims[request] = -1;
        if (resident_count == cache_size) {
            int eligible[MAX_PAGES]; size_t eligible_count = 0;
            for (int candidate = 0; candidate < MAX_PAGES; ++candidate)
                if (resident[candidate] && !marked[candidate]) eligible[eligible_count++] = candidate;
            if (eligible_count == 0) {
                for (int candidate = 0; candidate < MAX_PAGES; ++candidate)
                    if (resident[candidate]) { marked[candidate] = 0; eligible[eligible_count++] = candidate; }
            }
            if (choice_at >= choice_count || (size_t)choices[choice_at] >= eligible_count) return -1;
            const int victim = eligible[choices[choice_at++]];
            resident[victim] = 0; marked[victim] = 0; --resident_count; victims[request] = victim;
        }
        resident[page] = 1; marked[page] = 1; ++resident_count;
    }
    if (choice_at != choice_count) return -1;
    int64_t resident_mask = 0, marked_mask = 0;
    for (int page = 0; page < MAX_PAGES; ++page) {
        if (resident[page]) resident_mask |= (int64_t)(1u << page);
        if (resident[page] && marked[page]) marked_mask |= (int64_t)(1u << page);
    }
    int64_t words[3 + 2 * MAX_REQUESTS] = {0};
    words[0] = misses; words[1] = resident_mask; words[2] = marked_mask;
    for (size_t i = 0; i < requests; ++i) words[3 + i] = hits[i];
    for (size_t i = 0; i < requests; ++i) words[3 + requests + i] = victims[i];
    const size_t output_bytes = 8 * (3 + 2 * requests);
    if (output == nullptr || capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    for (size_t word = 0; word < 3 + 2 * requests; ++word) store_i64_le(staged, 8 * word, words[word]);
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
