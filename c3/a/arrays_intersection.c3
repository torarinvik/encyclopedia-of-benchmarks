module arrays_intersection;

const usz ARRAY_COUNT = 3;
const usz MAX_ARRAY_LENGTH = 64;
const usz MAX_INPUT_LENGTH = 195;
const usz MAX_OCCURRENCES = 192;
const usz TABLE_SIZE = 257;

fn void add_occurrence(long value, long* keys, usz* counts, bool* occupied,
                       usz* order, usz* order_length) {
    long remainder = value % 257;
    if (remainder < 0) remainder += 257;
    usz slot = (usz)remainder;
    while (occupied[slot] && keys[slot] != value) slot = (slot + 1) % TABLE_SIZE;
    if (!occupied[slot]) {
        occupied[slot] = true;
        keys[slot] = value;
        counts[slot] = 0;
        order[*order_length] = slot;
        (*order_length) += 1;
    }
    counts[slot] += 1;
}

fn void store_i32_le(char* output, usz position, long value) {
    uint bits = (uint)(int)value;
    for (usz byte = 0; byte < 4; byte++) output[position + byte] = (char)((bits >> (byte * 8)) & 255);
}

// Count all occurrences and emit keys whose aggregate count is exactly three.
fn long arrays_intersection(long* input, usz length, char* output, usz output_capacity)
    @export("arrays_intersection") {
    if (input == null || length < ARRAY_COUNT || length > MAX_INPUT_LENGTH) return -1;
    usz[ARRAY_COUNT] starts;
    usz[ARRAY_COUNT] sizes;
    usz position = 0;
    for (usz array = 0; array < ARRAY_COUNT; array++) {
        if (position >= length || input[position] < 0 || input[position] > (long)MAX_ARRAY_LENGTH) return -1;
        usz size = (usz)input[position];
        position++;
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (usz index = 0; index < size; index++) {
            if (input[position + index] < -2147483648L || input[position + index] > 2147483647L) return -1;
        }
        position += size;
    }
    if (position != length) return -1;

    long[TABLE_SIZE] keys;
    usz[TABLE_SIZE] counts;
    bool[TABLE_SIZE] occupied;
    usz[MAX_OCCURRENCES] order;
    for (usz index = 0; index < TABLE_SIZE; index++) {
        counts[index] = 0;
        occupied[index] = false;
    }
    usz order_length = 0;
    for (usz array = 0; array < ARRAY_COUNT; array++) {
        for (usz index = 0; index < sizes[array]; index++) {
            add_occurrence(input[starts[array] + index], &keys[0], &counts[0], &occupied[0], &order[0], &order_length);
        }
    }

    usz match_count = 0;
    for (usz index = 0; index < order_length; index++)
        if (counts[order[index]] == ARRAY_COUNT) match_count++;
    usz required = match_count * 4;
    if (output_capacity < required || (match_count > 0 && output == null)) return -2;
    usz written = 0;
    for (usz index = 0; index < order_length; index++) {
        usz slot = order[index];
        if (counts[slot] == ARRAY_COUNT) {
            store_i32_le(output, written * 4, keys[slot]);
            written++;
        }
    }
    return (long)written;
}
