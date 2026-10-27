module frequent_itemset_delivery;

const long MAX_ITEMS = 8;
const long MAX_ROWS = 64;
const usz MAX_INPUT = 69;
const usz MAX_OUTPUT = 200;

fn void put_u64(uint8* output, usz word, ulong value) {
    for (usz byte = 0; byte < 8; byte++) output[word * 8 + byte] = (uint8)(value >> (8 * byte));
}

fn long frequent_itemset_delivery(long* input, usz length, uint8* output, usz capacity)
    @export("frequent_itemset_delivery") {
    if (input == null || length < 6 || length > MAX_INPUT) return -1;
    long n0 = input[0], m0 = input[1], minimum = input[2], tail = input[3], prefix0 = input[4];
    if (n0 < 1 || n0 > MAX_ITEMS || m0 < 1 || m0 > MAX_ROWS || minimum < 1 || minimum > m0 || length != (usz)(5 + m0)) return -1;
    if (tail < -1 || tail >= n0 || prefix0 < 0) return -1;
    usz n = (usz)n0, rows = (usz)m0;
    ulong limit = (ulong)1 << n, prefix = (ulong)prefix0;
    if (prefix >= limit || (tail == -1 && prefix != 0) ||
        (tail >= 0 && (((prefix >> (usz)tail) & 1) == 0 || (prefix >> ((usz)tail + 1)) != 0))) return -1;
    ulong[8] occurrences;
    ulong[8] supports;
    for (usz item = 0; item < n; item++) { occurrences[item] = 0; supports[item] = 0; }
    for (usz row = 0; row < rows; row++) {
        long row0 = input[5 + row];
        if (row0 < 0 || (ulong)row0 >= limit) return -1;
        ulong mask = (ulong)row0;
        if ((mask & prefix) != prefix) continue;
        for (usz item = (usz)(tail + 1); item < n; item++) {
            if ((mask & ((ulong)1 << item)) != 0) {
                occurrences[item] |= (ulong)1 << row;
                supports[item]++;
            }
        }
    }
    ulong[25] words;
    for (usz word = 0; word < 25; word++) words[word] = 0;
    usz records = 0;
    for (usz item = (usz)(tail + 1); item < n; item++) {
        if (supports[item] < (ulong)minimum) continue;
        usz at = 1 + 3 * records;
        words[at] = item; words[at + 1] = occurrences[item]; words[at + 2] = supports[item];
        records++;
    }
    words[0] = records;
    usz word_count = 1 + 3 * records, bytes = 8 * word_count;
    if (bytes > MAX_OUTPUT) return -1;
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < word_count; word++) put_u64(output, word, words[word]);
    return (long)bytes;
}
