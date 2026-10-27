const MAX_N: usize = 3;
const MAX_M: usize = 3;
const MAX_CUTS: usize = 45;

fn addCut(cuts: *[MAX_N][MAX_CUTS]u64, counts: *[MAX_N]usize, node: usize, mask: u64, k: usize) void {
    if (@popCount(mask) > k) return;
    for (0..counts[node]) |i| if (cuts[node][i] == mask) return;
    if (counts[node] < MAX_CUTS) { cuts[node][counts[node]] = mask; counts[node] += 1; }
}
fn shiftCut(cut: u64, n: usize, delay: usize) ?u64 {
    var result: u64 = 0;
    for (0..3*n) |bit| {
        if (cut & (@as(u64, 1) << @intCast(bit)) != 0) {
            const node = bit / 3;
            const next_delay = bit % 3 + delay;
            if (next_delay > 2) return null;
            result |= @as(u64, 1) << @intCast(3*node + next_delay);
        }
    }
    return result;
}
fn putI64(output: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[word*8+byte] = @truncate(bits >> @intCast(byte*8));
}

export fn sequential_lut_k_cut_enumeration(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 12) return -1;
    const n0=input[0]; const k0=input[1]; const m0=input[2];
    if (n0<1 or n0>3 or k0<1 or k0>2 or m0<0 or m0>3 or length!=3+3*@as(usize,@intCast(m0))) return -1;
    const n: usize=@intCast(n0); const k: usize=@intCast(k0); const m: usize=@intCast(m0);
    var eu=[_]usize{0} ** MAX_M; var ev=[_]usize{0} ** MAX_M; var ed=[_]usize{0} ** MAX_M;
    for (0..m) |e| {
        const u=input[3+3*e]; const v=input[4+3*e]; const d=input[5+3*e];
        if (u<0 or v<=u or v>=n0 or (d!=0 and d!=1)) return -1;
        for (0..e) |j| if (eu[j]==@as(usize,@intCast(u)) and ev[j]==@as(usize,@intCast(v)) and ed[j]==@as(usize,@intCast(d))) return -1;
        eu[e]=@intCast(u); ev[e]=@intCast(v); ed[e]=@intCast(d);
    }
    var in_u=[_]usize{0} ** (MAX_N*MAX_M); var in_d=[_]usize{0} ** (MAX_N*MAX_M); var degree=[_]usize{0} ** MAX_N;
    for (0..m) |e| { const v=ev[e]; const slot=degree[v]; in_u[v*MAX_M+slot]=eu[e];in_d[v*MAX_M+slot]=ed[e];degree[v]+=1; }
    var cuts=[_]u64{0} ** (MAX_N*MAX_CUTS); var counts=[_]usize{0} ** MAX_N;
    for (0..n) |v| {
        addCut(@ptrCast(&cuts),@ptrCast(&counts),v,@as(u64,1) << @intCast(3*v),k);
        if(degree[v]>0) {
            const c0=counts[in_u[v*MAX_M]];
            const c1=if(degree[v]>1) counts[in_u[v*MAX_M+1]] else 1;
            const c2=if(degree[v]>2) counts[in_u[v*MAX_M+2]] else 1;
            for (0..c0) |a| { for (0..c1) |b| { for (0..c2) |c| {
                const u0=in_u[v*MAX_M];
                var merged=shiftCut(cuts[u0*MAX_CUTS+a],n,in_d[v*MAX_M]) orelse return -1;
                if(degree[v]>1) { const u=in_u[v*MAX_M+1]; merged |= shiftCut(cuts[u*MAX_CUTS+b],n,in_d[v*MAX_M+1]) orelse return -1; }
                if(degree[v]>2) { const u=in_u[v*MAX_M+2]; merged |= shiftCut(cuts[u*MAX_CUTS+c],n,in_d[v*MAX_M+2]) orelse return -1; }
                addCut(@ptrCast(&cuts),@ptrCast(&counts),v,merged,k);
            }}}
        }
        for (1..counts[v]) |i| { const x=cuts[v*MAX_CUTS+i]; var j=i; while(j>0 and cuts[v*MAX_CUTS+j-1]>x):(j-=1){cuts[v*MAX_CUTS+j]=cuts[v*MAX_CUTS+j-1];} cuts[v*MAX_CUTS+j]=x; }
    }
    var words:usize=1; for(0..n)|v| words+=1+counts[v]; const bytes=words*8;
    if(output==null or capacity<bytes)return -2;
    putI64(output,0,@intCast(n)); var at:usize=1;
    for(0..n)|v|{putI64(output,at,@intCast(counts[v]));at+=1;for(0..counts[v])|i|{putI64(output,at,@intCast(cuts[v*MAX_CUTS+i]));at+=1;}}
    return @intCast(bytes);
}
