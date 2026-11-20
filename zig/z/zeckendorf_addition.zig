const MAX_BITS: usize = 64;
const MAX_PARSEABLE: usize = 131;
const MAX_OUTPUT: usize = 66;

fn canonical(bits: [*]const i64, length: usize) bool {
    if (length == 1 and bits[0] == 0) return true;
    if (length == 0 or bits[0] != 1) return false;
    for (0..length) |i| {
        if (bits[i] != 0 and bits[i] != 1) return false;
        if (i + 1 < length and bits[i] == 1 and bits[i + 1] == 1) return false;
    }
    return true;
}

fn stageOne(d: *[MAX_OUTPUT]u8, n: usize) void {
    if (n >= 4) {
        for (0..n - 3) |i| {
            if (d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 0) {
                d[i] = 1; d[i + 1] = 0; d[i + 2] = 0; d[i + 3] += 1;
            } else if (d[i] == 0 and d[i + 1] == 3 and d[i + 2] == 0) {
                d[i] = 1; d[i + 1] = 1; d[i + 2] = 0; d[i + 3] += 1;
            } else if (d[i] == 0 and d[i + 1] == 2 and d[i + 2] == 1) {
                d[i] = 1; d[i + 1] = 1; d[i + 2] = 0;
            } else if (d[i] == 0 and d[i + 1] == 1 and d[i + 2] == 2) {
                d[i] = 1; d[i + 1] = 0; d[i + 2] = 1;
            }
        }
    }
    if (n >= 3 and d[n - 3] == 0 and d[n - 2] == 3 and d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 0) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    } else if (n >= 4 and d[n - 4] == 0 and d[n - 3] == 1 and d[n - 2] == 2 and d[n - 1] == 0) {
        d[n - 4] = 1; d[n - 3] = 0; d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 and d[n - 3] == 0 and d[n - 2] == 2 and d[n - 1] == 1) {
        d[n - 3] = 1; d[n - 2] = 1; d[n - 1] = 0;
    }
    if (n >= 2 and d[n - 2] == 0 and d[n - 1] == 3) {
        d[n - 2] = 1; d[n - 1] = 1;
    } else if (n >= 2 and d[n - 2] == 0 and d[n - 1] == 2) {
        d[n - 2] = 1; d[n - 1] = 0;
    } else if (n >= 3 and d[n - 3] == 0 and d[n - 2] == 1 and d[n - 1] == 2) {
        d[n - 3] = 1; d[n - 2] = 0; d[n - 1] = 1;
    }
}

export fn zeckendorf_addition(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_PARSEABLE) return -1;
    const values = input.?;
    const first_n_i64 = values[0];
    if (first_n_i64 < 1 or first_n_i64 > MAX_BITS) return -1;
    const first_n: usize = @intCast(first_n_i64);
    const second_n_index = first_n + 1;
    if (second_n_index >= length) return -1;
    const second_n_i64 = values[second_n_index];
    if (second_n_i64 < 1 or second_n_i64 > MAX_BITS) return -1;
    const second_n: usize = @intCast(second_n_i64);
    if (length != second_n_index + second_n + 1) return -1;
    const first = values + 1;
    const second = values + second_n_index + 1;
    if (!canonical(first, first_n) or !canonical(second, second_n)) return -1;

    const width = @max(first_n, second_n);
    const first_offset = width - first_n;
    const second_offset = width - second_n;
    var digits: [MAX_OUTPUT]u8 = @splat(0);
    var digit_count = width + 1;
    for (0..width) |i| {
        const a: u8 = if (i < first_offset) 0 else @intCast(first[i - first_offset]);
        const b: u8 = if (i < second_offset) 0 else @intCast(second[i - second_offset]);
        digits[i + 1] = a + b;
    }
    stageOne(&digits, digit_count);
    var i = digit_count;
    while (i > 0) : (i -= 1) digits[i] = digits[i - 1];
    digits[0] = 0;
    digit_count += 1;
    i = digit_count - 2;
    while (i > 0) : (i -= 1) {
        const start = i - 1;
        if (digits[start] == 0 and digits[start + 1] == 1 and digits[start + 2] == 1) {
            digits[start] = 1; digits[start + 1] = 0; digits[start + 2] = 0;
        }
    }
    for (0..digit_count - 2) |j| {
        if (digits[j] == 0 and digits[j + 1] == 1 and digits[j + 2] == 1) {
            digits[j] = 1; digits[j + 1] = 0; digits[j + 2] = 0;
        }
    }
    var first_output: usize = 0;
    while (first_output + 1 < digit_count and digits[first_output] == 0) first_output += 1;
    const required = digit_count - first_output;
    if (output == null or output_capacity < required) return -2;
    const destination = output.?;
    for (0..required) |j| destination[j] = '0' + digits[first_output + j];
    return @intCast(required);
}
