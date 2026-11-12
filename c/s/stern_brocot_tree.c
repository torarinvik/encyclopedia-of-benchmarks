#include <stddef.h>
#include <stdint.h>

#define MAX_QUERIES 128
#define MAX_RUNS 64
#define MAX_INPUT_LENGTH 16384
#define MAX_OUTPUT_WORDS 32768
#define MAX_COMPONENT INT64_C(1000000000)

typedef struct {
    int64_t direction;
    int64_t count;
} run_t;

static int64_t gcd_i64(int64_t a, int64_t b) {
    while (b != 0) {
        const int64_t remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

static int valid_fraction(int64_t numerator, int64_t denominator) {
    return numerator >= 1 && numerator <= MAX_COMPONENT
        && denominator >= 1 && denominator <= MAX_COMPONENT
        && gcd_i64(numerator, denominator) == 1;
}

static int encode_path(int64_t numerator, int64_t denominator,
                       run_t *runs, size_t *run_count) {
    *run_count = 0;
    while (numerator != denominator) {
        if (*run_count >= MAX_RUNS) return 0;
        if (numerator < denominator) {
            const int64_t count = (denominator - 1) / numerator;
            runs[*run_count] = (run_t){0, count};
            denominator -= count * numerator;
        } else {
            const int64_t count = (numerator - 1) / denominator;
            runs[*run_count] = (run_t){1, count};
            numerator -= count * denominator;
        }
        ++*run_count;
    }
    return 1;
}

static int decode_path(const run_t *runs, size_t run_count,
                       int64_t *numerator, int64_t *denominator,
                       int64_t *lower_num, int64_t *lower_den,
                       int64_t *upper_num, int64_t *upper_den) {
    int64_t ln = 0, ld = 1, un = 1, ud = 0;
    int64_t previous_direction = -1;
    for (size_t i = 0; i < run_count; ++i) {
        const int64_t direction = runs[i].direction;
        const int64_t count = runs[i].count;
        if ((direction != 0 && direction != 1) || count < 1 || count > MAX_COMPONENT
            || direction == previous_direction) return 0;
        if (direction == 0) {
            un += count * ln;
            ud += count * ld;
            if (un > MAX_COMPONENT || ud > MAX_COMPONENT) return 0;
        } else {
            ln += count * un;
            ld += count * ud;
            if (ln > MAX_COMPONENT || ld > MAX_COMPONENT) return 0;
        }
        previous_direction = direction;
    }
    const int64_t n = ln + un;
    const int64_t d = ld + ud;
    if (!valid_fraction(n, d)) return 0;
    *numerator = n;
    *denominator = d;
    *lower_num = ln;
    *lower_den = ld;
    *upper_num = un;
    *upper_den = ud;
    return 1;
}

static void append_common_prefix(const run_t *left, size_t left_count,
                                const run_t *right, size_t right_count,
                                run_t *prefix, size_t *prefix_count) {
    size_t i = 0, j = 0;
    int64_t left_used = 0, right_used = 0;
    *prefix_count = 0;
    while (i < left_count && j < right_count && left[i].direction == right[j].direction) {
        const int64_t left_remaining = left[i].count - left_used;
        const int64_t right_remaining = right[j].count - right_used;
        const int64_t shared = left_remaining < right_remaining ? left_remaining : right_remaining;
        prefix[*prefix_count] = (run_t){left[i].direction, shared};
        ++*prefix_count;
        left_used += shared;
        right_used += shared;
        if (left_used == left[i].count) { ++i; left_used = 0; }
        if (right_used == right[j].count) { ++j; right_used = 0; }
    }
}

static int append_word(int64_t *words, size_t *length, int64_t value) {
    if (*length >= MAX_OUTPUT_WORDS) return 0;
    words[(*length)++] = value;
    return 1;
}

int64_t stern_brocot_tree(const int64_t *input, size_t length,
                          uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t query_count = input[0];
    if (query_count < 1 || query_count > MAX_QUERIES) return -1;
    int64_t words[MAX_OUTPUT_WORDS];
    size_t word_count = 0, position = 1;
    for (int64_t query = 0; query < query_count; ++query) {
        if (position >= length) return -1;
        const int64_t operation = input[position++];
        if (operation == 0) {
            if (position + 2 > length) return -1;
            const int64_t numerator = input[position++], denominator = input[position++];
            if (!valid_fraction(numerator, denominator)) return -1;
            run_t runs[MAX_RUNS];
            size_t run_count;
            if (!encode_path(numerator, denominator, runs, &run_count)
                || !append_word(words, &word_count, operation)
                || !append_word(words, &word_count, (int64_t)run_count)) return -1;
            for (size_t i = 0; i < run_count; ++i)
                if (!append_word(words, &word_count, runs[i].direction)
                    || !append_word(words, &word_count, runs[i].count)) return -1;
        } else if (operation == 1) {
            if (position >= length) return -1;
            const int64_t raw_count = input[position++];
            if (raw_count < 0 || raw_count > MAX_RUNS
                || position + (size_t)raw_count * 2 > length) return -1;
            const size_t run_count = (size_t)raw_count;
            run_t runs[MAX_RUNS];
            for (size_t i = 0; i < run_count; ++i) {
                runs[i] = (run_t){input[position], input[position + 1]};
                position += 2;
            }
            int64_t numerator, denominator, ln, ld, un, ud;
            if (!decode_path(runs, run_count, &numerator, &denominator, &ln, &ld, &un, &ud)
                || !append_word(words, &word_count, operation)
                || !append_word(words, &word_count, numerator)
                || !append_word(words, &word_count, denominator)) return -1;
        } else if (operation == 2) {
            if (position + 4 > length) return -1;
            const int64_t a = input[position++], b = input[position++];
            const int64_t c = input[position++], d = input[position++];
            if (!valid_fraction(a, b) || !valid_fraction(c, d)) return -1;
            run_t left[MAX_RUNS], right[MAX_RUNS], prefix[MAX_RUNS];
            size_t left_count, right_count, prefix_count;
            if (!encode_path(a, b, left, &left_count)
                || !encode_path(c, d, right, &right_count)) return -1;
            append_common_prefix(left, left_count, right, right_count, prefix, &prefix_count);
            int64_t numerator, denominator, ln, ld, un, ud;
            if (!decode_path(prefix, prefix_count, &numerator, &denominator, &ln, &ld, &un, &ud)
                || !append_word(words, &word_count, operation)
                || !append_word(words, &word_count, numerator)
                || !append_word(words, &word_count, denominator)) return -1;
        } else if (operation == 3) {
            if (position + 3 > length) return -1;
            const int64_t depth = input[position++];
            const int64_t numerator = input[position++], denominator = input[position++];
            if (depth < 1 || depth > MAX_COMPONENT || !valid_fraction(numerator, denominator)) return -1;
            run_t path[MAX_RUNS], prefix[MAX_RUNS];
            size_t path_count;
            if (!encode_path(numerator, denominator, path, &path_count)) return -1;
            int64_t total_depth = 0;
            for (size_t i = 0; i < path_count; ++i) total_depth += path[i].count;
            if (!append_word(words, &word_count, operation)) return -1;
            if (depth > total_depth) {
                if (!append_word(words, &word_count, -1)) return -1;
            } else {
                int64_t remaining = depth;
                size_t prefix_count = 0;
                for (size_t i = 0; i < path_count && remaining > 0; ++i) {
                    const int64_t take = remaining < path[i].count ? remaining : path[i].count;
                    prefix[prefix_count++] = (run_t){path[i].direction, take};
                    remaining -= take;
                }
                int64_t n, d, ln, ld, un, ud;
                if (!decode_path(prefix, prefix_count, &n, &d, &ln, &ld, &un, &ud)
                    || !append_word(words, &word_count, n)
                    || !append_word(words, &word_count, d)) return -1;
            }
        } else if (operation == 4) {
            if (position + 2 > length) return -1;
            const int64_t numerator = input[position++], denominator = input[position++];
            if (!valid_fraction(numerator, denominator)) return -1;
            run_t path[MAX_RUNS];
            size_t path_count;
            if (!encode_path(numerator, denominator, path, &path_count)) return -1;
            int64_t n, d, ln, ld, un, ud;
            if (!decode_path(path, path_count, &n, &d, &ln, &ld, &un, &ud)
                || !append_word(words, &word_count, operation)
                || !append_word(words, &word_count, ln)
                || !append_word(words, &word_count, ld)
                || !append_word(words, &word_count, un)
                || !append_word(words, &word_count, ud)) return -1;
        } else {
            return -1;
        }
    }
    if (position != length) return -1;
    const size_t byte_count = word_count * 8;
    if (output_capacity < byte_count || output == NULL) return -2;
    for (size_t i = 0; i < word_count; ++i) {
        const uint64_t bits = (uint64_t)words[i];
        for (size_t byte = 0; byte < 8; ++byte)
            output[i * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return query_count;
}
