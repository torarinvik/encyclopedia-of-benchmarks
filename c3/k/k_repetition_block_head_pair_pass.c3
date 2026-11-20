module k_repetition_block_head_pair_pass;

const usz MAX_N = 24;
const usz MAX_K = 3;
const usz MAX_INPUT = 27;
const usz MAX_CONTEXT = 48;
const usz MAX_FACTORS = 25;
const usz MAX_PERIODS = 13;
const usz BIT_WORDS = 117;
const usz MAX_OUTPUT = 39112;

struct Pass {
    int[MAX_N] text;
    usz n;
    usz budget;
    usz[MAX_FACTORS] starts;
    usz[MAX_FACTORS] ends;
    usz factor_count;
    ulong[BIT_WORDS] seen;
}

fn int extend_right(int* w, usz size, usz center, usz period, usz allowed) {
    usz left = center - period;
    usz limit = size - left < size - center ? size - left : size - center;
    usz errors = 0;
    for (usz j = 0; j < limit; j += 1) {
        if (w[left + j] != w[center + j]) { errors += 1; if (errors > allowed) return (int)j; }
    }
    return (int)limit;
}

fn int extend_left(int* w, usz center, usz period, usz allowed) {
    usz limit = center - period;
    usz errors = 0;
    for (usz j = 0; j < limit; j += 1) {
        if (w[center - period - 1 - j] != w[center - 1 - j]) {
            errors += 1; if (errors > allowed) return (int)j;
        }
    }
    return (int)limit;
}

fn void mark(Pass* s, usz base, usz size, usz center, usz next_head,
             usz lo, usz hi, usz period) {
    if (hi >= size || hi - lo + 1 < 2 * period) return;
    if (lo > center + 1 || hi + 1 < center) return;
    if (lo <= next_head + 1 && hi + 1 >= next_head) return;
    usz start = base + lo, end = base + hi;
    if (end >= s.n) return;
    usz index = (start * MAX_N + end) * MAX_PERIODS + period;
    s.seen[index / 64] |= (ulong)1 << (index % 64);
}

fn void at_head(Pass* s, int* w, usz size, usz base, usz center, usz next_head) {
    if (center == 0 || center + 1 >= size) return;
    for (usz period = 1; period <= center; period += 1) {
        for (usz split = 0; split <= s.budget; split += 1) {
            int f = extend_right(w, size, center, period, split);
            int b = extend_left(w, center, period, s.budget - split);
            if ((usz)f <= period && f + b >= (int)period)
                mark(s, base, size, center, next_head, center - period - (usz)b,
                     center + (usz)f - 1, period);
        }
    }
    int[MAX_CONTEXT] reversed = zeroed;
    for (usz i = 0; i < size; i += 1) reversed[i] = w[size - 1 - i];
    usz rc = size - 1 - center;
    for (usz period = 1; period <= rc; period += 1) {
        for (usz split = 0; split <= s.budget; split += 1) {
            int f = extend_right(&reversed[0], size, rc, period, split);
            int b = extend_left(&reversed[0], rc, period, s.budget - split);
            if ((usz)f <= period && f + b >= (int)period) {
                int rs = (int)(rc - period) - b;
                int re = (int)rc + f - 1;
                mark(s, base, size, center, next_head, size - 1 - (usz)re,
                     size - 1 - (usz)rs, period);
            }
        }
    }
}

fn void factorize(Pass* s) {
    usz pos = 0;
    while (pos < s.n) {
        usz best = 0;
        for (usz earlier = 0; earlier < pos; earlier += 1) {
            usz matched = 0;
            while (pos + matched < s.n && earlier + matched < s.n &&
                   s.text[earlier + matched] == s.text[pos + matched]) matched += 1;
            if (matched > best) best = matched;
        }
        usz end = pos + best + 1;
        if (end > s.n) end = s.n;
        s.starts[s.factor_count] = pos;
        s.ends[s.factor_count] = end;
        s.factor_count += 1;
        pos = end;
    }
}

fn void run_pass(Pass* s) {
    usz block = s.budget + 2;
    usz blocks = (s.factor_count + block - 1) / block;
    for (usz bi = 0; bi + 1 < blocks; bi += 1) {
        usz first = bi * block;
        usz first_end = first + block;
        if (first_end > s.factor_count) first_end = s.factor_count;
        usz second_end = first_end + block;
        if (second_end > s.factor_count) second_end = s.factor_count;
        usz head = s.ends[first_end - 1] - 1;
        usz next_head = s.ends[second_end - 1] - 1;
        usz pair_start = s.starts[first], pair_end = s.ends[second_end - 1];
        usz span = pair_end - pair_start;
        usz base = pair_start > span ? pair_start - span : 0;
        usz size = pair_end - base;
        int[MAX_CONTEXT] local = zeroed;
        for (usz i = 0; i < size; i += 1) local[i] = s.text[base + i];
        at_head(s, &local[0], size, base, head - base, next_head - base);
    }
}

fn void put_i64(char* output, usz offset, ulong value) {
    for (usz b = 0; b < 8; b += 1) output[offset + b] = (char)(value >> (8 * b));
}

fn long k_repetition_block_head_pair_pass(long* input, usz length, char* output, usz capacity)
        @export("k_repetition_block_head_pair_pass") {
    if (input == null || length < 3 || length > MAX_INPUT) return -1;
    long nv = input[0], kv = input[1];
    if (nv < 1 || nv > (long)MAX_N || kv < 0 || kv > (long)MAX_K) return -1;
    usz n = (usz)nv, budget = (usz)kv;
    if (length != n + 2) return -1;
    Pass s = {0};
    s.n = n; s.budget = budget;
    for (usz i = 0; i < n; i += 1) {
        if (input[i + 2] < 0 || input[i + 2] > 4) return -1;
        s.text[i] = (int)input[i + 2];
    }
    for (usz i = 0; i + 1 < n; i += 1) if (s.text[i] == s.text[n - 1]) return -1;
    factorize(&s);
    run_pass(&s);
    usz count = 0;
    for (usz start = 0; start < n; start += 1) {
        for (usz len = 2; len <= n - start; len += 1) {
            usz end = start + len - 1;
            for (usz p = 1; p <= len / 2; p += 1) {
                usz ix = (start * MAX_N + end) * MAX_PERIODS + p;
                if (s.seen[ix / 64] & ((ulong)1 << (ix % 64))) count += 1;
            }
        }
    }
    usz written = 8 + count * 32;
    if (written > MAX_OUTPUT) return -1;
    if (output == null || capacity < written) return -2;
    put_i64(output, 0, (ulong)count);
    usz offset = 8;
    for (usz start = 0; start < n; start += 1) {
        for (usz len = 2; len <= n - start; len += 1) {
            usz end = start + len - 1;
            for (usz p = 1; p <= len / 2; p += 1) {
                usz ix = (start * MAX_N + end) * MAX_PERIODS + p;
                if (!(s.seen[ix / 64] & ((ulong)1 << (ix % 64)))) continue;
                usz errors = 0;
                for (usz i = start; i + p <= end; i += 1) if (s.text[i] != s.text[i + p]) errors += 1;
                put_i64(output, offset, (ulong)start); offset += 8;
                put_i64(output, offset, (ulong)len); offset += 8;
                put_i64(output, offset, (ulong)p); offset += 8;
                put_i64(output, offset, (ulong)errors); offset += 8;
            }
        }
    }
    return (long)written;
}
