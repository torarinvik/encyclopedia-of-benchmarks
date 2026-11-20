module muthukrishnan_document_listing;

const usz MAX_N = 32;
const usz MAX_DOCS = 8;
const usz MAX_Q = 16;
const usz MAX_INPUT = 68;
const usz MAX_OUTPUT = 144;

struct State {
    long[32] da;
    long[32] previous;
    int[33] logs;
    int[6][32] table;
    char[144] staged;
    usz written;
}

fn int range_min(State* state, int lo, int hi) {
    usz len = (usz)(hi - lo + 1);
    int level = state->logs[len];
    int width = 1 << level;
    int left = state->table[level][lo];
    int right = state->table[level][hi - width + 1];
    if (state->previous[left] < state->previous[right] ||
        (state->previous[left] == state->previous[right] && left < right)) return left;
    return right;
}

fn void report(State* state, int lo, int hi, int query_lo, int* ranks, long* found_docs, int* count) {
    if (lo > hi) return;
    int index = range_min(state, lo, hi);
    if (state->previous[index] >= query_lo) return;
    ranks[*count] = index;
    found_docs[*count] = state->da[index];
    *count = *count + 1;
    if (index > lo) report(state, lo, index - 1, query_lo, ranks, found_docs, count);
    if (index < hi) report(state, index + 1, hi, query_lo, ranks, found_docs, count);
}

fn long muthukrishnan_document_listing(long* values, usz length, char* output,
                                      usz output_capacity)
        @export("muthukrishnan_document_listing") {
    if (values == null || length < 3 || length > MAX_INPUT) return -1;
    long n0 = values[0], docs0 = values[1], q0 = values[2];
    if (n0 < 1 || n0 > (long)MAX_N || docs0 < 1 || docs0 > (long)MAX_DOCS ||
        q0 < 1 || q0 > (long)MAX_Q) return -1;
    usz n = (usz)n0, docs = (usz)docs0, q = (usz)q0;
    if (length != 3 + n + 2 * q) return -1;

    State state = {};
    long[8] last;
    for (usz d = 0; d < docs; d++) last[d] = -1;
    for (usz i = 0; i < n; i++) {
        long document = values[3 + i];
        if (document < 0 || document >= docs0) return -1;
        state.da[i] = document;
        state.previous[i] = last[(usz)document];
        last[(usz)document] = (long)i;
    }
    for (usz query = 0; query < q; query++) {
        long lo = values[3 + n + 2 * query], hi = values[4 + n + 2 * query];
        if (lo < 0 || hi < lo || hi >= n0) return -1;
    }

    for (usz size = 2; size <= n; size++) state.logs[size] = state.logs[size / 2] + 1;
    for (usz i = 0; i < n; i++) state.table[0][i] = (int)i;
    int levels = state.logs[n] + 1;
    for (int level = 1; level < levels; level++) {
        int width = 1 << level, half = width >> 1;
        for (usz start = 0; start + (usz)width <= n; start++) {
            int left = state.table[level - 1][start];
            int right = state.table[level - 1][start + (usz)half];
            state.table[level][start] = state.previous[left] < state.previous[right] ||
                (state.previous[left] == state.previous[right] && left < right) ? left : right;
        }
    }

    for (usz query = 0; query < q; query++) {
        int lo = (int)values[3 + n + 2 * query];
        int hi = (int)values[4 + n + 2 * query];
        usz count_at = state.written++;
        int[8] ranks;
        long[8] found_docs;
        int count = 0;
        report(&state, lo, hi, lo, &ranks[0], &found_docs[0], &count);
        for (int i = 1; i < count; i++) {
            int rank = ranks[i];
            long document = found_docs[i];
            int j = i;
            while (j > 0 && ranks[j - 1] > rank) {
                ranks[j] = ranks[j - 1];
                found_docs[j] = found_docs[j - 1];
                j--;
            }
            ranks[j] = rank;
            found_docs[j] = document;
        }
        state.staged[count_at] = (char)count;
        for (int i = 0; i < count; i++) state.staged[state.written++] = (char)found_docs[i];
    }
    if (state.written > MAX_OUTPUT) return -1;
    if (output == null || output_capacity < state.written) return -2;
    for (usz i = 0; i < state.written; i++) output[i] = state.staged[i];
    return (long)state.written;
}
