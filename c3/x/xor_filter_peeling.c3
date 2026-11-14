module xor_filter_peeling;

fn long xor_filter_peeling(long* input, usz length) @export("xor_filter_peeling") {
    if (input == null || length < 3 || length > 259 || input[0] < 0 || input[0] > 32 || input[1] < 3 || input[1] > 96 || input[2] < 0 || input[2] > 32) return -1;
    int n = (int)input[0], slots = (int)input[1], q = (int)input[2];
    if (length != (usz)(3+4*(n+q))) return -1;
    for (int i = 0; i < n+q; i++) {
        int at = 3+4*i;
        long a = input[at], b = input[at+1], c = input[at+2], f = input[at+3];
        if (a < 0 || a >= slots || b < 0 || b >= slots || c < 0 || c >= slots || a == b || a == c || b == c || f < 0 || f > 255) return -1;
    }
    int[96] degree = {}, edge_xor = {}, queue = {}, table = {};
    int[32] stack_slot = {}, stack_edge = {};
    for (int edge = 0; edge < n; edge++) for (int j = 0; j < 3; j++) {
        int slot = (int)input[3+4*edge+j];
        degree[slot]++;
        edge_xor[slot] ^= edge;
    }
    int head = 0, tail = 0, used = 0;
    for (int slot = 0; slot < slots; slot++) if (degree[slot] == 1) queue[tail++] = slot;
    while (head < tail) {
        int slot = queue[head++];
        if (degree[slot] != 1) continue;
        int edge = edge_xor[slot];
        stack_slot[used] = slot;
        stack_edge[used++] = edge;
        for (int j = 0; j < 3; j++) {
            int v = (int)input[3+4*edge+j];
            degree[v]--;
            edge_xor[v] ^= edge;
            if (degree[v] == 1) queue[tail++] = v;
        }
    }
    if (used != n) return -2;
    while (used > 0) {
        used--;
        int at = 3+4*stack_edge[used];
        int a = (int)input[at], b = (int)input[at+1], c = (int)input[at+2];
        table[stack_slot[used]] = (int)input[at+3] ^ table[a] ^ table[b] ^ table[c];
    }
    long result = 0;
    for (int i = 0; i < q; i++) {
        int at = 3+4*(n+i);
        int a = (int)input[at], b = (int)input[at+1], c = (int)input[at+2];
        if ((table[a] ^ table[b] ^ table[c]) == input[at+3]) result += i+1;
    }
    return result;
}
