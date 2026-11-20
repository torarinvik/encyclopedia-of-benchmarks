// Independently authored draft; not compiled or run.
module suffix_automaton_kth_distinct_substring;
fn long suffix_automaton_kth_distinct_substring(long* input, usz length, char* output, usz capacity)
    @export("suffix_automaton_kth_distinct_substring") {
    if (input == null || length < 3 || length > 259) return -1;
    long raw_n = input[0], k = input[1];
    if (raw_n < 1 || raw_n > 256 || length != (usz)raw_n+2 || k < 1) return -1;
    usz n = (usz)raw_n;
    for (usz i = 0; i < n; i++) if (input[i+2] < 0 || input[i+2] > 255) return -1;
    int[131072] next = zeroed;
    int[512] links = zeroed, lengths = zeroed;
    long[512] paths = zeroed;
    for (usz i = 0; i < 131072; i++) next[i] = -1;
    for (usz i = 0; i < 512; i++) links[i] = -1;
    int count = 1, last = 0;
    for (usz i = 0; i < n; i++) {
        int symbol = (int)input[i+2], current = count++;
        lengths[current] = lengths[last]+1;
        int p = last;
        while (p >= 0 && next[p*256+symbol] < 0) {
            next[p*256+symbol] = current; p = links[p];
        }
        if (p < 0) links[current] = 0;
        else {
            int q = next[p*256+symbol];
            if (lengths[p]+1 == lengths[q]) links[current] = q;
            else {
                int clone = count++;
                for (int c = 0; c < 256; c++) next[clone*256+c] = next[q*256+c];
                links[clone] = links[q]; lengths[clone] = lengths[p]+1;
                while (p >= 0 && next[p*256+symbol] == q) {
                    next[p*256+symbol] = clone; p = links[p];
                }
                links[q] = clone; links[current] = clone;
            }
        }
        last = current;
    }
    int[257] buckets = zeroed;
    int[512] order = zeroed;
    for (int i = 0; i < count; i++) buckets[lengths[i]]++;
    for (usz i = 1; i <= n; i++) buckets[i] += buckets[i-1];
    for (int i = count-1; i >= 0; i--) {
        int l = lengths[i]; buckets[l]--; order[buckets[l]] = i;
    }
    for (int i = count-1; i >= 0; i--) {
        int state = order[i];
        for (int c = 0; c < 256; c++) {
            int target = next[state*256+c];
            if (target >= 0) paths[state] += 1 + paths[target];
        }
    }
    if (k > paths[0]) return -1;
    char[256] result = zeroed;
    usz used = 0;
    int state = 0;
    while (true) {
        bool found = false;
        for (int c = 0; c < 256; c++) {
            int target = next[state*256+c];
            if (target < 0) continue;
            long group = 1 + paths[target];
            if (k > group) { k -= group; continue; }
            result[used++] = (char)c; state = target; found = true; break;
        }
        if (!found) return -1;
        if (k == 1) break;
        k--;
    }
    if (output == null || capacity < used) return -2;
    for (usz i = 0; i < used; i++) output[i] = result[i];
    return (long)used;
}
