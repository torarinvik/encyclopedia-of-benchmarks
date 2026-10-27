const std = @import("std");
const max_n: usize = 8;
const max_input: usize = 75;

fn put64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset+byte] = @truncate(bits >> @intCast(8*byte));
}

export fn radio_network_decay_phase(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt==null or length<3 or length>max_input) return -1;
    const input=input_opt.?; const n64=input[0]; const k64=input[1]; const initial=input[2];
    if (n64<2 or n64>8 or k64<1 or k64>8 or length!=3+@as(usize,@intCast(n64))+@as(usize,@intCast(n64*k64))) return -1;
    const n:usize=@intCast(n64); const k:usize=@intCast(k64); const full=(@as(u64,1)<<@intCast(n))-1;
    if (initial<=0 or (@as(u64,@intCast(initial))&~full)!=0) return -1;
    var adjacency:[max_n]u64=@splat(0);
    for (0..n) |v| { const raw=input[3+v]; if (raw<0 or (@as(u64,@intCast(raw))&~full)!=0 or (@as(u64,@intCast(raw))&(@as(u64,1)<<@intCast(v)))!=0) return -1; adjacency[v]=@intCast(raw); }
    for (0..n) |u| { for (0..n) |v| { if ((adjacency[u]>>@intCast(v))&1 != (adjacency[v]>>@intCast(u))&1) return -1; } }
    const tape_at=3+n;
    for (0..n*k) |i| { if (input[tape_at+i]!=0 and input[tape_at+i]!=1) return -1; }
    if (output_opt==null or capacity<16) return -2;
    const output=output_opt.?; var active:[max_n]bool=@splat(false);
    for (0..n) |v| active[v]=((@as(u64,@intCast(initial))>>@intCast(v))&1)!=0;
    var newly:u64=0; var transmissions:i64=0;
    for (0..k) |slot| {
        for (0..n) |sender| { if (active[sender]) transmissions+=1; }
        for (0..n) |receiver| {
            if (((@as(u64,@intCast(initial))>>@intCast(receiver))&1)!=0) continue;
            var count:usize=0;
            for (0..n) |sender| { if (active[sender] and ((adjacency[sender]>>@intCast(receiver))&1)!=0) count+=1; }
            if (count==1) newly|=@as(u64,1)<<@intCast(receiver);
        }
        for (0..n) |sender| { if (active[sender] and (input[tape_at+sender*k+slot]==0 or slot+1==k)) active[sender]=false; }
    }
    var staged:[16]u8=@splat(0); put64(&staged,0,@bitCast(newly)); put64(&staged,8,transmissions);
    for (0..16) |i| output[i]=staged[i];
    return 16;
}
