module choiceset;

const MAX_OPERATIONS = 1024;
const MAX_ELEMENTS = 256;
const HASH_CAPACITY = 512;
const long MAX_KEY = 1000000000L;

fn usz hash_slot(int value) {
    ulong mixed = (ulong)(uint)value * 2654435761UL;
    return (usz)(((uint)mixed) >> 23);
}

fn usz find_slot(int* keys, int* states, int value) {
    usz slot = hash_slot(value);
    usz deleted = HASH_CAPACITY;
    for (usz probes = 0; probes < HASH_CAPACITY; probes++) {
        if (states[slot] == 0) return deleted < HASH_CAPACITY ? deleted : slot;
        if (states[slot] == 2) {
            if (deleted == HASH_CAPACITY) deleted = slot;
        } else if (keys[slot] == value) return slot;
        slot = (slot + 1) % HASH_CAPACITY;
    }
    return deleted;
}

fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn long choiceset(long* values, usz length, char* output, usz capacity)
    @export("choiceset") {
    if (values == null || length < 1 || values[0] < 0 || values[0] > MAX_OPERATIONS) return -1;
    usz operation_count = (usz)values[0];
    if (length != 1 + 2 * operation_count) return -1;
    usz output_bytes = operation_count * 8;

    int[MAX_ELEMENTS] elements;
    int[HASH_CAPACITY] map_keys;
    int[HASH_CAPACITY] map_indices;
    int[HASH_CAPACITY] states;
    long[MAX_OPERATIONS] results;
    usz element_count = 0;
    for (usz slot = 0; slot < HASH_CAPACITY; slot++) states[slot] = 0;
    for (usz operation_index = 0; operation_index < operation_count; operation_index++) {
        long operation = values[1 + 2 * operation_index];
        long argument = values[2 + 2 * operation_index];
        if (operation >= 1 && operation <= 3) {
            if (argument < -MAX_KEY || argument > MAX_KEY) return -1;
            int key = (int)argument;
            usz slot = find_slot(&map_keys[0], &states[0], key);
            bool found = states[slot] == 1 && map_keys[slot] == key;
            if (operation == 1) {
                if (found) {
                    results[operation_index] = 0;
                } else {
                    if (element_count == MAX_ELEMENTS || slot >= HASH_CAPACITY) return -1;
                    elements[element_count] = key;
                    map_keys[slot] = key;
                    map_indices[slot] = (int)element_count;
                    states[slot] = 1;
                    element_count++;
                    results[operation_index] = 1;
                }
            } else if (operation == 2) {
                results[operation_index] = found ? 1 : 0;
            } else if (!found) {
                results[operation_index] = 0;
            } else {
                usz index = (usz)map_indices[slot];
                usz last = element_count - 1;
                if (index != last) {
                    int moved = elements[last];
                    usz moved_slot = find_slot(&map_keys[0], &states[0], moved);
                    if (states[moved_slot] != 1 || map_keys[moved_slot] != moved) return -1;
                    elements[index] = moved;
                    map_indices[moved_slot] = (int)index;
                }
                element_count--;
                states[slot] = 2;
                results[operation_index] = 1;
            }
        } else if (operation == 4) {
            if (argument < 1 || (ulong)argument > element_count) return -1;
            results[operation_index] = elements[(usz)argument - 1];
        } else {
            return -1;
        }
    }
    if (capacity < output_bytes || (output_bytes > 0 && output == null)) return -2;
    for (usz index = 0; index < operation_count; index++) put_i64_le(results[index], output, index * 8);
    return (long)output_bytes;
}
