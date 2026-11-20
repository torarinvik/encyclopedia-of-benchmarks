module cuckoo_filter_operation_trace;

const usz BUCKETS = 8;
const usz WIDTH = 4;
const usz MAX_OPERATIONS = 32;
const usz MAX_KICKS = 8;

fn usz delta(long fingerprint) {
    return 1 + (5 * (usz)fingerprint + 3) % 7;
}

fn usz first_empty(long* table, usz bucket) {
    for (usz slot = 0; slot < WIDTH; slot++)
        if (table[bucket * WIDTH + slot] == 0) return slot;
    return WIDTH;
}

fn bool insert(long* table, usz primary, long fingerprint) {
    usz alternate = primary ^ delta(fingerprint);
    usz empty = first_empty(table, primary);
    if (empty < WIDTH) { table[primary * WIDTH + empty] = fingerprint; return true; }
    empty = first_empty(table, alternate);
    if (empty < WIDTH) { table[alternate * WIDTH + empty] = fingerprint; return true; }
    usz current = primary;
    long pending = fingerprint;
    for (usz kick = 0; kick < MAX_KICKS; kick++) {
        usz position = current * WIDTH;
        long evicted = table[position];
        table[position] = pending;
        pending = evicted;
        current ^= delta(pending);
        empty = first_empty(table, current);
        if (empty < WIDTH) { table[current * WIDTH + empty] = pending; return true; }
    }
    return false;
}

fn void write_i64(char* output, usz index, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[index * 8 + byte] = (char)(bits >> (8 * byte));
}

fn long cuckoo_filter_operation_trace(long* input, usz length,
        char* output, usz capacity) @export("cuckoo_filter_operation_trace") {
    if (input == null || length < 4 || length > 98) return -1;
    long raw_count = input[0];
    if (raw_count < 1 || raw_count > (long)MAX_OPERATIONS) return -1;
    usz count = (usz)raw_count;
    if (length != 1 + 3 * count) return -1;
    for (usz operation = 0; operation < count; operation++) {
        long opcode = input[1 + 3 * operation];
        long primary = input[2 + 3 * operation];
        long fingerprint = input[3 + 3 * operation];
        if (opcode < 0 || opcode > 2 || primary < 0 || primary >= (long)BUCKETS ||
                fingerprint < 1 || fingerprint > 15) return -1;
    }
    usz required = count * 8;
    if (output == null || capacity < required) return -2;

    long[BUCKETS * WIDTH] table;
    for (usz i = 0; i < BUCKETS * WIDTH; i++) table[i] = 0;
    long[MAX_OPERATIONS] statuses;
    for (usz operation = 0; operation < count; operation++) {
        long opcode = input[1 + 3 * operation];
        usz primary = (usz)input[2 + 3 * operation];
        long fingerprint = input[3 + 3 * operation];
        usz alternate = primary ^ delta(fingerprint);
        if (opcode == 0) {
            if (!insert(&table[0], primary, fingerprint)) return -3;
            statuses[operation] = 1;
        } else if (opcode == 1) {
            bool found = false;
            for (usz order = 0; order < 2; order++) {
                usz bucket = order == 0 ? primary : alternate;
                for (usz slot = 0; slot < WIDTH; slot++)
                    if (table[bucket * WIDTH + slot] == fingerprint) found = true;
            }
            statuses[operation] = found ? 1 : 0;
        } else {
            bool removed = false;
            for (usz order = 0; order < 2 && !removed; order++) {
                usz bucket = order == 0 ? primary : alternate;
                for (usz slot = 0; slot < WIDTH; slot++) {
                    usz position = bucket * WIDTH + slot;
                    if (table[position] == fingerprint) { table[position] = 0; removed = true; break; }
                }
            }
            statuses[operation] = removed ? 1 : 0;
        }
    }
    for (usz i = 0; i < count; i++) write_i64(output, i, statuses[i]);
    return (long)required;
}
