const MAX_LINES: usize = 16;
const MAX_SIDE: usize = 8;
const Domains = [MAX_LINES * 4]u64;

const Parsed = struct {
    height: usize,
    width: usize,
    clues: [MAX_LINES * 8]i64,
    counts: [MAX_LINES]usize,
};

fn parse(input: []const i64) ?Parsed {
    if (input.len < 2 or input[0] < 1 or input[0] > 8 or input[1] < 1 or input[1] > 8) return null;
    const height: usize = @intCast(input[0]);
    const width: usize = @intCast(input[1]);
    if (input.len != 2 + 5 * height + 5 * width) return null;
    var parsed = Parsed{ .height = height, .width = width,
        .clues = @splat(0), .counts = @splat(0) };
    var offset: usize = 2;
    for (0..2) |group| {
        const lines = if (group == 0) height else width;
        const line_length = if (group == 0) width else height;
        for (0..lines) |line| {
            const index = if (group == 0) line else height + line;
            const raw_count = input[offset]; offset += 1;
            if (raw_count < 0 or raw_count > 4) return null;
            const run_count: usize = @intCast(raw_count);
            parsed.counts[index] = run_count;
            var needed: i64 = if (raw_count == 0) 0 else raw_count - 1;
            for (0..4) |run| {
                const value = input[offset]; offset += 1;
                if (run < run_count) {
                    if (value <= 0 or value > @as(i64, @intCast(line_length))) return null;
                    parsed.clues[index * 8 + run] = value;
                    needed += value;
                } else if (value != 0) return null;
            }
            if (needed > @as(i64, @intCast(line_length))) return null;
        }
    }
    var row_total: i64 = 0;
    var col_total: i64 = 0;
    for (0..height) |row| {
        for (0..parsed.counts[row]) |run| row_total += parsed.clues[row * 8 + run];
    }
    for (0..width) |col| {
        const line = height + col;
        for (0..parsed.counts[line]) |run| col_total += parsed.clues[line * 8 + run];
    }
    if (row_total != col_total) return null;
    return parsed;
}

fn matches(mask: usize, length: usize, clues: *const [MAX_LINES * 8]i64,
           line: usize, count: usize) bool {
    var found: usize = 0;
    var run: usize = 0;
    for (0..length) |bit| {
        if ((mask >> bit) & 1 != 0) run += 1 else if (run != 0) {
            if (found >= count or clues[line * 8 + found] != @as(i64, @intCast(run))) return false;
            found += 1;
            run = 0;
        }
    }
    if (run != 0) {
        if (found >= count or clues[line * 8 + found] != @as(i64, @intCast(run))) return false;
        found += 1;
    }
    return found == count;
}
fn has(domains: *const Domains, line: usize, mask: usize) bool {
    return (domains[line * 4 + mask / 64] & (@as(u64, 1) << @intCast(mask % 64))) != 0;
}
fn add(domains: *Domains, line: usize, mask: usize) void {
    domains[line * 4 + mask / 64] |= @as(u64, 1) << @intCast(mask % 64);
}
fn domainCount(domains: *const Domains, line: usize, length: usize) usize {
    var total: usize = 0;
    for (0..(1 << length)) |mask| if (has(domains, line, mask)) { total += 1; };
    return total;
}
fn filter(domains: *Domains, line: usize, length: usize, pos: usize,
           allow_zero: bool, allow_one: bool) bool {
    var changed = false;
    for (0..(1 << length)) |mask| {
        if (!has(domains, line, mask)) continue;
        const one = (mask >> pos) & 1 != 0;
        if ((one and allow_one) or (!one and allow_zero)) continue;
        domains[line * 4 + mask / 64] &= ~(@as(u64, 1) << @intCast(mask % 64));
        changed = true;
    }
    return changed;
}
fn support(domains: *const Domains, line: usize, length: usize, pos: usize,
           zero: *bool, one: *bool) bool {
    zero.* = false;
    one.* = false;
    for (0..(1 << length)) |mask| {
        if (!has(domains, line, mask)) continue;
        if ((mask >> pos) & 1 != 0) one.* = true else zero.* = true;
    }
    return zero.* or one.*;
}
fn propagate(domains: *Domains, height: usize, width: usize) bool {
    var changed = true;
    while (changed) {
        changed = false;
        for (0..height) |row| {
            for (0..width) |col| {
                var rz = false; var ro = false; var cz = false; var co = false;
                if (!support(domains, row, width, col, &rz, &ro) or
                    !support(domains, height + col, height, row, &cz, &co)) return false;
                if (filter(domains, row, width, col, cz, co)) changed = true;
                if (filter(domains, height + col, height, row, rz, ro)) changed = true;
                if (domainCount(domains, row, width) == 0 or domainCount(domains, height + col, height) == 0) return false;
            }
        }
    }
    return true;
}
fn search(domains: *Domains, height: usize, width: usize) bool {
    if (!propagate(domains, height, width)) return false;
    var branch = height;
    for (0..height) |row| {
        if (domainCount(domains, row, width) > 1) { branch = row; break; }
    }
    if (branch == height) return true;
    for (0..(1 << width)) |mask| {
        if (!has(domains, branch, mask)) continue;
        var trial = domains.*;
        @memset(trial[branch * 4 .. branch * 4 + 4], 0);
        add(&trial, branch, mask);
        if (search(&trial, height, width)) { domains.* = trial; return true; }
    }
    return false;
}
fn solve(parsed: *const Parsed, output: *[64]u8) ?usize {
    var domains: Domains = @splat(0);
    for (0..parsed.height) |row| {
        for (0..(1 << parsed.width)) |mask| {
            if (matches(mask, parsed.width, &parsed.clues, row, parsed.counts[row])) add(&domains, row, mask);
        }
        if (domainCount(&domains, row, parsed.width) == 0) return null;
    }
    for (0..parsed.width) |col| {
        const line = parsed.height + col;
        for (0..(1 << parsed.height)) |mask| {
            if (matches(mask, parsed.height, &parsed.clues, line, parsed.counts[line])) add(&domains, line, mask);
        }
        if (domainCount(&domains, line, parsed.height) == 0) return null;
    }
    if (!search(&domains, parsed.height, parsed.width)) return null;
    for (0..parsed.height) |row| {
        var mask: usize = 0;
        while (mask < (1 << parsed.width) and !has(&domains, row, mask)) mask += 1;
        for (0..parsed.width) |col| output[row * parsed.width + col] = @intCast((mask >> col) & 1);
    }
    return parsed.height * parsed.width;
}

export fn nonogram_line_domain_solver(input: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    if (input == null or length > 82) return -1;
    const values = input.?[0..length];
    const parsed = parse(values) orelse return -1;
    var bytes: [64]u8 = @splat(0);
    const required = solve(&parsed, &bytes) orelse return -1;
    if (output == null or output_capacity < required) return -2;
    @memcpy(output.?[0..required], bytes[0..required]);
    return @intCast(required);
}
