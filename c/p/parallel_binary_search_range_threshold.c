#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_EVENTS = 32, MAX_QUERIES = 32, MAX_PARSEABLE_LENGTH = 196 };

static void bit_add(int64_t *bit, size_t index, int64_t delta, size_t limit) {
    while (index <= limit + 1) {
        bit[index] += delta;
        index += index & (0 - index);
    }
}

static int64_t bit_sum(const int64_t *bit, size_t index) {
    int64_t total = 0;
    while (index > 0) {
        total += bit[index];
        index -= index & (0 - index);
    }
    return total;
}

static void range_add(int64_t *bit1, int64_t *bit2, size_t n,
                      size_t left, size_t right, int64_t delta) {
    const size_t lo = left + 1;
    const size_t hi = right + 1;
    bit_add(bit1, lo, delta, n);
    bit_add(bit1, hi + 1, -delta, n);
    bit_add(bit2, lo, delta * (int64_t)(lo - 1), n);
    bit_add(bit2, hi + 1, -delta * (int64_t)hi, n);
}

static int64_t prefix_sum(const int64_t *bit1, const int64_t *bit2, size_t count) {
    return (int64_t)count * bit_sum(bit1, count) - bit_sum(bit2, count);
}

static int64_t range_sum(const int64_t *bit1, const int64_t *bit2,
                         size_t left, size_t right) {
    return prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left);
}

int64_t parallel_binary_search_range_threshold(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_N ||
        input[1] < 0 || input[1] > MAX_EVENTS ||
        input[2] < 0 || input[2] > MAX_QUERIES) return -1;
    const size_t n = (size_t)input[0];
    const size_t event_count = (size_t)input[1];
    const size_t query_count = (size_t)input[2];
    if (length != 3 + 3 * event_count + 3 * query_count) return -1;

    int64_t event_left[MAX_EVENTS], event_right[MAX_EVENTS], event_delta[MAX_EVENTS];
    int64_t query_left[MAX_QUERIES], query_right[MAX_QUERIES], query_target[MAX_QUERIES];
    size_t cursor = 3;
    for (size_t event = 0; event < event_count; ++event) {
        const int64_t left = input[cursor++];
        const int64_t right = input[cursor++];
        const int64_t delta = input[cursor++];
        if (left < 0 || left > right || right >= (int64_t)n || delta < 0 || delta > 1000) return -1;
        event_left[event] = left;
        event_right[event] = right;
        event_delta[event] = delta;
    }
    for (size_t query = 0; query < query_count; ++query) {
        const int64_t left = input[cursor++];
        const int64_t right = input[cursor++];
        const int64_t target = input[cursor++];
        if (left < 0 || left > right || right >= (int64_t)n ||
            target < 1 || target > 512000) return -1;
        query_left[query] = left;
        query_right[query] = right;
        query_target[query] = target;
    }

    int64_t low[MAX_QUERIES] = {0};
    int64_t high[MAX_QUERIES];
    int64_t next_query[MAX_QUERIES];
    for (size_t query = 0; query < query_count; ++query) high[query] = (int64_t)event_count + 1;

    for (;;) {
        int64_t heads[MAX_EVENTS + 1];
        for (size_t time = 0; time <= MAX_EVENTS; ++time) heads[time] = -1;
        for (size_t query = 0; query < query_count; ++query) next_query[query] = -1;
        int active = 0;
        for (size_t query = 0; query < query_count; ++query) {
            if (high[query] - low[query] > 1) {
                active = 1;
                const size_t middle = (size_t)((low[query] + high[query]) / 2);
                next_query[query] = heads[middle];
                heads[middle] = (int64_t)query;
            }
        }
        if (!active) break;

        int64_t bit1[MAX_N + 2] = {0};
        int64_t bit2[MAX_N + 2] = {0};
        size_t applied = 0;
        for (size_t middle = 0; middle <= event_count; ++middle) {
            while (applied < middle) {
                range_add(bit1, bit2, n, (size_t)event_left[applied],
                          (size_t)event_right[applied], event_delta[applied]);
                ++applied;
            }
            int64_t query = heads[middle];
            while (query >= 0) {
                const size_t id = (size_t)query;
                if (range_sum(bit1, bit2, (size_t)query_left[id],
                              (size_t)query_right[id]) >= query_target[id]) {
                    high[id] = (int64_t)middle;
                } else {
                    low[id] = (int64_t)middle;
                }
                query = next_query[id];
            }
        }
    }

    int64_t result = 0;
    for (size_t query = 0; query < query_count; ++query)
        result += (int64_t)(query + 1) * (high[query] + 1);
    return result;
}
