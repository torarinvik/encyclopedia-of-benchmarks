module invertible_bloom_lookup_table_reconciliation;

const usz SET_LIMIT = 8;
const usz MAX_KEY = 63;
const usz CELL_COUNT = 48;
const usz MAX_PEELS = 16;
const usz MAX_INPUT = 18;

fn ulong checksum(long key) {
    ulong x = (ulong)key;
    return x * x + 3 * x + 7;
}

fn void locations(long key, usz[3] *slots) {
    ulong x = (ulong)key;
    slots[0] = (usz)(x % 16);
    slots[1] = 16 + (usz)((3 * x + 5) % 16);
    slots[2] = 32 + (usz)((5 * x + 9) % 16);
}

fn void write_i64(char* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz b = 0; b < 8; b++) output[index * 8 + b] = (char)(bits >> (8 * b));
}

fn long invertible_bloom_lookup_table_reconciliation(long* input, usz length,
        char* output, usz capacity) @export("invertible_bloom_lookup_table_reconciliation") {
    if (input == null || length < 2 || length > MAX_INPUT + 1) return -1;
    long a0 = input[0], b0 = input[1];
    if (a0 < 0 || a0 > (long)SET_LIMIT || b0 < 0 || b0 > (long)SET_LIMIT) return -1;
    usz a_count = (usz)a0, b_count = (usz)b0;
    if (length != 2 + a_count + b_count) return -1;
    long previous = -1;
    for (usz i = 0; i < a_count; i++) {
        long key = input[2 + i];
        if (key < 0 || key > (long)MAX_KEY || key <= previous) return -1;
        previous = key;
    }
    previous = -1;
    for (usz i = 0; i < b_count; i++) {
        long key = input[2 + a_count + i];
        if (key < 0 || key > (long)MAX_KEY || key <= previous) return -1;
        previous = key;
    }

    long[CELL_COUNT] counts, sums, checks;
    for (usz i = 0; i < CELL_COUNT; i++) counts[i] = sums[i] = checks[i] = 0;
    for (usz side = 0; side < 2; side++) {
        usz n = side == 0 ? a_count : b_count;
        long sign = side == 0 ? 1 : -1;
        usz start = side == 0 ? 2 : 2 + a_count;
        for (usz i = 0; i < n; i++) {
            long key = input[start + i];
            usz[3] slots;
            locations(key, &slots);
            long tag = (long)checksum(key);
            for (usz j = 0; j < 3; j++) {
                counts[slots[j]] += sign;
                sums[slots[j]] += sign * key;
                checks[slots[j]] += sign * tag;
            }
        }
    }

    long[MAX_PEELS] positive, negative;
    usz positive_count = 0, negative_count = 0;
    bool repeated = false;
    for (usz peel = 0; peel < MAX_PEELS; peel++) {
        bool zero = true;
        for (usz i = 0; i < CELL_COUNT; i++) if (counts[i] != 0 || sums[i] != 0 || checks[i] != 0) { zero = false; break; }
        if (zero) break;
        bool found = false;
        long sign = 0, key = 0;
        for (usz i = 0; i < CELL_COUNT; i++) {
            if (counts[i] != 1 && counts[i] != -1) continue;
            long candidate_sign = counts[i];
            long candidate = candidate_sign * sums[i];
            if (candidate < 0 || candidate > (long)MAX_KEY) continue;
            if (checks[i] != candidate_sign * (long)checksum(candidate)) continue;
            sign = candidate_sign; key = candidate; found = true; break;
        }
        if (!found) break;
        for (usz i = 0; i < positive_count; i++) if (positive[i] == key) repeated = true;
        for (usz i = 0; i < negative_count; i++) if (negative[i] == key) repeated = true;
        if (repeated) break;
        if (sign > 0) positive[positive_count++] = key;
        else negative[negative_count++] = key;
        usz[3] slots;
        locations(key, &slots);
        long tag = (long)checksum(key);
        for (usz j = 0; j < 3; j++) { counts[slots[j]] -= sign; sums[slots[j]] -= sign * key; checks[slots[j]] -= sign * tag; }
    }

    bool zero = true;
    for (usz i = 0; i < CELL_COUNT; i++) if (counts[i] != 0 || sums[i] != 0 || checks[i] != 0) { zero = false; break; }
    for (usz i = 1; i < positive_count; i++) { long x = positive[i]; usz j = i; while (j > 0 && positive[j - 1] > x) { positive[j] = positive[j - 1]; j--; } positive[j] = x; }
    for (usz i = 1; i < negative_count; i++) { long x = negative[i]; usz j = i; while (j > 0 && negative[j - 1] > x) { negative[j] = negative[j - 1]; j--; } negative[j] = x; }

    long[3 + 2 * MAX_PEELS] staged;
    usz words = 0;
    staged[words++] = (!repeated && zero) ? 1 : 0;
    staged[words++] = (long)positive_count;
    staged[words++] = (long)negative_count;
    for (usz i = 0; i < positive_count; i++) staged[words++] = positive[i];
    for (usz i = 0; i < negative_count; i++) staged[words++] = negative[i];
    usz required = words * 8;
    if (output == null || capacity < required) return -2;
    for (usz i = 0; i < words; i++) write_i64(output, i, staged[i]);
    return (long)required;
}
