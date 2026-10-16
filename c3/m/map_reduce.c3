module map_reduce;

const usz MAX_INPUT = 256;
const usz MAX_WORDS = 128;
const usz TABLE_SIZE = 512;

fn bool is_space_byte(long value) {
    return value == 9 || value == 10 || value == 11 || value == 12 || value == 13 || value == 32;
}

fn usz token_hash(long* input, usz start, usz length) {
    usz hash = 0;
    for (usz offset = 0; offset < length; offset++)
        hash = (hash * 31 + (usz)input[start + offset]) % 1000003;
    return hash;
}

fn bool token_equal(long* input, usz start, usz length, usz other_start, usz other_length) {
    if (length != other_length) return false;
    for (usz offset = 0; offset < length; offset++)
        if (input[start + offset] != input[other_start + offset]) return false;
    return true;
}

fn usz write_count(char* output, usz position, usz count) {
    char digits[3];
    usz digit_count = 0;
    do {
        digits[digit_count++] = (char)('0' + count % 10);
        count /= 10;
    } while (count != 0);
    while (digit_count != 0) output[position++] = digits[--digit_count];
    return position;
}

fn long map_reduce(long* input, usz length, char* output, usz output_capacity)
        @export("map_reduce") {
    if (length > MAX_INPUT || (length != 0 && input == null)) return -1;
    for (usz index = 0; index < length; index++) {
        long value = input[index];
        if (!is_space_byte(value) && (value < 32 || value > 126)) return -1;
    }

    usz starts[MAX_WORDS];
    usz lengths[MAX_WORDS];
    usz counts[MAX_WORDS] = {0};
    usz table[TABLE_SIZE] = {0};
    usz unique_count = 0, begin = 0, end = length;
    while (begin < end && input[begin] <= 32) begin++;
    while (end > begin && input[end - 1] <= 32) end--;

    if (begin == end) {
        starts[0] = 0; lengths[0] = 0; counts[0] = 1; unique_count = 1;
        table[0] = 1;
    } else {
        usz cursor = begin;
        while (cursor < end) {
            while (cursor < end && is_space_byte(input[cursor])) cursor++;
            if (cursor == end) break;
            usz start = cursor;
            while (cursor < end && !is_space_byte(input[cursor])) cursor++;
            usz token_length = cursor - start;
            usz slot = token_hash(input, start, token_length) % TABLE_SIZE;
            while (table[slot] != 0) {
                usz item = table[slot] - 1;
                if (token_equal(input, start, token_length, starts[item], lengths[item])) {
                    counts[item]++;
                    break;
                }
                slot = (slot + 1) % TABLE_SIZE;
            }
            if (table[slot] == 0) {
                starts[unique_count] = start; lengths[unique_count] = token_length;
                counts[unique_count] = 1; table[slot] = unique_count + 1; unique_count++;
            }
        }
    }

    usz required = 0;
    for (usz item = 0; item < unique_count; item++) {
        usz digits = 1, value = counts[item];
        while (value >= 10) { value /= 10; digits++; }
        required += lengths[item] + 2 + digits + (item != 0 ? 1 : 0);
    }
    if (output == null || output_capacity < required) return -2;

    usz written = 0;
    for (usz item = 0; item < unique_count; item++) {
        if (item != 0) output[written++] = ',';
        for (usz offset = 0; offset < lengths[item]; offset++)
            output[written++] = (char)input[starts[item] + offset];
        output[written++] = ':'; output[written++] = ' ';
        written = write_count(output, written, counts[item]);
    }
    return (long)written;
}
