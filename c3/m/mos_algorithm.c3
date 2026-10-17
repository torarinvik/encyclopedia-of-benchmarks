module mos_algorithm;

const usz MAX_N = 256;
const usz MAX_Q = 256;
const usz MAX_INPUT_LENGTH = 1029;
const ulong FNV_OFFSET = 0xcbf29ce484222325;
const ulong FNV_PRIME = 0x100000001b3;

fn ulong hash_byte(ulong hash, uint8 byte) { return (hash ^ (ulong)byte) * FNV_PRIME; }

fn bool query_before(usz a, usz b, int32* lefts, int32* rights, usz block_size) {
    int32 block_a = lefts[a] / (int32)block_size;
    int32 block_b = lefts[b] / (int32)block_size;
    if (block_a != block_b) return block_a < block_b;
    if ((block_a & 1) != 0) return rights[a] < rights[b];
    return rights[a] > rights[b];
}

long mos_algorithm(long* input, usz length) @export("mos_algorithm") {
    if (input == null || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    long operation = input[0];
    long n64 = input[1];
    long q64 = input[2];
    long target64 = input[3];
    if ((operation != 0 && operation != 1) || n64 < 1 || n64 > 256 || q64 < 0 || q64 > 256
        || target64 < -1000000 || target64 > 1000000
        || length != 4 + (usz)n64 + 3 * (usz)q64) return -1;
    usz n = (usz)n64;
    usz q = (usz)q64;
    int32 target = (int32)target64;

    int32[MAX_N] values;
    for (usz index = 0; index < n; index += 1) {
        long value = input[4 + index];
        if (value < -1000000 || value > 1000000) return -1;
        values[index] = (int32)value;
    }
    int32[MAX_Q] lefts;
    int32[MAX_Q] rights;
    int32[MAX_Q] indices;
    usz[MAX_Q] order;
    bool[MAX_Q] seen;
    usz offset = 4 + n;
    for (usz query = 0; query < q; query += 1) {
        long left = input[offset + 3 * query];
        long right = input[offset + 3 * query + 1];
        long index = input[offset + 3 * query + 2];
        if (left < 0 || right < left || right >= n64 || index < 0 || index >= q64 || seen[(usz)index]) return -1;
        lefts[query] = (int32)left;
        rights[query] = (int32)right;
        indices[query] = (int32)index;
        seen[(usz)index] = true;
        order[query] = query;
    }

    usz block_size = 1;
    while ((block_size + 1) * (block_size + 1) <= n) block_size += 1;
    for (usz query = 1; query < q; query += 1) {
        usz current = order[query];
        usz position = query;
        while (position > 0 && query_before(current, order[position - 1], &lefts[0], &rights[0], block_size)) {
            order[position] = order[position - 1];
            position -= 1;
        }
        order[position] = current;
    }

    int32[MAX_Q] results;
    int32 current_left = 0;
    int32 current_right = -1;
    int32 aggregate = 0;
    for (usz sorted = 0; sorted < q; sorted += 1) {
        usz query = order[sorted];
        int32 left = lefts[query];
        int32 right = rights[query];
        if (operation == 0) {
            while (current_right < right) { current_right += 1; aggregate += values[(usz)current_right]; }
            while (current_right > right) { aggregate -= values[(usz)current_right]; current_right -= 1; }
            while (current_left < left) { aggregate -= values[(usz)current_left]; current_left += 1; }
            while (current_left > left) { current_left -= 1; aggregate += values[(usz)current_left]; }
        } else {
            while (current_right < right) { current_right += 1; if (values[(usz)current_right] == target) aggregate += 1; }
            while (current_right > right) { if (values[(usz)current_right] == target) aggregate -= 1; current_right -= 1; }
            while (current_left < left) { if (values[(usz)current_left] == target) aggregate -= 1; current_left += 1; }
            while (current_left > left) { current_left -= 1; if (values[(usz)current_left] == target) aggregate += 1; }
        }
        results[(usz)indices[query]] = aggregate;
    }

    ulong hash = hash_byte(FNV_OFFSET, (uint8)operation);
    hash = hash_byte(hash, (uint8)q);
    hash = hash_byte(hash, (uint8)(q >> 8));
    for (usz index = 0; index < q; index += 1) {
        ulong bits = (ulong)results[index];
        for (uint shift = 0; shift < 32; shift += 8) hash = hash_byte(hash, (uint8)(bits >> shift));
    }
    return (long)(hash & 0x7fffffffffffffff);
}
