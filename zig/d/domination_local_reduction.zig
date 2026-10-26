fn put_word(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| output[offset+b] = @truncate(bits >> @intCast(8*b));
}

export fn domination_local_reduction(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > 135) return -1;
    const n0=input[0];const m0=input[1];const p0=input[2];
    if(n0<1 or n0>12 or m0<0 or m0>66 or p0<0 or p0>=n0 or length!=3+2*@as(usize,@intCast(m0)))return -1;
    const n:usize=@intCast(n0);const m:usize=@intCast(m0);const p:usize=@intCast(p0);
    var adj=[_]bool{false}**144;
    for(0..m)|e|{const u0=input[3+2*e];const v0=input[4+2*e];if(u0<0 or v0<=u0 or v0>=n0)return -1;const u:usize=@intCast(u0);const v:usize=@intCast(v0);if(adj[u*12+v])return -1;adj[u*12+v]=true;adj[v*12+u]=true;}
    var closed=[_]bool{false}**12;var exits=[_]bool{false}**12;var guards=[_]bool{false}**12;var prisoners=[_]bool{false}**12;closed[p]=true;
    for(0..n)|u|{if(adj[p*12+u])closed[u]=true;}
    for(0..n)|u|{if(adj[p*12+u]){for(0..n)|x|{if(adj[u*12+x] and !closed[x]){exits[u]=true;break;}}}}
    for(0..n)|u|{if(adj[p*12+u] and !exits[u]){for(0..n)|x|{if(exits[x] and adj[u*12+x]){guards[u]=true;break;}}}}
    var np:usize=0;for(0..n)|u|{if(adj[p*12+u] and !exits[u] and !guards[u]){prisoners[u]=true;np+=1;}}if(np==0)return -1;
    var ids=[_]usize{0}**12;var remap=[_]isize{-1}**12;var kept:usize=0;
    for(0..n)|u|{if(!guards[u] and !prisoners[u]){ids[kept]=u;remap[u]=@intCast(kept);kept+=1;}}
    const k=kept+1;const leaf=k-1;var words=[_]i64{0}**25;words[0]=@intCast(k);
    for(0..kept)|i|words[1+i]=@intCast(ids[i]);words[1+kept]=-1;
    for(0..kept)|i|{for(0..kept)|j|{if(adj[ids[i]*12+ids[j]])words[1+k+i]|=@intCast(@as(u64,1)<<@intCast(j));}}
    const rp:usize=@intCast(remap[p]);words[1+k+rp]|=@intCast(@as(u64,1)<<@intCast(leaf));words[1+k+leaf]=@intCast(@as(u64,1)<<@intCast(rp));
    const count=1+2*k;const bytes=count*8;if(output==null or capacity<bytes)return -2;
    for(0..count)|i|put_word(output,8*i,words[i]);return @intCast(bytes);
}
