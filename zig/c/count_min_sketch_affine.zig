const PRIME: i64 = 2_147_483_647;

fn putI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

pub export fn count_min_sketch_affine(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 59) return -1;
    const d0 = input[0];
    const w0 = input[1];
    const ops0 = input[2];
    if (d0 < 1 or d0 > 4 or w0 < 1 or w0 > 8 or ops0 < 0 or ops0 > 16) return -1;
    const d: usize = @intCast(d0); const w: usize = @intCast(w0); const ops: usize = @intCast(ops0);
    const start = 3 + 2*d;
    if (length != start + 3*ops) return -1;
    var a = [_]i64{0} ** 4; var b = [_]i64{0} ** 4;
    for (0..d) |r| {
        a[r] = input[3+2*r]; b[r] = input[4+2*r];
        if (a[r] < 1 or a[r] >= PRIME or b[r] < 0 or b[r] >= PRIME) return -1;
    }
    var queries: usize = 0;
    for (0..ops) |op| {
        const kind = input[start+3*op]; const key = input[start+3*op+1]; const weight = input[start+3*op+2];
        if (key < 0 or key > 1_000_000) return -1;
        if (kind == 0) { if (weight < 1 or weight > 1_000_000) return -1; }
        else if (kind == 1) { if (weight != 0) return -1; queries += 1; }
        else return -1;
    }
    var table = [_][8]i64{[_]i64{0} ** 8} ** 4;
    var staged = [_]i64{0} ** 16; var result_count: usize = 0;
    for (0..ops) |op| {
        const kind = input[start+3*op]; const key = input[start+3*op+1]; const weight = input[start+3*op+2];
        var slots = [_]usize{0} ** 4;
        for (0..d) |r| slots[r] = @intCast(@mod(@mod(a[r]*key+b[r], PRIME), @as(i64, @intCast(w))));
        if (kind == 0) { for (0..d) |r| table[r][slots[r]] += weight; }
        else {
            var minimum = table[0][slots[0]];
            for (1..d) |r| {
                if (table[r][slots[r]] < minimum) minimum = table[r][slots[r]];
            }
            staged[result_count] = minimum; result_count += 1;
        }
    }
    const required = queries * 8;
    if (capacity < required or (required > 0 and output == null)) return -2;
    if (required > 0) {
        for (0..result_count) |i| putI64Le(output, 8*i, staged[i]);
    }
    return @intCast(required);
}
