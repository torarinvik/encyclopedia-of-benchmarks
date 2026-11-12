module games_on_arbitrary_graphs;

const usz MAX_V = 16;
const usz MAX_E = 32;
const usz MAX_INPUT = 66;
const usz MAX_OUTPUT = 17;

fn long games_on_arbitrary_graphs(long* input, usz length, char* output, usz capacity) @export("games_on_arbitrary_graphs") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = input[0], me = input[1];
    if (nv < 0 || nv > 16 || me < 0 || me > 32) return -1;
    usz n = (usz)nv, m = (usz)me;
    if (length != 2 + 2 * m) return -1;

    u16[MAX_V] outmask = zeroed;
    int[MAX_V] head;
    int[MAX_E] edge_source;
    int[MAX_E] edge_next;
    int[MAX_V] remaining = zeroed;
    int[MAX_V] status = zeroed;
    int[MAX_V] queue;
    char[MAX_OUTPUT] staged = zeroed;
    for (usz v = 0; v < n; v++) head[v] = -1;

    usz unique_edges = 0;
    for (usz i = 0; i < m; i++) {
        long sv = input[2 + 2 * i], tv = input[3 + 2 * i];
        if (sv < 0 || sv >= nv || tv < 0 || tv >= nv) return -1;
        usz s = (usz)sv, t = (usz)tv;
        u16 bit = (u16)(1u << t);
        if ((outmask[s] & bit) == 0) {
            outmask[s] |= bit;
            edge_source[unique_edges] = (int)s;
            edge_next[unique_edges] = head[t];
            head[t] = (int)unique_edges;
            unique_edges++;
            remaining[s]++;
        }
    }

    usz first = 0, count = 0;
    for (usz v = 0; v < n; v++) {
        if (remaining[v] == 0) { status[v] = 2; queue[count] = (int)v; count++; }
    }
    while (first < count) {
        int resolved = queue[first];
        first++;
        int edge = head[resolved];
        while (edge != -1) {
            int predecessor = edge_source[(usz)edge];
            if (status[predecessor] == 0) {
                if (status[resolved] == 2) {
                    status[predecessor] = 1;
                    queue[count] = predecessor;
                    count++;
                } else {
                    remaining[predecessor]--;
                    if (remaining[predecessor] == 0) {
                        status[predecessor] = 2;
                        queue[count] = predecessor;
                        count++;
                    }
                }
            }
            edge = edge_next[(usz)edge];
        }
    }
    staged[0] = (char)n;
    for (usz v = 0; v < n; v++) staged[v + 1] = (char)status[v];
    usz needed = n + 1;
    if (output == null || capacity < needed) return -2;
    for (usz i = 0; i < needed; i++) output[i] = staged[i];
    return (long)needed;
}
