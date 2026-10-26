fn put_i64(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn dc_tree_k_server_path(input: [*]const i64, length: usize, output: [*]u8, capacity: usize) i64 {
    if (@intFromPtr(input) == 0 or length < 5 or length > 18) return -1;
    const k0=input[0]; const q0=input[1];
    if (k0 < 2 or k0 > 4 or q0 < 1 or q0 > 12) return -1;
    const k: usize = @intCast(k0); const q: usize = @intCast(q0);
    if (length != 2+k+q) return -1;
    var pos=[_]i64{0}**4;
    for (0..k) |i| { pos[i]=input[2+i]; if (pos[i] < 0 or pos[i] > 15) return -1; }
    for (0..q) |r| { const x=input[2+k+r]; if (x < 0 or x > 15) return -1; }
    var staged=[_]i64{0}**60; var at: usize=0;
    for (0..q) |r| {
        const target=input[2+k+r]; var active=[_]bool{false}**4; var count:usize=0; var nearest:i64=9223372036854775807;
        for (0..k) |i| {
            var first=true; for (0..i) |j| { if (pos[j]==pos[i]) { first=false; break; } }
            if (!first) continue;
            active[i]=true;count+=1;const delta=if(pos[i]>target) pos[i]-target else target-pos[i];if(delta<nearest)nearest=delta;
        }
        staged[at]=nearest*@as(i64,@intCast(count));at+=1;
        for(0..k)|i|{if(active[i]){if(pos[i]<target)pos[i]+=nearest else if(pos[i]>target)pos[i]-=nearest;}}
        for(0..k)|i|{staged[at]=pos[i];at+=1;}
    }
    const bytes=8*q*(k+1);if(@intFromPtr(output)==0 or capacity<bytes)return -2;
    for(0..at)|i|put_i64(output,8*i,staged[i]);return @intCast(bytes);
}
