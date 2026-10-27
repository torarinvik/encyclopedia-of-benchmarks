module integer_sequence_codes;

const int MAX_N = 32;
const int MAX_INPUT = 35;
const int MAX_OUTPUT = 4096;
const int MAX_RESULT = 512;

fn void emit_bit(uint8 *out, usz *used, bool value) { out[*used] = value ? '1' : '0'; *used = *used + 1; }
fn void emit_byte(uint8 *out, usz *used, uint8 value) { out[*used] = value; *used = *used + 1; }
fn void emit_number(uint8 *out, usz *used, ulong value, int width) {
    for (int shift = width - 1; shift >= 0; shift--) emit_bit(out, used, ((value >> shift) & 1ul) != 0);
}
fn void emit_unary(uint8 *out, usz *used, ulong value) {
    for (ulong i = 0; i < value; i++) emit_bit(out, used, true);
    emit_bit(out, used, false);
}
fn int floor_log2(ulong value) {
    int width = -1;
    while (value != 0) { width++; value >>= 1; }
    return width;
}
fn void emit_minimal(uint8 *out, usz *used, ulong value, ulong universe) {
    if (universe == 1) return;
    int low_width = floor_log2(universe);
    ulong short_count = (1ul << (low_width + 1)) - universe;
    if (value < short_count) emit_number(out, used, value, low_width);
    else emit_number(out, used, value + short_count, low_width + 1);
}
fn void emit_gamma(uint8 *out, usz *used, ulong value) {
    ulong shifted = value + 1;
    int width = floor_log2(shifted);
    emit_unary(out, used, (ulong)width);
    emit_number(out, used, shifted - (1ul << width), width);
}
fn void emit_delta(uint8 *out, usz *used, ulong value) {
    ulong shifted = value + 1;
    int width = floor_log2(shifted);
    emit_gamma(out, used, (ulong)width);
    emit_number(out, used, shifted - (1ul << width), width);
}
fn void emit_interpolative(uint8 *out, usz *used, long *values, int left, int right, long low, long high) {
    if (left >= right) return;
    int middle = left + (right - left - 1) / 2;
    long value = values[middle];
    long lower = low + (middle - left);
    long upper = high - (right - middle - 1);
    emit_minimal(out, used, (ulong)(value - lower), (ulong)(upper - lower));
    emit_interpolative(out, used, values, left, middle, low, value);
    emit_interpolative(out, used, values, middle + 1, right, value + 1, high);
}
fn void emit_simple9(uint8 *out, usz *used, long *values, int n) {
    const int[9] slots = {28,14,9,7,5,4,3,2,1};
    const int[9] widths = {1,2,3,4,5,7,9,14,28};
    int position = 0;
    while (position < n) {
        int selector = 0, take = 0, width = 0;
        for (int s = 0; s < 9; s++) {
            int count = slots[s] < n - position ? slots[s] : n - position;
            bool fits = true;
            for (int j = 0; j < count; j++) if ((ulong)values[position + j] >= (1ul << widths[s])) fits = false;
            if (fits) { selector = s; take = count; width = widths[s]; break; }
        }
        ulong word = (ulong)selector << 28;
        for (int j = 0; j < take; j++) word |= (ulong)values[position + j] << (28 - width * (j + 1));
        emit_number(out, used, word, 32);
        position += take;
    }
}

fn long integer_sequence_codes(long *input, usz length, uint8 *output, usz capacity) @export("integer_sequence_codes") {
    if (input == null || length < 4 || length > MAX_INPUT) return -1;
    long mode = input[0], n0 = input[1], parameter = input[2];
    if (mode < 0 || mode > 9 || n0 < 1 || n0 > MAX_N || length != (usz)n0 + 3) return -1;
    int n = (int)n0;
    long *values = input + 3;
    if (mode == 0) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] > 31) return -1;
    } else if (mode == 1) {
        if (parameter < 2 || parameter > 1000000) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] >= parameter) return -1;
    } else if (mode == 2 || mode == 3) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else if (mode == 4) {
        if (parameter < 1 || parameter > 128) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] > 127) return -1;
    } else if (mode == 7) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else if (mode == 8) {
        if (parameter != 0) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] >= (1l << 28)) return -1;
    } else if (mode == 9) {
        if (parameter < 1 || parameter > 20) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] > 1000000) return -1;
    } else {
        if (parameter < 2 || parameter > 4096 || n > parameter) return -1;
        for (int i = 0; i < n; i++) if (values[i] < 0 || values[i] >= parameter || (i > 0 && values[i - 1] >= values[i])) return -1;
    }
    uint8[4096] staged = zeroed;
    usz used = 0;
    if (mode == 0) {
        for (int i = 0; i < n; i++) emit_unary(&staged[0], &used, (ulong)values[i]);
    } else if (mode == 1) {
        for (int i = 0; i < n; i++) emit_minimal(&staged[0], &used, (ulong)values[i], (ulong)parameter);
    } else if (mode == 2) {
        for (int i = 0; i < n; i++) emit_gamma(&staged[0], &used, (ulong)values[i]);
    } else if (mode == 3) {
        for (int i = 0; i < n; i++) emit_delta(&staged[0], &used, (ulong)values[i]);
    } else if (mode == 4) {
        for (int i = 0; i < n; i++) {
            ulong quotient = (ulong)(values[i] / parameter), remainder = (ulong)(values[i] % parameter);
            emit_unary(&staged[0], &used, quotient);
            emit_minimal(&staged[0], &used, remainder, (ulong)parameter);
        }
    } else if (mode == 5) {
        int width = 0;
        while ((ulong)n * (1ul << (width + 1)) <= (ulong)parameter) width++;
        ulong bucket_size = 1ul << width;
        int buckets = (int)(((ulong)parameter + bucket_size - 1) / bucket_size);
        uint8[4096] counts = zeroed;
        for (int i = 0; i < n; i++) counts[(ulong)values[i] / bucket_size]++;
        for (int b = 0; b < buckets; b++) emit_unary(&staged[0], &used, counts[b]);
        for (int i = 0; i < n; i++) emit_number(&staged[0], &used, (ulong)values[i] % bucket_size, width);
    } else if (mode == 6) {
        emit_interpolative(&staged[0], &used, values, 0, n, 0, parameter);
    } else if (mode == 7) {
        for (int i = 0; i < n; i++) {
            ulong value = (ulong)values[i];
            int highest = floor_log2(value);
            if (highest < 0) highest = 0; else highest = (highest / 7) * 7;
            for (int shift = highest; shift >= 0; shift -= 7) {
                uint8 byte = (uint8)((value >> shift) & 0x7ful);
                if (shift != 0) byte |= 0x80;
                emit_byte(&staged[0], &used, byte);
            }
        }
    } else if (mode == 8) {
        emit_simple9(&staged[0], &used, values, n);
    } else {
        int width = (int)parameter;
        ulong low_mask = (1ul << width) - 1;
        int exception_count = 0;
        for (int i = 0; i < n; i++) {
            emit_number(&staged[0], &used, (ulong)values[i] & low_mask, width);
            if ((ulong)values[i] >= (1ul << width)) exception_count++;
        }
        emit_number(&staged[0], &used, (ulong)exception_count, 6);
        int position_width = 0;
        while ((1 << position_width) < n) position_width++;
        for (int i = 0; i < n; i++) if ((ulong)values[i] >= (1ul << width)) {
            emit_number(&staged[0], &used, (ulong)i, position_width);
            emit_number(&staged[0], &used, (ulong)values[i], 20);
        }
    }
    if (output == null) return -2;
    if (mode == 7) {
        if (capacity < used) return -2;
        for (usz i = 0; i < used; i++) output[i] = staged[i];
        return (long)used;
    }
    usz bytes = (used + 7) / 8;
    if (capacity < bytes) return -2;
    uint8[MAX_RESULT] packed = zeroed;
    for (usz i = 0; i < used; i++) if (staged[i] == '1') packed[i / 8] |= (uint8)(1u << (7 - i % 8));
    for (usz i = 0; i < bytes; i++) output[i] = packed[i];
    return (long)bytes;
}
