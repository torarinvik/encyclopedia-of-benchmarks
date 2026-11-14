// Unverified divide-and-conquer tangent-merge hull draft.
const Point = [2]i64;

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b[0]-a[0])*(c[1]-a[1]) - (b[1]-a[1])*(c[0]-a[0]);
}

fn chain(points: *const [32]Point, order: *const [32]usize, out: *[32]usize,
         lo: usize, hi: usize, base: usize, upper: bool) usize {
    if (hi-lo == 1) { out[base] = order[lo]; return 1; }
    const middle = lo+(hi-lo)/2;
    const left_capacity = middle-lo;
    const left_n = chain(points, order, out, lo, middle, base, upper);
    const right_n = chain(points, order, out, middle, hi, base+left_capacity, upper);
    var i = left_n-1;
    var j: usize = 0;
    var changed = true;
    while (changed) {
        changed = false;
        while (i > 0) {
            const sign = cross(points[out[base+i]], points[out[base+left_capacity+j]], points[out[base+i-1]]);
            const move_endpoint = if (upper) sign > 0 else sign < 0;
            if (!move_endpoint) break;
            i -= 1; changed = true;
        }
        while (j+1 < right_n) {
            const sign = cross(points[out[base+i]], points[out[base+left_capacity+j]], points[out[base+left_capacity+j+1]]);
            const move_endpoint = if (upper) sign > 0 else sign < 0;
            if (!move_endpoint) break;
            j += 1; changed = true;
        }
    }
    const suffix = right_n-j;
    for (0..suffix) |k| out[base+i+1+k] = out[base+left_capacity+j+k];
    return i+1+suffix;
}

export fn divide_conquer_tangent_hull(input_opt: ?[*]const i64, length: usize,
                                      output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > 66) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > 32) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1+2*n) return -1;
    var points: [32]Point = undefined;
    var order: [32]usize = undefined;
    var scratch: [32]usize = undefined;
    for (0..n) |i| {
        points[i] = .{ input[1+2*i], input[2+2*i] };
        if (points[i][0] < -1000 or points[i][0] > 1000 or points[i][1] < -1000 or points[i][1] > 1000) return -1;
        for (0..i) |j| {
            if (points[i][0] == points[j][0]) return -1;
        }
        order[i] = i;
    }
    for (0..n) |i| {
        for (i+1..n) |j| {
            for (j+1..n) |k| {
                if (cross(points[i], points[j], points[k]) == 0) return -1;
            }
        }
    }
    var width: usize = 1;
    while (width < n) : (width *= 2) {
        var begin: usize = 0;
        while (begin < n) : (begin += 2*width) {
            const middle = @min(begin+width, n);
            const end = @min(begin+2*width, n);
            var left = begin;
            var right = middle;
            var dest = begin;
            while (left < middle and right < end) : (dest += 1) {
                if (points[order[right]][0] < points[order[left]][0]) {
                    scratch[dest] = order[right]; right += 1;
                } else { scratch[dest] = order[left]; left += 1; }
            }
            while (left < middle) : (left += 1) { scratch[dest] = order[left]; dest += 1; }
            while (right < end) : (right += 1) { scratch[dest] = order[right]; dest += 1; }
        }
        for (0..n) |i| order[i] = scratch[i];
    }
    var lower: [32]usize = undefined;
    var upper: [32]usize = undefined;
    var hull: [32]usize = undefined;
    const lower_n = chain(&points, &order, &lower, 0, n, 0, false);
    const upper_n = chain(&points, &order, &upper, 0, n, 0, true);
    var count: usize = 0;
    for (0..lower_n) |i| { hull[count] = lower[i]; count += 1; }
    var i = upper_n-1;
    while (i > 1) { i -= 1; hull[count] = upper[i]; count += 1; }
    const bytes = 16*count;
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    for (0..count) |index| {
        for (0..2) |axis| {
            const bits: u64 = @bitCast(points[hull[index]][axis]);
            for (0..8) |b| output[16*index+8*axis+b] = @truncate(bits >> @intCast(8*b));
        }
    }
    return @intCast(bytes);
}
