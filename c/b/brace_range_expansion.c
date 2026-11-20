#include <stddef.h>
#include <stdint.h>

typedef struct {
    int open, close, first_sep, second_sep;
    int start, end, step, letter, pad, count;
} brace_plan;

static int parse_endpoint(const int64_t *p, int begin, int end, int *value,
                          int *letter, int *width, int *upper) {
    int n = end - begin;
    if (n == 1 && ((p[begin] >= 65 && p[begin] <= 90) ||
                   (p[begin] >= 97 && p[begin] <= 122))) {
        *value = (int)p[begin];
        *letter = 1;
        *width = 1;
        *upper = p[begin] <= 90;
        return 1;
    }
    if (n < 1 || n > 4) return 0;
    int result = 0;
    for (int i = begin; i < end; ++i) {
        if (p[i] < 48 || p[i] > 57) return 0;
        result = result * 10 + (int)p[i] - 48;
    }
    *value = result;
    *letter = 0;
    *width = n;
    *upper = 0;
    return 1;
}

static int parse_step(const int64_t *p, int begin, int end, int *step) {
    int sign = 1;
    if (begin < end && (p[begin] == 43 || p[begin] == 45)) {
        if (p[begin] == 45) sign = -1;
        ++begin;
    }
    if (end - begin < 1) return 0;
    int value = 0;
    for (int i = begin; i < end; ++i) {
        if (p[i] < 48 || p[i] > 57) return 0;
        if (value < 10000) {
            value = value * 10 + (int)p[i] - 48;
            if (value > 10000) value = 10000;
        }
    }
    if (value == 0) return 0;
    *step = sign * value;
    return 1;
}

static int make_plan(const int64_t *p, int n, brace_plan *plan) {
    if (n < 1 || n > 64) return 0;
    int open = -1, close = -1;
    for (int i = 0; i < n; ++i) {
        if (p[i] < 32 || p[i] > 126) return 0;
        if (p[i] == 123) {
            if (open >= 0) return 0;
            open = i;
        } else if (p[i] == 125) {
            if (close >= 0) return 0;
            close = i;
        }
    }
    if (open < 0 || close <= open) return 0;
    if (open + n - close - 1 > 32) return 0;
    int first_sep = -1, second_sep = -1;
    for (int i = open + 1; i + 1 < close; ++i) {
        if (p[i] == 46 && p[i+1] == 46) {
            if (first_sep < 0) first_sep = i;
            else if (second_sep < 0) second_sep = i;
            else return 0;
            ++i;
        }
    }
    if (first_sep < 0) return 0;
    int start, end, start_letter, end_letter, start_width, end_width;
    int start_upper, end_upper;
    int end_token = second_sep < 0 ? close : second_sep;
    if (!parse_endpoint(p, open + 1, first_sep, &start, &start_letter, &start_width, &start_upper) ||
        !parse_endpoint(p, first_sep + 2, end_token, &end, &end_letter, &end_width, &end_upper) ||
        start_letter != end_letter ||
        (start_letter && start_upper != end_upper)) return 0;
    int step;
    if (second_sep < 0) step = start <= end ? 1 : -1;
    else if (!parse_step(p, second_sep + 2, close, &step)) return 0;
    if ((start < end && step <= 0) || (start > end && step >= 0)) return 0;
    int count = start == end ? 1 :
        (start < end ? (end - start) / step : (start - end) / -step) + 1;
    if (count > 16) return 0;
    int pad = 0;
    if (!start_letter && (p[open + 1] == 48 || p[first_sep + 2] == 48)) {
        pad = start_width > end_width ? start_width : end_width;
    }
    *plan = (brace_plan){open, close, first_sep, second_sep,
                         start, end, step, start_letter, pad, count};
    return 1;
}

int64_t brace_range_expansion(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 65) return -1;
    int n = (int)input[0];
    if (n < 1 || n > 64 || length != (size_t)(n + 1)) return -1;
    brace_plan plan;
    if (!make_plan(input + 1, n, &plan)) return -1;
    uint8_t staged[591];
    int out = 0, value = plan.start;
    int prefix_len = plan.open, suffix_start = plan.close + 1;
    int suffix_len = n - suffix_start;
    for (int item = 0; item < plan.count; ++item) {
        if (item) staged[out++] = 0;
        for (int i = 0; i < prefix_len; ++i) staged[out++] = (uint8_t)input[1+i];
        if (plan.letter) staged[out++] = (uint8_t)value;
        else {
            int digits[4], digits_n = 0, remaining = value;
            do { digits[digits_n++] = remaining % 10; remaining /= 10; } while (remaining > 0);
            while (digits_n < plan.pad) staged[out++] = 48;
            while (digits_n > 0) staged[out++] = (uint8_t)(48 + digits[--digits_n]);
        }
        for (int i = 0; i < suffix_len; ++i) staged[out++] = (uint8_t)input[1+suffix_start+i];
        value += plan.step;
    }
    if (!output || capacity < (size_t)out) return -2;
    for (int i = 0; i < out; ++i) output[i] = staged[i];
    return out;
}
