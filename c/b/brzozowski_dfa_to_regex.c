#include <stddef.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

enum { MAX_STATES = 3, MAX_TEXT = 512, MAX_PARSEABLE_LENGTH = 10 };

static size_t text_length(const char *text) {
    size_t length = 0;
    while (text[length] != '\0') ++length;
    return length;
}

static int text_copy(char *output, const char *source) {
    if (output == source) return 1;
    const size_t length = text_length(source);
    if (length >= MAX_TEXT) return 0;
    memcpy(output, source, length + 1);
    return 1;
}

static int regex_union(char *output, const char *left, const char *right) {
    if (strcmp(left, "#") == 0) return text_copy(output, right);
    if (strcmp(right, "#") == 0 || strcmp(left, right) == 0)
        return text_copy(output, left);
    const char *first = strcmp(left, right) < 0 ? left : right;
    const char *second = first == left ? right : left;
    char temporary[MAX_TEXT];
    const int written = snprintf(temporary, sizeof temporary, "(%s|%s)", first, second);
    if (written < 0 || (size_t)written >= sizeof temporary) return 0;
    return text_copy(output, temporary);
}

static int regex_concat(char *output, const char *left, const char *right) {
    if (strcmp(left, "#") == 0 || strcmp(right, "#") == 0)
        return text_copy(output, "#");
    if (strcmp(left, "@") == 0) return text_copy(output, right);
    if (strcmp(right, "@") == 0) return text_copy(output, left);
    char temporary[MAX_TEXT];
    const int written = snprintf(temporary, sizeof temporary, "(%s.%s)", left, right);
    if (written < 0 || (size_t)written >= sizeof temporary) return 0;
    return text_copy(output, temporary);
}

static int regex_star(char *output, const char *value) {
    if (strcmp(value, "#") == 0 || strcmp(value, "@") == 0)
        return text_copy(output, "@");
    char temporary[MAX_TEXT];
    const int written = snprintf(temporary, sizeof temporary, "(%s)*", value);
    if (written < 0 || (size_t)written >= sizeof temporary) return 0;
    return text_copy(output, temporary);
}

int64_t brzozowski_dfa_to_regex(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_PARSEABLE_LENGTH) return -1;
    const int64_t n64 = input[0], start64 = input[1], accepting64 = input[2];
    if (n64 < 1 || n64 > MAX_STATES || start64 < 0 || start64 >= n64
        || accepting64 < 0 || accepting64 >= (INT64_C(1) << n64)
        || length != 3 + 2 * (size_t)n64) return -1;
    const size_t n = (size_t)n64, start = (size_t)start64;
    char coefficient[MAX_STATES][MAX_STATES][MAX_TEXT];
    char constant[MAX_STATES][MAX_TEXT];
    for (size_t state = 0; state < n; ++state) {
        if (!text_copy(constant[state], (accepting64 & (INT64_C(1) << state)) ? "@" : "#"))
            return -1;
        for (size_t target = 0; target < n; ++target)
            if (!text_copy(coefficient[state][target], "#")) return -1;
        for (size_t symbol = 0; symbol < 2; ++symbol) {
            const int64_t next = input[3 + 2 * state + symbol];
            if (next < 0 || next >= n64) return -1;
            const char label[2] = {(char)('0' + symbol), '\0'};
            if (!regex_union(coefficient[state][next], coefficient[state][next], label))
                return -1;
        }
    }

    for (size_t pivot = 0; pivot < n; ++pivot) {
        if (pivot == start) continue;
        char loop[MAX_TEXT];
        if (!regex_star(loop, coefficient[pivot][pivot])) return -1;
        for (size_t source = 0; source < n; ++source) {
            if (source == pivot) continue;
            char prefix[MAX_TEXT];
            if (!regex_concat(prefix, coefficient[source][pivot], loop)) return -1;
            for (size_t target = 0; target < n; ++target) {
                if (target == pivot) continue;
                char through[MAX_TEXT];
                if (!regex_concat(through, prefix, coefficient[pivot][target])
                    || !regex_union(coefficient[source][target],
                                    coefficient[source][target], through)) return -1;
            }
            char through_constant[MAX_TEXT];
            if (!regex_concat(through_constant, prefix, constant[pivot])
                || !regex_union(constant[source], constant[source], through_constant)) return -1;
        }
    }

    char loop[MAX_TEXT], answer[MAX_TEXT];
    if (!regex_star(loop, coefficient[start][start])
        || !regex_concat(answer, loop, constant[start])) return -1;
    const size_t result_length = text_length(answer);
    if (result_length > 270) return -1;
    if (output == NULL || capacity < result_length) return -2;
    memcpy(output, answer, result_length);
    return (int64_t)result_length;
}
