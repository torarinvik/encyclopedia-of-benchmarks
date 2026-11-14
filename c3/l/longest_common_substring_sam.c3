module longest_common_substring_sam;

long longest_common_substring_sam(long* input, usz length) @export("longest_common_substring_sam") {
    if (input == null || length < 2 || length > 515 || input[0] < 0 || input[0] > 256) return -1;
    int n = (int)input[0];
    if (length < (usz)(n+2) || input[n+1] < 0 || input[n+1] > 256) return -1;
    int m = (int)input[n+1];
    if (length != (usz)(n+m+2)) return -1;
    for (int i = 0; i < n; i += 1) if (input[1+i] < 32 || input[1+i] > 126) return -1;
    for (int i = 0; i < m; i += 1) if (input[n+2+i] < 32 || input[n+2+i] > 126) return -1;
    int[48735] edges = zeroed; int[513] links = zeroed, lens = zeroed;
    for (int i = 0; i < 48735; i += 1) edges[i] = -1;
    for (int i = 0; i < 513; i += 1) links[i] = -1;
    int size = 1, last = 0;
    for (int i = 0; i < n; i += 1) {
        int symbol = (int)input[1+i]-32, current = size++, p = last; lens[current] = lens[last]+1;
        while (p >= 0 && edges[95*p+symbol] < 0) { edges[95*p+symbol] = current; p = links[p]; }
        if (p < 0) links[current] = 0;
        else {
            int q = edges[95*p+symbol];
            if (lens[p]+1 == lens[q]) links[current] = q;
            else {
                int clone = size++;
                for (int a = 0; a < 95; a += 1) edges[95*clone+a] = edges[95*q+a];
                links[clone] = links[q]; lens[clone] = lens[p]+1;
                while (p >= 0 && edges[95*p+symbol] == q) { edges[95*p+symbol] = clone; p = links[p]; }
                links[q] = clone; links[current] = clone;
            }
        }
        last = current;
    }
    int state = 0, matched = 0, best = 0;
    for (int i = 0; i < m; i += 1) {
        int symbol = (int)input[n+2+i]-32;
        while (state != 0 && edges[95*state+symbol] < 0) { state = links[state]; matched = lens[state]; }
        int next = edges[95*state+symbol];
        if (next < 0) { state = 0; matched = 0; }
        else { state = next; matched += 1; if (matched > best) best = matched; }
    }
    return best;
}
