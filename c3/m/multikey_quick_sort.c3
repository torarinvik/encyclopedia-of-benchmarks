module multikey_quick_sort;

const usz MAX_STRINGS = 32;
const usz MAX_STRING_LENGTH = 16;
const usz MAX_INPUT_WORDS = 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH);
const usz MAX_PARSEABLE_INPUT_WORDS = MAX_INPUT_WORDS + 1;
const usz MAX_OUTPUT_BYTES = 4 * MAX_INPUT_WORDS;

struct StringRecord { int length; char[16] bytes; }

fn int char_at(StringRecord value, int depth) {
    if (depth < value.length) return (uint)value.bytes[depth] & 255;
    return 0;
}
fn int median3(int a, int b, int c) {
    if (a < b) return b < c ? b : (a < c ? c : a);
    return b > c ? b : (a < c ? a : c);
}
fn int compare_from_depth(StringRecord left, StringRecord right, int depth) {
    while (depth < left.length && depth < right.length && left.bytes[depth] == right.bytes[depth]) depth += 1;
    int a = char_at(left, depth), b = char_at(right, depth);
    return (a > b) - (a < b);
}
fn void insertion_sort(StringRecord* values, int lo, int hi, int depth) {
    for (int i = lo + 1; i < hi; i += 1) {
        StringRecord value = values[i];
        int j = i;
        while (j > lo && compare_from_depth(values[j - 1], value, depth) > 0) { values[j] = values[j - 1]; j -= 1; }
        values[j] = value;
    }
}
fn void multikey_sort(StringRecord* values, int lo, int hi, int depth) {
    int count = hi - lo;
    if (count < 10) { insertion_sort(values, lo, hi, depth); return; }
    int mid = lo + count / 2, pivot;
    if (count > 30) {
        int delta = count / 8;
        pivot = median3(
            median3(char_at(values[lo], depth), char_at(values[lo + delta], depth), char_at(values[lo + 2 * delta], depth)),
            median3(char_at(values[mid - delta], depth), char_at(values[mid], depth), char_at(values[mid + delta], depth)),
            median3(char_at(values[hi - 1 - 2 * delta], depth), char_at(values[hi - 1 - delta], depth), char_at(values[hi - 1], depth)));
    } else pivot = median3(char_at(values[lo], depth), char_at(values[mid], depth), char_at(values[hi - 1], depth));
    int less = lo, scan = lo, greater = hi;
    while (scan < greater) {
        int key = char_at(values[scan], depth);
        if (key < pivot) { StringRecord tmp = values[less]; values[less++] = values[scan]; values[scan++] = tmp; }
        else if (key > pivot) { greater -= 1; StringRecord tmp = values[greater]; values[greater] = values[scan]; values[scan] = tmp; }
        else scan += 1;
    }
    multikey_sort(values, lo, less, depth);
    if (pivot != 0) multikey_sort(values, less, greater, depth + 1);
    multikey_sort(values, greater, hi, depth);
}
fn void put_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

long multikey_quick_sort(int* input, usz length, char* output, usz capacity)
        @export("multikey_quick_sort") {
    if (input == null || length < 1 || length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    int count = input[0];
    if (count < 0 || count > 32) return -1;
    StringRecord[32] values;
    usz pos = 1;
    for (int i = 0; i < count; i += 1) {
        if (pos >= length || input[pos] < 0 || input[pos] > 16) return -1;
        int string_length = input[pos++];
        if (pos + (usz)string_length > length) return -1;
        values[i].length = string_length;
        for (int j = 0; j < string_length; j += 1) {
            int byte = input[pos++];
            if (byte < 1 || byte > 127) return -1;
            values[i].bytes[j] = (char)byte;
        }
    }
    if (pos != length) return -1;
    usz bytes = length * 4;
    if (output == null || capacity < bytes) return -2;
    multikey_sort(&values[0], 0, count, 0);
    char[2180] buffer;
    usz word = 0;
    put_i32_le(&buffer[0], word++ * 4, count);
    for (int i = 0; i < count; i += 1) {
        put_i32_le(&buffer[0], word++ * 4, values[i].length);
        for (int j = 0; j < values[i].length; j += 1) put_i32_le(&buffer[0], word++ * 4, (uint)values[i].bytes[j] & 255);
    }
    for (usz i = 0; i < bytes; i += 1) output[i] = buffer[i];
    return (long)bytes;
}
