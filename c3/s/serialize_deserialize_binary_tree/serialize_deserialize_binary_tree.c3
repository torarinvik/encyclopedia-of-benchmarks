module serialize_deserialize_binary_tree;

const usz MAX_INPUT = 2200;
const usz MAX_NODES = 127;

fn bool ascii_space(long value) { return value == 32 || (value >= 9 && value <= 13); }

fn bool parse_integer(long* input, usz start, usz end, long* result) {
    while (start < end && ascii_space(input[start])) start++;
    while (end > start && ascii_space(input[end - 1])) end--;
    if (start == end) return false;
    bool negative = false;
    if (input[start] == '-' || input[start] == '+') { negative = input[start] == '-'; start++; }
    if (start == end) return false;
    long limit = negative ? 2147483648 : 2147483647;
    long magnitude = 0;
    for (usz i = start; i < end; i++) {
        if (input[i] < '0' || input[i] > '9') return false;
        long digit = input[i] - '0';
        if (magnitude > (limit - digit) / 10) return false;
        magnitude = magnitude * 10 + digit;
    }
    *result = negative ? -magnitude : magnitude;
    return true;
}

fn usz emit_integer(char* output, usz position, long value) {
    ulong magnitude;
    if (value < 0) { output[position++] = '-'; magnitude = (ulong)(-value); }
    else magnitude = (ulong)value;
    char[10] digits;
    usz count = 0;
    do { digits[count++] = (char)('0' + magnitude % 10); magnitude /= 10; } while (magnitude > 0);
    while (count > 0) output[position++] = digits[--count];
    return position;
}

fn long serialize_deserialize_binary_tree(long* values, usz length, char* output, usz output_capacity)
    @export("serialize_deserialize_binary_tree") {
    if (values == null || length == 0 || length > MAX_INPUT) return -1;
    for (usz i = 0; i < length; i++) if (values[i] < 0 || values[i] > 127) return -1;
    char[MAX_INPUT] encoded;
    usz written = 0, position = 0, slots = 1, nodes = 0;
    while (position < length) {
        if (slots == 0) return -1;
        usz start = position;
        while (position < length && values[position] != ',') position++;
        usz end = position;
        if (start == end) return -1;
        bool is_null = end - start == 4 && values[start] == 'n' && values[start + 1] == 'u' &&
                       values[start + 2] == 'l' && values[start + 3] == 'l';
        if (written > 0) encoded[written++] = ',';
        if (is_null) { encoded[written++] = 'n'; encoded[written++] = 'u'; encoded[written++] = 'l'; encoded[written++] = 'l'; }
        else {
            long number;
            if (!parse_integer(values, start, end, &number) || ++nodes > MAX_NODES) return -1;
            written = emit_integer(encoded, written, number);
        }
        slots--;
        if (!is_null) slots += 2;
        if (position < length) { position++; if (position == length) return -1; }
    }
    if (slots != 0) return -1;
    if (output == null || output_capacity < written) return -2;
    for (usz i = 0; i < written; i++) output[i] = encoded[i];
    return (long)written;
}
