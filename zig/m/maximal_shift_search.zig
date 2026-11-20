const MAX_TEXT: usize = 4096;
const MAX_PATTERN: usize = 128;
const MAX_INPUT_LENGTH: usize = 4227;
const ALPHABET: usize = 4;

fn matchShift(pattern: []const u8, orderLoc: []const i32, orderSymbol: []const i32,
    m: i32, prefixLength: i32, initialShift: i32) i32 {
    var shift = initialShift;
    while (shift < m) {
        var orderIndex = prefixLength - 1;
        while (orderIndex >= 0) {
            const orderAt: usize = @intCast(orderIndex);
            const patternIndex = orderLoc[orderAt] - shift;
            if (patternIndex >= 0 and orderSymbol[orderAt] != pattern[@intCast(patternIndex)]) break;
            orderIndex -= 1;
        }
        if (orderIndex < 0) break;
        shift += 1;
    }
    return shift;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const m64 = input[1];
    if (n64 < 0 or n64 > @as(i64, @intCast(MAX_TEXT)) or
        m64 < 1 or m64 > @as(i64, @intCast(MAX_PATTERN))) return null;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    if (input.len != 2 + n + m) return null;
    var text: [MAX_TEXT]u8 = @splat(0);
    var pattern: [MAX_PATTERN]u8 = @splat(0);
    for (0..n) |q| {
        const value = input[2 + q];
        if (value < 0 or value >= @as(i64, @intCast(ALPHABET))) return null;
        text[q] = @intCast(value);
    }
    for (0..m) |q| {
        const value = input[2 + n + q];
        if (value < 0 or value >= @as(i64, @intCast(ALPHABET))) return null;
        pattern[q] = @intCast(value);
    }
    if (n < m) return 0;

    var leadingShift: [MAX_PATTERN]i32 = @splat(0);
    var orderLoc: [MAX_PATTERN + 1]i32 = @splat(0);
    var orderSymbol: [MAX_PATTERN + 1]i32 = @splat(0);
    var quickShift: [ALPHABET]i32 = @splat(0);
    var adaptedShift: [MAX_PATTERN + 1]i32 = @splat(0);
    for (0..m) |i| {
        var previous: isize = @as(isize, @intCast(i)) - 1;
        while (previous >= 0 and pattern[@intCast(previous)] != pattern[i]) previous -= 1;
        leadingShift[i] = @intCast(@as(isize, @intCast(i)) - previous);
        var position = i;
        while (position > 0) {
            const priorLoc: usize = @intCast(orderLoc[position - 1]);
            if (leadingShift[priorLoc] > leadingShift[i] or
                (leadingShift[priorLoc] == leadingShift[i] and priorLoc > i)) break;
            orderLoc[position] = orderLoc[position - 1];
            position -= 1;
        }
        orderLoc[position] = @intCast(i);
    }
    for (0..m) |i| orderSymbol[i] = @intCast(pattern[@intCast(orderLoc[i])]);
    orderLoc[m] = @intCast(m);
    orderSymbol[m] = -1;
    for (0..ALPHABET) |symbol| quickShift[symbol] = @as(i32, @intCast(m)) + 1;
    for (0..m) |i| quickShift[@intCast(pattern[i])] = @as(i32, @intCast(m - i));

    var shift: i32 = 1;
    adaptedShift[0] = 1;
    for (1..m + 1) |prefixLength| {
        shift = matchShift(pattern[0..m], orderLoc[0..], orderSymbol[0..], @intCast(m), @intCast(prefixLength), shift);
        adaptedShift[prefixLength] = shift;
    }
    for (0..m + 1) |prefixLength| {
        shift = adaptedShift[prefixLength];
        while (shift < @as(i32, @intCast(m))) {
            const patternIndex = orderLoc[prefixLength] - shift;
            if (patternIndex < 0 or orderSymbol[prefixLength] != pattern[@intCast(patternIndex)]) break;
            shift += 1;
            shift = matchShift(pattern[0..m], orderLoc[0..], orderSymbol[0..], @intCast(m), @intCast(prefixLength), shift);
        }
        adaptedShift[prefixLength] = shift;
    }

    var count: i64 = 0;
    var offsetSum: i64 = 0;
    var offsetXor: i64 = 0;
    var start: usize = 0;
    while (start <= n - m) {
        var compared: usize = 0;
        while (compared < m and orderSymbol[compared] == @as(i32, @intCast(text[start + @as(usize, @intCast(orderLoc[compared]))]))) compared += 1;
        if (compared == m) {
            count += 1;
            offsetSum += @intCast(start);
            offsetXor ^= @intCast(start);
        }
        const lookahead = start + m;
        if (lookahead >= n) break;
        const advance: usize = @intCast(@max(adaptedShift[compared], quickShift[@intCast(text[lookahead])]));
        start += advance;
    }
    return (count << 36) | (offsetSum << 12) | offsetXor;
}

export fn maximal_shift_search(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
