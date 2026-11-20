const max_n: usize = 8;
const max_input: usize = 203;
const max_output: usize = 88;

fn ceil_log2(value: usize) usize {
    var exponent: usize = 0;
    var power: usize = 1;
    while (power < value) : (exponent += 1) { power <<= 1; }
    return exponent;
}

fn put64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @intCast(8*byte));
}

export fn radio_network_bgi_broadcast(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 3 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const source64 = input[1]; const delta64 = input[2];
    if (n64 < 2 or n64 > 8 or source64 < 0 or source64 >= n64 or delta64 < 2 or delta64 > 8) return -1;
    const n: usize = @intCast(n64); const source: usize = @intCast(source64); const delta: usize = @intCast(delta64);
    const k = 2 * ceil_log2(delta); const t = ceil_log2(2*n); const tape_at = 3+n; const tape_count = n*t*k;
    if (length != tape_at + tape_count) return -1;
    const full = (@as(u64,1) << @intCast(n)) - 1;
    var adjacency: [max_n]u64 = @splat(0);
    for (0..n) |v| {
        const raw = input[3+v];
        if (raw < 0 or (@as(u64,@intCast(raw)) & ~full) != 0 or (@as(u64,@intCast(raw)) & (@as(u64,1) << @intCast(v))) != 0) return -1;
        adjacency[v] = @intCast(raw);
        if (@as(usize, @intCast(@popCount(adjacency[v]))) > delta) return -1;
    }
    for (0..n) |u| { for (0..n) |v| { if ((adjacency[u] >> @intCast(v)) & 1 != (adjacency[v] >> @intCast(u)) & 1) return -1; } }
    for (0..tape_count) |i| { if (input[tape_at+i] != 0 and input[tape_at+i] != 1) return -1; }
    const output_bytes = 8*(n+3);
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    var informed: [max_n]bool = @splat(false); var active: [max_n]bool = @splat(false); var newly: [max_n]bool = @splat(false);
    var calls: [max_n]usize = @splat(0); var first_slot: [max_n]i64 = @splat(-1);
    informed[source] = true; first_slot[source] = 0;
    var transmissions: i64 = 0; var phases: i64 = 0;
    for (0..n*t) |phase| {
        var starters: usize = 0;
        for (0..n) |v| { active[v] = informed[v] and calls[v] < t; newly[v] = false; if (active[v]) starters += 1; }
        if (starters == 0) break;
        for (0..k) |slot| {
            for (0..n) |sender| { if (active[sender]) transmissions += 1; }
            for (0..n) |receiver| {
                if (informed[receiver] or newly[receiver]) continue;
                var sender_count: usize = 0;
                for (0..n) |sender| { if (active[sender] and ((adjacency[sender] >> @intCast(receiver)) & 1) != 0) sender_count += 1; }
                if (sender_count == 1) { newly[receiver] = true; first_slot[receiver] = @intCast(phase*k+slot); }
            }
            for (0..n) |sender| { if (active[sender]) {
                const at = tape_at + (sender*t+calls[sender])*k+slot;
                if (slot+1 == k or input[at] == 0) active[sender] = false;
            } }
        }
        for (0..n) |v| { if (informed[v] and calls[v] < t) calls[v] += 1; if (newly[v]) informed[v] = true; }
        phases = @intCast(phase+1);
    }
    var staged: [max_output]u8 = @splat(0);
    put64(&staged,0,n64); put64(&staged,8,phases); put64(&staged,16,transmissions);
    for (0..n) |v| put64(&staged,24+8*v,first_slot[v]);
    for (0..output_bytes) |i| output[i] = staged[i];
    return @intCast(output_bytes);
}
