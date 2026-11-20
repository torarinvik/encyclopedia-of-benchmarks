module addition_chain_enumeration;

const int MAX_TARGET = 31;
const usz OUTPUT_BYTES = 24;

struct Search {
    int target;
    int limit;
    int[MAX_TARGET + 1] chain;
    long total_count;
    long brauer_count;
}

fn void visit(Search* state, usz length, bool prefix_is_brauer) {
    int last = state.chain[length - 1];
    int steps = (int)length - 1;
    if (last == state.target) {
        if (steps == state.limit) {
            state.total_count++;
            if (prefix_is_brauer) state.brauer_count++;
        }
        return;
    }
    int remaining = state.limit - steps;
    if (remaining <= 0 || last * (1 << remaining) < state.target) return;

    bool[MAX_TARGET + 1] generated = zeroed;
    for (usz left = 0; left < length; left++) {
        for (usz right = left; right < length; right++) {
            int candidate = state.chain[left] + state.chain[right];
            if (candidate <= last || candidate > state.target || generated[candidate]) continue;
            generated[candidate] = true;
            state.chain[length] = candidate;
            bool uses_last = false;
            for (usz index = 0; index < length; index++)
                if (last + state.chain[index] == candidate) uses_last = true;
            visit(state, length + 1, prefix_is_brauer && uses_last);
        }
    }
}

fn int bit_length(int value) {
    int count = 0;
    while (value != 0) { count++; value >>= 1; }
    return count;
}

fn int popcount(int value) {
    int count = 0;
    while (value != 0) { count += value & 1; value >>= 1; }
    return count;
}

fn void minimum_counts(int target, long* result) {
    if (target == 1) { result[0] = 0; result[1] = 1; result[2] = 0; return; }
    int lower = bit_length(target - 1);
    int upper = bit_length(target) - 1 + popcount(target) - 1;
    for (int limit = lower; limit <= upper; limit++) {
        Search state = zeroed;
        state.target = target;
        state.limit = limit;
        state.chain[0] = 1;
        visit(&state, 1, true);
        if (state.total_count != 0) {
            result[0] = limit;
            result[1] = state.brauer_count;
            result[2] = state.total_count - state.brauer_count;
            return;
        }
    }
}

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(bits >> (byte * 8));
}

fn long addition_chain_enumeration(long* input, usz length, char* output, usz output_capacity)
    @export("addition_chain_enumeration") {
    if (input == null || length != 1 || input[0] < 1 || input[0] > MAX_TARGET) return -1;
    long[3] result = zeroed;
    minimum_counts((int)input[0], &result[0]);
    if (output == null || output_capacity < OUTPUT_BYTES) return -2;
    for (usz index = 0; index < 3; index++) store_i64_le(output, index * 8, result[index]);
    return (long)OUTPUT_BYTES;
}
