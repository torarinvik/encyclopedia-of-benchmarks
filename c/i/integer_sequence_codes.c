#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT = 35, MAX_OUTPUT = 4096, MAX_RESULT = 512 };

static void emit_bit(uint8_t *out, size_t *used, int bit) {
    out[(*used)++] = (uint8_t)(bit ? '1' : '0');
}
static void emit_byte(uint8_t *out, size_t *used, uint8_t value) { out[(*used)++] = value; }

static void emit_number(uint8_t *out, size_t *used, uint64_t value, int width) {
    for (int shift = width - 1; shift >= 0; --shift)
        emit_bit(out, used, (int)((value >> shift) & 1u));
}

static void emit_unary(uint8_t *out, size_t *used, uint64_t value) {
    for (uint64_t i = 0; i < value; ++i) emit_bit(out, used, 1);
    emit_bit(out, used, 0);
}

static int floor_log2_u64(uint64_t value) {
    int width = -1;
    while (value != 0) { ++width; value >>= 1; }
    return width;
}

static void emit_minimal(uint8_t *out, size_t *used, uint64_t value, uint64_t universe) {
    if (universe == 1) return;
    int low_width = floor_log2_u64(universe);
    uint64_t short_count = (UINT64_C(1) << (low_width + 1)) - universe;
    if (value < short_count) emit_number(out, used, value, low_width);
    else emit_number(out, used, value + short_count, low_width + 1);
}

static void emit_gamma(uint8_t *out, size_t *used, uint64_t value) {
    uint64_t shifted = value + 1;
    int width = floor_log2_u64(shifted);
    emit_unary(out, used, (uint64_t)width);
    emit_number(out, used, shifted - (UINT64_C(1) << width), width);
}

static void emit_delta(uint8_t *out, size_t *used, uint64_t value) {
    uint64_t shifted = value + 1;
    int width = floor_log2_u64(shifted);
    emit_gamma(out, used, (uint64_t)width);
    emit_number(out, used, shifted - (UINT64_C(1) << width), width);
}

static void emit_interpolative(uint8_t *out, size_t *used, const int64_t *values,
                               int left, int right, int64_t low, int64_t high) {
    if (left >= right) return;
    int middle = left + (right - left - 1) / 2;
    int64_t value = values[middle];
    int64_t lower = low + (middle - left);
    int64_t upper = high - (right - middle - 1);
    emit_minimal(out, used, (uint64_t)(value - lower), (uint64_t)(upper - lower));
    emit_interpolative(out, used, values, left, middle, low, value);
    emit_interpolative(out, used, values, middle + 1, right, value + 1, high);
}

static void emit_simple9(uint8_t *out, size_t *used, const int64_t *values, int n) {
    static const int slots[9] = {28, 14, 9, 7, 5, 4, 3, 2, 1};
    static const int widths[9] = {1, 2, 3, 4, 5, 7, 9, 14, 28};
    int position = 0;
    while (position < n) {
        int selector = 0, take = 0, width = 0;
        for (int s = 0; s < 9; ++s) {
            int candidate_count = slots[s] < n - position ? slots[s] : n - position;
            int fits = 1;
            for (int j = 0; j < candidate_count; ++j)
                if ((uint64_t)values[position + j] >= (UINT64_C(1) << widths[s])) fits = 0;
            if (fits) { selector = s; take = candidate_count; width = widths[s]; break; }
        }
        uint64_t word = (uint64_t)selector << 28;
        for (int j = 0; j < take; ++j) {
            int shift = 28 - width * (j + 1);
            word |= (uint64_t)values[position + j] << shift;
        }
        emit_number(out, used, word, 32);
        position += take;
    }
}

int64_t integer_sequence_codes(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT) return -1;
    int64_t mode = input[0], n0 = input[1], parameter = input[2];
    if (mode < 0 || mode > 9 || n0 < 1 || n0 > MAX_N || length != (size_t)n0 + 3) return -1;
    int n = (int)n0;
    const int64_t *values = input + 3;
    if (mode == 0) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 31) return -1;
    } else if (mode == 1) {
        if (parameter < 2 || parameter > 1000000) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] >= parameter) return -1;
    } else if (mode == 2 || mode == 3) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else if (mode == 4) {
        if (parameter < 1 || parameter > 128) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    } else if (mode == 7) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else if (mode == 8) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] >= (INT64_C(1) << 28)) return -1;
    } else if (mode == 9) {
        if (parameter < 1 || parameter > 20) return -1;
        for (int i = 0; i < n; ++i) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else {
        if (parameter < 2 || parameter > 4096 || n > parameter) return -1;
        for (int i = 0; i < n; ++i)
            if (values[i] < 0 || values[i] >= parameter || (i > 0 && values[i - 1] >= values[i])) return -1;
    }

    uint8_t staged[MAX_OUTPUT];
    size_t used = 0;
    if (mode == 0) {
        for (int i = 0; i < n; ++i) emit_unary(staged, &used, (uint64_t)values[i]);
    } else if (mode == 1) {
        for (int i = 0; i < n; ++i) emit_minimal(staged, &used, (uint64_t)values[i], (uint64_t)parameter);
    } else if (mode == 2) {
        for (int i = 0; i < n; ++i) emit_gamma(staged, &used, (uint64_t)values[i]);
    } else if (mode == 3) {
        for (int i = 0; i < n; ++i) emit_delta(staged, &used, (uint64_t)values[i]);
    } else if (mode == 4) {
        for (int i = 0; i < n; ++i) {
            uint64_t quotient = (uint64_t)values[i] / (uint64_t)parameter;
            uint64_t remainder = (uint64_t)values[i] % (uint64_t)parameter;
            emit_unary(staged, &used, quotient);
            emit_minimal(staged, &used, remainder, (uint64_t)parameter);
        }
    } else if (mode == 5) {
        int width = 0;
        while ((uint64_t)n * (UINT64_C(1) << (width + 1)) <= (uint64_t)parameter) ++width;
        uint64_t bucket_size = UINT64_C(1) << width;
        int buckets = (int)(((uint64_t)parameter + bucket_size - 1) / bucket_size);
        uint8_t counts[4096] = {0};
        for (int i = 0; i < n; ++i) ++counts[(uint64_t)values[i] / bucket_size];
        for (int bucket = 0; bucket < buckets; ++bucket) emit_unary(staged, &used, counts[bucket]);
        for (int i = 0; i < n; ++i) emit_number(staged, &used, (uint64_t)values[i] % bucket_size, width);
    } else if (mode == 6) {
        emit_interpolative(staged, &used, values, 0, n, 0, parameter);
    } else if (mode == 7) {
        for (int i = 0; i < n; ++i) {
            uint64_t value = (uint64_t)values[i];
            int highest_shift = floor_log2_u64(value);
            if (highest_shift < 0) highest_shift = 0;
            else highest_shift = (highest_shift / 7) * 7;
            for (int shift = highest_shift; shift >= 0; shift -= 7) {
                uint8_t byte = (uint8_t)((value >> shift) & 0x7Fu);
                if (shift != 0) byte |= 0x80u;
                emit_byte(staged, &used, byte);
            }
        }
    } else if (mode == 8) {
        emit_simple9(staged, &used, values, n);
    } else {
        int width = (int)parameter;
        uint64_t low_mask = (UINT64_C(1) << width) - 1;
        int exception_count = 0;
        for (int i = 0; i < n; ++i) {
            emit_number(staged, &used, (uint64_t)values[i] & low_mask, width);
            if ((uint64_t)values[i] >= (UINT64_C(1) << width)) ++exception_count;
        }
        emit_number(staged, &used, (uint64_t)exception_count, 6);
        int position_width = 0;
        while ((1 << position_width) < n) ++position_width;
        for (int i = 0; i < n; ++i) if ((uint64_t)values[i] >= (UINT64_C(1) << width)) {
            emit_number(staged, &used, (uint64_t)i, position_width);
            emit_number(staged, &used, (uint64_t)values[i], 20);
        }
    }
    if (output == NULL) return -2;
    if (mode == 7) {
        if (capacity < used) return -2;
        for (size_t i = 0; i < used; ++i) output[i] = staged[i];
        return (int64_t)used;
    }
    size_t bytes = (used + 7u) / 8u;
    if (capacity < bytes) return -2;
    uint8_t packed[MAX_RESULT] = {0};
    for (size_t i = 0; i < used; ++i)
        if (staged[i] == '1') packed[i / 8u] |= (uint8_t)(1u << (7u - (i % 8u)));
    for (size_t i = 0; i < bytes; ++i) output[i] = packed[i];
    return (int64_t)bytes;
}
