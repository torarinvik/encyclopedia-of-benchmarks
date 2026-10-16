module problem551;

extern fn void* calloc(usz count, usz size);
extern fn void free(void* pointer);
const long MAX_N = 1000000000000000;
const int STATE_CAPACITY = 32768;
const int JUMP_CAPACITY = 131072;
const ulong TABLE_MASK = 32767;

struct State { int prefix_sum; long suffix; int head; }
struct Jump { long difference; long terms; int k; int next; }
struct Memo { State* states; Jump* jumps; int jump_count; bool failed; }

fn long power10_i64(long exponent) {
    long value = 1;
    while (exponent > 0) { value *= 10; exponent--; }
    return value;
}
fn long digit_sum_i64(long value) {
    long total = 0;
    while (value > 0) { total += value % 10; value /= 10; }
    return total;
}
fn ulong state_hash(long prefix_sum, long suffix) {
    ulong value = (ulong)suffix ^ ((ulong)prefix_sum * 0x9e3779b97f4a7c15u64);
    value ^= value >> 30; value *= 0xbf58476d1ce4e5b9u64;
    value ^= value >> 27; value *= 0x94d049bb133111ebu64;
    value ^= value >> 31;
    return value & TABLE_MASK;
}
fn int find_state(Memo* memo, long prefix_sum, long suffix) {
    ulong slot = state_hash(prefix_sum, suffix);
    for (int probe = 0; probe < STATE_CAPACITY; probe++) {
        int index = (int)((slot + (ulong)probe) & TABLE_MASK);
        State* state = &memo.states[index];
        if (state.head == -2) {
            state.prefix_sum = (int)prefix_sum; state.suffix = suffix; state.head = -1;
            return index;
        }
        if (state.prefix_sum == prefix_sum && state.suffix == suffix) return index;
    }
    memo.failed = true;
    return -1;
}
fn void add_jump(Memo* memo, int state_index, long difference, long terms, long k) {
    if (memo.jump_count >= JUMP_CAPACITY) { memo.failed = true; return; }
    int index = memo.jump_count++;
    memo.jumps[index] = Jump{difference, terms, (int)k, memo.states[state_index].head};
    memo.states[state_index].head = index;
}
fn void compute(long* value, long k, long index, long target, long* difference_out, long* terms_out) {
    long start = index;
    long base = power10_i64(k);
    long prefix_sum = digit_sum_i64(*value / base);
    long suffix = *value % base;
    long difference = 0;
    while (index < target) {
        index++;
        long addend = prefix_sum + digit_sum_i64(suffix);
        difference += addend; suffix += addend;
        if (suffix >= base) break;
    }
    *value += difference;
    *difference_out = difference; *terms_out = index - start;
}
fn void next_term(long* value, long k, long index, long target, Memo* memo,
                  long* difference_out, long* terms_out) {
    long base = power10_i64(k);
    long prefix_sum = digit_sum_i64(*value / base);
    long suffix = *value % base;
    long max_terms = target - index;
    int state_index = find_state(memo, prefix_sum, suffix);
    if (state_index < 0) { *difference_out = 0; *terms_out = 0; return; }
    long difference = 0, terms = 0;
    int best = -1;
    for (int jump = memo.states[state_index].head; jump >= 0; jump = memo.jumps[jump].next) {
        Jump* entry = &memo.jumps[jump];
        if (entry.k <= k && entry.terms <= max_terms &&
            (best < 0 || entry.terms > memo.jumps[best].terms)) best = jump;
    }
    if (best >= 0) {
        difference = memo.jumps[best].difference; terms = memo.jumps[best].terms;
        *value += difference;
    }
    if (terms >= max_terms || suffix + difference >= base) {
        *difference_out = difference; *terms_out = terms; return;
    }
    if (k > 2) {
        while (!memo.failed) {
            long extra, jumped;
            next_term(value, k - 1, index + terms, target, memo, &extra, &jumped);
            difference += extra; terms += jumped;
            if (terms >= max_terms || suffix + difference >= base) break;
        }
    } else {
        long extra, jumped;
        compute(value, k, index + terms, target, &extra, &jumped);
        difference += extra; terms += jumped;
    }
    if (!memo.failed && terms < max_terms) add_jump(memo, state_index, difference, terms, k);
    *difference_out = difference; *terms_out = terms;
}
fn long problem551(long n) @export("problem551") {
    if (n < 1 || n > MAX_N) return -1;
    State* states = (State*)calloc(STATE_CAPACITY, sizeof(State));
    Jump* jumps = (Jump*)calloc(JUMP_CAPACITY, sizeof(Jump));
    if (states == null || jumps == null) { if (states != null) free(states); if (jumps != null) free(jumps); return -1; }
    defer free(states); defer free(jumps);
    for (int i = 0; i < STATE_CAPACITY; i++) states[i].head = -2;
    Memo memo; memo.states = states; memo.jumps = jumps; memo.jump_count = 0; memo.failed = false;
    long value = 1, jumped = 0;
    while (jumped != n - 1 && !memo.failed) {
        long ignored, terms;
        next_term(&value, 18, 1 + jumped, n, &memo, &ignored, &terms);
        jumped += terms;
    }
    return memo.failed ? -1 : value;
}
