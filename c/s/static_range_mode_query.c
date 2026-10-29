/* Static range mode queries using whole-block modes and occurrence lists. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_Q = 16, MAX_BLOCKS = 6, MAX_INPUT_LENGTH = 66 };

static size_t lower_bound_i64(const int64_t *values, size_t begin, size_t end, int64_t target) {
    while (begin < end) {
        size_t middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

static size_t lower_bound_size(const size_t *values, size_t begin, size_t end, size_t target) {
    while (begin < end) {
        size_t middle = begin + (end - begin) / 2;
        if (values[middle] < target) begin = middle + 1;
        else end = middle;
    }
    return begin;
}

static size_t range_frequency(const size_t *occurrences, const size_t *offsets,
                              size_t id, size_t left, size_t right) {
    size_t begin = offsets[id], end = offsets[id + 1];
    return lower_bound_size(occurrences, begin, end, right) -
           lower_bound_size(occurrences, begin, end, left);
}

static void write_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t static_range_mode_query(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 1 || q_value > MAX_Q) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value;
    if (length != 2 + n + 2 * q) return -1;
    for (size_t index = 0; index < n; ++index)
        if (input[2 + index] < 0 || input[2 + index] > 1000000000) return -1;
    for (size_t query = 0; query < q; ++query) {
        int64_t left = input[2 + n + 2 * query], right = input[3 + n + 2 * query];
        if (left < 0 || right <= left || right > n_value) return -1;
    }
    if (output == NULL || output_capacity < 16 * q) return -2;

    int64_t sorted[MAX_N], unique_values[MAX_N];
    size_t compressed[MAX_N], frequencies[MAX_N] = {0};
    size_t offsets[MAX_N + 1] = {0}, cursor[MAX_N] = {0}, occurrences[MAX_N];
    size_t block_mode[MAX_BLOCKS * MAX_BLOCKS];
    for (size_t index = 0; index < n; ++index) {
        int64_t value = input[2 + index];
        size_t position = index;
        while (position > 0 && sorted[position - 1] > value) {
            sorted[position] = sorted[position - 1];
            --position;
        }
        sorted[position] = value;
    }
    size_t distinct = 0;
    for (size_t index = 0; index < n; ++index)
        if (distinct == 0 || sorted[index] != unique_values[distinct - 1])
            unique_values[distinct++] = sorted[index];

    for (size_t index = 0; index < n; ++index) {
        size_t id = lower_bound_i64(unique_values, 0, distinct, input[2 + index]);
        compressed[index] = id;
        ++frequencies[id];
    }
    for (size_t id = 0; id < distinct; ++id) offsets[id + 1] = offsets[id] + frequencies[id];
    for (size_t id = 0; id < distinct; ++id) cursor[id] = offsets[id];
    for (size_t index = 0; index < n; ++index)
        occurrences[cursor[compressed[index]]++] = index;

    size_t block_size = 1;
    while (block_size * block_size < n) ++block_size;
    size_t block_count = (n + block_size - 1) / block_size;
    size_t frequency[MAX_N] = {0};
    for (size_t first = 0; first < block_count; ++first) {
        for (size_t id = 0; id < distinct; ++id) frequency[id] = 0;
        size_t best_id = 0, best_count = 0;
        for (size_t last = first; last < block_count; ++last) {
            size_t begin = last * block_size, end = begin + block_size;
            if (end > n) end = n;
            for (size_t index = begin; index < end; ++index) {
                size_t id = compressed[index];
                size_t count = ++frequency[id];
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            block_mode[first * MAX_BLOCKS + last] = best_id;
        }
    }

    for (size_t query = 0; query < q; ++query) {
        size_t left = (size_t)input[2 + n + 2 * query];
        size_t right = (size_t)input[3 + n + 2 * query];
        size_t first_full = (left + block_size - 1) / block_size;
        size_t after_full = right / block_size;
        size_t best_id = 0, best_count = 0;
        if (first_full < after_full) {
            best_id = block_mode[first_full * MAX_BLOCKS + after_full - 1];
            best_count = range_frequency(occurrences, offsets, best_id, left, right);
            size_t span_start = first_full * block_size;
            size_t span_end = after_full * block_size;
            for (size_t index = left; index < span_start; ++index) {
                size_t id = compressed[index], count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
            for (size_t index = span_end; index < right; ++index) {
                size_t id = compressed[index], count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        } else {
            for (size_t index = left; index < right; ++index) {
                size_t id = compressed[index], count = range_frequency(occurrences, offsets, id, left, right);
                if (count > best_count || (count == best_count && id < best_id)) {
                    best_id = id;
                    best_count = count;
                }
            }
        }
        write_i64(output, 16 * query, unique_values[best_id]);
        write_i64(output, 16 * query + 8, (int64_t)best_count);
    }
    return (int64_t)(16 * q);
}
