module slicing_floorplan_stockmeyer;

const usz MAX_NODES = 15;
const usz MAX_CANDIDATES = 256;
const usz MAX_INPUT = 32;
const usz OUTPUT_BYTES = 32;

bool mask_lex_less(long a, long b, usz leaves) {
    for (usz bit = 0; bit < leaves; bit++) {
        long av = (a >> bit) & 1, bv = (b >> bit) & 1;
        if (av != bv) return av < bv;
    }
    return false;
}

void store_i64_le(char* output, usz offset, long value) {
    long bits = value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long slicing_floorplan_stockmeyer(long* input, usz length, char* output, usz capacity)
        @export("slicing_floorplan_stockmeyer") {
    if (input == null || length < 4 || length > MAX_INPUT || input[0] < 1 || input[0] > 8) return -1;
    usz leaves = (usz)input[0];
    long[MAX_NODES] op = zeroed, stack = zeroed;
    long[MAX_NODES * MAX_CANDIDATES] cand_h = zeroed, cand_w = zeroed, cand_mask = zeroed;
    usz[MAX_NODES] count = zeroed;
    for (usz i = 0; i < MAX_NODES; i++) op[i] = -1;
    usz stack_size = 0, node_count = 0, leaf_count = 0, internal_count = 0, position = 1;
    while (position < length) {
        long token = input[position++];
        if (token == 2) {
            if (position + 2 > length || leaf_count >= leaves || node_count >= MAX_NODES) return -1;
            long height = input[position++], width = input[position++];
            if (height < 1 || height > 20 || width < 1 || width > 20) return -1;
            op[node_count] = 2;
            usz base = node_count * MAX_CANDIDATES;
            cand_h[base] = height; cand_w[base] = width; cand_mask[base] = 0;
            cand_h[base + 1] = width; cand_w[base + 1] = height; cand_mask[base + 1] = 1 << leaf_count;
            count[node_count] = 2;
            bool[MAX_CANDIDATES] dominated = zeroed;
            for (usz i = 0; i < count[node_count]; i++) for (usz j = 0; j < count[node_count]; j++) {
                if (i == j) continue;
                usz ai = base + i, bi = base + j;
                if (cand_h[bi] <= cand_h[ai] && cand_w[bi] <= cand_w[ai] &&
                    (cand_h[bi] < cand_h[ai] || cand_w[bi] < cand_w[ai] ||
                     mask_lex_less(cand_mask[bi], cand_mask[ai], leaves) ||
                     (cand_mask[bi] == cand_mask[ai] && j < i))) dominated[i] = true;
            }
            usz kept = 0;
            for (usz i = 0; i < count[node_count]; i++) if (!dominated[i]) {
                cand_h[base + kept] = cand_h[base + i]; cand_w[base + kept] = cand_w[base + i]; cand_mask[base + kept] = cand_mask[base + i]; kept++;
            }
            count[node_count] = kept;
            stack[stack_size++] = (long)node_count++;
            leaf_count++;
        } else if (token == 0 || token == 1) {
            if (stack_size < 2 || internal_count >= leaves - 1 || node_count >= MAX_NODES) return -1;
            usz right = (usz)stack[--stack_size], left = (usz)stack[--stack_size];
            if (op[right] == token) return -1;
            op[node_count] = token;
            usz base = node_count * MAX_CANDIDATES;
            for (usz i = 0; i < count[left]; i++) for (usz j = 0; j < count[right]; j++) {
                if (count[node_count] >= MAX_CANDIDATES) return -1;
                usz li = left * MAX_CANDIDATES + i, ri = right * MAX_CANDIDATES + j;
                usz dest = base + count[node_count]++;
                cand_mask[dest] = cand_mask[li] | cand_mask[ri];
                if (token == 0) {
                    cand_h[dest] = cand_h[li] > cand_h[ri] ? cand_h[li] : cand_h[ri];
                    cand_w[dest] = cand_w[li] + cand_w[ri];
                } else {
                    cand_h[dest] = cand_h[li] + cand_h[ri];
                    cand_w[dest] = cand_w[li] > cand_w[ri] ? cand_w[li] : cand_w[ri];
                }
            }
            bool[MAX_CANDIDATES] dominated = zeroed;
            for (usz i = 0; i < count[node_count]; i++) for (usz j = 0; j < count[node_count]; j++) {
                if (i == j) continue;
                usz ai = base + i, bi = base + j;
                if (cand_h[bi] <= cand_h[ai] && cand_w[bi] <= cand_w[ai] &&
                    (cand_h[bi] < cand_h[ai] || cand_w[bi] < cand_w[ai] ||
                     mask_lex_less(cand_mask[bi], cand_mask[ai], leaves) ||
                     (cand_mask[bi] == cand_mask[ai] && j < i))) dominated[i] = true;
            }
            usz kept = 0;
            for (usz i = 0; i < count[node_count]; i++) if (!dominated[i]) {
                cand_h[base + kept] = cand_h[base + i]; cand_w[base + kept] = cand_w[base + i]; cand_mask[base + kept] = cand_mask[base + i]; kept++;
            }
            count[node_count] = kept;
            stack[stack_size++] = (long)node_count++;
            internal_count++;
        } else return -1;
    }
    if (position != length || leaf_count != leaves || internal_count != leaves - 1 || node_count != 2 * leaves - 1 || stack_size != 1) return -1;
    usz root = (usz)stack[0], base = root * MAX_CANDIDATES;
    if (count[root] == 0) return -1;
    usz best = 0;
    for (usz i = 1; i < count[root]; i++) {
        usz current = base + i, prior = base + best;
        long area = cand_h[current] * cand_w[current], best_area = cand_h[prior] * cand_w[prior];
        if (area < best_area || (area == best_area && (cand_h[current] < cand_h[prior] ||
            (cand_h[current] == cand_h[prior] && (cand_w[current] < cand_w[prior] ||
            (cand_w[current] == cand_w[prior] && mask_lex_less(cand_mask[current], cand_mask[prior], leaves))))))) best = i;
    }
    if (output == null || capacity < OUTPUT_BYTES) return -2;
    char[OUTPUT_BYTES] staged = zeroed;
    store_i64_le(staged, 0, cand_h[base + best] * cand_w[base + best]);
    store_i64_le(staged + 8, cand_h[base + best]);
    store_i64_le(staged + 16, cand_w[base + best]);
    store_i64_le(staged + 24, cand_mask[base + best]);
    for (usz i = 0; i < OUTPUT_BYTES; i++) output[i] = staged[i];
    return OUTPUT_BYTES;
}
