module suffix_array_sais;

const usz MAX_TEXT_LENGTH = 32;
const usz MAX_INPUT_LENGTH = 34;
const int MAX_ALPHABET = 256;

fn void induce(int* symbols, int length, int upper, bool* is_s,
               int* sum_s, int* sum_l, int* lms, int lms_count,
               int* suffixes) {
    int[MAX_ALPHABET + 2] bucket = zeroed;
    for (int i = 0; i < length; i++) suffixes[i] = -1;
    for (int i = 0; i <= upper + 1; i++) bucket[i] = sum_s[i];
    for (int i = 0; i < lms_count; i++) {
        int position = lms[i];
        suffixes[bucket[symbols[position]]++] = position;
    }
    for (int i = 0; i <= upper + 1; i++) bucket[i] = sum_l[i];
    for (int i = 0; i < length; i++) {
        int position = suffixes[i];
        if (position > 0 && !is_s[position - 1]) {
            int symbol = symbols[position - 1];
            suffixes[bucket[symbol]++] = position - 1;
        }
    }
    for (int i = 0; i <= upper + 1; i++) bucket[i] = sum_l[i];
    for (int i = length - 1; i >= 0; i--) {
        int position = suffixes[i];
        if (position > 0 && is_s[position - 1]) {
            int symbol = symbols[position - 1] + 1;
            suffixes[--bucket[symbol]] = position - 1;
        }
    }
}

fn bool same_lms(int* symbols, bool* is_s, int* lms_map,
                 int length, int left, int right) {
    if (left == right) return true;
    for (int offset = 0; offset < length; offset++) {
        int a = left + offset, b = right + offset;
        if (a >= length || b >= length || symbols[a] != symbols[b] || is_s[a] != is_s[b]) return false;
        bool a_lms = offset > 0 && lms_map[a] >= 0;
        bool b_lms = offset > 0 && lms_map[b] >= 0;
        if (a_lms || b_lms) return a_lms && b_lms;
    }
    return false;
}

fn void sais(int* symbols, int length, int upper, int* suffixes) {
    if (length == 0) return;
    if (length <= 2) {
        for (int i = 0; i < length; i++) suffixes[i] = i;
        if (length == 2 && symbols[0] >= symbols[1]) {
            suffixes[0] = 1;
            suffixes[1] = 0;
        }
        return;
    }

    bool[MAX_TEXT_LENGTH + 1] is_s = zeroed;
    is_s[length - 1] = 1;
    for (int i = length - 2; i >= 0; i--)
        is_s[i] = symbols[i] < symbols[i + 1] || (symbols[i] == symbols[i + 1] && is_s[i + 1]);

    int[MAX_TEXT_LENGTH + 2] lms_map = zeroed;
    int[MAX_TEXT_LENGTH + 1] lms = zeroed;
    for (int i = 0; i <= length; i++) lms_map[i] = -1;
    int lms_count = 0;
    for (int i = 1; i < length; i++) {
        if (!is_s[i - 1] && is_s[i]) {
            lms_map[i] = lms_count;
            lms[lms_count++] = i;
        }
    }

    int[MAX_ALPHABET + 2] sum_s = zeroed;
    int[MAX_ALPHABET + 2] sum_l = zeroed;
    for (int i = 0; i < length; i++) {
        int symbol = symbols[i];
        if (is_s[i]) sum_l[symbol + 1]++;
        else sum_s[symbol]++;
    }
    for (int symbol = 0; symbol <= upper; symbol++) {
        sum_s[symbol] += sum_l[symbol];
        sum_l[symbol + 1] += sum_s[symbol];
    }

    induce(&symbols[0], length, upper, &is_s[0], &sum_s[0], &sum_l[0], &lms[0], lms_count, &suffixes[0]);
    int[MAX_TEXT_LENGTH + 1] sorted_lms = zeroed;
    int sorted_count = 0;
    for (int i = 0; i < length; i++) {
        int position = suffixes[i];
        if (position >= 0 && lms_map[position] >= 0) sorted_lms[sorted_count++] = position;
    }

    int[MAX_TEXT_LENGTH + 1] reduced = zeroed;
    int reduced_upper = 0;
    for (int i = 0; i < sorted_count; i++) {
        if (i > 0 && !same_lms(&symbols[0], &is_s[0], &lms_map[0], length,
                               sorted_lms[i - 1], sorted_lms[i])) reduced_upper++;
        reduced[lms_map[sorted_lms[i]]] = reduced_upper;
    }
    int[MAX_TEXT_LENGTH + 1] reduced_order = zeroed;
    if (reduced_upper + 1 == sorted_count) {
        for (int i = 0; i < sorted_count; i++) reduced_order[reduced[i]] = i;
    } else {
        sais(&reduced[0], sorted_count, reduced_upper, &reduced_order[0]);
    }
    int[MAX_TEXT_LENGTH + 1] ordered_lms = zeroed;
    for (int i = 0; i < sorted_count; i++) ordered_lms[i] = lms[reduced_order[i]];
    induce(&symbols[0], length, upper, &is_s[0], &sum_s[0], &sum_l[0],
           &ordered_lms[0], sorted_count, &suffixes[0]);
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long suffix_array_sais(long* values, usz length, char* output, usz capacity)
        @export("suffix_array_sais") {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long count_value = values[0];
    if (count_value < 0 || count_value > 32) return -1;
    int count = (int)count_value;
    if (length != (usz)count + 1) return -1;
    for (int i = 0; i < count; i++) if (values[i + 1] < 0 || values[i + 1] > 255) return -1;
    usz output_bytes = (usz)count * 8;
    if (output == null || capacity < output_bytes) return -2;
    int[MAX_TEXT_LENGTH + 1] symbols = zeroed;
    for (int i = 0; i < count; i++) symbols[i] = (int)values[i + 1] + 1;
    symbols[count] = 0;
    int[MAX_TEXT_LENGTH + 1] suffixes = zeroed;
    sais(&symbols[0], count + 1, 256, &suffixes[0]);
    int out = 0;
    for (int i = 0; i <= count; i++) {
        if (suffixes[i] == count) continue;
        store_i64_le(output, (usz)out++ * 8, suffixes[i]);
    }
    return (long)output_bytes;
}
