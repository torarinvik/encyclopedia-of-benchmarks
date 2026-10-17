const MAX_N: usize = 512;
const MAX_VALID_INPUT_LENGTH: usize = 513;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 514;
const MAX_VALUE: i64 = 1_000_000;
const OFFSET: i64 = 1_000_001;
const LEONARDO: [16]usize = .{ 1, 1, 3, 5, 9, 15, 25, 41, 67, 109, 177, 287, 465, 753, 1219, 1973 };

fn sift(values: *[MAX_N]i64, order_arg: usize, root_arg: usize) void {
    var order = order_arg;
    var root = root_arg;
    const value = values[root];
    while (order > 1) {
        const right = root - 1;
        const left = root - 1 - LEONARDO[order - 2];
        if (!(value < values[left]) and !(value < values[right])) break;
        if (!(values[left] < values[right])) {
            values[root] = values[left];
            root = left;
            order -= 1;
        } else {
            values[root] = values[right];
            root = right;
            order -= 2;
        }
    }
    values[root] = value;
}

fn trinkle(values: *[MAX_N]i64, p_arg: u64, order_arg: usize, root_arg: usize, trusty_arg: bool) void {
    var p = p_arg;
    var order = order_arg;
    var root = root_arg;
    var trusty = trusty_arg;
    const value = values[root];
    while (p != 1) {
        const stepson = root - LEONARDO[order];
        if (!(value < values[stepson])) break;
        if (!trusty and order > 1) {
            const right = root - 1;
            const left = root - 1 - LEONARDO[order - 2];
            if (!(values[right] < values[stepson]) or !(values[left] < values[stepson])) break;
        }
        values[root] = values[stepson];
        root = stepson;
        const mask = p & ~@as(u64, 1);
        const shift = @ctz(mask);
        p >>= shift;
        order += @as(usize, shift);
        trusty = false;
    }
    if (!trusty) {
        values[root] = value;
        sift(values, order, root);
    }
}

fn smoothsort(values: *[MAX_N]i64, length: usize) void {
    if (length < 2) return;
    const last = length - 1;
    var p: u64 = 1;
    var pshift: usize = 1;
    var head: usize = 0;
    while (head < last) {
        if ((p & 3) == 3) {
            sift(values, pshift, head);
            p >>= 2;
            pshift += 2;
        } else {
            if (LEONARDO[pshift - 1] >= last - head) trinkle(values, p, pshift, head, false) else sift(values, pshift, head);
            if (pshift == 1) {
                p <<= 1;
                pshift = 0;
            } else {
                p <<= @intCast(pshift - 1);
                pshift = 1;
            }
        }
        p |= 1;
        head += 1;
    }
    trinkle(values, p, pshift, head, false);
    while (pshift != 1 or p != 1) {
        if (pshift <= 1) {
            const mask = p & ~@as(u64, 1);
            const shift = @ctz(mask);
            p >>= shift;
            pshift += @as(usize, shift);
        } else {
            p <<= 2;
            p ^= 7;
            pshift -= 2;
            trinkle(values, p >> 1, pshift + 1, head - LEONARDO[pshift] - 1, true);
            trinkle(values, p, pshift, head - 1, true);
        }
        head -= 1;
    }
}

export fn smooth_sort_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_INPUT_LENGTH or length > MAX_VALID_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > MAX_N) return -1;
    const count: usize = @intCast(input[0]);
    if (length != count + 1) return -1;
    var values: [MAX_N]i64 = @splat(0);
    for (0..count) |index| {
        const value = input[index + 1];
        if (value < -MAX_VALUE or value > MAX_VALUE) return -1;
        values[index] = value;
    }
    smoothsort(&values, count);
    var checksum: i64 = 0;
    for (0..count) |index| checksum += (@as(i64, @intCast(index)) + 1) * (values[index] + OFFSET);
    return checksum;
}
