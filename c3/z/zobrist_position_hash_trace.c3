module zobrist_position_hash_trace;

const usz SLOTS = 16;
const usz FEATURES = 3;
const usz MAX_OPERATIONS = 64;
const usz BASE_WORDS = 1 + SLOTS * FEATURES + SLOTS;
const usz MAX_VALID_WORDS = BASE_WORDS + 2 * MAX_OPERATIONS;

fn void store_hash(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(value & 255);
        value >>= 8;
    }
}

fn long zobrist_position_hash_trace(long* input, usz length,
                                    char* output, usz capacity) @export("zobrist_position_hash_trace") {
    if (input == null || length < BASE_WORDS || length > MAX_VALID_WORDS + 1) return -1;
    long count_value = input[0];
    if (count_value < 0 || count_value > (long)MAX_OPERATIONS) return -1;
    usz count = (usz)count_value;
    if (length != BASE_WORDS + 2 * count) return -1;

    for (usz i = 0; i < SLOTS * FEATURES; i++)
        if (input[1 + i] < 0) return -1;
    usz state_start = 1 + SLOTS * FEATURES;
    for (usz slot = 0; slot < SLOTS; slot++)
        if (input[state_start + slot] < 0 || input[state_start + slot] > (long)FEATURES) return -1;
    usz edits_start = state_start + SLOTS;
    for (usz edit = 0; edit < count; edit++) {
        long slot = input[edits_start + 2 * edit];
        long feature = input[edits_start + 2 * edit + 1];
        if (slot < 0 || slot >= (long)SLOTS || feature < 0 || feature > (long)FEATURES) return -1;
    }

    usz required = 8 * (count + 1);
    if (output == null || capacity < required) return -2;

    u8[SLOTS] board;
    ulong hash = 0;
    for (usz slot = 0; slot < SLOTS; slot++) {
        u8 feature = (u8)input[state_start + slot];
        board[slot] = feature;
        if (feature != 0) hash ^= (ulong)input[1 + slot * FEATURES + (usz)feature - 1];
    }
    store_hash(output, 0, hash);
    for (usz edit = 0; edit < count; edit++) {
        usz slot = (usz)input[edits_start + 2 * edit];
        u8 next = (u8)input[edits_start + 2 * edit + 1];
        u8 previous = board[slot];
        if (previous != 0) hash ^= (ulong)input[1 + slot * FEATURES + (usz)previous - 1];
        if (next != 0) hash ^= (ulong)input[1 + slot * FEATURES + (usz)next - 1];
        board[slot] = next;
        store_hash(output, 8 * (edit + 1), hash);
    }
    return (long)required;
}
