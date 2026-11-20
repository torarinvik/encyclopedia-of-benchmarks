module observed_remove_set;

const long MAX_Q = 32L;
const long MAX_TAGS = 64L;
const long MAX_INPUT = 129L;

fn long observed_remove_set(long* input, usz length) @export("observed_remove_set") {
    if (input == null || length < 1 || length > MAX_INPUT) return -1;
    long qv = input[0];
    if (qv < 0 || qv > MAX_Q || length != 1 + (usz)qv * 4) return -1;
    usz q = (usz)qv;
    for (usz i = 0; i < q; i++) {
        long op = input[1 + i * 4], replica = input[2 + i * 4];
        long element = input[3 + i * 4], peer = input[4 + i * 4];
        if (op >= 0 && op <= 2) {
            if (replica < 0 || replica > 1 || element < 0 || element > 15 || peer != 0) return -1;
        } else if (op == 3 || op == 4) {
            if (replica < 0 || replica > 1 || element != 0 || peer < 0 || peer > 1) return -1;
        } else return -1;
    }

    bool[MAX_TAGS] used = zeroed;
    long[MAX_TAGS] tag_element = zeroed;
    usz[2] next_sequence = zeroed;
    bool[2 * MAX_TAGS] additions = zeroed;
    bool[2 * MAX_TAGS] removals = zeroed;
    long answer = 0;
    usz read_count = 0;
    for (usz i = 0; i < q; i++) {
        long op = input[1 + i * 4], replica_value = input[2 + i * 4];
        long element = input[3 + i * 4], peer_value = input[4 + i * 4];
        usz replica = (usz)replica_value, peer = (usz)peer_value;
        usz base = replica * MAX_TAGS;
        usz peer_base = peer * MAX_TAGS;
        bool result = false;
        if (op == 0) {
            usz tag = replica * MAX_Q + next_sequence[replica]++;
            used[tag] = true;
            tag_element[tag] = element;
            additions[base + tag] = true;
        } else if (op == 1) {
            for (usz tag = 0; tag < MAX_TAGS; tag++) {
                if (additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element)
                    removals[base + tag] = true;
            }
        } else if (op == 2) {
            for (usz tag = 0; tag < MAX_TAGS; tag++)
                if (additions[base + tag] && !removals[base + tag] && used[tag] && tag_element[tag] == element)
                    result = true;
        } else if (op == 3) {
            for (usz tag = 0; tag < MAX_TAGS; tag++) {
                additions[base + tag] = additions[base + tag] || additions[peer_base + tag];
                removals[base + tag] = removals[base + tag] || removals[peer_base + tag];
            }
        } else {
            result = true;
            for (usz tag = 0; tag < MAX_TAGS; tag++)
                if ((additions[base + tag] && !additions[peer_base + tag]) ||
                    (removals[base + tag] && !removals[peer_base + tag])) result = false;
        }
        if (op == 2 || op == 4) {
            if (result) answer |= 1L << read_count;
            read_count++;
        }
    }
    return answer;
}
