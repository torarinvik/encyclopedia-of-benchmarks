module stack_tracking_min_max;

fn void put64(char* output, usz* position, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[*position] = (char)(bits & 255);
        *position += 1;
        bits >>= 8;
    }
}

fn long stack_tracking_min_max(long* input, usz length, char* output, usz capacity)
    @export("stack_tracking_min_max") {
    if (input == null || length < 2 || length > 130) return -1;
    long max_size = input[0];
    long op_count = input[1];
    if (max_size < 0 || max_size > 64 || op_count < 0 || op_count > 64) return -1;
    usz cursor = 2;
    for (long i = 0; i < op_count; i++) {
        if (cursor >= length) return -1;
        long op = input[cursor++];
        if (op == 1) {
            if (cursor >= length || input[cursor] < -2147483648 || input[cursor] > 2147483647) return -1;
            cursor++;
        } else if (op < 2 || op > 5) {
            return -1;
        }
    }
    if (cursor != length) return -1;

    long[64] values, minima, maxima;
    long[192] records;
    usz top = 0;
    usz record_count = 0;
    cursor = 2;
    for (long i = 0; i < op_count; i++) {
        long op = input[cursor++];
        long tag = 0;
        long result = 0;
        if (op == 1) {
            long value = input[cursor++];
            if (top == (usz)max_size) {
                records[record_count * 3] = 1;
                records[record_count * 3 + 1] = 4;
                records[record_count * 3 + 2] = 1;
                record_count++;
                break;
            }
            values[top] = value;
            minima[top] = top != 0 && minima[top - 1] < value ? minima[top - 1] : value;
            maxima[top] = top != 0 && maxima[top - 1] > value ? maxima[top - 1] : value;
            top++;
            tag = 1;
            result = 1;
        } else if (op == 2) {
            if (top != 0) {
                result = values[--top];
            } else {
                tag = 3;
            }
        } else if (op == 3) {
            if (top != 0) {
                result = minima[top - 1];
            } else {
                tag = 3;
            }
        } else if (op == 4) {
            if (top != 0) {
                result = maxima[top - 1];
            } else {
                tag = 3;
            }
        } else {
            tag = 1;
            result = top != 0 ? 1 : 0;
        }
        records[record_count * 3] = op;
        records[record_count * 3 + 1] = tag;
        records[record_count * 3 + 2] = result;
        record_count++;
    }
    usz needed = record_count * 24;
    if (output == null || capacity < needed) return -2;
    usz position = 0;
    for (usz i = 0; i < record_count * 3; i++) put64(output, &position, records[i]);
    return (long)position;
}
