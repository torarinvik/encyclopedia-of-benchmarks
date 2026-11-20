module fast_minimal_triangulation;

const int N = 8, M = 28, MAX_INPUT = 59;

fn void put_word(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at+b] = (char)((bits >> (8*b)) & 255);
}

fn ulong fmt(ushort vertices, ushort[8] graph) {
    bool complete = true;
    for (int u=0; u<N; u++) if (((vertices >> u) & 1) != 0) {
        ushort others = vertices & ~(ushort(1) << u);
        if ((graph[u] & others) != others) complete = false;
    }
    if (complete) return 0;
    int pivot = 0;
    while (pivot < N) {
        if (((vertices >> pivot) & 1) != 0) {
            ushort others = vertices & ~(ushort(1) << pivot);
            if ((graph[pivot] & others) != others) break;
        }
        pivot++;
    }
    ushort a = (ushort(1) << pivot) | (graph[pivot] & vertices);
    ushort unseen = vertices & ~a;
    ushort[N] components = zeroed, closures = zeroed;
    int count = 0;
    while (unseen != 0) {
        int seed = 0; while (((unseen >> seed) & 1) == 0) seed++;
        ushort comp = ushort(1) << seed;
        unseen &= ~comp;
        ushort frontier = comp;
        while (frontier != 0) {
            int u = 0; while (((frontier >> u) & 1) == 0) u++;
            frontier &= ~(ushort(1) << u);
            ushort added = graph[u] & unseen;
            comp |= added; frontier |= added; unseen &= ~added;
        }
        components[count++] = comp;
    }
    ushort[N] saturated = graph;
    ulong result = 0;
    for (int ci=0; ci<count; ci++) {
        ushort comp = components[ci], boundary = 0;
        for (int u=0; u<N; u++) if (((comp >> u) & 1) != 0) boundary |= graph[u] & vertices & ~comp;
        closures[ci] = comp | boundary;
        for (int u=0; u<N; u++) if (((boundary >> u) & 1) != 0)
            for (int v=u+1; v<N; v++) if (((boundary >> v) & 1) != 0 && ((saturated[u] >> v) & 1) == 0) {
                saturated[u] |= ushort(1) << v; saturated[v] |= ushort(1) << u;
                result |= 1ul << (u*N+v);
            }
    }
    result |= fmt(a, saturated);
    for (int ci=0; ci<count; ci++) result |= fmt(closures[ci], saturated);
    return result;
}

fn long fast_minimal_triangulation(long* input, usz length, char* output, usz capacity)
    @export("fast_minimal_triangulation") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > N || m64 < 0 || m64 > M || length != 2 + 2*m64.usz()) return -1;
    int n = n64.int(), m = m64.int();
    ushort[N] graph = zeroed;
    ulong original = 0;
    long previous_u = -1, previous_v = -1;
    for (int i=0; i<m; i++) {
        long u64 = input[2+2*i], v64 = input[3+2*i];
        if (u64 < 0 || v64 <= u64 || v64 >= n64 || u64 < previous_u || (u64 == previous_u && v64 <= previous_v)) return -1;
        previous_u = u64; previous_v = v64;
        int u=u64.int(), v=v64.int();
        graph[u] |= ushort(1) << v; graph[v] |= ushort(1) << u;
        original |= 1ul << (u*N+v);
    }
    ulong fill = fmt((ushort(1) << n)-1, graph) & ~original;
    int count = 0;
    for (int u=0; u<n; u++) for (int v=u+1; v<n; v++) if (((fill >> (u*N+v)) & 1) != 0) count++;
    usz bytes = 8 * (1 + 2*count).usz();
    if (output == null || capacity < bytes) return -2;
    put_word(output, 0, count);
    usz index = 1;
    for (int u=0; u<n; u++) for (int v=u+1; v<n; v++) if (((fill >> (u*N+v)) & 1) != 0) {
        put_word(output, 8*index, u); index++;
        put_word(output, 8*index, v); index++;
    }
    return bytes.long();
}
