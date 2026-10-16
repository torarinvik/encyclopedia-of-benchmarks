const NMAX: usize = 5;
const EMAX: usize = 12;
const INF: i64 = 1_000_000_000;
pub export fn edmonds(a: [*c]const i64, length: usize) i64 {
    if (a == null or length < 3 or length > 39) return -1;
    const n64=a[0]; const root64=a[1]; const m64=a[2];
    if (n64 < 1 or n64 > NMAX or root64 < 0 or root64 >= n64 or m64 < 0 or m64 > EMAX or length != 3 + 3 * @as(usize,@intCast(m64))) return -1;
    var n: usize=@intCast(n64); var root: usize=@intCast(root64); const m: usize=@intCast(m64);
    var eu: [EMAX]usize=@splat(0); var ev: [EMAX]usize=@splat(0); var ew: [EMAX]i64=@splat(0);
    for (0..m) |i| { const u=a[3+3*i]; const v=a[4+3*i]; const w=a[5+3*i]; if (u<0 or u>=n64 or v<0 or v>=n64 or w<0 or w>100) return -1; eu[i]=@intCast(u); ev[i]=@intCast(v); ew[i]=w; }
    var answer: i64=0;
    while (true) {
        var inn: [NMAX]i64=@splat(INF); var pre: [NMAX]i64=@splat(-1);
        for (0..m) |i| { if (eu[i]!=ev[i] and ev[i]!=root and ew[i]<inn[ev[i]]) { inn[ev[i]]=ew[i]; pre[ev[i]]=@intCast(eu[i]); } }
        inn[root]=0;
        for (0..n) |i| { if (inn[i]==INF) return -1; }
        var ids: [NMAX]i64=@splat(-1); var vis: [NMAX]i64=@splat(-1); var cycles: i64=0;
        for (0..n) |i| {
            answer+=inn[i]; var v: usize=i;
            while (vis[v]!=@as(i64,@intCast(i)) and ids[v]==-1 and v!=root) { vis[v]=@intCast(i); v=@intCast(pre[v]); }
            if (v!=root and ids[v]==-1) { var u:usize=@intCast(pre[v]); while(u!=v){ids[u]=cycles;u=@intCast(pre[u]);} ids[v]=cycles;cycles+=1; }
        }
        if (cycles==0) return answer;
        for (0..n) |i| { if(ids[i]==-1){ids[i]=cycles;cycles+=1;} }
        for (0..m) |i| { const oldv=ev[i]; const u:usize=@intCast(ids[eu[i]]); const v:usize=@intCast(ids[oldv]); if(u!=v) ew[i]-=inn[oldv]; eu[i]=u;ev[i]=v; }
        root=@intCast(ids[root]); n=@intCast(cycles);
    }
}
