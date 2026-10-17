module list_array;

fn void put_i64_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz i = 0; i < 8; i++) { output[offset + i] = (uint8)(bits >> (8 * i)); }
}

fn long list_array(long* input, usz length, uint8* output, usz output_capacity) @export("list_array") {
    if (input == null || length < 2 || length > 130) { return -1; }
    long capacity_value = input[0], operation_count_value = input[1];
    if (capacity_value < 1 || capacity_value > 16 || operation_count_value < 1 || operation_count_value > 64) { return -1; }
    usz capacity = (usz)capacity_value, operations = (usz)operation_count_value;
    if (length != 2 + 2 * operations) { return -1; }

    long[64] opcodes = {0}, arguments = {0};
    bool sorted = false;
    for (usz i = 0; i < operations; i++) {
        long opcode = input[2 + 2 * i], argument = input[3 + 2 * i];
        if (opcode == 0) {
            if (sorted || argument < 0) { return -1; }
        } else if (opcode == 1) {
            if (sorted || argument != 0) { return -1; }
            sorted = true;
        } else if (opcode == 2 || opcode == 3) {
            if (!sorted || argument < 0) { return -1; }
        } else { return -1; }
        opcodes[i] = opcode;
        arguments[i] = argument;
    }
    if (!sorted) { return -1; }

    ulong[16] items = {0};
    long[64] results = {0};
    long[65] output_words = {0};
    usz count = 0, result_count = 0;
    for (usz i = 0; i < operations; i++) {
        long opcode = opcodes[i], argument = arguments[i];
        if (opcode == 0) {
            if (count == capacity) { return -1; }
            items[count] = (ulong)argument;
            count++;
        } else if (opcode == 1) {
            for (usz a = 0; a < count; a++) {
                usz minimum = a;
                for (usz b = a + 1; b < count; b++) { if (items[b] < items[minimum]) { minimum = b; } }
                ulong value = items[minimum];
                items[minimum] = items[a];
                items[a] = value;
            }
        } else {
            if (count == 0 || (ulong)argument < items[0]) { return -1; }
            if (opcode == 3 && count >= capacity) { return -1; }
            long first = 0, last = (long)count - 1, position = -1;
            while (first <= last) {
                long middle = (first + last) / 2;
                ulong value = items[(usz)middle];
                if (value == (ulong)argument) { position = middle; break; }
                if ((ulong)argument < value) { last = middle - 1; }
                else { first = middle + 1; }
            }
            results[result_count++] = position;
            if (opcode == 3 && position >= 0) {
                usz j = (usz)position;
                while (j < count) { items[j] = items[j + 1]; j++; }
                count--;
            }
        }
    }

    usz word_count = 0;
    output_words[word_count++] = (long)result_count;
    for (usz i = 0; i < result_count; i++) { output_words[word_count++] = results[i]; }
    output_words[word_count++] = (long)count;
    for (usz i = 0; i < count; i++) { output_words[word_count++] = (long)items[i]; }
    usz required = word_count * 8;
    if (output == null || output_capacity < required) { return -2; }
    for (usz i = 0; i < word_count; i++) { put_i64_le(output, i * 8, output_words[i]); }
    return (long)required;
}
