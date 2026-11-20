module k_repetition_within_factor_copy_propagation;

const usz MAX_N = 16;
const usz MAX_K = 3;
const usz MAX_INPUT = 1557;
const usz MAX_RECORDS = 372;
const usz PERIODS = 9;
const usz BIT_WORDS = 39;
const usz MAX_OUTPUT = 11912;

struct Record { int start; int end; int period; int errors; }
struct State {
    int[MAX_N] word;
    int[MAX_N] starts;
    int[MAX_N] ends;
    int[MAX_N] copies;
    Record[MAX_RECORDS] records;
    ulong[BIT_WORDS] known;
    ulong[BIT_WORDS] generated;
    usz n;
    usz budget;
    usz factor_count;
    usz record_count;
}

fn usz bit_index(usz start, usz end, usz period) {
    return (start * (MAX_N + 1) + end) * PERIODS + period;
}

fn bool marked(ulong* bits, usz bit) {
    return (bits[bit / 64] & ((ulong)1 << (bit % 64))) != 0;
}

fn usz lce(State* s, usz left, usz right) {
    usz length = 0;
    while (left + length < s.n && right + length < s.n &&
           s.word[left + length] == s.word[right + length]) length += 1;
    return length;
}

fn bool less_record(Record a, Record b) {
    if (a.start != b.start) return a.start < b.start;
    if (a.end != b.end) return a.end < b.end;
    if (a.period != b.period) return a.period < b.period;
    return a.errors < b.errors;
}

fn void add_record(State* s, Record record, bool is_generated) {
    usz bit = bit_index((usz)record.start, (usz)record.end, (usz)record.period);
    if (marked(&s.known[0], bit)) return;
    s.known[bit / 64] |= (ulong)1 << (bit % 64);
    if (is_generated) s.generated[bit / 64] |= (ulong)1 << (bit % 64);
    usz at = s.record_count;
    while (at > 0 && less_record(record, s.records[at - 1])) {
        s.records[at] = s.records[at - 1];
        at -= 1;
    }
    s.records[at] = record;
    s.record_count += 1;
}

fn bool factors_valid(State* s) {
    if (s.factor_count == 0 || s.factor_count > s.n) return false;
    usz position = 0;
    for (usz f = 0; f < s.factor_count; f += 1) {
        int a = s.starts[f], b = s.ends[f], c = s.copies[f];
        if (a < 0 || (usz)a != position || b <= a || (usz)b > s.n) return false;
        if (f == 0) {
            if (a != 0 || b != 1 || c != -1) return false;
            position = (usz)b;
            continue;
        }
        usz longest = 0;
        for (usz earlier = 0; earlier < (usz)a; earlier += 1) {
            usz match = lce(s, earlier, (usz)a);
            if (match > longest) longest = match;
        }
        usz expected_end = (usz)a + longest + 1;
        if (expected_end > s.n) expected_end = s.n;
        if ((usz)b != expected_end) return false;
        usz prefix = expected_end - (usz)a - 1;
        if (prefix == 0) {
            if (c != -1) return false;
        } else if (c < 0 || (usz)c >= (usz)a || lce(s, (usz)c, (usz)a) != prefix) {
            return false;
        }
        position = expected_end;
    }
    return position == s.n;
}

fn usz mismatch_count(State* s, usz start, usz end, usz period) {
    usz errors = 0;
    for (usz i = start; i < end - period; i += 1)
        if (s.word[i] != s.word[i + period]) errors += 1;
    return errors;
}

fn bool valid_seed(State* s, Record r) {
    if (r.start < 0 || r.end <= r.start || (usz)r.end > s.n || r.period < 1 || (usz)r.period > s.n / 2) return false;
    usz a = (usz)r.start, b = (usz)r.end, p = (usz)r.period;
    if (b - a < 2 * p) return false;
    usz errors = mismatch_count(s, a, b, p);
    if ((usz)r.errors != errors || errors > s.budget) return false;
    if (a > 0 && errors + (usz)(s.word[a - 1] != s.word[a + p - 1]) <= s.budget) return false;
    if (b < s.n && errors + (usz)(s.word[b - p] != s.word[b]) <= s.budget) return false;
    return true;
}

fn void propagate(State* s) {
    for (usz f = 0; f < s.factor_count; f += 1) {
        usz a = (usz)s.starts[f], b = (usz)s.ends[f];
        int copy_value = s.copies[f];
        usz copied = b - a - 1;
        if (copied == 0) continue;
        usz c = (usz)copy_value;
        usz delta = a - c, copy_end = c + copied;
        for (usz target = a + 1; target < b - 1; target += 1) {
            usz source_start = target - delta;
            usz index = 0;
            while (index < s.record_count && (usz)s.records[index].start < source_start) index += 1;
            while (index < s.record_count && (usz)s.records[index].start == source_start) {
                Record source = s.records[index];
                if ((usz)source.end > copy_end) break;
                usz target_end = (usz)source.end + delta;
                if (target_end <= b - 2) {
                    Record shifted = {(int)target, (int)target_end, source.period, source.errors};
                    add_record(s, shifted, true);
                }
                index += 1;
            }
        }
    }
}

fn void put_i64(char* output, usz offset, ulong value) {
    for (usz b = 0; b < 8; b += 1) output[offset + b] = (char)(value >> (8 * b));
}

fn long k_repetition_within_factor_copy_propagation(long* input, usz length, char* output, usz capacity)
        @export("k_repetition_within_factor_copy_propagation") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = input[0], kv = input[1];
    if (nv < 1 || nv > (long)MAX_N || kv < 0 || kv > (long)MAX_K) return -1;
    usz n = (usz)nv, budget = (usz)kv;
    if (length < n + 3) return -1;
    State s = {0};
    s.n = n; s.budget = budget;
    usz cursor = 2;
    for (usz i = 0; i < n; i += 1) {
        if (input[cursor] < 0 || input[cursor] > 5) return -1;
        s.word[i] = (int)input[cursor]; cursor += 1;
    }
    for (usz i = 0; i + 1 < n; i += 1) if (s.word[i] == s.word[n - 1]) return -1;
    if (cursor >= length || input[cursor] < 1 || input[cursor] > (long)n) return -1;
    s.factor_count = (usz)input[cursor]; cursor += 1;
    if (cursor + 3 * s.factor_count >= length) return -1;
    for (usz i = 0; i < s.factor_count; i += 1) {
        long a = input[cursor], b = input[cursor + 1], c = input[cursor + 2];
        if (a < 0 || a > (long)n || b < 0 || b > (long)n || c < -1 || c > (long)n) return -1;
        s.starts[i] = (int)a; s.ends[i] = (int)b; s.copies[i] = (int)c; cursor += 3;
    }
    if (cursor >= length || !factors_valid(&s)) return -1;
    long seed_value = input[cursor]; cursor += 1;
    if (seed_value < 0 || seed_value > (long)MAX_RECORDS || cursor + 4 * (usz)seed_value != length) return -1;
    for (usz i = 0; i < (usz)seed_value; i += 1) {
        long a = input[cursor], b = input[cursor + 1], p = input[cursor + 2], e = input[cursor + 3];
        if (a < 0 || a > (long)n || b < 0 || b > (long)n || p < 0 || p > (long)n || e < 0 || e > (long)MAX_K) return -1;
        Record seed = {(int)a, (int)b, (int)p, (int)e};
        if (!valid_seed(&s, seed)) return -1;
        add_record(&s, seed, false); cursor += 4;
    }
    propagate(&s);
    usz count = 0;
    for (usz i = 0; i < s.record_count; i += 1) {
        Record r = s.records[i];
        usz bit = bit_index((usz)r.start, (usz)r.end, (usz)r.period);
        if (marked(&s.generated[0], bit)) count += 1;
    }
    usz written = 8 + count * 32;
    if (written > MAX_OUTPUT) return -1;
    if (output == null || capacity < written) return -2;
    put_i64(output, 0, (ulong)count);
    usz offset = 8;
    for (usz i = 0; i < s.record_count; i += 1) {
        Record r = s.records[i];
        usz bit = bit_index((usz)r.start, (usz)r.end, (usz)r.period);
        if (!marked(&s.generated[0], bit)) continue;
        put_i64(output, offset, (ulong)r.start); offset += 8;
        put_i64(output, offset, (ulong)r.end); offset += 8;
        put_i64(output, offset, (ulong)r.period); offset += 8;
        put_i64(output, offset, (ulong)r.errors); offset += 8;
    }
    return (long)written;
}
