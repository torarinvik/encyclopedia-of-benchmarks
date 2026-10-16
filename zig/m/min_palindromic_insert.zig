const MAX_N: usize = 256;
const MAX_OUTPUT: usize = 527;

fn writeI64(payload: *[MAX_OUTPUT]u8, position: usize, value: i64) usize {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| payload[position + i] = @truncate(bits >> @intCast(8 * i));
    return position + 8;
}

export fn min_palindromic_insert(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 1 or length > MAX_N + 1) return -1;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N)) or length != @as(usize, @intCast(n_value + 1))) return -1;
    const n: usize = @intCast(n_value);
    var chars = [_]u8{0} ** MAX_N;
    for (0..n) |i| {
        if (input[i + 1] < 32 or input[i + 1] > 126) return -1;
        chars[i] = @intCast(input[i + 1]);
    }
    var dp = [_]u16{0} ** (MAX_N * MAX_N);
    for (2..n + 1) |span| {
        for (0..n - span + 1) |left| {
            const right = left + span - 1;
            if (chars[left] == chars[right]) {
                if (span > 2) dp[left * MAX_N + right] = dp[(left + 1) * MAX_N + right - 1];
            } else {
                const a = dp[(left + 1) * MAX_N + right];
                const b = dp[left * MAX_N + right - 1];
                dp[left * MAX_N + right] = @as(u16, @min(a, b)) + 1;
            }
        }
    }
    const insertions: usize = @intCast(dp[n - 1]);
    const palindrome_length = n + insertions;
    var palindrome = [_]u8{0} ** (2 * MAX_N - 1);
    var left: usize = 0;
    var right = n - 1;
    var out_left: usize = 0;
    var out_right = palindrome_length - 1;
    while (left <= right) {
        if (chars[left] == chars[right]) {
            palindrome[out_left] = chars[left]; palindrome[out_right] = chars[right]; left += 1;
            if (right == 0) break;
            right -= 1;
        } else if (dp[(left + 1) * MAX_N + right] < dp[left * MAX_N + right - 1]) {
            palindrome[out_left] = chars[left]; palindrome[out_right] = chars[left]; left += 1;
        } else {
            palindrome[out_left] = chars[right]; palindrome[out_right] = chars[right];
            if (right == 0) break;
            right -= 1;
        }
        out_left += 1;
        if (out_right == 0) break;
        out_right -= 1;
    }
    var payload = [_]u8{0} ** MAX_OUTPUT;
    var written = writeI64(&payload, 0, @intCast(insertions));
    written = writeI64(&payload, written, @intCast(palindrome_length));
    @memcpy(payload[written .. written + palindrome_length], palindrome[0..palindrome_length]);
    written += palindrome_length;
    if (output == null or capacity < written) return -2;
    for (0..written) |i| output[i] = payload[i];
    return @intCast(written);
}
