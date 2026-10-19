// Derived from the Reed-Solomon program by Simon Rockliff, 26 June 1991.
// See benchmarks/m/misc_reed_solomon/LICENSE.txt for the complete permission notice.
const MESSAGE_BYTES: usize = 188;
const PARITY_BYTES: usize = 16;
const CODEWORD_BYTES: usize = 204;
const FULL_BYTES: usize = 255;

fn makeTables(alpha: [*]i32, indexOf: [*]i32) void {
    const polynomial = [_]i32{ 1, 0, 1, 1, 1, 0, 0, 0 };
    for (0..256) |i| indexOf[i] = -1;
    var mask: i32 = 1;
    var alpha8: i32 = 0;
    for (0..8) |i| {
        alpha[i] = mask;
        indexOf[@intCast(alpha[i])] = @intCast(i);
        if (polynomial[i] != 0) alpha8 ^= mask;
        mask <<= 1;
    }
    alpha[8] = alpha8;
    indexOf[@intCast(alpha8)] = 8;
    mask >>= 1;
    for (9..FULL_BYTES) |i| {
        if (alpha[i - 1] >= mask)
            alpha[i] = alpha8 ^ ((alpha[i - 1] ^ mask) << 1)
        else
            alpha[i] = alpha[i - 1] << 1;
        indexOf[@intCast(alpha[i])] = @intCast(i);
    }
    indexOf[0] = -1;
}

fn makeGenerator(alpha: [*]i32, indexOf: [*]i32, generator: [*]i32) void {
    generator[0] = 2;
    generator[1] = 1;
    for (2..PARITY_BYTES + 1) |root| {
        generator[root] = 1;
        var index = root;
        while (index > 1) {
            index -= 1;
            if (generator[index] != 0)
                generator[index] = generator[index - 1] ^ alpha[@intCast(@mod(indexOf[@intCast(generator[index])] + @as(i32, @intCast(root)), @as(i32, @intCast(FULL_BYTES))))]
            else
                generator[index] = generator[index - 1];
        }
        generator[0] = alpha[@intCast(@mod(indexOf[@intCast(generator[0])] + @as(i32, @intCast(root)), @as(i32, @intCast(FULL_BYTES))))];
    }
    for (0..PARITY_BYTES + 1) |index| generator[index] = indexOf[@intCast(generator[index])];
}

fn encode(values: [*c]const i64, alpha: [*]i32, indexOf: [*]i32,
          generator: [*]i32, codeword: [*]i32) void {
    var data = [_]i32{0} ** 239;
    var parity = [_]i32{0} ** PARITY_BYTES;
    for (0..MESSAGE_BYTES) |index| data[51 + index] = @intCast(values[index]);
    var dataIndex: i32 = 238;
    while (dataIndex >= 0) : (dataIndex -= 1) {
        const feedback = indexOf[@intCast(data[@intCast(dataIndex)] ^ parity[15])];
        if (feedback != -1) {
            var parityIndex: i32 = 15;
            while (parityIndex > 0) : (parityIndex -= 1) {
                const p: usize = @intCast(parityIndex);
                if (generator[p] != -1)
                    parity[p] = parity[p - 1] ^ alpha[@intCast(@mod(generator[p] + feedback, @as(i32, @intCast(FULL_BYTES))))]
                else
                    parity[p] = parity[p - 1];
            }
            parity[0] = alpha[@intCast(@mod(generator[0] + feedback, @as(i32, @intCast(FULL_BYTES))))];
        } else {
            var parityIndex: i32 = 15;
            while (parityIndex > 0) : (parityIndex -= 1) {
                const p: usize = @intCast(parityIndex);
                parity[p] = parity[p - 1];
            }
            parity[0] = 0;
        }
    }
    for (0..MESSAGE_BYTES) |index| codeword[index] = @intCast(values[index]);
    for (0..PARITY_BYTES) |index| codeword[MESSAGE_BYTES + index] = parity[index];
}

fn multiply(left: i32, right: i32, alpha: [*]i32, indexOf: [*]i32) i32 {
    if (left == 0 or right == 0) return 0;
    var exponent = indexOf[@intCast(left)] + indexOf[@intCast(right)];
    if (exponent >= @as(i32, @intCast(FULL_BYTES))) exponent -= @intCast(FULL_BYTES);
    return alpha[@intCast(exponent)];
}

fn divide(left: i32, right: i32, alpha: [*]i32, indexOf: [*]i32) i32 {
    if (left == 0) return 0;
    var exponent = indexOf[@intCast(left)] - indexOf[@intCast(right)];
    if (exponent < 0) exponent += @intCast(FULL_BYTES);
    return alpha[@intCast(exponent)];
}

fn correctOne(codeword: [*]i32, expectedPosition: i32, alpha: [*]i32, indexOf: [*]i32) bool {
    var syndrome1: i32 = 0;
    var syndrome2: i32 = 0;
    for (0..FULL_BYTES) |fullPosition| {
        var symbol: i32 = 0;
        if (fullPosition < PARITY_BYTES)
            symbol = codeword[MESSAGE_BYTES + fullPosition]
        else if (fullPosition >= 67)
            symbol = codeword[fullPosition - 67];
        syndrome1 ^= multiply(symbol, alpha[fullPosition % FULL_BYTES], alpha, indexOf);
        syndrome2 ^= multiply(symbol, alpha[(2 * fullPosition) % FULL_BYTES], alpha, indexOf);
    }
    if (syndrome1 == 0 and syndrome2 == 0) return true;
    if (syndrome1 == 0) return false;
    const location = divide(syndrome2, syndrome1, alpha, indexOf);
    var fullPosition: i32 = -1;
    for (0..FULL_BYTES) |index| {
        if (alpha[index] == location) {
            fullPosition = @intCast(index);
            break;
        }
    }
    if (fullPosition < 0) return false;
    var transmittedPosition: i32 = 0;
    if (fullPosition < @as(i32, @intCast(PARITY_BYTES)))
        transmittedPosition = @as(i32, @intCast(MESSAGE_BYTES)) + fullPosition
    else if (fullPosition >= 67)
        transmittedPosition = fullPosition - 67
    else
        return false;
    if (transmittedPosition != expectedPosition) return false;
    const magnitude = divide(syndrome1, alpha[@intCast(fullPosition)], alpha, indexOf);
    codeword[@intCast(transmittedPosition)] ^= magnitude;
    return true;
}

export fn misc_reed_solomon(values: [*c]const i64, length: usize,
                            output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or (length != MESSAGE_BYTES + 1 and length != MESSAGE_BYTES + 3)) return -1;
    for (0..MESSAGE_BYTES) |index| if (values[index] < 0 or values[index] > 255) return -1;
    const errorCount = values[MESSAGE_BYTES];
    if ((errorCount == 0 and length != MESSAGE_BYTES + 1) or
        (errorCount == 1 and length != MESSAGE_BYTES + 3) or
        (errorCount != 0 and errorCount != 1)) return -1;
    var errorPosition: i32 = -1;
    if (errorCount == 1) {
        if (values[189] < 0 or values[189] >= @as(i64, @intCast(CODEWORD_BYTES)) or values[190] < 0 or values[190] > 255) return -1;
        errorPosition = @intCast(values[189]);
    }
    if (output == null or output_capacity < CODEWORD_BYTES) return -2;

    var alpha = [_]i32{0} ** FULL_BYTES;
    var indexOf = [_]i32{0} ** 256;
    var generator = [_]i32{0} ** (PARITY_BYTES + 1);
    var staged = [_]i32{0} ** CODEWORD_BYTES;
    makeTables(alpha[0..].ptr, indexOf[0..].ptr);
    makeGenerator(alpha[0..].ptr, indexOf[0..].ptr, generator[0..].ptr);
    encode(values, alpha[0..].ptr, indexOf[0..].ptr, generator[0..].ptr, staged[0..].ptr);
    if (errorCount == 1) staged[@intCast(errorPosition)] = @intCast(values[190]);
    if (!correctOne(staged[0..].ptr, errorPosition, alpha[0..].ptr, indexOf[0..].ptr)) return -1;
    for (0..CODEWORD_BYTES) |index| output[index] = @intCast(staged[index]);
    return @intCast(CODEWORD_BYTES);
}
