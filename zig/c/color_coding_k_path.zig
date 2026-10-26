/// Subset/endpoint dynamic program for a colorful path of exactly k vertices.
export fn color_coding_k_path(values: ?[*]const i64, length: usize,
    output: ?[*]u8, output_capacity: usize) i64 {
    const input = values orelse return -2;
    if (length < 3 or length > 147) return -1;
    const nv=input[0]; const mv=input[1]; const kv=input[2];
    if(nv<1 or nv>12 or mv<0 or mv>66 or kv<1 or kv>6 or kv>nv)return -1;
    const n:usize=@intCast(nv);const m:usize=@intCast(mv);const k:usize=@intCast(kv);const split=3+n;
    if(length!=split+2*m)return -1;
    var colors:[12]usize=@splat(0);var adj:[12]u16=@splat(0);
    for(0..n)|v|{const c=input[3+v];if(c<0 or c>=kv)return -1;colors[v]=@intCast(c);}
    for(0..m)|e|{const av=input[split+2*e];const bv=input[split+2*e+1];
        if(av<0 or bv<0 or av>=nv or bv>=nv or av==bv)return -1;const a:usize=@intCast(av);const b:usize=@intCast(bv);
        const bit:u16=@as(u16,1)<<@intCast(b);if((adj[a]&bit)!=0)return -1;adj[a]|=bit;adj[b]|=@as(u16,1)<<@intCast(a);}
    var dp:[64][12]bool=@splat(@splat(false));for(0..n)|v|dp[1<<colors[v]][v]=true;
    const full=(1<<k)-1;var found=false;
    var mask:usize=1;while(mask<=full and !found):(mask+=1){for(0..n)|v|{if(!dp[mask][v])continue;if(mask==full){found=true;break;}
        for(0..n)|u|{const bit=1<<colors[u];if(adj[v]&(1<<u)!=0 and mask&bit==0)dp[mask|bit][u]=true;}}}
    const out=output orelse return -2;if(output_capacity<8)return -2;
    out[0]=@intFromBool(found);for(1..8)|i|out[i]=0;return 8;
}
