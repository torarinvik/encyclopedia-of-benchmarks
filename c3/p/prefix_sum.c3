module prefix_sum;

const usz MAX_LENGTH = 256;
const usz HASH_CAPACITY = 1024;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)((bits >> (byte * 8)) & 255);
}
fn usz hash_key(long key) { long bucket = key % (long)HASH_CAPACITY; if (bucket < 0) bucket += (long)HASH_CAPACITY; return (usz)bucket; }
fn bool contains_sum(long* prefix, usz count, long target) {
    long[HASH_CAPACITY] keys; bool[HASH_CAPACITY] used;
    for (usz i = 0; i < HASH_CAPACITY; i++) { keys[i] = 0; used[i] = false; }
    usz slot = hash_key(0); keys[slot] = 0; used[slot] = true;
    for (usz end = 1; end <= count; end++) {
        long wanted = prefix[end] - target; slot = hash_key(wanted);
        while (used[slot] && keys[slot] != wanted) slot = (slot + 1) % HASH_CAPACITY;
        if (used[slot]) return true;
        slot = hash_key(prefix[end]);
        while (used[slot] && keys[slot] != prefix[end]) slot = (slot + 1) % HASH_CAPACITY;
        if (!used[slot]) { used[slot] = true; keys[slot] = prefix[end]; }
    }
    return false;
}

fn long prefix_sum(long* input, usz length, char* output, usz output_capacity) @export("prefix_sum") {
    if (input == null || length < 2 || input[0] < 0 || input[0] > 2 || input[1] < 0 || input[1] > (long)MAX_LENGTH) return -1;
    long operation = input[0]; usz count = (usz)input[1]; usz extra = operation == 1 ? 2 : operation == 2 ? 1 : 0;
    if (length != 2 + count + extra || (operation == 1 && count == 0)) return -1;
    for (usz i = 0; i < count; i++) if (input[2 + i] < -2147483648 || input[2 + i] > 2147483647) return -1;
    if (operation == 1) { long left=input[2+count], right=input[3+count]; if (left < 0 || right < left || right >= (long)count) return -1; }
    else if (operation == 2 && (input[2+count] < -1000000000000 || input[2+count] > 1000000000000)) return -1;
    long[MAX_LENGTH + 1] prefix;
    for (usz i = 0; i <= MAX_LENGTH; i++) prefix[i] = 0;
    for (usz i = 0; i < count; i++) prefix[i + 1] = prefix[i] + input[2 + i];
    usz words = operation == 0 ? count : 1;
    if (output_capacity < words * 8 || (words != 0 && output == null)) return -2;
    if (operation == 0) { for (usz i = 0; i < count; i++) store_i64_le(output, i * 8, prefix[i + 1]); return (long)count; }
    long result = operation == 1 ? prefix[(usz)input[3+count] + 1] - prefix[(usz)input[2+count]] : contains_sum(prefix, count, input[2+count]) ? 1 : 0;
    store_i64_le(output, 0, result);
    return 1;
}
