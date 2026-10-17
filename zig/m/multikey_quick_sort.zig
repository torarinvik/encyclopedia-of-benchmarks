const MAX_STRINGS: usize = 32;
const MAX_STRING_LENGTH: usize = 16;
const MAX_INPUT_WORDS: usize = 1 + MAX_STRINGS * (1 + MAX_STRING_LENGTH);
const MAX_PARSEABLE_INPUT_WORDS: usize = MAX_INPUT_WORDS + 1;
const MAX_OUTPUT_BYTES: usize = 4 * MAX_INPUT_WORDS;

const StringRecord = struct { length: usize = 0, bytes: [MAX_STRING_LENGTH]u8 = [_]u8{0} ** MAX_STRING_LENGTH };

fn charAt(value: StringRecord, depth: usize) i32 {
    return if (depth < value.length) value.bytes[depth] else 0;
}
fn median3(a: i32, b: i32, c: i32) i32 {
    if (a < b) return if (b < c) b else if (a < c) c else a;
    return if (b > c) b else if (a < c) a else c;
}
fn compareFromDepth(left: StringRecord, right: StringRecord, depth_value: usize) i32 {
    var depth = depth_value;
    while (depth < left.length and depth < right.length and left.bytes[depth] == right.bytes[depth]) : (depth += 1) {}
    const a = charAt(left, depth);
    const b = charAt(right, depth);
    return @as(i32, @intFromBool(a > b)) - @as(i32, @intFromBool(a < b));
}
fn insertionSort(values: *[MAX_STRINGS]StringRecord, lo: usize, hi: usize, depth: usize) void {
    var i = lo + 1;
    while (i < hi) : (i += 1) {
        const value = values[i];
        var j = i;
        while (j > lo and compareFromDepth(values[j - 1], value, depth) > 0) : (j -= 1) values[j] = values[j - 1];
        values[j] = value;
    }
}
fn multikeySort(values: *[MAX_STRINGS]StringRecord, lo: usize, hi: usize, depth: usize) void {
    const count = hi - lo;
    if (count < 10) { insertionSort(values, lo, hi, depth); return; }
    const mid = lo + count / 2;
    const pivot = if (count > 30) blk: {
        const delta = count / 8;
        break :blk median3(
            median3(charAt(values[lo], depth), charAt(values[lo + delta], depth), charAt(values[lo + 2 * delta], depth)),
            median3(charAt(values[mid - delta], depth), charAt(values[mid], depth), charAt(values[mid + delta], depth)),
            median3(charAt(values[hi - 1 - 2 * delta], depth), charAt(values[hi - 1 - delta], depth), charAt(values[hi - 1], depth)),
        );
    } else median3(charAt(values[lo], depth), charAt(values[mid], depth), charAt(values[hi - 1], depth));
    var less = lo;
    var scan = lo;
    var greater = hi;
    while (scan < greater) {
        const key = charAt(values[scan], depth);
        if (key < pivot) {
            const tmp = values[less]; values[less] = values[scan]; values[scan] = tmp;
            less += 1; scan += 1;
        } else if (key > pivot) {
            greater -= 1;
            const tmp = values[greater]; values[greater] = values[scan]; values[scan] = tmp;
        } else scan += 1;
    }
    multikeySort(values, lo, less, depth);
    if (pivot != 0) multikeySort(values, less, greater, depth + 1);
    multikeySort(values, greater, hi, depth);
}
fn putI32Le(output: []u8, offset: usize, value: i32) void {
    const bits: u32 = @bitCast(value);
    for (0..4) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn multikey_quick_sort(input_opt: ?[*]const i32, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_WORDS) return -1;
    const input = input_opt.?;
    const count_raw = input[0];
    if (count_raw < 0 or count_raw > MAX_STRINGS) return -1;
    const count: usize = @intCast(count_raw);
    var values: [MAX_STRINGS]StringRecord = [_]StringRecord{.{}} ** MAX_STRINGS;
    var pos: usize = 1;
    for (0..count) |i| {
        if (pos >= length or input[pos] < 0 or input[pos] > MAX_STRING_LENGTH) return -1;
        const string_length: usize = @intCast(input[pos]); pos += 1;
        if (pos + string_length > length) return -1;
        values[i].length = string_length;
        for (0..string_length) |j| {
            const byte = input[pos]; pos += 1;
            if (byte < 1 or byte > 127) return -1;
            values[i].bytes[j] = @intCast(byte);
        }
    }
    if (pos != length) return -1;
    const bytes = length * 4;
    if (output_opt == null or capacity < bytes) return -2;
    multikeySort(&values, 0, count, 0);
    var buffer: [MAX_OUTPUT_BYTES]u8 = undefined;
    var word: usize = 0;
    putI32Le(&buffer, word * 4, count_raw); word += 1;
    for (0..count) |i| {
        putI32Le(&buffer, word * 4, @intCast(values[i].length)); word += 1;
        for (0..values[i].length) |j| { putI32Le(&buffer, word * 4, values[i].bytes[j]); word += 1; }
    }
    const output = output_opt.?;
    for (0..bytes) |i| output[i] = buffer[i];
    return @intCast(bytes);
}
