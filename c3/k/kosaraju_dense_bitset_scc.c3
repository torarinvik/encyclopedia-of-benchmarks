module kosaraju_dense_bitset_scc;

const usz MAX_VERTICES = 256;
const usz MAX_WORDS = 4;
const usz MAX_CELLS = MAX_VERTICES * MAX_WORDS;
const usz MAX_PARSEABLE_INPUT_LENGTH = 1 + MAX_CELLS + 1;

fn uint lowest_bit_index(ulong bits) {
    uint index = 0;
    while ((bits & 1ul) == 0ul) { bits >>= 1; index++; }
    return index;
}

fn void write_u16_le(char* output, usz position, ushort value) {
    output[position] = (char)(value & 255);
    output[position + 1] = (char)(value >> 8);
}

fn long kosaraju_dense_bitset_scc(long* input, usz length, char* output, usz output_capacity)
    @export("kosaraju_dense_bitset_scc") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > (long)MAX_VERTICES) return -1;
    usz n = (usz)input[0];
    usz words = (n + 63) / 64;
    if (length != 1 + n * words) return -1;

    ulong[MAX_CELLS] adjacency = zeroed;
    ulong[MAX_CELLS] transpose = zeroed;
    for (usz cell = 0; cell < n * words; cell++) adjacency[cell] = (ulong)input[1 + cell];
    if ((n & 63) != 0) {
        ulong valid = (1ul << (n & 63)) - 1ul;
        for (usz vertex = 0; vertex < n; vertex++)
            if ((adjacency[vertex * words + words - 1] & ~valid) != 0ul) return -1;
    }
    for (usz source = 0; source < n; source++) {
        for (usz word = 0; word < words; word++) {
            ulong bits = adjacency[source * words + word];
            while (bits != 0ul) {
                uint bit = lowest_bit_index(bits);
                usz target = word * 64 + (usz)bit;
                transpose[target * words + source / 64] |= 1ul << (source & 63);
                bits &= bits - 1ul;
            }
        }
    }

    ulong[MAX_WORDS] unvisited;
    for (usz word = 0; word < words; word++) unvisited[word] = 0xfffffffffffffffful;
    if ((n & 63) != 0) unvisited[words - 1] = (1ul << (n & 63)) - 1ul;
    ushort[MAX_VERTICES] stack, next_word, order;
    usz order_length = 0;
    for (usz root = 0; root < n; root++) {
        usz root_word = root / 64;
        usz root_bit = root & 63;
        if (((unvisited[root_word] >> root_bit) & 1ul) == 0ul) continue;
        unvisited[root_word] &= ~(1ul << root_bit);
        usz stack_length = 1;
        stack[0] = (ushort)root;
        next_word[0] = 0;
        while (stack_length != 0) {
            usz depth = stack_length - 1;
            usz vertex = stack[depth];
            bool pushed = false;
            while ((usz)next_word[depth] < words) {
                usz word = next_word[depth];
                ulong candidates = adjacency[vertex * words + word] & unvisited[word];
                if (candidates != 0ul) {
                    uint bit = lowest_bit_index(candidates);
                    usz neighbor = word * 64 + (usz)bit;
                    unvisited[word] &= ~(1ul << bit);
                    stack[stack_length] = (ushort)neighbor;
                    next_word[stack_length] = 0;
                    stack_length++;
                    pushed = true;
                    break;
                }
                next_word[depth]++;
            }
            if (!pushed && (usz)next_word[depth] == words) {
                order[order_length++] = (ushort)vertex;
                stack_length--;
            }
        }
    }

    for (usz word = 0; word < words; word++) unvisited[word] = 0xfffffffffffffffful;
    if ((n & 63) != 0) unvisited[words - 1] = (1ul << (n & 63)) - 1ul;
    ushort[MAX_VERTICES] raw_component;
    ushort component_count = 0;
    while (order_length != 0) {
        usz root = order[--order_length];
        usz root_word = root / 64;
        usz root_bit = root & 63;
        if (((unvisited[root_word] >> root_bit) & 1ul) == 0ul) continue;
        unvisited[root_word] &= ~(1ul << root_bit);
        usz stack_length = 1;
        stack[0] = (ushort)root;
        raw_component[root] = component_count;
        while (stack_length != 0) {
            usz vertex = stack[--stack_length];
            for (usz word = 0; word < words; word++) {
                ulong candidates = transpose[vertex * words + word] & unvisited[word];
                while (candidates != 0ul) {
                    uint bit = lowest_bit_index(candidates);
                    usz neighbor = word * 64 + (usz)bit;
                    ulong selected = 1ul << bit;
                    unvisited[word] &= ~selected;
                    candidates &= ~selected;
                    raw_component[neighbor] = component_count;
                    stack[stack_length++] = (ushort)neighbor;
                }
            }
        }
        component_count++;
    }

    ushort[MAX_VERTICES] remap;
    for (usz component = 0; component < MAX_VERTICES; component++) remap[component] = 65535;
    ushort canonical_count = 0;
    for (usz vertex = 0; vertex < n; vertex++) {
        usz raw = (usz)raw_component[vertex];
        if (remap[raw] == 65535) { remap[raw] = canonical_count; canonical_count++; }
    }
    usz output_length = 2 + 2 * n;
    if (output == null || output_capacity < output_length) return -2;
    write_u16_le(output, 0, canonical_count);
    for (usz vertex = 0; vertex < n; vertex++)
        write_u16_le(output, 2 + 2 * vertex, remap[(usz)raw_component[vertex]]);
    return (long)output_length;
}
