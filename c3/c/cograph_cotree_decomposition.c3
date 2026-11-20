module cograph_cotree_decomposition;

const usz N = 12, M = 66, PARSEABLE = 135, OUTPUT = 47;

fn usz ct_components(ushort mask, ushort* adjacency, bool complement, ushort* parts) {
    ushort remaining = mask;
    usz count = 0;
    for (usz root = 0; root < N; root++) {
        ushort root_bit = (ushort)(1 << root);
        if ((remaining & root_bit) == 0) continue;
        ushort reached = root_bit;
        usz[12] queue = {};
        usz head = 0, tail = 1;
        queue[0] = root;
        while (head < tail) {
            usz vertex = queue[head++];
            ushort neighbors = (ushort)(adjacency[vertex] & mask);
            if (complement)
                neighbors = (ushort)(mask & (ushort)~adjacency[vertex] & (ushort)~(ushort)(1 << vertex));
            ushort fresh = (ushort)(neighbors & (ushort)~reached);
            for (usz next = 0; next < N; next++) {
                ushort bit = (ushort)(1 << next);
                if ((fresh & bit) != 0) {
                    fresh = (ushort)(fresh & (ushort)~bit);
                    reached = (ushort)(reached | bit);
                    queue[tail++] = next;
                }
            }
        }
        parts[count++] = reached;
        remaining = (ushort)(remaining & (ushort)~reached);
    }
    return count;
}

fn bool ct_emit(ushort mask, ushort* adjacency, uint8* output, usz* position) {
    if ((mask & (ushort)(mask - 1)) == 0) {
        usz vertex = 0;
        while ((mask & (ushort)(1 << vertex)) == 0) vertex++;
        output[*position] = 0;
        output[*position + 1] = (uint8)vertex;
        *position += 2;
        return true;
    }
    ushort[12] parts = {};
    usz count = ct_components(mask, adjacency, false, &parts[0]);
    uint8 kind = 1;
    if (count == 1) {
        count = ct_components(mask, adjacency, true, &parts[0]);
        kind = 2;
        if (count <= 1) return false;
    }
    output[*position] = kind;
    output[*position + 1] = (uint8)count;
    *position += 2;
    for (usz i = 0; i < count; i++)
        if (!ct_emit(parts[i], adjacency, output, position)) return false;
    return true;
}

fn long cograph_cotree_decomposition(long* input, usz length, uint8* output,
                                    usz capacity) @export("cograph_cotree_decomposition") {
    if (input == null || length < 2 || length > PARSEABLE) return -1;
    long n_value = input[0], m_value = input[1];
    if (n_value < 1 || n_value > N.long() || m_value < 0 || m_value > M.long() || m_value > n_value * (n_value - 1) / 2 ||
        length != 2 + 2 * m_value.usz()) return -1;
    usz n = n_value.usz(), m = m_value.usz();
    ushort[12] adjacency = {};
    for (usz edge = 0; edge < m; edge++) {
        long u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n.long() || v_value < 0 || v_value >= n.long() || u_value == v_value) return -1;
        usz u = u_value.usz(), v = v_value.usz();
        ushort ub = (ushort)(1 << u), vb = (ushort)(1 << v);
        if ((adjacency[u] & vb) != 0) return -1;
        adjacency[u] = (ushort)(adjacency[u] | vb);
        adjacency[v] = (ushort)(adjacency[v] | ub);
    }
    uint8[47] staged = {};
    usz output_length = 1;
    ushort all = (ushort)((1 << n) - 1);
    if (ct_emit(all, &adjacency[0], &staged[0], &output_length)) staged[0] = 1;
    else { staged[0] = 0; output_length = 1; }
    if (output == null || capacity < output_length) return -2;
    for (usz i = 0; i < output_length; i++) output[i] = staged[i];
    return output_length.long();
}
