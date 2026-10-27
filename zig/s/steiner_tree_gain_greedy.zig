const std = @import("std");
const N: usize = 4;
const Edge = struct { u: usize, v: usize, w: i64 };

fn putI64(out: [*]u8, word: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[word * 8 + b] = @truncate(bits >> @intCast(8 * b));
}
fn findRoot(p: *[N]usize, x0: usize) usize {
    var x = x0;
    while (p.*[x] != x) { p.*[x] = p.*[p.*[x]]; x = p.*[x]; }
    return x;
}
fn join(p: *[N]usize, a: usize, b: usize) bool {
    const ra = findRoot(p,a); const rb = findRoot(p,b);
    if (ra == rb) return false;
    p.*[rb] = ra; return true;
}
fn groupCount(n: usize, mask: i64, h: *const [N][N]bool) usize {
    var p = [_]usize{0,1,2,3};
    for (0..n) |i| for (i+1..n) |j| { if (h.*[i][j]) _ = join(&p,i,j); };
    var seen = [_]bool{false} ** N; var count: usize = 0;
    for (0..n) |i| if ((mask & (@as(i64,1) << @intCast(i))) != 0) {
        const r = findRoot(&p,i); if (!seen[r]) {seen[r]=true;count+=1;}
    };
    return count;
}
fn lessEdge(a: Edge, b: Edge) bool { return a.w < b.w or (a.w == b.w and (a.u < b.u or (a.u == b.u and a.v < b.v))); }
fn metricMst(n: usize, mask: i64, w: *const [N][N]i64) i64 {
    var verts = [_]usize{0} ** N; var vn: usize = 0;
    for (0..n) |i| if ((mask & (@as(i64,1) << @intCast(i))) != 0) {verts[vn]=i;vn+=1;};
    if (vn<=1) return 0;
    var used = [_]bool{false} ** N; var best = [_]i64{std.math.maxInt(i64)} ** N;
    used[verts[0]]=true;for (1..vn) |x| best[verts[x]]=w.*[verts[0]][verts[x]];
    var total:i64=0;
    for (1..vn) |_| {var pick:usize=N;for (0..vn) |x| {const v=verts[x];if(!used[v] and (pick==N or best[v]<best[pick] or (best[v]==best[pick] and v<pick))) pick=v;}
        total+=best[pick];used[pick]=true;for(0..vn)|x|{const v=verts[x];if(!used[v] and w.*[pick][v]<best[v])best[v]=w.*[pick][v];}}
    return total;
}
fn mstH(n:usize,w:*const [N][N]i64,h:*const [N][N]bool,tree:*[3]Edge,tree_n:*usize)i64{
    var es=[_]Edge{.{.u=0,.v=0,.w=0}} ** 6;var en:usize=0;
    for(0..n)|i|for(i+1..n)|j|{if(h.*[i][j]){es[en]=.{.u=i,.v=j,.w=w.*[i][j]};en+=1;}};
    for(1..en)|i|{const x=es[i];var j=i;while(j>0 and lessEdge(x,es[j-1])){es[j]=es[j-1];j-=1;}es[j]=x;}
    var p=[_]usize{0,1,2,3};var cost:i64=0;tree_n.*=0;
    for(0..en)|i|{const e=es[i];if(join(&p,e.u,e.v)){tree.*[tree_n.*]=e;tree_n.*+=1;cost+=e.w;}}
    return cost;
}
fn contractedMst(n:usize,mask:i64,w:*const [N][N]i64,h:*const [N][N]bool)i64{
    var d=w.*;var p=[_]usize{0,1,2,3};
    for(0..n)|i|for(i+1..n)|j|{if(h.*[i][j]){d[i][j]=0;d[j][i]=0;_=join(&p,i,j);}};
    for(0..n)|k|for(0..n)|i|for(0..n)|j|{if(d[i][j]>d[i][k]+d[k][j])d[i][j]=d[i][k]+d[k][j];};
    var roots=[_]usize{0} ** N;var g:usize=0;
    for(0..n)|v|if((mask&(@as(i64,1)<<@intCast(v)))!=0){const r=findRoot(&p,v);var found=false;for(0..g)|x|{if(roots[x]==r)found=true;}if(!found){roots[g]=r;g+=1;}};
    if(g<=1)return 0;
    var q=[_] [N]i64{[_]i64{0}**N}**N;
    for(0..g)|a|for(a+1..g)|b|{var best=std.math.maxInt(i64);for(0..n)|u|{if(findRoot(&p,u)==roots[a])for(0..n)|v|{if(findRoot(&p,v)==roots[b] and d[u][v]<best)best=d[u][v];};}q[a][b]=best;q[b][a]=best;};
    var used=[_]bool{false}**N;var best=[_]i64{std.math.maxInt(i64)}**N;used[0]=true;for(1..g)|j|best[j]=q[0][j];var total:i64=0;
    for(1..g)|_|{var pick:usize=N;for(0..g)|v|{if(!used[v] and (pick==N or best[v]<best[pick] or (best[v]==best[pick] and v<pick)))pick=v;}total+=best[pick];used[pick]=true;for(0..g)|v|{if(!used[v] and q[pick][v]<best[v])best[v]=q[pick][v];}}
    return total;
}

export fn steiner_tree_gain_greedy(input_opt:?[*]const i64,length:usize,output_opt:?[*]u8,capacity:usize)i64{
    const input=input_opt orelse return -1;if(length<4 or length>37)return -1;
    const n0=input[0];const mask=input[1];const c0=input[2];if(n0<2 or n0>4 or mask<=0 or (mask>>@intCast(n0))!=0 or c0<1 or c0>4)return -1;
    const n:usize=@intCast(n0);const count:usize=@intCast(c0);var tc:usize=0;for(0..n)|i|{if((mask&(@as(i64,1)<<@intCast(i)))!=0)tc+=1;}if(tc<2)return -1;
    var w=[_] [N]i64{[_]i64{0}**N}**N;var at:usize=3;
    for(0..n)|i|for(i+1..n)|j|{if(at>=length or input[at]<0 or input[at]>1000)return -1;w[i][j]=input[at];w[j][i]=input[at];at+=1;};
    for(0..n)|i|for(0..n)|j|for(0..n)|k|{if(w[i][j]>w[i][k]+w[k][j])return -1;};
    var fam=[_] [3]Edge{[_]Edge{.{.u=0,.v=0,.w=0}}**3}**4;var sizes=[_]usize{0}**4;var fh=[_] [N]bool{[_]bool{false}**N}**N;
    for(0..count)|c|{if(at>=length)return -1;const ec0=input[at];at+=1;if(ec0<1 or ec0>n0-1 or at+2*@as(usize,@intCast(ec0))>length)return -1;const ec:usize=@intCast(ec0);
        var p=[_]usize{0,1,2,3};var deg=[_]usize{0}**N;
        for(0..ec)|e|{const u0=input[at];const v0=input[at+1];at+=2;if(u0<0 or u0>=n0 or v0<0 or v0>=n0 or u0==v0)return -1;var u:usize=@intCast(u0);var v:usize=@intCast(v0);if(!join(&p,u,v))return -1;if(u>v){const t=u;u=v;v=t;}for(0..e)|x|{if(fam[c][x].u==u and fam[c][x].v==v)return -1;}fam[c][e]=.{.u=u,.v=v,.w=0};fh[u][v]=true;fh[v][u]=true;deg[u]+=1;deg[v]+=1;}
        var seen:usize=0;var leaves:usize=0;var first:usize=N;for(0..n)|v|{if(deg[v]>0){seen+=1;if(first==N)first=findRoot(&p,v) else if(findRoot(&p,v)!=first)return -1;if(deg[v]==1){if((mask&(@as(i64,1)<<@intCast(v)))==0)return -1;leaves+=1;}else if((mask&(@as(i64,1)<<@intCast(v)))!=0)return -1;}}
        if(seen!=ec+1 or leaves<2 or leaves>3)return -1;sizes[c]=ec;
    }
    if(at!=length or groupCount(n,mask,&fh)!=1)return -1;
    const baseline=metricMst(n,mask,&w);var h=[_] [N]bool{[_]bool{false}**N}**N;var selected=[_]bool{false}**4;
    while(groupCount(n,mask,&h)>1){const before=groupCount(n,mask,&h);var best:usize=4;var best_gain:i64=std.math.minInt(i64);
        for(0..count)|c|{if(selected[c])continue;var trial=h;for(0..sizes[c])|e|{const u=fam[c][e].u;const v=fam[c][e].v;trial[u][v]=true;trial[v][u]=true;}if(groupCount(n,mask,&trial)>=before)continue;
            var scratch=[_]Edge{.{.u=0,.v=0,.w=0}}**3;var scratch_n:usize=0;const gain=baseline-contractedMst(n,mask,&w,&trial)-mstH(n,&w,&trial,&scratch,&scratch_n);if(best==4 or gain>best_gain){best=c;best_gain=gain;}}
        if(best==4)return -1;selected[best]=true;for(0..sizes[best])|e|{const u=fam[best][e].u;const v=fam[best][e].v;h[u][v]=true;h[v][u]=true;}}
    var tree=[_]Edge{.{.u=0,.v=0,.w=0}}**3;var tree_n:usize=0;const cost=mstH(n,&w,&h,&tree,&tree_n);const bytes=8*(3+2*tree_n);const output=output_opt orelse return -2;if(capacity<bytes)return -2;
    putI64(output,0,1);putI64(output,1,cost);putI64(output,2,@intCast(tree_n));for(0..tree_n)|i|{putI64(output,3+2*i,@intCast(tree[i].u));putI64(output,4+2*i,@intCast(tree[i].v));}return @intCast(bytes);
}
