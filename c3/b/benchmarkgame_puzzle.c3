module benchmarkgame_puzzle;

extern fn void* malloc(usz size);
extern fn void free(void* pointer);

const long MAX_ARRAY_SIZE = 100000;
const long MAX_ROUNDS = 8;
const long MAX_SCANS_PER_ARRAY = 64;

fn uint puzzle_rand(ulong* state) {
    *state = *state * 1103515245 + 12345;
    uint shifted = (uint)(*state / 65536);
    return shifted % 32767 + 1;
}

fn usz puzzle_rand_int(usz minimum, usz maximum, ulong* state) {
    usz range = maximum - minimum + 1;
    uint draw = puzzle_rand(state);
    usz offset = (usz)((double)range * ((double)draw / 32768.0));
    return offset == range ? offset + minimum - 1 : offset + minimum;
}

fn void puzzle_shuffle(int* items, usz length, ulong* state) {
    for (usz index = length - 1; index > 0; index--) {
        usz range = index + 1;
        uint draw = puzzle_rand(state);
        usz k = (usz)((double)range * ((double)draw / 32768.0));
        usz chosen = k == range ? k - 1 : k;
        int temporary = items[index];
        items[index] = items[chosen];
        items[chosen] = temporary;
    }
}

fn int puzzle_find_duplicate(int* data, usz length) {
    uint result = 0;
    for (usz index = 0; index < length; index++)
        result ^= (uint)(index + 1) ^ (uint)data[index];
    result ^= (uint)length;
    return (int)result;
}

fn void puzzle_store_i32_le(char* output, usz offset, int value) {
    uint bits = (uint)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long benchmarkgame_puzzle(long* input, usz length, char* output, usz output_capacity)
    @export("benchmarkgame_puzzle") {
    if (input == null || length != 3) return -1;
    long raw_size = input[0], raw_rounds = input[1], raw_scans = input[2];
    if (raw_size < 1 || raw_size > MAX_ARRAY_SIZE || raw_rounds < 1 || raw_rounds > MAX_ROUNDS ||
        raw_scans < 1 || raw_scans > MAX_SCANS_PER_ARRAY) return -1;
    usz size = (usz)raw_size, rounds = (usz)raw_rounds, scans = (usz)raw_scans;
    usz output_bytes = rounds * 4;
    if (output_capacity < output_bytes || output == null) return -2;

    ulong random_state = 1;
    for (usz round = 0; round < rounds; round++) {
        int* data = (int*)malloc((size + 1) * 4);
        if (data == null) return -1;
        for (usz index = 0; index <= size; index++) data[index] = (int)index;
        data[0] = (int)puzzle_rand_int(1, size, &random_state);
        puzzle_shuffle(data, size + 1, &random_state);
        int duplicate = 0;
        for (usz scan = 0; scan < scans; scan++) duplicate = puzzle_find_duplicate(data, size + 1);
        puzzle_store_i32_le(output, round * 4, duplicate);
        free(data);
    }
    return (long)output_bytes;
}
