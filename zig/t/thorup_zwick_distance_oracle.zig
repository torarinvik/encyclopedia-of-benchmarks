const N: usize = 12;
const M: usize = 66;
const Q: usize = 32;
const INF: i64 = std.math.maxInt(i64) / 4;
const std = @import("std");

fn read(p: [*]const i64, i: usize) i64 { return p[i]; }
fn put(out: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[at + b] = @truncate(bits >> @intCast(8 * b));
}

export fn thorup_zwick_distance_oracle(input: ?[*]const i64, length: usize,
    output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 4 or length > 266) return -1;
    const p = input.?;
    if (p[0] < 1 or p[0] > N or p[1] < 0 or p[1] > M or p[2] <= 0) return -1;
    const n: usize = @intCast(p[0]); const m: usize = @intCast(p[1]); const mask: u64 = @intCast(p[2]);
    if ((mask >> @intCast(n)) != 0) return -1;
    const q_at = 3 + 3 * m;
    if (q_at >= length or p[q_at] < 0 or p[q_at] > Q) return -1;
    const q: usize = @intCast(p[q_at]);
    if (length != q_at + 1 + 2 * q) return -1;
    var d = [_][N]i64{[_]i64{INF} ** N} ** N;
    for (0..n) |i| d[i][i] = 0;
    for (0..m) |e| {
        const ur=p[3+3*e]; const vr=p[4+3*e]; const w=p[5+3*e];
        if (ur<0 or vr<=ur or vr>=p[0] or w<1 or w>1000) return -1;
        const u:usize=@intCast(ur);const v:usize=@intCast(vr);
        if(d[u][v]!=INF)return -1;d[u][v]=w;d[v][u]=w;
    }
    for(0..n)|k|for(0..n)|i|for(0..n)|j|{if(d[i][k]!=INF and d[k][j]!=INF and d[i][k]+d[k][j]<d[i][j])d[i][j]=d[i][k]+d[k][j];};
    for(0..n)|i|for(0..n)|j|{if(d[i][j]==INF)return -1;};
    var nearest=[_]usize{0}**N;var near_d=[_]i64{INF}**N;
    for(0..n)|v|{var found=false;for(0..n)|a|{if((mask>>@intCast(a))&1!=0 and (!found or d[v][a]<near_d[v] or (d[v][a]==near_d[v] and a<nearest[v]))){nearest[v]=a;near_d[v]=d[v][a];found=true;}}}
    var bunch=[_][N]bool{[_]bool{false}**N}**N;
    for(0..n)|u|for(0..n)|x|{bunch[u][x]=((mask>>@intCast(x))&1)!=0 or d[u][x]<near_d[u];};
    var staged=[_]i64{0}**(Q+1);staged[0]=@intCast(q);
    for(0..q)|z|{const ar=p[q_at+1+2*z];const br=p[q_at+2+2*z];if(ar<0 or ar>=p[0] or br<0 or br>=p[0])return -1;var u:usize=@intCast(ar);var v:usize=@intCast(br);var found=false;
        for(0..2)|level|{const pivot=if(level==0)v else nearest[v];if(bunch[u][pivot]){staged[z+1]=d[u][pivot]+d[v][pivot];found=true;break;}const tmp=u;u=v;v=tmp;}
        if(!found)return -1;
    }
    const bytes=8*(q+1);if(output==null or capacity<bytes)return -2;const out=output.?;
    for(0..q+1)|i|put(out,8*i,staged[i]);return @intCast(bytes);
}
