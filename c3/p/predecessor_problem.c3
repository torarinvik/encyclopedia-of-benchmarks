module predecessor_problem;

const usz MAX_N = 4096;
const usz MAX_WORDS = 64;
const usz MAX_QUERIES = 512;
const usz MAX_INPUT_LENGTH = 1090;
const usz MAX_OUTPUT_BYTES = 4096;

fn long find_next(ulong* words, usz word_count, usz n, usz key) {
    usz first_word = key / 64;
    for (usz word = first_word; word < word_count; word++) {
        usz first_bit = word == first_word ? key % 64 : 0;
        ulong candidates = words[word];
        if (first_bit != 0) candidates &= 18446744073709551615ul << first_bit;
        if (candidates == 0) continue;
        usz end_bit = (word + 1) * 64 < n ? 64 : n - word * 64;
        for (usz bit = first_bit; bit < end_bit; bit++)
            if (((candidates >> bit) & 1ul) != 0) return (long)(word * 64 + bit);
    }
    return -1;
}

fn long find_previous(ulong* words, usz n, usz key) {
    usz first_word = key / 64;
    usz word = first_word + 1;
    while (word > 0) {
        word--;
        usz valid_bits = (word + 1) * 64 > n ? n - word * 64 : 64;
        usz requested_end = word == first_word ? key % 64 + 1 : valid_bits;
        usz end_bit = requested_end < valid_bits ? requested_end : valid_bits;
        ulong mask = end_bit == 64 ? 18446744073709551615ul : ((1ul << end_bit) - 1);
        ulong candidates = words[word] & mask;
        if (candidates != 0) {
            usz bit = end_bit;
            while (bit > 0) {
                bit--;
                if (((candidates >> bit) & 1ul) != 0) return (long)(word * 64 + bit);
            }
        }
    }
    return -1;
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255ul); bits >>= 8; }
}

fn long predecessor_problem(long* input, usz length, char* output, usz capacity)
    @export("predecessor_problem") {
    if (input == null || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    long n_value = input[0], query_value = input[1];
    if (n_value < 1 || n_value > MAX_N || query_value < 0 || query_value > MAX_QUERIES) return -1;
    usz n = (usz)n_value, queries = (usz)query_value;
    usz word_count = (n + 63) / 64, operation_offset = 2 + word_count;
    if (length != operation_offset + 2 * queries) return -1;
    ulong[MAX_WORDS] words;
    for (usz word = 0; word < word_count; word++) words[word] = (ulong)input[2 + word];
    usz tail_bits = n % 64;
    if (tail_bits != 0 && (words[word_count - 1] >> tail_bits) != 0) return -1;
    for (usz query = 0; query < queries; query++) {
        long operation = input[operation_offset + 2 * query];
        long key = input[operation_offset + 2 * query + 1];
        if (operation < 0 || operation > 4 || key < 0 || key >= n_value) return -1;
    }
    long[MAX_QUERIES] answers;
    usz answer_count = 0;
    for (usz query = 0; query < queries; query++) {
        long operation = input[operation_offset + 2 * query];
        usz key = (usz)input[operation_offset + 2 * query + 1], word = key / 64;
        ulong mask = 1ul << (key % 64);
        if (operation == 0) words[word] |= mask;
        else if (operation == 1) words[word] &= ~mask;
        else if (operation == 2) answers[answer_count++] = (words[word] & mask) != 0;
        else if (operation == 3) answers[answer_count++] = find_next(&words[0], word_count, n, key);
        else answers[answer_count++] = find_previous(&words[0], n, key);
    }
    usz output_bytes = answer_count * 8;
    if (output == null || capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged;
    for (usz index = 0; index < answer_count; index++) store_i64_le(&staged[0], index * 8, answers[index]);
    for (usz byte = 0; byte < output_bytes; byte++) output[byte] = staged[byte];
    return (long)output_bytes;
}
