const max_jobs: usize = 4;
const max_time: usize = 8;
const max_input: usize = 13;
const max_output: usize = 152;

fn gcd64(a0: i64, b0: i64) i64 {
    var a = a0;
    var b = b0;
    while (b != 0) {
        const r = @rem(a, b);
        a = b;
        b = r;
    }
    return a;
}

fn put64(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn yds_speed_scaling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    if (n64 < 1 or n64 > 4) return -1;
    const n: usize = @intCast(n64);
    if (length != 1 + 3 * n) return -1;
    var release: [max_jobs]usize = @splat(0);
    var deadline: [max_jobs]usize = @splat(0);
    var work: [max_jobs]i64 = @splat(0);
    var active: [max_jobs]bool = @splat(false);
    for (0..n) |j| {
        const r = input[1 + 3*j];
        const d = input[2 + 3*j];
        const w = input[3 + 3*j];
        if (r < 0 or r >= d or d > 8 or w < 1 or w > 8) return -1;
        release[j] = @intCast(r);
        deadline[j] = @intCast(d);
        work[j] = w;
        active[j] = true;
    }
    var staged: [max_output / 8]i64 = @splat(0);
    var output_values: usize = 3;
    var stages: i64 = 0;
    var energy_num: i64 = 0;
    var energy_den: i64 = 1;
    var remaining = n;
    while (remaining > 0) {
        var release_seen: [max_time + 1]bool = @splat(false);
        var deadline_seen: [max_time + 1]bool = @splat(false);
        for (0..n) |j| {
            if (active[j]) { release_seen[release[j]] = true; deadline_seen[deadline[j]] = true; }
        }
        var have_best = false;
        var best_a: usize = 0;
        var best_b: usize = 1;
        var best_work: i64 = 0;
        var best_duration: i64 = 1;
        for (0..max_time + 1) |a| {
            if (!release_seen[a]) continue;
            for (a + 1..max_time + 1) |b| {
                if (!deadline_seen[b]) continue;
                var total: i64 = 0;
                for (0..n) |j| {
                    if (active[j] and release[j] >= a and deadline[j] <= b) total += work[j];
                }
                if (total == 0) continue;
                const duration: i64 = @intCast(b - a);
                if (!have_best or total * best_duration > best_work * duration or
                    (total * best_duration == best_work * duration and (a < best_a or (a == best_a and b < best_b)))) {
                    have_best = true;
                    best_a = a;
                    best_b = b;
                    best_work = total;
                    best_duration = duration;
                }
            }
        }
        if (!have_best) return -1;
        var job_mask: u64 = 0;
        for (0..n) |j| {
            if (active[j] and release[j] >= best_a and deadline[j] <= best_b) {
                job_mask |= @as(u64, 1) << @intCast(j);
            }
        }
        staged[output_values] = @intCast(best_a); output_values += 1;
        staged[output_values] = @intCast(best_b); output_values += 1;
        staged[output_values] = best_work; output_values += 1;
        staged[output_values] = @intCast(job_mask); output_values += 1;

        const term_num = best_work * best_work * best_work;
        const term_den = best_duration * best_duration;
        const common = gcd64(energy_den, term_den);
        energy_num = energy_num * @divTrunc(term_den, common) + term_num * @divTrunc(energy_den, common);
        energy_den *= @divTrunc(term_den, common);
        const energy_gcd = gcd64(energy_num, energy_den);
        energy_num = @divTrunc(energy_num, energy_gcd);
        energy_den = @divTrunc(energy_den, energy_gcd);

        for (0..n) |j| {
            if (!active[j]) continue;
            if (release[j] >= best_a and deadline[j] <= best_b) {
                active[j] = false;
                remaining -= 1;
            } else {
                if (release[j] > best_a and release[j] < best_b) {
                    release[j] = best_a;
                } else if (release[j] >= best_b) {
                    release[j] -= @intCast(best_duration);
                }
                if (deadline[j] > best_a and deadline[j] < best_b) {
                    deadline[j] = best_a;
                } else if (deadline[j] >= best_b) {
                    deadline[j] -= @intCast(best_duration);
                }
            }
        }
        stages += 1;
    }
    staged[0] = stages;
    staged[1] = energy_num;
    staged[2] = energy_den;
    const output_bytes = 8 * output_values;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var bytes: [max_output]u8 = @splat(0);
    for (0..output_values) |i| put64(&bytes, 8 * i, staged[i]);
    @memcpy(output[0..output_bytes], bytes[0..output_bytes]);
    return @intCast(output_bytes);
}
