module table_list;

const usz MAX_INPUT_LENGTH = 98;
const usz MAX_OUTPUT_FIELDS = 594;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;

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

long table_list(long* input, usz length, char* output, usz output_capacity) @export("table_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long operation_count = input[0];
    if (operation_count < 0 || operation_count > 32 || length != 1 + 3 * (usz)operation_count) return -1;
    long[64] items;
    long[MAX_OUTPUT_FIELDS] records;
    usz head = 32, item_count = 0, record_count = 0, cursor = 1;
    for (long step = 0; step < operation_count; step += 1) {
        long opcode = input[cursor++], arg1 = input[cursor++], arg2 = input[cursor++];
        switch (opcode) {
        case 0:
            if (arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32) return -1;
            items[--head] = arg1;
            item_count += 1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0);
            break;
        case 1:
            if (arg1 < MIN_VALUE || arg1 > MAX_VALUE || arg2 != 0 || item_count >= 32) return -1;
            items[head + item_count++] = arg1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0);
            break;
        case 2:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode);
            if (item_count == 0) append(&records[0], &record_count, 0);
            else { append(&records[0], &record_count, 1); append(&records[0], &record_count, items[head++]); item_count -= 1; }
            break;
        case 3:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode);
            if (item_count == 0) append(&records[0], &record_count, 0);
            else { append(&records[0], &record_count, 1); item_count -= 1; append(&records[0], &record_count, items[head + item_count]); }
            break;
        case 4:
        case 5:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode);
            if (item_count == 0) append(&records[0], &record_count, 0);
            else { append(&records[0], &record_count, 1); append(&records[0], &record_count, opcode == 4 ? items[head] : items[head + item_count - 1]); }
            break;
        case 6:
            if (arg2 != 0 || arg1 < 1 || (ulong)arg1 > item_count) return -1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1);
            append(&records[0], &record_count, items[head + (usz)arg1 - 1]);
            break;
        case 7:
            if (arg1 < 1 || (ulong)arg1 > item_count || arg2 < MIN_VALUE || arg2 > MAX_VALUE) return -1;
            items[head + (usz)arg1 - 1] = arg2;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 0);
            break;
        case 8:
            if (arg1 < -1 || arg1 > 33 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1);
            append(&records[0], &record_count, arg1 >= 1 && (ulong)arg1 <= item_count ? 1 : 0);
            break;
        case 9:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, 1); append(&records[0], &record_count, (long)item_count);
            break;
        case 10:
        case 11:
            if (arg1 != 0 || arg2 != 0) return -1;
            append(&records[0], &record_count, opcode); append(&records[0], &record_count, (long)item_count);
            for (usz offset = 0; offset < item_count; offset += 1) {
                usz logical = opcode == 10 ? offset + 1 : item_count - offset;
                append(&records[0], &record_count, (long)logical);
                append(&records[0], &record_count, items[head + logical - 1]);
            }
            break;
        default: return -1;
        }
    }
    append(&records[0], &record_count, 12); append(&records[0], &record_count, (long)item_count);
    for (usz index = 0; index < item_count; index += 1) append(&records[0], &record_count, items[head + index]);
    usz output_bytes = record_count * 8;
    if (output == null || output_capacity < output_bytes) return -2;
    for (usz index = 0; index < record_count; index += 1) write_i64_le(output, index * 8, records[index]);
    return (long)output_bytes;
}
