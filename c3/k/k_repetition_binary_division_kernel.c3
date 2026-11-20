module k_repetition_binary_division_kernel;

const usz MAX_N = 32;
const usz MAX_K = 3;
const usz MAX_INPUT = 35;
const usz MAX_PERIODS = 17;
const usz BIT_WORDS = 272;
const usz MAX_FACTORS = 33;
const usz MAX_OUTPUT = 91400;

struct Search {
    int[MAX_N] text;
    usz n;
    usz budget;
    usz[MAX_FACTORS] starts;
    usz[MAX_FACTORS] ends;
    usz factor_count;
    ulong[BIT_WORDS] seen;
}

fn int lp(int* w, usz size, usz center, usz period, usz allowed) {
    usz left = center - period;
    usz limit = size - left < size - center ? size - left : size - center;
    usz errors = 0;
    for (usz j = 0; j < limit; j += 1) {
        if (w[left + j] != w[center + j]) { errors += 1; if (errors > allowed) return (int)j; }
    }
    return (int)limit;
}

fn int ls(int* w, usz center, usz period, usz allowed) {
    usz a = center - period, b = center;
    usz limit = a < b ? a : b;
    usz errors = 0;
    for (usz j = 0; j < limit; j += 1) {
        if (w[center - period - 1 - j] != w[center - 1 - j]) { errors += 1; if (errors > allowed) return (int)j; }
    }
    return (int)limit;
}

fn void mark(Search* s, usz lo, usz last_head, int start_local, int end_local, usz period) {
    int start_signed = (int)lo + start_local;
    int end_signed = (int)lo + end_local;
    if (start_signed <= (int)lo || end_signed >= (int)s.n || end_signed - start_signed + 1 < 2 * (int)period) return;
    usz start = (usz)start_signed, end = (usz)end_signed;
    if (start <= last_head + 1 && end + 1 >= last_head) return;
    usz index = (start * MAX_N + end) * MAX_PERIODS + period;
    s.seen[index / 64] |= (ulong)1 << (index % 64);
}

fn void at_center(Search* s, int* w, usz size, usz center, usz lo, usz last_head) {
    if (center == 0 || center + 1 >= size) return;
    for (usz period = 1; period <= center; period += 1) {
        for (usz k = 0; k <= s.budget; k += 1) {
            int forward = lp(w, size, center, period, k);
            int backward = ls(w, center, period, s.budget - k);
            if ((usz)forward <= period && forward + backward >= (int)period)
                mark(s, lo, last_head, (int)(center - period) - backward,
                     (int)center + forward - 1, period);
        }
    }
    int[MAX_N] reversed = zeroed;
    for (usz i = 0; i < size; i += 1) reversed[i] = w[size - 1 - i];
    usz rc = size - 1 - center;
    for (usz period = 1; period <= rc; period += 1) {
        for (usz k = 0; k <= s.budget; k += 1) {
            int forward = lp(&reversed[0], size, rc, period, k);
            int backward = ls(&reversed[0], rc, period, s.budget - k);
            if ((usz)forward <= period && forward + backward >= (int)period) {
                int rs = (int)(rc - period) - backward;
                int re = (int)rc + forward - 1;
                mark(s, lo, last_head, (int)(size - 1) - re, (int)(size - 1) - rs, period);
            }
        }
    }
}

fn void divide(Search* s, usz first, usz last) {
    if (first >= last) return;
    usz mid = first + (last - first) / 2;
    usz lo = s.starts[first], hi = s.ends[last];
    usz center = s.ends[mid] - 1, last_head = s.ends[last] - 1;
    at_center(s, &s.text[lo], hi - lo, center - lo, lo, last_head);
    divide(s, first, mid);
    divide(s, mid + 1, last);
}

fn void encode_i64(char* output, usz offset, ulong value) {
    for (usz i = 0; i < 8; i += 1) output[offset + i] = (char)(value >> (8 * i));
}

fn long k_repetition_binary_division_kernel(long* input, usz length, char* output, usz capacity)
        @export("k_repetition_binary_division_kernel") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long nv = input[0], kv = input[1];
    if (nv < 1 || nv > (long)MAX_N || kv < 0 || kv > (long)MAX_K) return -1;
    usz n = (usz)nv, budget = (usz)kv;
    if (length != n + 2) return -1;
    Search state = {0};
    state.n = n; state.budget = budget;
    for (usz i = 0; i < n; i += 1) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        state.text[i] = (int)input[i + 2];
    }
    for (usz i = 0; i + 1 < n; i += 1) if (state.text[i] == state.text[n - 1]) return -1;

    usz pos = 0;
    while (pos < n) {
        usz best = 0;
        for (usz earlier = 0; earlier < pos; earlier += 1) {
            usz matched = 0;
            while (pos + matched < n && earlier + matched < n
                   && state.text[earlier + matched] == state.text[pos + matched]) matched += 1;
            if (matched > best) best = matched;
        }
        usz end = pos + best + 1;
        if (end > n) end = n;
        state.starts[state.factor_count] = pos;
        state.ends[state.factor_count] = end;
        state.factor_count += 1;
        pos = end;
    }
    usz block_size = budget + 2;
    for (usz first = 0; first < state.factor_count; first += block_size) {
        usz last = first + block_size;
        if (last > state.factor_count) last = state.factor_count;
        divide(&state, first, last - 1);
    }
    usz record_count = 0;
    for (usz start = 0; start < n; start += 1) {
        for (usz len = 2; len <= n - start; len += 1) {
            usz end = start + len - 1;
            for (usz period = 1; period <= len / 2; period += 1) {
                usz index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (state.seen[index / 64] & ((ulong)1 << (index % 64))) record_count += 1;
            }
        }
    }
    usz written = 8 + record_count * 32;
    if (written > MAX_OUTPUT) return -1;
    if (output == null || capacity < written) return -2;
    encode_i64(output, 0, (ulong)record_count);
    usz offset = 8;
    for (usz start = 0; start < n; start += 1) {
        for (usz len = 2; len <= n - start; len += 1) {
            usz end = start + len - 1;
            for (usz period = 1; period <= len / 2; period += 1) {
                usz index = (start * MAX_N + end) * MAX_PERIODS + period;
                if (!(state.seen[index / 64] & ((ulong)1 << (index % 64)))) continue;
                usz mismatches = 0;
                for (usz i = start; i + period <= end; i += 1)
                    if (state.text[i] != state.text[i + period]) mismatches += 1;
                encode_i64(output, offset, (ulong)start); offset += 8;
                encode_i64(output, offset, (ulong)len); offset += 8;
                encode_i64(output, offset, (ulong)period); offset += 8;
                encode_i64(output, offset, (ulong)mismatches); offset += 8;
            }
        }
    }
    return (long)written;
}
