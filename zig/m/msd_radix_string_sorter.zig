const MAX_STRINGS = 256;
const MAX_LENGTH = 32;
const MAX_INPUT = 1 + MAX_STRINGS * (1 + MAX_LENGTH) + 1;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const EncodedString = struct { bytes: [MAX_LENGTH]u8 = [_]u8{0} ** MAX_LENGTH, length: usize = 0 };

fn bucket(value: *const EncodedString, digit: usize) usize {
    return if (digit >= value.length) 0 else @as(usize, value.bytes[digit]) + 1;
}

fn msdSort(values: *[MAX_STRINGS]EncodedString, auxiliary: *[MAX_STRINGS]EncodedString,
           low: usize, high: usize, digit: usize) void {
    if (high - low < 2 or digit >= MAX_LENGTH) return;
    var counts = [_]usize{0} ** 257;
    for (low..high) |i| counts[bucket(&values[i], digit)] += 1;
    var starts = [_]usize{0} ** 257;
    var next = [_]usize{0} ** 257;
    var position = low;
    for (0..257) |b| { starts[b] = position; next[b] = position; position += counts[b]; }
    for (low..high) |i| { const b = bucket(&values[i], digit); auxiliary[next[b]] = values[i]; next[b] += 1; }
    for (low..high) |i| values[i] = auxiliary[i];
    for (1..257) |b| {
        const first = starts[b]; const last = first + counts[b];
        if (last - first > 1) msdSort(values, auxiliary, first, last, digit + 1);
    }
}

export fn msd_radix_string_sorter(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length == 0 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_STRINGS) return -1;
    const count: usize = @intCast(input[0]);
    var values = [_]EncodedString{.{}} ** MAX_STRINGS;
    var auxiliary = [_]EncodedString{.{}} ** MAX_STRINGS;
    var position: usize = 1;
    for (0..count) |i| {
        if (position >= length or input[position] < 0 or input[position] > MAX_LENGTH) return -1;
        const n: usize = @intCast(input[position]); position += 1;
        if (n > length - position) return -1;
        values[i].length = n;
        for (0..n) |digit| {
            if (input[position] < 0 or input[position] > 255) return -1;
            values[i].bytes[digit] = @intCast(input[position]); position += 1;
        }
    }
    if (position != length) return -1;
    if (count > 1) msdSort(&values, &auxiliary, 0, count, 0);
    var hash = FNV_OFFSET;
    const n16: u16 = @intCast(count);
    hash = (hash ^ @as(u64, @truncate(n16))) *% FNV_PRIME;
    hash = (hash ^ @as(u64, @truncate(n16 >> 8))) *% FNV_PRIME;
    for (values[0..count]) |value| {
        hash = (hash ^ @as(u64, @intCast(value.length))) *% FNV_PRIME;
        for (value.bytes[0..value.length]) |byte| hash = (hash ^ @as(u64, byte)) *% FNV_PRIME;
    }
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}
