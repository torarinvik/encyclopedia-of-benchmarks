module indexed_block_list;

const usz B = 4, MAX_INITIAL = 16, MAX_OPS = 64, MAX_INSERTS = 32;
const usz MAX_ACCESSES = 32, MAX_NODES = 16, MAX_ITEMS = 48, MAX_PARSEABLE = 179;
const usz STRIDE = 9;

fn bool valid_input(long* input, usz length, usz* accesses) {
    if (input == null || length < 2 || length > MAX_PARSEABLE || input[0] < 0 || input[0] > 16) return false;
    usz initial = (usz)input[0];
    if (length < initial + 2) return false;
    for (usz i = 0; i < initial; i++) if (input[1 + i] < -1000000 || input[1 + i] > 1000000) return false;
    long raw_ops = input[1 + initial];
    if (raw_ops < 0 || raw_ops > 64) return false;
    usz cursor = initial + 2, size = initial, inserts = 0;
    *accesses = 0;
    for (usz op = 0; op < (usz)raw_ops; op++) {
        if (cursor >= length) return false;
        if (input[cursor] == 0) {
            if (cursor + 3 > length) return false;
            long index = input[cursor + 1], value = input[cursor + 2];
            if (index < 0 || (ulong)index > size || value < -1000000 || value > 1000000) return false;
            inserts++;
            if (inserts > MAX_INSERTS) return false;
            size++; cursor += 3;
        } else if (input[cursor] == 1) {
            if (cursor + 2 > length) return false;
            long index = input[cursor + 1];
            if (index < 0 || (ulong)index >= size) return false;
            *accesses = *accesses + 1;
            if (*accesses > MAX_ACCESSES) return false;
            cursor += 2;
        } else return false;
    }
    return cursor == length && size <= MAX_ITEMS;
}

fn long indexed_block_list(long* input, usz length, char* output, usz output_capacity)
    @export("indexed_block_list")
{
    usz access_count = 0;
    if (!valid_input(input, length, &access_count)) return -1;
    usz required = access_count * 8;
    if (required > 0 && (output == null || output_capacity < required)) return -2;
    long[144] blocks;
    usz[16] sizes;
    int[16] next;
    long[32] answers;
    for (usz i = 0; i < MAX_NODES; i++) { sizes[i] = 0; next[i] = -1; }
    usz node_count = 1;
    usz initial = (usz)input[0];
    for (usz index = 0; index < initial; index++) {
        int node = 0; usz offset = 0;
        while (next[node] >= 0 && index > offset + sizes[node]) { offset += sizes[node]; node = next[node]; }
        usz local = index - offset;
        for (usz j = sizes[node]; j > local; j--) blocks[(usz)node * STRIDE + j] = blocks[(usz)node * STRIDE + j - 1];
        blocks[(usz)node * STRIDE + local] = input[1 + index]; sizes[node]++;
        if (sizes[node] > 2 * B) {
            int fresh = (int)node_count; node_count++;
            usz first = sizes[node] - B;
            for (usz j = 0; j < B; j++) blocks[(usz)fresh * STRIDE + j] = blocks[(usz)node * STRIDE + first + j];
            sizes[fresh] = B; sizes[node] -= B; next[fresh] = next[node]; next[node] = fresh;
        }
    }
    usz cursor = initial + 2, operation_count = (usz)input[1 + initial], answer_count = 0;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[cursor]; usz index = (usz)input[cursor + 1];
        if (opcode == 0) {
            int node = 0; usz offset = 0;
            while (next[node] >= 0 && index > offset + sizes[node]) { offset += sizes[node]; node = next[node]; }
            usz local = index - offset;
            for (usz j = sizes[node]; j > local; j--) blocks[(usz)node * STRIDE + j] = blocks[(usz)node * STRIDE + j - 1];
            blocks[(usz)node * STRIDE + local] = input[cursor + 2]; sizes[node]++;
            if (sizes[node] > 2 * B) {
                int fresh = (int)node_count; node_count++;
                usz first = sizes[node] - B;
                for (usz j = 0; j < B; j++) blocks[(usz)fresh * STRIDE + j] = blocks[(usz)node * STRIDE + first + j];
                sizes[fresh] = B; sizes[node] -= B; next[fresh] = next[node]; next[node] = fresh;
            }
            cursor += 3;
        } else {
            int node = 0; usz offset = 0;
            while (index >= offset + sizes[node]) { offset += sizes[node]; node = next[node]; }
            answers[answer_count++] = blocks[(usz)node * STRIDE + index - offset]; cursor += 2;
        }
    }
    for (usz i = 0; i < answer_count; i++) for (usz b = 0; b < 8; b++) output[8 * i + b] = (char)(((ulong)answers[i] >> (8 * b)) & 255);
    return (long)required;
}
