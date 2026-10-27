module sugiyama_barycentric_crossing_reduction;

fn void put_i64(uint8* out, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) out[word * 8 + b] = (uint8)(bits >> (8 * b));
}

fn void positions(long* order, long* sizes, long layer, long* pos) {
    for (long i = 0; i < sizes[layer]; i++) {
        long vertex = order[layer * 32 + i];
        pos[vertex] = i;
    }
}

fn void reorder(long* order, long* sizes, long* owner, long* eu, long* ev,
                long edge_count, long target, long fixed, bool down, long* pos) {
    positions(order, sizes, fixed, pos);
    long[32] rank;
    long[32] numerator;
    long[32] denominator;
    for (long i = 0; i < sizes[target]; i++) rank[order[target * 32 + i]] = i;
    for (long e = 0; e < edge_count; e++) {
        long u = eu[e], v = ev[e];
        if (down && owner[u] == fixed && owner[v] == target) {
            numerator[v] += pos[u];
            denominator[v] += 1;
        } else if (!down && owner[u] == target && owner[v] == fixed) {
            numerator[u] += pos[v];
            denominator[u] += 1;
        }
    }
    for (long i = 0; i < sizes[target]; i++) {
        long v = order[target * 32 + i];
        if (denominator[v] == 0) { numerator[v] = rank[v]; denominator[v] = 1; }
    }
    for (long i = 1; i < sizes[target]; i++) {
        long vertex = order[target * 32 + i];
        long j = i;
        while (j > 0) {
            long previous = order[target * 32 + j - 1];
            long left = numerator[vertex] * denominator[previous];
            long right = numerator[previous] * denominator[vertex];
            if (left > right || (left == right && rank[vertex] > rank[previous])) break;
            order[target * 32 + j] = previous;
            j -= 1;
        }
        order[target * 32 + j] = vertex;
    }
    positions(order, sizes, target, pos);
}

fn long sugiyama_barycentric_crossing_reduction(long* input, usz length,
    uint8* output, usz capacity) @export("sugiyama_barycentric_crossing_reduction") {
    if (input == null || length < 2 || length > 299) return -1;
    long layers = input[0], limit = input[1];
    if (layers < 2 || layers > 8 || limit < 0 || limit > 16) return -1;
    long[256] order;
    long[8] sizes;
    long[32] owner;
    long[32] pos;
    long[128] eu;
    long[128] ev;
    for (long i = 0; i < 32; i++) owner[i] = -1;
    usz at = 2;
    long total = 0;
    for (long level = 0; level < layers; level++) {
        if (at >= length) return -1;
        long count = input[at++];
        if (count < 1 || count > 32 || at + (usz)count > length) return -1;
        sizes[level] = count;
        total += count;
        if (total > 32) return -1;
        for (long i = 0; i < count; i++) {
            long id = input[at++];
            if (id < 0 || id >= 32) return -1;
            if (owner[id] != -1) return -1;
            order[level * 32 + i] = id;
            owner[id] = level;
        }
    }
    if (total < 2 || at >= length) return -1;
    long edge_count = input[at++];
    if (edge_count < 0 || edge_count > 128 || at + 2 * (usz)edge_count != length) return -1;
    for (long e = 0; e < edge_count; e++) {
        long u = input[at + 2 * (usz)e], v = input[at + 2 * (usz)e + 1];
        if (u < 0 || u >= 32 || v < 0 || v >= 32 || owner[u] < 0 || owner[v] != owner[u] + 1) return -1;
        for (long j = 0; j < e; j++) if (eu[j] == u && ev[j] == v) return -1;
        eu[e] = u; ev[e] = v;
    }
    long sweeps = 0;
    for (long pass = 0; pass < limit; pass++) {
        long[256] before = order;
        for (long level = 0; level < layers - 1; level++)
            reorder(order, sizes, owner, eu, ev, edge_count, level + 1, level, true, pos);
        for (long step = 0; step < layers - 1; step++) {
            long level = layers - 2 - step;
            reorder(order, sizes, owner, eu, ev, edge_count, level, level + 1, false, pos);
        }
        sweeps += 1;
        bool changed = false;
        for (long l = 0; l < layers; l++)
            for (long i = 0; i < sizes[l]; i++)
                if (before[l * 32 + i] != order[l * 32 + i]) changed = true;
        if (!changed) break;
    }
    for (long l = 0; l < layers; l++) positions(order, sizes, l, pos);
    long crossings = 0;
    for (long i = 0; i < edge_count; i++)
        for (long j = i + 1; j < edge_count; j++)
            if (owner[eu[i]] == owner[eu[j]] &&
                (pos[eu[i]] - pos[eu[j]]) * (pos[ev[i]] - pos[ev[j]]) < 0) crossings += 1;
    usz bytes = 8 * ((usz)total + 2);
    if (output == null || capacity < bytes) return -2;
    put_i64(output, 0, sweeps);
    put_i64(output, 1, crossings);
    usz word = 2;
    for (long l = 0; l < layers; l++)
        for (long i = 0; i < sizes[l]; i++) put_i64(output, word++, order[l * 32 + i]);
    return (long)bytes;
}
