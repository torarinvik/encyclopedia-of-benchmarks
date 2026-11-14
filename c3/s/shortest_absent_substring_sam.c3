module shortest_absent_substring_sam;

long shortest_absent_substring_sam(long* input, usz length, char* output, usz capacity) @export("shortest_absent_substring_sam") {
    if (input == null || length < 2 || length > 66 || input[0] < 2 || input[0] > 4 || input[1] < 0 || input[1] > 64) return -1;
    int alphabet = (int)input[0], n = (int)input[1];
    if (length != (usz)(2+n)) return -1;
    for (int i = 0; i < n; i += 1) if (input[2+i] < 0 || input[2+i] >= alphabet) return -1;
    int[516] edges = zeroed; int[129] links = zeroed, lens = zeroed;
    for (int i = 0; i < 516; i += 1) edges[i] = -1;
    for (int i = 0; i < 129; i += 1) links[i] = -1;
    int size = 1, last = 0;
    for (int i = 0; i < n; i += 1) {
        int symbol = (int)input[2+i], current = size++, p = last; lens[current] = lens[last]+1;
        while (p >= 0 && edges[4*p+symbol] < 0) { edges[4*p+symbol] = current; p = links[p]; }
        if (p < 0) links[current] = 0;
        else {
            int q = edges[4*p+symbol];
            if (lens[p]+1 == lens[q]) links[current] = q;
            else {
                int clone = size++;
                for (int a = 0; a < 4; a += 1) edges[4*clone+a] = edges[4*q+a];
                links[clone] = links[q]; lens[clone] = lens[p]+1;
                while (p >= 0 && edges[4*p+symbol] == q) { edges[4*p+symbol] = clone; p = links[p]; }
                links[q] = clone; links[current] = clone;
            }
        }
        last = current;
    }
    int[65] counts = zeroed; int[129] order = zeroed, dp = zeroed;
    for (int s = 0; s < size; s += 1) counts[lens[s]] += 1;
    for (int i = 1; i <= n; i += 1) counts[i] += counts[i-1];
    for (int s = size-1; s >= 0; s -= 1) { counts[lens[s]] -= 1; order[counts[lens[s]]] = s; }
    for (int i = size-1; i >= 0; i -= 1) {
        int s = order[i], best = 100;
        for (int a = 0; a < alphabet; a += 1) { int child = edges[4*s+a], candidate = child < 0 ? 1 : 1+dp[child]; if (candidate < best) best = candidate; }
        dp[s] = best;
    }
    char[6] result = zeroed; int count = 0, state = 0;
    while (state >= 0) for (int a = 0; a < alphabet; a += 1) {
        int child = edges[4*state+a];
        if ((child < 0 && dp[state] == 1) || (child >= 0 && dp[state] == 1+dp[child])) { result[count++] = (char)a; state = child; break; }
    }
    if (output == null || capacity < (usz)count) return -2;
    for (int i = 0; i < count; i += 1) output[i] = result[i];
    return count;
}
