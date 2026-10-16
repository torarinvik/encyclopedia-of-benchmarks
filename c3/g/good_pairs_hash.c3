module good_pairs_hash;

const usz MAX_ARRAY_LENGTH = 256;
const usz MAX_INPUT_LENGTH = 258;
const usz TABLE_SIZE = 512;
const long MAX_VALUE = 1000000;

fn long good_pairs_hash(long* input, usz length) @export("good_pairs_hash") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long declared = input[0];
    if (declared < 0 || declared > (long)MAX_ARRAY_LENGTH || length != (usz)(declared + 1)) return -1;
    usz count = (usz)declared;
    long[TABLE_SIZE] keys = zeroed;
    ulong[TABLE_SIZE] frequencies = zeroed;
    bool[TABLE_SIZE] occupied = zeroed;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -MAX_VALUE || value > MAX_VALUE) return -1;
        usz slot = (usz)(((ulong)(value + MAX_VALUE) * 2654435761) & (TABLE_SIZE - 1));
        while (occupied[slot] && keys[slot] != value) slot = (slot + 1) & (TABLE_SIZE - 1);
        if (!occupied[slot]) { occupied[slot] = true; keys[slot] = value; }
        frequencies[slot]++;
    }
    ulong pairs = 0;
    for (usz slot = 0; slot < TABLE_SIZE; slot++) {
        ulong frequency = frequencies[slot];
        if (frequency > 1) pairs += frequency * (frequency - 1) / 2;
    }
    return (long)pairs;
}
