// Uncompiled and unexecuted next-occurrence automaton draft.
module subsequence_automaton;
fn long subsequence_automaton(long* input, usz length) @export("subsequence_automaton") {
    if (input == null || length < 2 || length > 354) return -1;
    if (input[0] < 0 || input[0] > 64 || input[1] < 0 || input[1] > 32) return -1;
    usz n = (usz)input[0], queries = (usz)input[1];
    if (length < 2+n) return -1;
    for (usz i = 0; i < n; i++) if (input[2+i] < 0 || input[2+i] > 3) return -1;
    usz[260] next = {};
    for (usz c = 0; c < 4; c++) next[4*n+c] = n;
    usz row = n;
    while (row > 0) {
        row--;
        for (usz c = 0; c < 4; c++) next[4*row+c] = next[4*(row+1)+c];
        next[4*row+(usz)input[2+row]] = row;
    }
    usz pos = 2+n, total = 0;
    long answer = 0;
    for (usz q = 0; q < queries; q++) {
        if (pos == length || input[pos] < 0 || input[pos] > 256) return -1;
        usz count = (usz)input[pos++];
        if (count > 256-total || count > length-pos) return -1;
        usz cursor = 0;
        bool matches = true;
        for (usz i = 0; i < count; i++) {
            long symbol = input[pos+i];
            if (symbol < 0 || symbol > 3) return -1;
            if (matches) {
                usz found = next[4*cursor+(usz)symbol];
                if (found == n) matches = false; else cursor = found+1;
            }
        }
        if (matches) answer += (long)(q+1);
        pos += count; total += count;
    }
    return pos == length ? answer : -1;
}
