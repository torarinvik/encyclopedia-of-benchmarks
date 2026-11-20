module bond_sequential_search;

const usz MAX_N = 64;
const long MAX_VALUE = 255;
const long ABSENT_CODE = 64;
const long PACK_BASE = 65;

fn long bond_sequential_search(long* input, usz length) @export("bond_sequential_search") {
    if (input == null || length < 3 || length > 68) return -1;
    long count_value = input[0];
    long key_a = input[1];
    long key_b = input[2];
    if (count_value < 0 || count_value > (long)MAX_N || length != (usz)count_value + 3
            || key_a < 0 || key_a > MAX_VALUE || key_b < 0 || key_b > MAX_VALUE
            || key_a == key_b) return -1;

    usz count = (usz)count_value;
    for (usz i = 0; i < count; i++) {
        long value = input[i + 3];
        if (value < 0 || value > MAX_VALUE) return -1;
    }

    long index_a = ABSENT_CODE;
    long index_b = ABSENT_CODE;
    long composite = key_a | key_b;
    for (usz i = 0; i < count && (index_a == ABSENT_CODE || index_b == ABSENT_CODE); i++) {
        long value = input[i + 3];
        if ((value & composite) != value) continue;
        if (index_a == ABSENT_CODE && value == key_a) index_a = (long)i;
        if (index_b == ABSENT_CODE && value == key_b) index_b = (long)i;
    }
    return index_a * PACK_BASE + index_b;
}
