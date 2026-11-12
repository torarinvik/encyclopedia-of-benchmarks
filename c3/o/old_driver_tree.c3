module old_driver_tree;

const usz MAX_N = 32;
const usz MAX_Q = 32;
const usz MAX_INPUT = 195;
const usz MAX_RUNS = 36;

struct Run { long left; long right; long value; }
struct Operation { long kind; long left; long right; long arg; long extra; }

fn usz lower_bound(Run* runs, usz count, long point) {
    usz lo = 0, hi = count;
    while (lo < hi) {
        usz mid = lo + (hi - lo) / 2;
        if (runs[mid].left < point) lo = mid + 1; else hi = mid;
    }
    return lo;
}
fn void split_at(Run* runs, usz* count, long point, long n) {
    if (point <= 0 || point >= n) return;
    usz at = lower_bound(runs, *count, point);
    if (at < *count && runs[at].left == point) return;
    Run old = runs[at - 1];
    for (usz i = *count; i > at; i--) runs[i] = runs[i - 1];
    runs[at - 1].right = point - 1;
    runs[at] = {point, old.right, old.value};
    *count = *count + 1;
}
fn void coalesce(Run* runs, usz* count) {
    usz write = 0;
    for (usz read = 0; read < *count; read++) {
        if (write > 0 && runs[write - 1].right + 1 == runs[read].left && runs[write - 1].value == runs[read].value)
            runs[write - 1].right = runs[read].right;
        else { runs[write] = runs[read]; write++; }
    }
    *count = write;
}
fn long modular_power(long base, long exponent, long modulus) {
    long value = base % modulus;
    if (value < 0) value += modulus;
    long result = 1 % modulus;
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = result * value % modulus;
        value = value * value % modulus;
        exponent = exponent / 2;
    }
    return result;
}
fn void store_le(uint8* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (uint8)(bits & 255); bits = bits >> 8; }
}

fn long old_driver_tree(long* input, usz length, uint8* output, usz capacity) @export("old_driver_tree") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    long nv = input[0], qv = input[1];
    if (nv < 1 || nv > (long)MAX_N || qv < 0 || qv > (long)MAX_Q || length < 2 + (usz)nv) return -1;
    usz n = (usz)nv, q = (usz)qv, cursor = 2 + n, answer_count = 0;
    long[MAX_N] initial = {0};
    Operation[MAX_Q] ops = {0};
    for (usz i = 0; i < n; i++) { initial[i] = input[2 + i]; if (initial[i] < -1000 || initial[i] > 1000) return -1; }
    for (usz i = 0; i < q; i++) {
        if (cursor >= length) return -1;
        long kind = input[cursor++];
        usz words = kind == 3 ? 4 : kind >= 0 && kind <= 2 ? 3 : 0;
        if (words == 0 || length - cursor < words) return -1;
        Operation op = {kind, input[cursor], input[cursor + 1], input[cursor + 2], 0};
        cursor += 3;
        if (kind == 3) op.extra = input[cursor++];
        if (op.left < 0 || op.left > op.right || op.right >= nv) return -1;
        if ((kind <= 1 && (op.arg < -1000 || op.arg > 1000)) ||
            (kind == 2 && (op.arg < 1 || op.arg > op.right - op.left + 1)) ||
            (kind == 3 && (op.arg < 0 || op.arg > 8 || op.extra < 1 || op.extra > 1000000000))) return -1;
        if (kind >= 2) answer_count++;
        ops[i] = op;
    }
    if (cursor != length || length > 2 + MAX_N + 5 * MAX_Q) return -1;
    usz required = 8 * answer_count;
    if (required > 0 && (output == null || capacity < required)) return -2;
    Run[MAX_RUNS] runs = {0}; usz run_count = 0;
    for (usz i = 0; i < n; i++) {
        if (run_count > 0 && runs[run_count - 1].value == initial[i]) runs[run_count - 1].right = (long)i;
        else { runs[run_count] = {(long)i, (long)i, initial[i]}; run_count++; }
    }
    usz written = 0;
    for (usz oi = 0; oi < q; oi++) {
        Operation op = ops[oi];
        if (op.kind <= 1) {
            split_at(&runs[0], &run_count, op.right + 1, nv);
            split_at(&runs[0], &run_count, op.left, nv);
            usz start = lower_bound(&runs[0], run_count, op.left);
            usz end = lower_bound(&runs[0], run_count, op.right + 1);
            if (op.kind == 0) {
                usz removed = end - start, old_count = run_count;
                for (usz i = end; i < old_count; i++) runs[i - removed] = runs[i];
                run_count = old_count - removed;
                for (usz i = run_count; i > start; i--) runs[i] = runs[i - 1];
                runs[start] = {op.left, op.right, op.arg}; run_count++;
            } else for (usz i = start; i < end; i++) runs[i].value += op.arg;
            coalesce(&runs[0], &run_count);
        } else if (op.kind == 2) {
            long[MAX_N] ordered = {0}; usz used = 0;
            for (usz i = 0; i < run_count; i++) {
                long lo = runs[i].left > op.left ? runs[i].left : op.left;
                long hi = runs[i].right < op.right ? runs[i].right : op.right;
                for (long j = lo; j <= hi; j++) {
                    usz at = used++;
                    while (at > 0 && ordered[at - 1] > runs[i].value) { ordered[at] = ordered[at - 1]; at--; }
                    ordered[at] = runs[i].value;
                }
            }
            store_le(output, 8 * written++, ordered[(usz)op.arg - 1]);
        } else {
            long total = 0;
            for (usz i = 0; i < run_count; i++) {
                long lo = runs[i].left > op.left ? runs[i].left : op.left;
                long hi = runs[i].right < op.right ? runs[i].right : op.right;
                if (lo <= hi) total = (total + (hi - lo + 1) * modular_power(runs[i].value, op.arg, op.extra)) % op.extra;
            }
            store_le(output, 8 * written++, total);
        }
    }
    return (long)required;
}
