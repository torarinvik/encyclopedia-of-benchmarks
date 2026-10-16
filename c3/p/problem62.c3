// Group cubes by sorted decimal digits and return the first cube in the target group.
module problem62;

const usz TABLE_SIZE = 16384;
const long MAX_BASE = 8384;
const long SIGNATURE_LENGTH_FACTOR = 4503599627370496;

fn long digit_signature(long cube) {
    long[10] counts = {0};
    long length = 0;
    if (cube == 0) {
        counts[0] = 1;
        length = 1;
    } else {
        while (cube > 0) {
            counts[(usz)(cube % 10)]++;
            length++;
            cube /= 10;
        }
    }
    long sorted_digits = 0;
    for (usz digit = 0; digit < 10; digit++) {
        for (long occurrence = 0; occurrence < counts[digit]; occurrence++)
            sorted_digits = sorted_digits * 16 + (long)digit;
    }
    return length * SIGNATURE_LENGTH_FACTOR + sorted_digits;
}

fn usz signature_slot(long key) {
    long size = (long)TABLE_SIZE;
    long hash = (key % size + (key / size % size) * 31 +
                 (key / (size * size) % size) * 17 +
                 (key / (size * size * size) % size) * 7) % size;
    return (usz)hash;
}

fn long problem62(long target_count) @export("problem62") {
    if (target_count < 1 || target_count > 5) return -1;
    long[16384] keys = {0};
    long[16384] first_cubes = {0};
    long[16384] counts = {0};

    for (long base = 0; base <= MAX_BASE; base++) {
        long cube = base * base * base;
        long key = digit_signature(cube);
        usz slot = signature_slot(key);
        while (keys[slot] != 0 && keys[slot] != key) slot = (slot + 1) % TABLE_SIZE;
        if (keys[slot] == 0) {
            keys[slot] = key;
            first_cubes[slot] = cube;
        }
        counts[slot]++;
        if (counts[slot] == target_count) return first_cubes[slot];
    }
    return -1;
}
