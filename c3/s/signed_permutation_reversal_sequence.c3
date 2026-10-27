module signed_permutation_reversal_sequence;

const usz MAX_N = 5;
const usz MAX_STATES = 3840;
const usz MAX_MOVES = 10;
const usz MAX_OUTPUT_BYTES = 168;

fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn int encode(long* permutation, usz n) {
    int rank = 0;
    uint signs = 0;
    for (usz i = 0; i < n; i += 1) {
        int value = (int)(permutation[i] < 0 ? -permutation[i] : permutation[i]);
        int smaller = 0;
        for (usz j = i + 1; j < n; j += 1) {
            int other = (int)(permutation[j] < 0 ? -permutation[j] : permutation[j]);
            if (other < value) smaller += 1;
        }
        rank = rank * (int)(n - i) + smaller;
        if (permutation[i] < 0) signs |= 1u << (value - 1);
    }
    return rank * (1 << (int)n) + (int)signs;
}

fn void decode_state(int state, usz n, int* factorials, long* permutation) {
    uint sign_count = 1u << (int)n;
    int rank = state / (int)sign_count;
    uint signs = (uint)state % sign_count;
    int[MAX_N] available = zeroed;
    for (usz i = 0; i < n; i += 1) available[i] = (int)i + 1;
    usz remaining = n;
    for (usz i = 0; i < n; i += 1) {
        int factor = factorials[n - i - 1];
        int digit = rank / factor;
        rank %= factor;
        int value = available[digit];
        for (usz j = digit.usz(); j + 1 < remaining; j += 1) available[j] = available[j + 1];
        remaining -= 1;
        permutation[i] = if (signs & (1u << (value - 1))) != 0: -value.long() else: value.long();
    }
}

fn void reverse_signed(long* permutation, usz left_start, usz right_start) {
    usz left = left_start, right = right_start;
    while (left < right) {
        long a = permutation[left], b = permutation[right];
        permutation[left] = -b; permutation[right] = -a;
        left += 1; right -= 1;
    }
    if (left == right) permutation[left] = -permutation[left];
}

long signed_permutation_reversal_sequence(long* input, usz length, char* output, usz capacity)
        @export("signed_permutation_reversal_sequence") {
    if (input == null || length < 3 || length > MAX_N + 1) return -1;
    long raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_N.long() || length != (raw_n + 1).usz()) return -1;
    usz n = raw_n.usz();
    uint seen = 0;
    long[MAX_N] permutation = zeroed;
    for (usz i = 0; i < n; i += 1) {
        long value = input[i + 1];
        if (value == 0 || value < -raw_n || value > raw_n) return -1;
        int absolute = (int)(if value < 0: -value else: value);
        uint bit = 1u << (absolute - 1);
        if (seen & bit) != 0 return -1;
        seen |= bit;
        permutation[i] = value;
    }
    if (seen != (1u << (int)n) - 1u) return -1;
    if (output == null) return -2;

    int[MAX_N + 1] factorials = {1, 1, 2, 6, 24, 120};
    int state_count = factorials[n] * (1 << (int)n);
    int[MAX_STATES] parent = zeroed;
    int[MAX_STATES] queue = zeroed;
    char[MAX_STATES] move_left = zeroed, move_right = zeroed;
    for (int state = 0; state < state_count; state += 1) parent[state.usz()] = -2;
    int start = encode(&permutation[0], n);
    int head = 0, tail = 0;
    parent[start.usz()] = -1; queue[tail.usz()] = start; tail += 1;
    while (head < tail && parent[0] == -2) {
        int current = queue[head.usz()]; head += 1;
        long[MAX_N] current_permutation = zeroed;
        decode_state(current, n, &factorials[0], &current_permutation[0]);
        for (usz left = 0; left < n && parent[0] == -2; left += 1) {
            for (usz right = left; right < n; right += 1) {
                long[MAX_N] neighbor = current_permutation;
                reverse_signed(&neighbor[0], left, right);
                int next = encode(&neighbor[0], n);
                if (parent[next.usz()] != -2) continue;
                parent[next.usz()] = current;
                move_left[next.usz()] = (char)(left + 1);
                move_right[next.usz()] = (char)(right + 1);
                queue[tail.usz()] = next; tail += 1;
                if (next == 0) break;
            }
        }
    }
    if (parent[0] == -2) return -1;
    long[MAX_MOVES * 2] reverse_moves = zeroed;
    int move_count = 0, current = 0;
    while (parent[current.usz()] >= 0) {
        if (move_count == MAX_MOVES) return -1;
        reverse_moves[2 * move_count] = move_left[current.usz()].long();
        reverse_moves[2 * move_count + 1] = move_right[current.usz()].long();
        move_count += 1;
        current = parent[current.usz()];
    }
    usz output_bytes = 8 * (1 + 2 * move_count.usz());
    if (capacity < output_bytes) return -2;
    char[MAX_OUTPUT_BYTES] staged = zeroed;
    store_i64_le(&staged[0], 0, move_count.long());
    for (int i = 0; i < move_count; i += 1) {
        int reverse_index = move_count - 1 - i;
        store_i64_le(&staged[0], 8 * (1 + 2 * i).usz(), reverse_moves[2 * reverse_index]);
        store_i64_le(&staged[0], 8 * (2 + 2 * i).usz(), reverse_moves[2 * reverse_index + 1]);
    }
    for (usz byte = 0; byte < output_bytes; byte += 1) output[byte] = staged[byte];
    return output_bytes.long();
}
