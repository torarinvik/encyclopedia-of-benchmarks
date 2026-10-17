module lru;

const usz MAX_INPUT_LENGTH = 99;
const usz MAX_OPERATIONS = 32;
const usz MAX_CAPACITY = 16;
const usz MAX_OUTPUT_FIELDS = 114;

fn void append(long* records, usz* count, long value) {
    records[*count] = value;
    *count += 1;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long lru(long* input, usz length, char* output, usz output_capacity) @export("lru") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long capacity_value = input[0];
    long operation_count = input[1];
    if (capacity_value < 2 || capacity_value > 16 || operation_count < 0 || operation_count > 32 || length != 2 + 3 * (usz)operation_count) return -1;
    usz capacity = (usz)capacity_value;

    long[MAX_CAPACITY] keys;
    long[MAX_CAPACITY] values;
    long[MAX_OPERATIONS] seen;
    usz[MAX_CAPACITY] order;
    long[MAX_OUTPUT_FIELDS] records;
    usz cache_count = 0, seen_count = 0, record_count = 0, cursor = 2;
    for (long step = 0; step < operation_count; step += 1) {
        long opcode = input[cursor++];
        long key = input[cursor++];
        long value = input[cursor++];
        if (key < -1000000 || key > 1000000) return -1;
        if (opcode == 0) {
            if (value < -1000000 || value > 1000000) return -1;
            for (usz index = 0; index < seen_count; index += 1)
                if (seen[index] == key) return -1;
            seen[seen_count++] = key;
            usz slot;
            if (cache_count == capacity) {
                slot = order[0];
                for (usz index = 0; index + 1 < cache_count; index += 1) order[index] = order[index + 1];
                cache_count -= 1;
            } else {
                slot = cache_count;
            }
            keys[slot] = key;
            values[slot] = value;
            order[cache_count++] = slot;
            append(&records[0], &record_count, 0);
            append(&records[0], &record_count, 0);
        } else if (opcode == 1) {
            if (value != 0) return -1;
            usz position = 0;
            while (position < cache_count && keys[order[position]] != key) position += 1;
            if (position == cache_count) return -1;
            usz slot = order[position];
            long cached_value = values[slot];
            for (usz index = position; index + 1 < cache_count; index += 1) order[index] = order[index + 1];
            order[cache_count - 1] = slot;
            append(&records[0], &record_count, 1);
            append(&records[0], &record_count, 1);
            append(&records[0], &record_count, cached_value);
        } else {
            return -1;
        }
    }
    append(&records[0], &record_count, 2);
    append(&records[0], &record_count, (long)cache_count);
    for (usz index = 0; index < cache_count; index += 1) {
        usz slot = order[index];
        append(&records[0], &record_count, keys[slot]);
        append(&records[0], &record_count, values[slot]);
    }
    usz output_bytes = record_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < record_count; index += 1) write_i64_le(output, index * 8, records[index]);
    return (long)output_bytes;
}
