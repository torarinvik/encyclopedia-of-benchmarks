#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 5, MAX_STATES = 3840, MAX_MOVES = 10, MAX_OUTPUT_BYTES = 168 };

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static int encode(const int64_t *permutation, int n) {
    int rank = 0;
    unsigned signs = 0;
    for (int i = 0; i < n; ++i) {
        const int value = (int)(permutation[i] < 0 ? -permutation[i] : permutation[i]);
        int smaller = 0;
        for (int j = i + 1; j < n; ++j) {
            const int other = (int)(permutation[j] < 0 ? -permutation[j] : permutation[j]);
            if (other < value) ++smaller;
        }
        rank = rank * (n - i) + smaller;
        if (permutation[i] < 0) signs |= 1u << (value - 1);
    }
    return rank * (1 << n) + (int)signs;
}

static void decode_state(int state, int n, const int *factorials, int64_t *permutation) {
    const unsigned sign_count = 1u << n;
    int rank = state / (int)sign_count;
    const unsigned signs = (unsigned)state % sign_count;
    int available[MAX_N];
    for (int i = 0; i < n; ++i) available[i] = i + 1;
    int remaining = n;
    for (int i = 0; i < n; ++i) {
        const int factor = factorials[n - i - 1];
        const int digit = rank / factor;
        rank %= factor;
        const int value = available[digit];
        for (int j = digit; j + 1 < remaining; ++j) available[j] = available[j + 1];
        --remaining;
        permutation[i] = (signs & (1u << (value - 1))) ? -value : value;
    }
}

static void reverse_signed(int64_t *permutation, int left, int right) {
    while (left < right) {
        const int64_t a = permutation[left], b = permutation[right];
        permutation[left++] = -b;
        permutation[right--] = -a;
    }
    if (left == right) permutation[left] = -permutation[left];
}

int64_t signed_permutation_reversal_sequence(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_N + 1) return -1;
    const int64_t raw_n = input[0];
    if (raw_n < 2 || raw_n > MAX_N || length != (size_t)raw_n + 1) return -1;
    const int n = (int)raw_n;
    unsigned seen = 0;
    int64_t permutation[MAX_N];
    for (int i = 0; i < n; ++i) {
        const int64_t value = input[i + 1];
        if (value == 0 || value == INT64_MIN) return -1;
        const int64_t absolute = value < 0 ? -value : value;
        if (absolute > n) return -1;
        const unsigned bit = 1u << ((unsigned)absolute - 1u);
        if (seen & bit) return -1;
        seen |= bit;
        permutation[i] = value;
    }
    if (seen != (1u << n) - 1u) return -1;
    if (output == NULL) return -2;

    int factorials[MAX_N + 1] = {1, 1, 2, 6, 24, 120};
    const int state_count = factorials[n] * (1 << n);
    int32_t parent[MAX_STATES];
    int32_t queue[MAX_STATES];
    int8_t move_left[MAX_STATES], move_right[MAX_STATES];
    for (int state = 0; state < state_count; ++state) parent[state] = -2;
    const int start = encode(permutation, n);
    int head = 0, tail = 0;
    parent[start] = -1;
    queue[tail++] = start;
    while (head < tail && parent[0] == -2) {
        const int current = queue[head++];
        int64_t current_permutation[MAX_N];
        decode_state(current, n, factorials, current_permutation);
        for (int left = 0; left < n && parent[0] == -2; ++left) {
            for (int right = left; right < n; ++right) {
                int64_t neighbor[MAX_N];
                for (int i = 0; i < n; ++i) neighbor[i] = current_permutation[i];
                reverse_signed(neighbor, left, right);
                const int next = encode(neighbor, n);
                if (parent[next] != -2) continue;
                parent[next] = current;
                move_left[next] = (int8_t)(left + 1);
                move_right[next] = (int8_t)(right + 1);
                queue[tail++] = next;
                if (next == 0) break;
            }
        }
    }
    if (parent[0] == -2) return -1;
    int64_t reverse_moves[MAX_MOVES][2];
    int move_count = 0;
    int current = 0;
    while (parent[current] >= 0) {
        if (move_count == MAX_MOVES) return -1;
        reverse_moves[move_count][0] = move_left[current];
        reverse_moves[move_count][1] = move_right[current];
        ++move_count;
        current = parent[current];
    }
    const size_t output_bytes = 8u * (1u + 2u * (size_t)move_count);
    if (capacity < output_bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    store_i64_le(staged, 0, move_count);
    for (int i = 0; i < move_count; ++i) {
        const int reverse_index = move_count - 1 - i;
        store_i64_le(staged, 8u * (1u + 2u * (size_t)i), reverse_moves[reverse_index][0]);
        store_i64_le(staged, 8u * (2u + 2u * (size_t)i), reverse_moves[reverse_index][1]);
    }
    for (size_t byte = 0; byte < output_bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)output_bytes;
}
