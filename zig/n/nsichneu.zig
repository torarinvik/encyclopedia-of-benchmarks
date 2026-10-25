const input_count: usize = 9;
const output_count: usize = 17;
const output_bytes: usize = output_count * 8;
const max_runs: i64 = 64;

pub export fn nsichneu(input: [*c]const i64, length: usize,
                       output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != input_count or input[0] < 1 or input[0] > max_runs) return -1;
    for (1..input_count) |index| {
        if (input[index] < -1000 or input[index] > 1000) return -1;
    }
    if (output == null or capacity < output_bytes) return -2;

    var p1 = [3]i64{ input[1], input[2], input[3] };
    var p2 = [5]i64{ input[4], input[5], input[6], input[7], input[8] };
    var p3 = [_]i64{0} ** 6;
    var p1_count: i64 = 3;
    var p2_count: i64 = 5;
    var p3_count: i64 = 0;

    const runs: usize = @intCast(input[0]);
    for (0..runs) |_| {
        p1_count = 3;
        p2_count = 5;
        p3_count = 0;
        for (0..3) |first| {
            for (0..3) |second| {
                if (second == first) continue;
                for (0..3) |third| {
                    if (third == first or third == second) continue;
                    if (p1_count >= 3 and p3_count + 3 <= 6 and p1[second] == p1[third]) {
                        const x = p1[first];
                        const y = p1[second];
                        if (x < y) {
                            const at: usize = @intCast(p3_count);
                            p1_count -= 3;
                            p3[at] = x;
                            p3[at + 1] = y;
                            p3[at + 2] = x - y;
                            p3_count += 3;
                        }
                    }
                }
            }
        }

        for (0..5) |subset_number| {
            const omitted = 4 - subset_number;
            var subset: [4]usize = .{0} ** 4;
            var count: usize = 0;
            for (0..5) |index| {
                if (index != omitted) {
                    subset[count] = index;
                    count += 1;
                }
            }
            for (0..4) |a| {
                for (0..4) |b| {
                    if (b == a) continue;
                    for (0..4) |c| {
                        if (c == a or c == b) continue;
                        for (0..4) |d| {
                            if (d == a or d == b or d == c) continue;
                            const i0 = subset[a];
                            const i1 = subset[b];
                            const i2 = subset[c];
                            const i3 = subset[d];
                            if (p2_count >= 4 and p3_count + 3 <= 6 and
                                p2[i1] == p2[i2] and p2[i1] == p2[i3])
                            {
                                const x = p2[i0];
                                const y = p2[i1];
                                if (y > x) {
                                    const at: usize = @intCast(p3_count);
                                    p2_count -= 4;
                                    p3[at] = x;
                                    p3[at + 1] = y;
                                    p3[at + 2] = x + y;
                                    p3_count += 3;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    var snapshot: [output_count]i64 = .{0} ** output_count;
    var position: usize = 0;
    snapshot[position] = p1_count;
    position += 1;
    for (p1) |value| { snapshot[position] = value; position += 1; }
    snapshot[position] = p2_count;
    position += 1;
    for (p2) |value| { snapshot[position] = value; position += 1; }
    snapshot[position] = p3_count;
    position += 1;
    for (p3) |value| { snapshot[position] = value; position += 1; }
    for (0..output_count) |index| {
        const bits: u64 = @bitCast(snapshot[index]);
        for (0..8) |byte| output[index * 8 + byte] = @truncate(bits >> @intCast(byte * 8));
    }
    return @intCast(output_bytes);
}
