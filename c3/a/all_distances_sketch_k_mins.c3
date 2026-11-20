module all_distances_sketch_k_mins;

const long MAX_N = 6;
const long MAX_ASSIGNMENTS = 3;
const usz MAX_INPUT = 27;
const usz MAX_WORDS = 73;

fn void put_i64(uint8 *output, usz word, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++)
        output[8 * word + byte] = (uint8)((bits >> (8 * byte)) & 255);
}

fn long all_distances_sketch_k_mins(long *input, usz length, uint8 *output,
                                    usz capacity) @export("all_distances_sketch_k_mins") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long n0 = input[0], assignments0 = input[1];
    if (n0 < 1 || n0 > MAX_N || assignments0 < 1 || assignments0 > MAX_ASSIGNMENTS) return -1;
    usz n = (usz)n0, assignments = (usz)assignments0;
    if (length != 2 + n + assignments * n) return -1;

    long[MAX_N] distances = {};
    for (usz item = 0; item < n; item++) {
        long distance = input[2 + item];
        if (distance < 0 || distance > 1000000 || (item > 0 && distances[item - 1] >= distance)) return -1;
        distances[item] = distance;
    }
    long[MAX_ASSIGNMENTS][MAX_N] ranks = {};
    for (usz assignment = 0; assignment < assignments; assignment++) {
        bool[MAX_N] seen = {};
        for (usz item = 0; item < n; item++) {
            long rank = input[2 + n + assignment * n + item];
            if (rank < 0 || rank >= n0 || seen[(usz)rank]) return -1;
            seen[(usz)rank] = true;
            ranks[assignment][item] = rank;
        }
    }

    long[MAX_WORDS] staged = {};
    usz count = 0;
    for (usz assignment = 0; assignment < assignments; assignment++) {
        long best_rank = n0;
        for (usz item = 0; item < n; item++) {
            long rank = ranks[assignment][item];
            if (rank < best_rank) {
                staged[1 + 4 * count] = (long)assignment;
                staged[2 + 4 * count] = (long)item;
                staged[3 + 4 * count] = rank;
                staged[4 + 4 * count] = distances[item];
                count++;
                best_rank = rank;
            }
        }
    }
    staged[0] = (long)count;
    usz words = 1 + 4 * count, bytes = 8 * words;
    if (output == null || capacity < bytes) return -2;
    for (usz word = 0; word < words; word++) put_i64(output, word, staged[word]);
    return (long)bytes;
}
