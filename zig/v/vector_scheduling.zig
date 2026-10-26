// Clean-room explicit-choice profile of randomized vector scheduling.
const MAX_N:usize=16;const MAX_M:usize=8;const MAX_D:usize=4;const INPUT:usize=83;const FIELDS:usize=35;
fn put(out:[*]u8,at:usize,value:i64)void{const bits:u64=@bitCast(value);for(0..8)|b|out[at+b]=@truncate(bits>>@intCast(8*b));}
export fn vector_scheduling(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > INPUT) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const m64 = input[1]; const d64 = input[2];
    if (n64 < 1 or n64 > 16 or m64 < 1 or m64 > 8 or d64 < 1 or d64 > 4 or
        length != 3 + @as(usize, @intCast(n64)) + @as(usize, @intCast(n64*d64))) return -1;
    const n: usize = @intCast(n64); const m: usize = @intCast(m64); const d: usize = @intCast(d64);
    for (0..n) |job| if (input[3+job] < 0 or input[3+job] >= m64) return -1;
    for (0..n*d) |i| if (input[3+n+i] < 0 or input[3+n+i] > 1000) return -1;
    var loads: [MAX_M*MAX_D]i64 = @splat(0);
    for (0..n) |job| {
        const machine: usize = @intCast(input[3+job]);
        for (0..d) |dimension| loads[machine*MAX_D+dimension] += input[3+n+job*d+dimension];
    }
    var makespan: i64 = 0;
    for (0..m) |machine| {
        for (0..d) |dimension| makespan = @max(makespan, loads[machine*MAX_D+dimension]);
    }
    var staged: [FIELDS]i64 = @splat(0); var count: usize = 0;
    staged[count] = m64; count += 1;
    staged[count] = d64; count += 1;
    staged[count] = makespan; count += 1;
    for (0..m) |machine| {
        for (0..d) |dimension| { staged[count] = loads[machine*MAX_D+dimension]; count += 1; }
    }
    if (output_opt == null or capacity < 8*count) return -2;
    const output = output_opt.?;
    for (0..count) |i| put(output,8*i,staged[i]);
    return @intCast(8*count);
}
