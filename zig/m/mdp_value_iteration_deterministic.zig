const max_states: usize = 4;
const max_actions: usize = 3;
const max_input: usize = 29;
const max_output: usize = 72;

fn put64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @intCast(8*byte));
}

export fn mdp_value_iteration_deterministic(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 7 or length > max_input) return -1;
    const input = input_opt.?;
    const s64=input[0]; const a64=input[1]; const h64=input[2]; const p=input[3]; const q=input[4];
    if (s64<1 or s64>4 or a64<1 or a64>3 or h64<1 or h64>8 or q<1 or q>4 or p<0 or p>=q or length!=5+2*@as(usize,@intCast(s64))*@as(usize,@intCast(a64))) return -1;
    const states:usize=@intCast(s64); const actions:usize=@intCast(a64); const horizon:usize=@intCast(h64);
    var rewards:[max_states][max_actions]i64=@splat(@splat(0));
    var targets:[max_states][max_actions]i64=@splat(@splat(0));
    var at:usize=5;
    for (0..states) |s| { for (0..actions) |a| {
        const reward=input[at]; const target=input[at+1]; at+=2;
        if (reward < -100 or reward > 100 or target < 0 or target >= s64) return -1;
        rewards[s][a]=reward; targets[s][a]=target;
    } }
    var scale:i64=1;
    for (0..horizon) |_| scale*=q;
    var value:[max_states]i64=@splat(0); var next_value:[max_states]i64=@splat(0); var policy:[max_states]i64=@splat(0);
    for (0..horizon) |_| {
        for (0..states) |s| {
            var best:i64=std.math.minInt(i64); var best_action:usize=0;
            for (0..actions) |a| {
                const candidate=rewards[s][a]*scale+p*(value[@intCast(targets[s][a])]/q);
                if (candidate>best) { best=candidate; best_action=a; }
            }
            next_value[s]=best; policy[s]=@intCast(best_action);
        }
        for (0..states) |s| value[s]=next_value[s];
    }
    const bytes=8*(1+2*states);
    if (output_opt==null or capacity<bytes) return -2;
    const output=output_opt.?;
    var staged:[max_output]u8=@splat(0);
    put64(&staged,0,scale);
    for (0..states) |s| put64(&staged,8*(1+s),value[s]);
    for (0..states) |s| put64(&staged,8*(1+states+s),policy[s]);
    for (0..bytes) |i| output[i]=staged[i];
    return @intCast(bytes);
}

const std = @import("std");
