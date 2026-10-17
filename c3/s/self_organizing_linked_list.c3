module self_organizing_linked_list;

const usz MAX_INPUT_LENGTH = 130;
const usz MAX_OPERATIONS = 64;
const usz MAX_LIST_LENGTH = 64;
const usz MAX_OUTPUT_FIELDS = 194;

fn void append_i64(long* records, usz* count, long value) {
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

long self_organizing_linked_list(long* input, usz length, char* output,
                                 usz output_capacity) @export("self_organizing_linked_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > 64
        || length != 1 + 2 * (usz)operation_count) return -1;

    long[MAX_LIST_LENGTH] items;
    long[MAX_OUTPUT_FIELDS] records;
    usz item_count = 0, record_count = 0, cursor = 1;
    for (long step = 0; step < operation_count; step += 1) {
        long opcode = input[cursor++];
        long value = input[cursor++];
        if (value < -2147483648 || value > 2147483647) return -1;
        if (opcode == 0) {
            if (item_count == MAX_LIST_LENGTH) return -1;
            items[item_count++] = value;
            append_i64(&records[0], &record_count, 0);
            append_i64(&records[0], &record_count, 0);
        } else if (opcode == 1) {
            usz found_at = 0;
            while (found_at < item_count && items[found_at] != value) found_at += 1;
            long found = found_at < item_count ? 1 : 0;
            append_i64(&records[0], &record_count, 1);
            append_i64(&records[0], &record_count, 1);
            append_i64(&records[0], &record_count, found);
            if (found != 0 && found_at != 0) {
                usz index = found_at;
                while (index > 0) {
                    items[index] = items[index - 1];
                    index -= 1;
                }
                items[0] = value;
            }
        } else {
            return -1;
        }
    }
    append_i64(&records[0], &record_count, 2);
    append_i64(&records[0], &record_count, (long)item_count);
    for (usz index = 0; index < item_count; index += 1)
        append_i64(&records[0], &record_count, items[index]);

    usz output_bytes = record_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < record_count; index += 1)
        write_i64_le(output, index * 8, records[index]);
    return (long)output_bytes;
}
