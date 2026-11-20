module zwick_deterministic_bridging_set;

const uint MAX_N = 8;
const uint INF_DIST = 9;

fn uint popcount16(uint value) {
    uint count = 0;
    while (value != 0) { count += value & 1; value >>= 1; }
    return count;
}

fn uint subpath(uint* witness, uint n, uint from, uint to, uint limit,
                uint* output, uint offset) {
    if (limit == 0 || witness[from * n + to] == 0) return 0;
    uint middle = witness[from * n + to] - 1;
    uint count = subpath(witness, n, from, middle, limit - 1, output, offset);
    output[offset + count] = middle;
    count += 1;
    uint remaining = limit - count;
    if (remaining > 0)
        count += subpath(witness, n, middle, to, remaining, output, offset + count);
    return count;
}

fn bool decode(long* input, usz length, uint* n_out, uint* s_out,
               uint* edge, uint* witness, uint* distance) {
    if (input == null || length < 2 || length > 131) return false;
    if (input[0] < 2 || input[0] > MAX_N) return false;
    uint n = (uint)input[0];
    if (input[1] < 2 || input[1] > (long)n || length != (usz)(2 + 2*n*n)) return false;
    uint s = (uint)input[1];
    uint matrix = n*n;
    for (uint i = 0; i < matrix; i++) {
        if (input[2+i] < 0 || input[2+i] > 1 || input[2+matrix+i] < 0 || input[2+matrix+i] > (long)n)
            return false;
        edge[i] = (uint)input[2+i];
        witness[i] = (uint)input[2+matrix+i];
    }
    for (uint i = 0; i < n; i++) if (edge[i*n+i] != 0) return false;
    for (uint i = 0; i < n; i++) for (uint j = 0; j < n; j++)
        distance[i*n+j] = i == j ? 0 : (edge[i*n+j] != 0 ? 1 : INF_DIST);
    for (uint k = 0; k < n; k++) for (uint i = 0; i < n; i++) for (uint j = 0; j < n; j++) {
        uint candidate = distance[i*n+k] + distance[k*n+j];
        if (candidate < distance[i*n+j]) distance[i*n+j] = candidate;
    }
    for (uint i = 0; i < n; i++) for (uint j = 0; j < n; j++) {
        uint d = distance[i*n+j], w = witness[i*n+j];
        if (d >= INF_DIST) return false;
        if (d <= 1) { if (w != 0) return false; }
        else {
            if (w == 0) return false;
            uint v = w - 1;
            if (v == i || v == j) return false;
            uint left = distance[i*n+v], right = distance[v*n+j];
            if (left + right != d || left >= d || right >= d) return false;
        }
    }
    *n_out = n;
    *s_out = s;
    return true;
}

fn long zwick_deterministic_bridging_set(long* input, usz length)
    @export("zwick_deterministic_bridging_set") {
    uint[64] edge = zeroed, witness = zeroed, distance = zeroed;
    uint n = 0, s = 0;
    if (!decode(input, length, &n, &s, &edge[0], &witness[0], &distance[0])) return -1;
    uint[64] constraints = zeroed;
    uint constraint_count = 0;
    for (uint i = 0; i < n; i++) for (uint j = 0; j < n; j++) {
        uint[8] internal = zeroed;
        uint count = subpath(&witness[0], n, i, j, s, &internal[0], 0);
        uint mask = (1 << i) | (1 << j);
        for (uint k = 0; k < count; k++) mask |= 1 << internal[k];
        if (popcount16(mask) >= s) {
            bool duplicate = false;
            for (uint c = 0; c < constraint_count; c++) if (constraints[c] == mask) duplicate = true;
            if (!duplicate) { constraints[constraint_count] = mask; constraint_count++; }
        }
    }
    bool[64] unhit = zeroed;
    for (uint i = 0; i < constraint_count; i++) unhit[i] = true;
    uint remaining = constraint_count, selected = 0;
    while (remaining > 0) {
        uint best_vertex = 0, best_score = 0;
        for (uint v = 0; v < n; v++) {
            uint score = 0;
            for (uint c = 0; c < constraint_count; c++)
                if (unhit[c] && (constraints[c] & (1 << v)) != 0) score++;
            if (score > best_score) { best_score = score; best_vertex = v; }
        }
        if (best_score == 0) return -1;
        selected |= 1 << best_vertex;
        for (uint c = 0; c < constraint_count; c++)
            if (unhit[c] && (constraints[c] & (1 << best_vertex)) != 0) {
                unhit[c] = false;
                remaining--;
            }
    }
    return (long)selected;
}
