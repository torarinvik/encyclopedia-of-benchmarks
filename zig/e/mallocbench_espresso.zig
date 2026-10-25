/*
 * Copyright (c) 1988, 1989, 1990, Regents of the University of California.
 * All rights reserved.
 *
 * Use and copying of this software and preparation of derivative works
 * based upon this software are permitted. However, any distribution of
 * this software or derivative works must include the above copyright
 * notice.
 *
 * This software is made available AS IS, and neither the Electronics
 * Research Laboratory or the University of California make any warranty
 * about the software, its performance or its conformity to any
 * specification.
 *
 * Clean-room bounded EXPAND/IRREDUNDANT profile; no upstream code copied.
 */
const MAX_VARS: usize = 5;
const MAX_TERMS: usize = 32;

fn cubeCovers(fixed: u32, value: u32, minterm: u32) bool {
    return (minterm & fixed) == value;
}

export fn mallocbench_espresso(input: [*c]const i64, length: usize) i64 {
    if (input == null or length != 3) return -1;
    const vars_value = input[0];
    if (vars_value < 1 or vars_value > MAX_VARS or input[1] < 0 or input[2] < 0) return -1;
    const vars: usize = @intCast(vars_value);
    const minterms: usize = @as(usize, 1) << @intCast(vars);
    const valid: u64 = (@as(u64, 1) << @intCast(minterms)) - 1;
    const onset: u64 = @intCast(input[1]);
    const dcset: u64 = @intCast(input[2]);
    if (((onset | dcset) & ~valid) != 0 or (onset & dcset) != 0) return -1;

    var fixed = [_]u32{0} ** MAX_TERMS;
    var values = [_]u32{0} ** MAX_TERMS;
    var count: usize = 0;
    const full: u32 = @intCast(minterms - 1);
    for (0..minterms) |m| {
        if ((onset & (@as(u64, 1) << @intCast(m))) != 0) {
            fixed[count] = full;
            values[count] = @intCast(m);
            count += 1;
        }
    }
    const allowed = onset | dcset;
    for (0..count) |i| {
        for (0..vars) |bit| {
            const candidate_fixed = fixed[i] & ~(@as(u32, 1) << @intCast(bit));
            const candidate_value = values[i] & candidate_fixed;
            var legal = true;
            for (0..minterms) |m| {
                if (cubeCovers(candidate_fixed, candidate_value, @intCast(m)) and
                    (allowed & (@as(u64, 1) << @intCast(m))) == 0) {
                    legal = false;
                    break;
                }
            }
            if (legal) { fixed[i] = candidate_fixed; values[i] = candidate_value; }
        }
    }
    var active = [_]bool{false} ** MAX_TERMS;
    for (0..count) |i| active[i] = true;
    for (0..count) |i| {
        var redundant = true;
        for (0..minterms) |m| {
            const bit = @as(u64, 1) << @intCast(m);
            if ((onset & bit) == 0 or !cubeCovers(fixed[i], values[i], @intCast(m))) continue;
            var covered = false;
            for (0..count) |j| {
                if (j != i and active[j] and cubeCovers(fixed[j], values[j], @intCast(m))) {
                    covered = true;
                    break;
                }
            }
            if (!covered) { redundant = false; break; }
        }
        if (redundant) active[i] = false;
    }
    var cubes: i64 = 0;
    var literals: i64 = 0;
    for (0..count) |i| {
        if (!active[i]) continue;
        cubes += 1;
        for (0..vars) |bit| literals += @intCast((fixed[i] >> @intCast(bit)) & 1);
    }
    return cubes * 1024 + literals;
}
