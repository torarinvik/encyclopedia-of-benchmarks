/* Pinned digit-sum sequence with cached decimal-prefix jumps. */
#include <stdint.h>
#include <stdlib.h>

#define MAX_N INT64_C(1000000000000000)
#define STATE_CAPACITY 32768
#define JUMP_CAPACITY 131072
#define TABLE_MASK (STATE_CAPACITY - 1)

typedef struct { int32_t prefix_sum; int64_t suffix; int32_t head; } State;
typedef struct { int64_t difference, terms; int32_t k, next; } Jump;
typedef struct { State *states; Jump *jumps; int32_t jump_count; int failed; } Memo;

static int64_t power10_i64(int64_t exponent)
{
    int64_t value = 1;
    while (exponent-- > 0) value *= 10;
    return value;
}

static int64_t digit_sum_i64(int64_t value)
{
    int64_t total = 0;
    while (value > 0) { total += value % 10; value /= 10; }
    return total;
}

static uint32_t state_hash(int64_t prefix_sum, int64_t suffix)
{
    uint64_t value = (uint64_t)suffix ^ ((uint64_t)prefix_sum * UINT64_C(0x9e3779b97f4a7c15));
    value ^= value >> 30; value *= UINT64_C(0xbf58476d1ce4e5b9);
    value ^= value >> 27; value *= UINT64_C(0x94d049bb133111eb);
    value ^= value >> 31;
    return (uint32_t)value & TABLE_MASK;
}

static int32_t find_state(Memo *memo, int64_t prefix_sum, int64_t suffix)
{
    uint32_t slot = state_hash(prefix_sum, suffix);
    for (uint32_t probe = 0; probe < STATE_CAPACITY; ++probe) {
        State *state = &memo->states[(slot + probe) & TABLE_MASK];
        if (state->head == -2) {
            state->prefix_sum = (int32_t)prefix_sum;
            state->suffix = suffix;
            state->head = -1;
            return (int32_t)((slot + probe) & TABLE_MASK);
        }
        if (state->prefix_sum == prefix_sum && state->suffix == suffix)
            return (int32_t)((slot + probe) & TABLE_MASK);
    }
    memo->failed = 1;
    return -1;
}

static void add_jump(Memo *memo, int32_t state_index, int64_t difference, int64_t terms, int64_t k)
{
    if (memo->jump_count >= JUMP_CAPACITY) { memo->failed = 1; return; }
    int32_t index = memo->jump_count++;
    memo->jumps[index] = (Jump){difference, terms, (int32_t)k, memo->states[state_index].head};
    memo->states[state_index].head = index;
}

static void compute(int64_t *value, int64_t k, int64_t index, int64_t target,
                    int64_t *difference_out, int64_t *terms_out)
{
    const int64_t start = index;
    const int64_t base = power10_i64(k);
    const int64_t prefix_sum = digit_sum_i64(*value / base);
    int64_t suffix = *value % base;
    int64_t difference = 0;
    while (index < target) {
        ++index;
        const int64_t addend = prefix_sum + digit_sum_i64(suffix);
        difference += addend;
        suffix += addend;
        if (suffix >= base) break;
    }
    *value += difference;
    *difference_out = difference;
    *terms_out = index - start;
}

static void next_term(int64_t *value, int64_t k, int64_t index, int64_t target,
                      Memo *memo, int64_t *difference_out, int64_t *terms_out)
{
    const int64_t base = power10_i64(k);
    const int64_t prefix_sum = digit_sum_i64(*value / base);
    const int64_t suffix = *value % base;
    const int64_t max_terms = target - index;
    const int32_t state_index = find_state(memo, prefix_sum, suffix);
    if (state_index < 0) { *difference_out = 0; *terms_out = 0; return; }
    int64_t difference = 0, terms = 0;
    int32_t best = -1;
    for (int32_t jump = memo->states[state_index].head; jump >= 0; jump = memo->jumps[jump].next) {
        const Jump *entry = &memo->jumps[jump];
        if (entry->k <= k && entry->terms <= max_terms &&
            (best < 0 || entry->terms > memo->jumps[best].terms)) best = jump;
    }
    if (best >= 0) {
        difference = memo->jumps[best].difference;
        terms = memo->jumps[best].terms;
        *value += difference;
    }
    if (terms >= max_terms || suffix + difference >= base) {
        *difference_out = difference; *terms_out = terms; return;
    }
    if (k > 2) {
        while (!memo->failed) {
            int64_t extra, jumped;
            next_term(value, k - 1, index + terms, target, memo, &extra, &jumped);
            difference += extra; terms += jumped;
            if (terms >= max_terms || suffix + difference >= base) break;
        }
    } else {
        int64_t extra, jumped;
        compute(value, k, index + terms, target, &extra, &jumped);
        difference += extra; terms += jumped;
    }
    if (!memo->failed && terms < max_terms) add_jump(memo, state_index, difference, terms, k);
    *difference_out = difference; *terms_out = terms;
}

int64_t problem551(int64_t n)
{
    if (n < 1 || n > MAX_N) return -1;
    State *states = (State *)calloc(STATE_CAPACITY, sizeof(State));
    Jump *jumps = (Jump *)calloc(JUMP_CAPACITY, sizeof(Jump));
    if (states == NULL || jumps == NULL) { free(states); free(jumps); return -1; }
    for (int32_t i = 0; i < STATE_CAPACITY; ++i) states[i].head = -2;
    Memo memo = {states, jumps, 0, 0};
    int64_t value = 1, jumped = 0;
    while (jumped != n - 1 && !memo.failed) {
        int64_t ignored, terms;
        next_term(&value, 18, 1 + jumped, n, &memo, &ignored, &terms);
        jumped += terms;
    }
    const int64_t result = memo.failed ? -1 : value;
    free(jumps); free(states);
    return result;
}
