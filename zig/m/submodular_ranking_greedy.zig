const max_input: usize = 131;
fn storeI64LE(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at+b] = @truncate(bits >> @intCast(8*b));
}

export fn submodular_ranking_greedy(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input=input_opt.?;const n64=input[0];const m64=input[1];
    if(n64<1 or n64>5 or m64<1 or m64>4)return -1;
    const n:usize=@intCast(n64);const m:usize=@intCast(m64);const size:usize=@as(usize,1)<<@intCast(n);
    if(length!=2+m*size)return -1;
    var f:[4][32]i64=@splat(@splat(0));
    for(0..m)|i|{
        for(0..size)|a|{const v=input[2+i*size+a];if(v<0 or v>8)return -1;f[i][a]=v;}
        if(f[i][0]!=0 or f[i][size-1]!=8)return -1;
        for(0..size)|a|{for(0..n)|bit|{const e:usize=@as(usize,1)<<@intCast(bit);if((a&e)==0 and f[i][a]>f[i][a|e])return -1;}}
        for(0..size)|a|{for(0..size)|b|{if((a&b)!=a)continue;for(0..n)|bit|{const e:usize=@as(usize,1)<<@intCast(bit);if((b&e)==0 and f[i][a|e]-f[i][a]<f[i][b|e]-f[i][b])return -1;}}}
    }
    const out_bytes=8*(1+n+m);if(output_opt==null or capacity<out_bytes)return -2;const output=output_opt.?;
    var order:[5]usize=@splat(0);var times:[4]i64=@splat(0);var total:i64=0;var mask:usize=0;
    for(1..n+1)|t|{
        var winner:usize=0;var best_num:i64=-1;var best_den:i64=1;
        for(0..n)|e|{const bit:usize=@as(usize,1)<<@intCast(e);if((mask&bit)!=0)continue;var num:i64=0;var den:i64=1;
            for(0..m)|i|{const cur=f[i][mask];if(cur==8)continue;const d:i64=8-cur;const gain=f[i][mask|bit]-cur;num=num*d+gain*den;den*=d;}
            if(best_num<0 or num*best_den>best_num*den){winner=e;best_num=num;best_den=den;}
        }
        mask|=@as(usize,1)<<@intCast(winner);order[t-1]=winner;
        for(0..m)|i|{if(times[i]==0 and f[i][mask]==8){times[i]=@intCast(t);total+=@intCast(t);}}
    }
    storeI64LE(output,0,total);for(0..n)|j|storeI64LE(output,8*(1+j),@intCast(order[j]));
    for(0..m)|i|storeI64LE(output,8*(1+n+i),times[i]);return @intCast(out_bytes);
}
