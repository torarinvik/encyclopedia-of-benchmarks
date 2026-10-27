const max_m: usize = 6;
const max_w: usize = 6;
const max_input: usize = 74;
const max_output: usize = 48;
const max_steps: usize = 121;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn manPrefers(man: usize, a: usize, b: usize, rank: *const [max_m * max_w]i64,
    woman_partner: *const [max_w]i64) bool {
    const ra = rank.*[man * max_w + a];
    const rb = rank.*[man * max_w + b];
    if (ra != rb) return ra < rb;
    const a_maiden = woman_partner.*[a] == -1;
    const b_maiden = woman_partner.*[b] == -1;
    if (a_maiden != b_maiden) return a_maiden;
    return a < b;
}

fn uncertain(man: usize, w: usize, rank: *const [max_m * max_w]i64,
    live: *const [max_m * max_w]bool, assignment: *const [max_m]i64,
    woman_partner: *const [max_w]i64, status: *const [max_m]u8) bool {
    if (status.*[man] != 0 or assignment.*[man] < 0) return false;
    const fiance: usize = @intCast(assignment.*[man]);
    for (0..w) |woman| {
        if (live.*[man * max_w + woman] and woman != fiance and
            (rank.*[man*max_w+woman] < rank.*[man*max_w+fiance] or
             (rank.*[man*max_w+woman] == rank.*[man*max_w+fiance] and
              woman_partner.*[woman] == -1 and woman_partner.*[fiance] != -1))) return true;
    }
    return false;
}

fn womanPrefers(woman: usize, candidate: usize, incumbent: usize, incumbent_uncertain: bool,
    rank: *const [max_w * max_m]i64, status: *const [max_m]u8) bool {
    if (incumbent_uncertain) return true;
    const rc = rank.*[woman * max_m + candidate];
    const ri = rank.*[woman * max_m + incumbent];
    if (rc != ri) return rc < ri;
    if (status.*[candidate] != status.*[incumbent]) return status.*[candidate] > status.*[incumbent];
    return candidate < incumbent;
}

export fn kiraly_max_smt_i_approx(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const m64 = input[0];
    const w64 = input[1];
    if (m64 < 1 or m64 > 6 or w64 < 1 or w64 > 6) return -1;
    const m: usize = @intCast(m64);
    const w: usize = @intCast(w64);
    if (length != 2 + 2 * m * w) return -1;
    var men_rank: [max_m * max_w]i64 = @splat(0);
    var women_rank: [max_w * max_m]i64 = @splat(0);
    var live: [max_m * max_w]bool = @splat(false);
    var assignment: [max_m]i64 = @splat(-1);
    var woman_partner: [max_w]i64 = @splat(-1);
    var status: [max_m]u8 = @splat(0);
    for (0..m) |man| {
        for (0..w) |woman| {
            const rank = input[2 + man * w + woman];
            if (rank < -1 or rank >= 6) return -1;
            men_rank[man * max_w + woman] = rank;
        }
    }
    for (0..w) |woman| {
        for (0..m) |man| {
            const rank = input[2 + m * w + woman * m + man];
            if (rank < -1 or rank >= 6) return -1;
            women_rank[woman * max_m + man] = rank;
        }
    }
    for (0..m) |man| {
        for (0..w) |woman| {
            const ma = men_rank[man * max_w + woman] >= 0;
            const wa = women_rank[woman * max_m + man] >= 0;
            if (ma != wa) return -1;
            live[man * max_w + woman] = ma;
        }
    }
    const output_bytes = 8 * m;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var steps: usize = 0;
    while (true) {
        steps += 1;
        if (steps > max_steps) return -1;
        var man = m;
        for (0..m) |x| {
            if (status[x] != 2 and assignment[x] == -1) { man = x; break; }
        }
        if (man == m) break;
        var woman = w;
        for (0..w) |x| {
            if (live[man * max_w + x] and (woman == w or manPrefers(man, x, woman, &men_rank, &woman_partner))) woman = x;
        }
        if (woman == w) {
            if (status[man] == 0) {
                status[man] = 1;
                for (0..w) |x| {
                    live[man * max_w + x] = men_rank[man * max_w + x] >= 0;
                }
            } else status[man] = 2;
            continue;
        }
        const incumbent64 = woman_partner[woman];
        if (incumbent64 < 0) {
            assignment[man] = @intCast(woman);
            woman_partner[woman] = @intCast(man);
            continue;
        }
        const incumbent: usize = @intCast(incumbent64);
        const old_uncertain = uncertain(incumbent, w, &men_rank, &live, &assignment, &woman_partner, &status);
        if (womanPrefers(woman, man, incumbent, old_uncertain, &women_rank, &status)) {
            assignment[incumbent] = -1;
            woman_partner[woman] = -1;
            if (!old_uncertain) live[incumbent * max_w + woman] = false;
            assignment[man] = @intCast(woman);
            woman_partner[woman] = @intCast(man);
        } else live[man * max_w + woman] = false;
    }
    var staged: [max_output]u8 = @splat(0);
    for (0..m) |man| put64(&staged, 8 * man, assignment[man]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
