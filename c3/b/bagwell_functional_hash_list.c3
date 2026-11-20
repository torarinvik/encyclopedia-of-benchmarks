module bagwell_functional_hash_list;

const usz MAX_INPUT = 131;
const usz MAX_OUTPUT = 256;
const usz SLOTS = 56;

fn void put_i64_le(char* output, usz at, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[at + b] = (char)(bits >> (8 * b));
}

fn long bagwell_functional_hash_list(long* input, usz length, char* output,
                                     usz capacity) @export("bagwell_functional_hash_list") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = input[0];
    if (nv < 0 || nv > 32) return -1;
    usz n = (usz)nv, q_at = 1 + 2 * n;
    if (q_at >= length) return -1;
    long qv = input[q_at];
    if (qv < 1 || qv > 32) return -1;
    usz q = (usz)qv, query_at = q_at + 1;
    if (length != 2 + 2 * n + 2 * q) return -1;
    for (usz i = 0; i < n; i++)
        if (input[1 + 2 * i] < -2147483648 || input[1 + 2 * i] > 2147483647
            || input[2 + 2 * i] < -2147483648 || input[2 + 2 * i] > 2147483647) return -1;
    for (usz j = 0; j < q; j++) {
        long root = input[query_at + 2 * j], key = input[query_at + 2 * j + 1];
        if (root < 0 || root > nv || key < -2147483648 || key > 2147483647) return -1;
    }
    usz bytes = 8 * q;
    if (output == null || capacity < bytes) return -2;

    long[56] keys = {0}, values = {0};
    int[56] next, heads;
    int[3] prev = {-1, -1, -1};
    int[33] root_block, root_offset;
    for (usz i = 0; i < SLOTS; i++) { next[i] = -1; heads[i] = -1; }
    for (usz i = 0; i <= 32; i++) { root_block[i] = -1; root_offset[i] = -1; }
    usz current = 0;
    for (usz i = 0; i < n; i++) {
        if (i == 8 || i == 24) { prev[current + 1] = (int)current; current++; }
        usz start = current == 0 ? 0 : current == 1 ? 8 : 24;
        usz side = current == 0 ? 8 : current == 1 ? 16 : 32;
        usz offset = i - start, slot = start + offset;
        ulong hash = (ulong)input[1 + 2 * i];
        usz bucket = (usz)(hash & (ulong)(side - 1)), head_slot = start + bucket;
        keys[slot] = input[1 + 2 * i]; values[slot] = input[2 + 2 * i];
        next[slot] = heads[head_slot]; heads[head_slot] = (int)offset;
        root_block[i + 1] = (int)current; root_offset[i + 1] = (int)offset;
    }
    for (usz j = 0; j < q; j++) {
        long root = input[query_at + 2 * j], key = input[query_at + 2 * j + 1];
        int block = root_block[(usz)root], limit = root_offset[(usz)root];
        long answer = -9223372036854775807L - 1;
        if (block >= 0) {
            ulong hash = (ulong)key;
            bool first = true;
            while (block >= 0 && answer == (-9223372036854775807L - 1)) {
                usz b = (usz)block;
                usz start = b == 0 ? 0 : b == 1 ? 8 : 24;
                usz side = b == 0 ? 8 : b == 1 ? 16 : 32;
                usz bucket = (usz)(hash & (ulong)(side - 1));
                int chain = heads[start + bucket];
                while (chain >= 0) {
                    usz slot = start + (usz)chain;
                    if ((!first || chain <= limit) && keys[slot] == key) { answer = values[slot]; break; }
                    chain = next[slot];
                }
                block = prev[b]; first = false;
            }
        }
        put_i64_le(output, 8 * j, answer);
    }
    return (long)bytes;
}
