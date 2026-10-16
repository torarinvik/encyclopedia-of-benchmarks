module problem345;

const int MAX_DIMENSION = 15;
const usz MAX_STATES = 1 << MAX_DIMENSION;

fn int bit_count(uint value) {
    int count = 0;
    while (value != 0) { count += (int)(value & 1); value >>= 1; }
    return count;
}

fn long problem345(long* input, usz length) @export("problem345") {
    if (input == null || length < 2 || length > MAX_DIMENSION * MAX_DIMENSION + 1) return -1;
    long dimension = input[0];
    if (dimension < 1 || dimension > MAX_DIMENSION || length != (usz)(dimension * dimension) + 1) return -1;
    for (usz index = 1; index < length; index++) if (input[index] < 0 || input[index] > 1000) return -1;

    long[MAX_STATES] best = {};
    for (usz mask = 0; mask < MAX_STATES; mask++) best[mask] = -1;
    best[0] = 0;
    uint state_count = 1 << (uint)dimension;
    for (uint mask = 0; mask < state_count; mask++) {
        if (best[mask] < 0) continue;
        int row = bit_count(mask);
        if (row >= dimension) continue;
        for (int column = 0; column < dimension; column++) {
            uint bit = 1 << (uint)column;
            if ((mask & bit) != 0) continue;
            uint next = mask | bit;
            long candidate = best[mask] + input[1 + (usz)row * (usz)dimension + (usz)column];
            if (candidate > best[next]) best[next] = candidate;
        }
    }
    return best[state_count - 1];
}
