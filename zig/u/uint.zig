const MAX_DIGITS: usize = 64;
const MAX_OUTPUT_DIGITS: usize = 1665;

const Big = struct {
    digits: [MAX_OUTPUT_DIGITS]u32 = [_]u32{0} ** MAX_OUTPUT_DIGITS,
    len: usize = 0,
};

fn trim(value: *Big) void {
    while (value.len > 0 and value.digits[value.len - 1] == 0) value.len -= 1;
}

fn fromSmall(value_input: u32, base: u32) Big {
    var value = value_input;
    var result: Big = .{};
    while (value > 0) {
        result.digits[result.len] = value % base;
        result.len += 1;
        value /= base;
    }
    return result;
}

fn add(left: *Big, right: *const Big, base: u32) void {
    var index: usize = 0;
    var carry: u64 = 0;
    while (index < right.len or carry != 0) {
        const a: u64 = if (index < left.len) @as(u64, left.digits[index]) else @as(u64, 0);
        const b: u64 = if (index < right.len) @as(u64, right.digits[index]) else @as(u64, 0);
        const sum = carry + a + b;
        left.digits[index] = @intCast(sum % @as(u64, base));
        if (index >= left.len) left.len = index + 1;
        carry = sum / @as(u64, base);
        index += 1;
    }
    if (left.len < right.len) {
        @memcpy(left.digits[left.len..right.len], right.digits[left.len..right.len]);
        left.len = right.len;
    }
}

fn multiply(left: *const Big, right: *const Big, base: u32) Big {
    var result: Big = .{};
    if (left.len == 0 or right.len == 0) return result;
    result.len = left.len + right.len;
    for (0..left.len) |i| {
        var carry: u64 = 0;
        for (0..right.len) |j| {
            const at = i + j;
            const product = @as(u64, left.digits[i]) * @as(u64, right.digits[j]) + @as(u64, result.digits[at]) + carry;
            result.digits[at] = @intCast(product % @as(u64, base));
            carry = product / @as(u64, base);
        }
        var at = i + right.len;
        while (carry != 0) {
            const sum = @as(u64, result.digits[at]) + carry;
            result.digits[at] = @intCast(sum % @as(u64, base));
            carry = sum / @as(u64, base);
            at += 1;
            if (at > result.len) result.len = at;
        }
    }
    trim(&result);
    return result;
}

fn power(factor_input: Big, exponent_input: usize, base: u32) Big {
    var factor = factor_input;
    var exponent = exponent_input;
    var result = fromSmall(1, base);
    while (exponent > 0) {
        if ((exponent & 1) != 0) result = multiply(&result, &factor, base);
        exponent >>= 1;
        if (exponent > 0) factor = multiply(&factor, &factor, base);
    }
    return result;
}

fn convertBase(digits: []const u32, source_base: u32, target_base: u32) Big {
    if (digits.len == 0) return .{};
    if (source_base == target_base) {
        var copy: Big = .{};
        copy.len = digits.len;
        @memcpy(copy.digits[0..digits.len], digits);
        return copy;
    }
    if (digits.len == 1) return fromSmall(digits[0], target_base);
    const middle = digits.len / 2;
    var low = convertBase(digits[0..middle], source_base, target_base);
    const high = convertBase(digits[middle..], source_base, target_base);
    const scale = power(fromSmall(source_base, target_base), middle, target_base);
    const shifted = multiply(&high, &scale, target_base);
    add(&low, &shifted, target_base);
    return low;
}

export fn uint_convert_base(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_DIGITS + 4) return -1;
    const values = input.?[0..length];
    const source_value = values[0];
    const target_value = values[1];
    const count_value = values[2];
    if (source_value < 2 or source_value > (1 << 26) or target_value < 2 or target_value > (1 << 26) or
        count_value < 0 or count_value > @as(i64, @intCast(MAX_DIGITS)) or length != @as(usize, @intCast(count_value)) + 3) return -1;
    const source_base: u32 = @intCast(source_value);
    const target_base: u32 = @intCast(target_value);
    const count: usize = @intCast(count_value);
    var source_digits: [MAX_DIGITS]u32 = [_]u32{0} ** MAX_DIGITS;
    for (0..count) |i| {
        if (values[i + 3] < 0 or values[i + 3] >= source_value) return -1;
        source_digits[i] = @intCast(values[i + 3]);
    }
    if (count > 0 and source_digits[count - 1] == 0) return -1;
    const result = convertBase(source_digits[0..count], source_base, target_base);
    if (result.len > 1664) return -1;
    const bytes = result.len * 4;
    if (output == null or capacity < bytes) return -2;
    for (0..result.len) |i| {
        for (0..4) |byte| output.?[i * 4 + byte] = @truncate(result.digits[i] >> @as(u5, @intCast(byte * 8)));
    }
    return @intCast(bytes);
}
