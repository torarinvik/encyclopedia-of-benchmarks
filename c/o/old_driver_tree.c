#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_Q = 32, MAX_INPUT = 195, MAX_RUNS = 36 };
typedef struct { int64_t left, right, value; } run;
typedef struct { int64_t kind, left, right, arg, extra; } operation;

static size_t lower_bound(const run items[MAX_RUNS], size_t count, int64_t point) {
    size_t lo = 0, hi = count;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (items[mid].left < point) lo = mid + 1; else hi = mid;
    }
    return lo;
}
static void split_at(run items[MAX_RUNS], size_t *count, int64_t point, int64_t n) {
    if (point <= 0 || point >= n) return;
    size_t at = lower_bound(items, *count, point);
    if (at < *count && items[at].left == point) return;
    run old = items[at - 1];
    for (size_t i = *count; i > at; --i) items[i] = items[i - 1];
    items[at - 1].right = point - 1;
    items[at] = (run){point, old.right, old.value};
    ++*count;
}
static void coalesce(run items[MAX_RUNS], size_t *count) {
    size_t write = 0;
    for (size_t read = 0; read < *count; ++read) {
        if (write > 0 && items[write - 1].right + 1 == items[read].left &&
            items[write - 1].value == items[read].value) {
            items[write - 1].right = items[read].right;
        } else {
            items[write++] = items[read];
        }
    }
    *count = write;
}
static int64_t modular_power(int64_t base, int64_t exponent, int64_t modulus) {
    int64_t value = base % modulus;
    if (value < 0) value += modulus;
    int64_t result = 1 % modulus;
    while (exponent > 0) {
        if (exponent & 1) result = result * value % modulus;
        value = value * value % modulus;
        exponent >>= 1;
    }
    return result;
}
static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t old_driver_tree(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > MAX_N || q_value < 0 || q_value > MAX_Q || length < 2 + (size_t)n_value) return -1;
    size_t n = (size_t)n_value, q = (size_t)q_value, cursor = 2 + n, answer_count = 0;
    int64_t initial[MAX_N];
    operation ops[MAX_Q];
    for (size_t i = 0; i < n; ++i) {
        initial[i] = input[2 + i];
        if (initial[i] < -1000 || initial[i] > 1000) return -1;
    }
    for (size_t i = 0; i < q; ++i) {
        if (cursor >= length) return -1;
        int64_t kind = input[cursor++];
        size_t words = kind == 3 ? 4 : kind >= 0 && kind <= 2 ? 3 : 0;
        if (words == 0 || length - cursor < words) return -1;
        operation current = {kind, input[cursor], input[cursor + 1], input[cursor + 2], 0};
        cursor += 3;
        if (kind == 3) current.extra = input[cursor++];
        if (current.left < 0 || current.left > current.right || current.right >= n_value) return -1;
        if ((kind == 0 || kind == 1) && (current.arg < -1000 || current.arg > 1000)) return -1;
        if (kind == 2 && (current.arg < 1 || current.arg > current.right - current.left + 1)) return -1;
        if (kind == 3 && (current.arg < 0 || current.arg > 8 || current.extra < 1 || current.extra > 1000000000)) return -1;
        if (kind == 2 || kind == 3) ++answer_count;
        ops[i] = current;
    }
    if (cursor != length || length > 2 + MAX_N + 5 * MAX_Q) return -1;
    size_t required = 8 * answer_count;
    if (required > 0 && (output == NULL || capacity < required)) return -2;

    run runs[MAX_RUNS]; size_t run_count = 0;
    for (size_t i = 0; i < n; ++i) {
        if (run_count > 0 && runs[run_count - 1].value == initial[i]) runs[run_count - 1].right = (int64_t)i;
        else runs[run_count++] = (run){(int64_t)i, (int64_t)i, initial[i]};
    }
    size_t written = 0;
    for (size_t oi = 0; oi < q; ++oi) {
        operation op = ops[oi];
        if (op.kind <= 1) {
            split_at(runs, &run_count, op.right + 1, n_value);
            split_at(runs, &run_count, op.left, n_value);
            size_t start = lower_bound(runs, run_count, op.left);
            size_t end = lower_bound(runs, run_count, op.right + 1);
            if (op.kind == 0) {
                size_t removed = end - start;
                size_t old_count = run_count;
                for (size_t i = end; i < old_count; ++i) runs[i - removed] = runs[i];
                run_count = old_count - removed;
                for (size_t i = run_count; i > start; --i) runs[i] = runs[i - 1];
                runs[start] = (run){op.left, op.right, op.arg};
                ++run_count;
            } else {
                for (size_t i = start; i < end; ++i) runs[i].value += op.arg;
            }
            coalesce(runs, &run_count);
        } else if (op.kind == 2) {
            int64_t ordered[MAX_N]; size_t used = 0;
            for (size_t i = 0; i < run_count; ++i) {
                int64_t lo = runs[i].left > op.left ? runs[i].left : op.left;
                int64_t hi = runs[i].right < op.right ? runs[i].right : op.right;
                for (int64_t j = lo; j <= hi; ++j) {
                    size_t at = used++;
                    while (at > 0 && ordered[at - 1] > runs[i].value) { ordered[at] = ordered[at - 1]; --at; }
                    ordered[at] = runs[i].value;
                }
            }
            store_le(output, 8 * written++, ordered[op.arg - 1]);
        } else {
            int64_t total = 0;
            for (size_t i = 0; i < run_count; ++i) {
                int64_t lo = runs[i].left > op.left ? runs[i].left : op.left;
                int64_t hi = runs[i].right < op.right ? runs[i].right : op.right;
                if (lo <= hi) total = (total + (hi - lo + 1) * modular_power(runs[i].value, op.arg, op.extra)) % op.extra;
            }
            store_le(output, 8 * written++, total);
        }
    }
    return (int64_t)required;
}
