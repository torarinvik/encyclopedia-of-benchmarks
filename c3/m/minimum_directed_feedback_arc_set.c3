module minimum_directed_feedback_arc_set;

const usz MAX_VERTICES = 8;
const usz MAX_EDGES = 56;
const usz MAX_LENGTH = 114;
const usz MAX_STATES = 256;
const long INF = 2305843009213693951;

fn long minimum_directed_feedback_arc_set(long* input, usz length)
        @export("minimum_directed_feedback_arc_set") {
    if (input == null || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES ||
        input[1] < 0 || input[1] > (long)MAX_EDGES) return -1;
    usz vertices = (usz)input[0];
    usz edges = (usz)input[1];
    if (length != 2 + 2 * edges) return -1;

    usz[MAX_VERTICES] outgoing = zeroed;
    for (usz edge = 0; edge < edges; edge++) {
        long tail_value = input[2 + 2 * edge];
        long head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 || (usz)tail_value >= vertices ||
            (usz)head_value >= vertices || tail_value == head_value) return -1;
        usz tail = (usz)tail_value;
        usz head = (usz)head_value;
        usz bit = (usz)1 << head;
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] = outgoing[tail] | bit;
    }

    usz full = ((usz)1 << vertices) - 1;
    long[MAX_STATES] dp;
    for (usz mask = 0; mask < MAX_STATES; mask++) dp[mask] = INF;
    dp[0] = 0;
    for (usz prefix = 0; prefix <= full; prefix++) {
        if (dp[prefix] == INF) continue;
        for (usz vertex = 0; vertex < vertices; vertex++) {
            usz bit = (usz)1 << vertex;
            if ((prefix & bit) != 0) continue;
            long backward = 0;
            for (usz prior = 0; prior < vertices; prior++) {
                if ((prefix & ((usz)1 << prior)) != 0 &&
                    (outgoing[vertex] & ((usz)1 << prior)) != 0) backward++;
            }
            usz target = prefix | bit;
            long candidate = dp[prefix] + backward;
            if (candidate < dp[target]) dp[target] = candidate;
        }
    }
    return dp[full];
}
