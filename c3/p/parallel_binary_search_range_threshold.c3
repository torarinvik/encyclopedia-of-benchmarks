module parallel_binary_search_range_threshold;

const usz MAX_N = 16;
const usz MAX_EVENTS = 32;
const usz MAX_QUERIES = 32;
const usz MAX_PARSEABLE_LENGTH = 196;

fn void bit_add(long* bit, usz index_value, long delta, usz limit) {
    usz index = index_value;
    while (index <= limit + 1) {
        bit[index] += delta;
        index += index & (0 - index);
    }
}

fn long bit_sum(long* bit, usz index_value) {
    usz index = index_value;
    long total = 0;
    while (index > 0) {
        total += bit[index];
        index -= index & (0 - index);
    }
    return total;
}

fn void range_add(long* bit1, long* bit2, usz n, usz left, usz right, long delta) {
    usz lo = left + 1;
    usz hi = right + 1;
    bit_add(bit1, lo, delta, n);
    bit_add(bit1, hi + 1, -delta, n);
    bit_add(bit2, lo, delta * (long)(lo - 1), n);
    bit_add(bit2, hi + 1, -delta * (long)hi, n);
}

fn long prefix_sum(long* bit1, long* bit2, usz count) {
    return (long)count * bit_sum(bit1, count) - bit_sum(bit2, count);
}

fn long range_sum(long* bit1, long* bit2, usz left, usz right) {
    return prefix_sum(bit1, bit2, right + 1) - prefix_sum(bit1, bit2, left);
}

fn long parallel_binary_search_range_threshold(long* input, usz length)
        @export("parallel_binary_search_range_threshold") {
    if (input == null || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N ||
        input[1] < 0 || input[1] > (long)MAX_EVENTS ||
        input[2] < 0 || input[2] > (long)MAX_QUERIES) return -1;
    usz n = (usz)input[0];
    usz event_count = (usz)input[1];
    usz query_count = (usz)input[2];
    if (length != 3 + 3 * event_count + 3 * query_count) return -1;

    long[MAX_EVENTS] event_left, event_right, event_delta;
    long[MAX_QUERIES] query_left, query_right, query_target;
    usz cursor = 3;
    for (usz event = 0; event < event_count; ++event) {
        long left = input[cursor++];
        long right = input[cursor++];
        long delta = input[cursor++];
        if (left < 0 || left > right || right >= (long)n || delta < 0 || delta > 1000) return -1;
        event_left[event] = left;
        event_right[event] = right;
        event_delta[event] = delta;
    }
    for (usz query = 0; query < query_count; ++query) {
        long left = input[cursor++];
        long right = input[cursor++];
        long target = input[cursor++];
        if (left < 0 || left > right || right >= (long)n || target < 1 || target > 512000) return -1;
        query_left[query] = left;
        query_right[query] = right;
        query_target[query] = target;
    }

    long[MAX_QUERIES] low, high, next_query;
    for (usz query = 0; query < query_count; ++query) {
        low[query] = 0;
        high[query] = (long)event_count + 1;
    }
    for (;;) {
        long[MAX_EVENTS + 1] heads;
        for (usz time = 0; time <= MAX_EVENTS; ++time) heads[time] = -1;
        for (usz query = 0; query < query_count; ++query) next_query[query] = -1;
        bool active = false;
        for (usz query = 0; query < query_count; ++query) {
            if (high[query] - low[query] > 1) {
                active = true;
                usz middle = (usz)((low[query] + high[query]) / 2);
                next_query[query] = heads[middle];
                heads[middle] = (long)query;
            }
        }
        if (!active) break;

        long[MAX_N + 2] bit1 = {0};
        long[MAX_N + 2] bit2 = {0};
        usz applied = 0;
        for (usz middle = 0; middle <= event_count; ++middle) {
            while (applied < middle) {
                range_add(&bit1[0], &bit2[0], n, (usz)event_left[applied],
                          (usz)event_right[applied], event_delta[applied]);
                ++applied;
            }
            long query = heads[middle];
            while (query >= 0) {
                usz id = (usz)query;
                if (range_sum(&bit1[0], &bit2[0], (usz)query_left[id],
                              (usz)query_right[id]) >= query_target[id])
                    high[id] = (long)middle;
                else
                    low[id] = (long)middle;
                query = next_query[id];
            }
        }
    }

    long result = 0;
    for (usz query = 0; query < query_count; ++query)
        result += (long)(query + 1) * (high[query] + 1);
    return result;
}
