const max_r: usize = 8;
const max_h: usize = 8;
const max_input: usize = 154;
const max_output: usize = 64;

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn hospitals_residents_rgs(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 5 or length > max_input) return -1;
    const input = input_opt.?;
    const r64 = input[0];
    const h64 = input[1];
    if (r64 < 1 or r64 > 8 or h64 < 1 or h64 > 8) return -1;
    const r: usize = @intCast(r64);
    const h: usize = @intCast(h64);
    if (length != 2 + 2 * h + r + 2 * r * h) return -1;
    const cap_offset: usize = 2;
    const rlen_offset = cap_offset + h;
    const rpref_offset = rlen_offset + r;
    const hlen_offset = rpref_offset + r * h;
    const hpref_offset = hlen_offset + h;
    var capacities: [max_h]i64 = @splat(0);
    var resident_length: [max_r]i64 = @splat(0);
    var resident_pref: [max_r * max_h]i64 = @splat(-1);
    var hospital_length: [max_h]i64 = @splat(0);
    var hospital_rank: [max_h * max_r]i64 = @splat(-1);
    var assignment: [max_r]i64 = @splat(-1);
    var next_choice: [max_r]usize = @splat(0);
    var occupancy: [max_h]usize = @splat(0);
    for (0..h) |hospital| {
        capacities[hospital] = input[cap_offset + hospital];
        hospital_length[hospital] = input[hlen_offset + hospital];
        if (capacities[hospital] < 1 or capacities[hospital] > r64 or
            hospital_length[hospital] < 0 or hospital_length[hospital] > r64) return -1;
    }
    for (0..r) |resident| {
        resident_length[resident] = input[rlen_offset + resident];
        if (resident_length[resident] < 0 or resident_length[resident] > h64) return -1;
        var seen: [max_h]bool = @splat(false);
        for (0..h) |slot| {
            const value = input[rpref_offset + resident * h + slot];
            if (slot < @as(usize, @intCast(resident_length[resident]))) {
                if (value < 0 or value >= h64) return -1;
                const id: usize = @intCast(value);
                if (seen[id]) return -1;
                seen[id] = true;
                resident_pref[resident * max_h + slot] = value;
            } else if (value != -1) return -1;
        }
    }
    for (0..h) |hospital| {
        var seen: [max_r]bool = @splat(false);
        for (0..r) |slot| {
            const value = input[hpref_offset + hospital * r + slot];
            if (slot < @as(usize, @intCast(hospital_length[hospital]))) {
                if (value < 0 or value >= r64) return -1;
                const id: usize = @intCast(value);
                if (seen[id]) return -1;
                seen[id] = true;
                hospital_rank[hospital * max_r + id] = @intCast(slot);
            } else if (value != -1) return -1;
        }
    }
    for (0..r) |resident| {
        for (0..h) |hospital| {
            var accepts = false;
            for (0..@as(usize, @intCast(resident_length[resident]))) |slot| {
                if (resident_pref[resident * max_h + slot] == @as(i64, @intCast(hospital))) accepts = true;
            }
            if (accepts != (hospital_rank[hospital * max_r + resident] >= 0)) return -1;
        }
    }
    const output_bytes = 8 * r;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;

    while (true) {
        var proposer = r;
        for (0..r) |resident| {
            if (assignment[resident] == -1 and next_choice[resident] < @as(usize, @intCast(resident_length[resident]))) {
                proposer = resident;
                break;
            }
        }
        if (proposer == r) break;
        const hospital: usize = @intCast(resident_pref[proposer * max_h + next_choice[proposer]]);
        next_choice[proposer] += 1;
        if (occupancy[hospital] < @as(usize, @intCast(capacities[hospital]))) {
            assignment[proposer] = @intCast(hospital);
            occupancy[hospital] += 1;
        } else {
            var worst = r;
            for (0..r) |resident| {
                if (assignment[resident] == @as(i64, @intCast(hospital)) and
                    (worst == r or hospital_rank[hospital * max_r + resident] > hospital_rank[hospital * max_r + worst])) worst = resident;
            }
            if (worst == r) return -1;
            if (hospital_rank[hospital * max_r + proposer] < hospital_rank[hospital * max_r + worst]) {
                assignment[worst] = -1;
                assignment[proposer] = @intCast(hospital);
            }
        }
    }
    var staged: [max_output]u8 = @splat(0);
    for (0..r) |resident| put64(&staged, 8 * resident, assignment[resident]);
    for (0..output_bytes) |byte| output[byte] = staged[byte];
    return @intCast(output_bytes);
}
