module dag_transitive_reduction;

const usz MAX_N = 8;
const usz MAX_M = 28;
const usz MAX_LENGTH = 58;

fn long dag_transitive_reduction(long* input, usz length)
        @export("dag_transitive_reduction") {
    if (input == null || length < 2 || length > MAX_LENGTH + 1) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_N || input[1] < 0 || input[1] > (long)MAX_M) return -1;
    usz n = (usz)input[0];
    usz m = (usz)input[1];
    if (length != 2 + 2 * m) return -1;

    usz[MAX_N] outgoing = zeroed;
    for (usz edge = 0; edge < m; edge++) {
        long tail_value = input[2 + 2 * edge];
        long head_value = input[3 + 2 * edge];
        if (tail_value < 0 || head_value < 0 || (usz)tail_value >= n ||
            (usz)head_value >= n || tail_value == head_value) return -1;
        usz tail = (usz)tail_value;
        usz head = (usz)head_value;
        usz bit = (usz)1 << head;
        if ((outgoing[tail] & bit) != 0) return -1;
        outgoing[tail] = outgoing[tail] | bit;
    }

    usz[MAX_N] reach;
    for (usz vertex = 0; vertex < n; vertex++) reach[vertex] = outgoing[vertex];
    for (usz middle = 0; middle < n; middle++) {
        usz middle_bit = (usz)1 << middle;
        for (usz source = 0; source < n; source++) {
            if ((reach[source] & middle_bit) != 0) reach[source] = reach[source] | reach[middle];
        }
    }
    for (usz vertex = 0; vertex < n; vertex++)
        if ((reach[vertex] & ((usz)1 << vertex)) != 0) return -1;

    long retained = 0;
    for (usz edge = 0; edge < m; edge++) {
        usz tail = (usz)input[2 + 2 * edge];
        usz head = (usz)input[3 + 2 * edge];
        bool redundant = false;
        for (usz middle = 0; middle < n; middle++) {
            if (middle != tail && middle != head &&
                (outgoing[tail] & ((usz)1 << middle)) != 0 &&
                (reach[middle] & ((usz)1 << head)) != 0) {
                redundant = true;
                break;
            }
        }
        if (!redundant) retained++;
    }
    return retained;
}
