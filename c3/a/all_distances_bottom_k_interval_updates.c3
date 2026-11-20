module all_distances_bottom_k_interval_updates;

const long MAX_N = 32;
const long MAX_K = 4;
const usz MAX_INPUT = 99;
const usz MAX_WORDS = 97;
const long DISTANCE_LIMIT = 1000000;
const long END_SENTINEL = 1000001;

struct Interval { long id, rank, first, past; }

fn void put_i64(uint8 *output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[8 * word + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long all_distances_bottom_k_interval_updates(long *input, usz length,
        uint8 *output, usz capacity) @export("all_distances_bottom_k_interval_updates") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], k0 = input[1];
    if (n0 < 2 || n0 > MAX_N || k0 < 2 || k0 > MAX_K || k0 > n0) return -1;
    usz n = (usz)n0, k = (usz)k0;
    if (length != 2 + 3 * n) return -1;

    long[MAX_N] ids = {}, distances = {}, ranks = {};
    bool[MAX_N] seen_id = {}, seen_rank = {};
    for (usz i = 0; i < n; i++) {
        ids[i] = input[2 + 3*i];
        distances[i] = input[3 + 3*i];
        ranks[i] = input[4 + 3*i];
        if (ids[i] < 0 || ids[i] >= n0 || seen_id[(usz)ids[i]]
                || ranks[i] < 0 || ranks[i] >= n0 || seen_rank[(usz)ranks[i]]
                || distances[i] < 0 || distances[i] > DISTANCE_LIMIT) return -1;
        seen_id[(usz)ids[i]] = true;
        seen_rank[(usz)ranks[i]] = true;
        for (usz j = 0; j < i; j++) if (distances[j] == distances[i]) return -1;
    }
    for (usz i = 1; i < k; i++) if (distances[i-1] >= distances[i]) return -1;
    for (usz i = k; i < n; i++) if (distances[i] <= distances[k-1]) return -1;

    Interval[MAX_N] intervals = {};
    usz count = k;
    for (usz i = 0; i < k; i++)
        intervals[i] = {ids[i], ranks[i], distances[i], END_SENTINEL};
    for (usz i = k; i < n; i++) {
        usz worst = MAX_N, active = 0;
        for (usz j = 0; j < count; j++) {
            if (intervals[j].first <= distances[i] && distances[i] < intervals[j].past) {
                active++;
                if (worst == MAX_N || intervals[j].rank > intervals[worst].rank) worst = j;
            }
        }
        if (active != k || worst == MAX_N) return -1;
        if (ranks[i] >= intervals[worst].rank) continue;
        long cursor = intervals[worst].past;
        intervals[worst].past = distances[i];
        while (cursor < END_SENTINEL) {
            usz next_worst = MAX_N;
            for (usz j = 0; j < count; j++) {
                if (intervals[j].first <= cursor && cursor < intervals[j].past
                        && (next_worst == MAX_N || intervals[j].rank > intervals[next_worst].rank))
                    next_worst = j;
            }
            if (next_worst == MAX_N || intervals[next_worst].rank <= ranks[i]) break;
            long next = intervals[next_worst].past;
            intervals[next_worst].past = cursor;
            cursor = next;
        }
        intervals[count++] = {ids[i], ranks[i], distances[i], cursor};
    }

    usz[MAX_N] order = {};
    usz out_count = 0;
    for (usz i = 0; i < count; i++) if (intervals[i].first < intervals[i].past) order[out_count++] = i;
    for (usz i = 1; i < out_count; i++) {
        usz key = order[i], j = i;
        while (j > 0 && (intervals[order[j-1]].first > intervals[key].first
                || (intervals[order[j-1]].first == intervals[key].first
                    && intervals[order[j-1]].id > intervals[key].id))) {
            order[j] = order[j-1]; j--;
        }
        order[j] = key;
    }
    long[MAX_WORDS] staged = {};
    staged[0] = (long)out_count;
    for (usz i = 0; i < out_count; i++) {
        Interval x = intervals[order[i]];
        staged[1 + 3*i] = x.id; staged[2 + 3*i] = x.first; staged[3 + 3*i] = x.past;
    }
    usz bytes = 8 * (1 + 3 * out_count);
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < 1 + 3 * out_count; word++) put_i64(output, word, staged[word]);
    return (long)bytes;
}
