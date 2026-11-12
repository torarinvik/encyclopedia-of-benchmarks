#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64u
#define MAX_OPERATIONS 64u
#define MAX_PARSEABLE_INPUT 387u
#define BLOCK_WIDTH 8u
#define MAX_BLOCKS 8u
#define CHECKSUM_OFFSET INT64_C(8000000)

static size_t block_end(size_t block, size_t n)
{
    const size_t end = (block + 1u) * BLOCK_WIDTH;
    return end < n ? end : n;
}

static void rebuild_hull(const int64_t *data, int64_t *hull_x, int64_t *hull_y,
                         size_t *hull_count, size_t block, size_t n)
{
    const size_t base = block * BLOCK_WIDTH;
    size_t count = 0u;
    for (size_t x = base; x < block_end(block, n); ++x) {
        while (count >= 2u) {
            const size_t p = base + count - 2u;
            const size_t q = base + count - 1u;
            const int64_t cross = (hull_x[q] - hull_x[p]) * (data[x] - hull_y[p])
                - (hull_y[q] - hull_y[p]) * ((int64_t)x - hull_x[p]);
            if (cross > 0) break;
            --count;
        }
        hull_x[base + count] = (int64_t)x;
        hull_y[base + count] = data[x];
        ++count;
    }
    hull_count[block] = count;
}

static void push_block(int64_t *data, int64_t *lazy_slope, int64_t *lazy_intercept,
                       size_t block, size_t n)
{
    const size_t start = block * BLOCK_WIDTH;
    for (size_t i = start; i < block_end(block, n); ++i)
        data[i] += lazy_slope[block] * (int64_t)i + lazy_intercept[block];
    lazy_slope[block] = 0;
    lazy_intercept[block] = 0;
}

static int64_t full_block_min(const int64_t *hull_x, const int64_t *hull_y,
                              const size_t *hull_count, const int64_t *lazy_slope,
                              const int64_t *lazy_intercept, size_t block)
{
    const size_t base = block * BLOCK_WIDTH;
    size_t low = 0u;
    size_t high = hull_count[block] - 1u;
    while (low < high) {
        const size_t middle = low + (high - low) / 2u;
        const int64_t left = hull_y[base + middle] + lazy_slope[block] * hull_x[base + middle];
        const int64_t right = hull_y[base + middle + 1u]
            + lazy_slope[block] * hull_x[base + middle + 1u];
        if (left <= right) high = middle;
        else low = middle + 1u;
    }
    return hull_y[base + low] + lazy_slope[block] * hull_x[base + low]
        + lazy_intercept[block];
}

int64_t range_linear_add_range_min_benchmark(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3u || length > MAX_PARSEABLE_INPUT) return -1;
    if (input[0] < 1 || input[0] > (int64_t)MAX_LENGTH ||
        input[1] < 1 || input[1] > (int64_t)MAX_OPERATIONS) return -1;
    const size_t n = (size_t)input[0];
    const size_t operation_count = (size_t)input[1];
    if (length < n + 2u) return -1;

    int64_t data[MAX_LENGTH] = {0};
    for (size_t i = 0u; i < n; ++i) {
        const int64_t value = input[i + 2u];
        if (value < -INT64_C(1000000) || value > INT64_C(1000000)) return -1;
        data[i] = value;
    }

    int64_t hull_x[MAX_LENGTH] = {0};
    int64_t hull_y[MAX_LENGTH] = {0};
    size_t hull_count[MAX_BLOCKS] = {0};
    int64_t lazy_slope[MAX_BLOCKS] = {0};
    int64_t lazy_intercept[MAX_BLOCKS] = {0};
    const size_t block_count = (n + BLOCK_WIDTH - 1u) / BLOCK_WIDTH;
    for (size_t block = 0u; block < block_count; ++block)
        rebuild_hull(data, hull_x, hull_y, hull_count, block, n);

    size_t cursor = n + 2u;
    int64_t checksum = 0;
    for (size_t operation = 0u; operation < operation_count; ++operation) {
        if (cursor >= length) return -1;
        const int64_t opcode = input[cursor++];
        if (opcode == 0) {
            if (cursor + 4u > length) return -1;
            const int64_t left_value = input[cursor++];
            const int64_t right_value = input[cursor++];
            const int64_t slope = input[cursor++];
            const int64_t intercept = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (int64_t)n ||
                slope < -99 || slope > 99 || intercept < -100000 || intercept > 100000)
                return -1;
            size_t position = (size_t)left_value;
            const size_t right = (size_t)right_value;
            while (position < right) {
                const size_t block = position / BLOCK_WIDTH;
                const size_t start = block * BLOCK_WIDTH;
                const size_t end = block_end(block, n);
                if (position == start && end <= right) {
                    lazy_slope[block] += slope;
                    lazy_intercept[block] += intercept;
                    position = end;
                } else {
                    push_block(data, lazy_slope, lazy_intercept, block, n);
                    const size_t stop = end < right ? end : right;
                    for (size_t i = position; i < stop; ++i)
                        data[i] += slope * (int64_t)i + intercept;
                    rebuild_hull(data, hull_x, hull_y, hull_count, block, n);
                    position = stop;
                }
            }
        } else if (opcode == 1) {
            if (cursor + 2u > length) return -1;
            const int64_t left_value = input[cursor++];
            const int64_t right_value = input[cursor++];
            if (left_value < 0 || left_value >= right_value || right_value > (int64_t)n)
                return -1;
            size_t position = (size_t)left_value;
            const size_t right = (size_t)right_value;
            int64_t minimum = INT64_MAX;
            while (position < right) {
                const size_t block = position / BLOCK_WIDTH;
                const size_t start = block * BLOCK_WIDTH;
                const size_t end = block_end(block, n);
                if (position == start && end <= right) {
                    const int64_t candidate = full_block_min(hull_x, hull_y, hull_count,
                        lazy_slope, lazy_intercept, block);
                    if (candidate < minimum) minimum = candidate;
                    position = end;
                } else {
                    const size_t stop = end < right ? end : right;
                    for (size_t i = position; i < stop; ++i) {
                        const int64_t candidate = data[i] + lazy_slope[block] * (int64_t)i
                            + lazy_intercept[block];
                        if (candidate < minimum) minimum = candidate;
                    }
                    position = stop;
                }
            }
            checksum += (int64_t)(operation + 1u) * (minimum + CHECKSUM_OFFSET);
        } else {
            return -1;
        }
    }
    return cursor == length ? checksum : -1;
}
