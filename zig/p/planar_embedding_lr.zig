const std = @import("std");
const N = 32;
const M = 96;
const D = 192;
const Inf: i32 = 1000;

const Interval = struct { low: i32 = -1, high: i32 = -1 };
const Conflict = struct { left: Interval = .{}, right: Interval = .{} };
const State = struct {
    n: usize = 0, m: usize = 0,
    edge_of: [N][N]i32 = @splat(@splat(-1)), adj: [N][N]i32 = @splat(@splat(0)), degree: [N]usize = @splat(0),
    eu: [M]i32 = @splat(0), ev: [M]i32 = @splat(0), tail: [M]i32 = @splat(-1), head: [M]i32 = @splat(-1),
    height: [N]i32 = @splat(-1), parent: [N]i32 = @splat(-1), low: [M]i32 = @splat(0), low2: [M]i32 = @splat(0), nest: [M]i32 = @splat(0),
    out: [N][N]i32 = @splat(@splat(0)), out_count: [N]usize = @splat(0),
    reference: [M]i32 = @splat(-1), side: [M]i32 = @splat(1), low_edge: [M]i32 = @splat(-1), bottom: [M]i32 = @splat(-1),
    stack: [D]Conflict = @splat(.{}), stack_len: usize = 0,
    rotation: [N][N]i32 = @splat(@splat(0)), rotation_count: [N]usize = @splat(0),
    left_ref: [N]i32 = @splat(-1), right_ref: [N]i32 = @splat(-1), roots: [N]i32 = @splat(0), root_count: usize = 0,

    fn updateParent(s: *State, back: usize, pe: i32) void {
        if (pe < 0) return;
        const p: usize = @intCast(pe);
        if (s.low[back] < s.low[p]) { s.low2[p] = @min(s.low[p], s.low2[back]); s.low[p] = s.low[back]; }
        else if (s.low[back] > s.low[p]) s.low2[p] = @min(s.low2[p], s.low[back])
        else s.low2[p] = @min(s.low2[p], s.low2[back]);
    }
    fn orient(s: *State, v: usize) void {
        const pe = s.parent[v];
        for (0..s.degree[v]) |i| {
            const w: usize = @intCast(s.adj[v][i]);
            const e: usize = @intCast(s.edge_of[v][w]);
            if (s.tail[e] >= 0) continue;
            s.tail[e] = @intCast(v); s.head[e] = @intCast(w); s.low[e] = s.height[v]; s.low2[e] = s.height[v];
            if (s.height[w] < 0) {
                s.parent[w] = @intCast(e); s.height[w] = s.height[v] + 1; s.orient(w);
                s.nest[e] = 2*s.low[e] + (if (s.low2[e] < s.height[v]) @as(i32, 1) else @as(i32, 0));
            } else {
                s.low[e] = s.height[w]; s.low2[e] = s.height[v];
                s.nest[e] = 2*s.low[e] + (if (s.low2[e] < s.height[v]) @as(i32, 1) else @as(i32, 0));
            }
            s.updateParent(e, pe);
        }
    }
    fn intervalConflicts(s: *const State, a: Interval, e: usize) bool { return a.high >= 0 and s.low[@intCast(a.high)] > s.low[e]; }
    fn pairLowest(s: *const State, p: Conflict) i32 {
        const a = if (p.left.low >= 0) s.low[@intCast(p.left.low)] else Inf;
        const b = if (p.right.low >= 0) s.low[@intCast(p.right.low)] else Inf;
        return @min(a,b);
    }
    fn addConstraints(s: *State, ei: usize, pe: usize) bool {
        var p = Conflict{};
        while (true) {
            if (s.stack_len == 0) return false;
            s.stack_len -= 1; var q = s.stack[s.stack_len];
            if (q.left.low >= 0) std.mem.swap(Interval, &q.left, &q.right);
            if (q.left.low >= 0) return false;
            if (s.low[@intCast(q.right.low)] > s.low[pe]) {
                if (p.right.low < 0) p.right = q.right
                else { s.reference[@intCast(p.right.low)] = q.right.high; p.right.low = q.right.low; }
            } else s.reference[@intCast(q.right.low)] = s.low_edge[pe];
            if (@as(isize, @intCast(s.stack_len)) - 1 == s.bottom[ei]) break;
        }
        while (s.stack_len > 0 and (s.intervalConflicts(s.stack[s.stack_len-1].left,ei) or s.intervalConflicts(s.stack[s.stack_len-1].right,ei))) {
            s.stack_len -= 1; var q=s.stack[s.stack_len];
            if (s.intervalConflicts(q.right,ei)) std.mem.swap(Interval,&q.left,&q.right);
            if (s.intervalConflicts(q.right,ei)) return false;
            if (p.right.low>=0) s.reference[@intCast(p.right.low)]=q.right.high;
            if (q.right.low>=0) p.right.low=q.right.low;
            if (p.left.low<0) p.left=q.left else { s.reference[@intCast(p.left.low)]=q.left.high; p.left.low=q.left.low; }
        }
        if (p.left.low>=0 or p.right.low>=0) { s.stack[s.stack_len]=p; s.stack_len+=1; }
        return true;
    }
    fn removeReturns(s: *State, e: usize) void {
        const u: usize = @intCast(s.tail[e]);
        while (s.stack_len>0 and s.pairLowest(s.stack[s.stack_len-1])==s.height[u]) {
            s.stack_len-=1; const p=s.stack[s.stack_len]; if(p.left.low>=0)s.side[@intCast(p.left.low)]=-1;
        }
        if(s.stack_len>0){
            s.stack_len-=1; var p=s.stack[s.stack_len];
            while(p.left.high>=0 and s.head[@intCast(p.left.high)]==u) p.left.high=s.reference[@intCast(p.left.high)];
            if(p.left.high<0 and p.left.low>=0){s.reference[@intCast(p.left.low)]=p.right.low;s.side[@intCast(p.left.low)]=-1;p.left.low=-1;}
            while(p.right.high>=0 and s.head[@intCast(p.right.high)]==u) p.right.high=s.reference[@intCast(p.right.high)];
            if(p.right.high<0 and p.right.low>=0){s.reference[@intCast(p.right.low)]=p.left.low;s.side[@intCast(p.right.low)]=-1;p.right.low=-1;}
            s.stack[s.stack_len]=p;s.stack_len+=1;
        }
        if(s.low[e]<s.height[u] and s.stack_len>0){
            const p=s.stack[s.stack_len-1];const lh=p.left.high;const rh=p.right.high;
            s.reference[e]=if(lh>=0 and (rh<0 or s.low[@intCast(lh)]>s.low[@intCast(rh)])) lh else rh;
        }
    }
    fn test(s: *State,v:usize) bool {
        const pe=s.parent[v];
        for(0..s.out_count[v]) |i| {
            const e:usize=@intCast(s.out[v][i]);const w:usize=@intCast(s.head[e]);s.bottom[e]=@intCast(s.stack_len)-1;
            if(s.parent[w]==@as(i32,@intCast(e))){if(!s.test(w))return false;} else {
                s.low_edge[e]=@intCast(e);var p=Conflict{};p.right=.{.low=@intCast(e),.high=@intCast(e)};s.stack[s.stack_len]=p;s.stack_len+=1;
                if(s.low[e]<s.height[v]){if(i==0){if(pe>=0)s.low_edge[@intCast(pe)]=@intCast(e);}else if(pe<0 or !s.addConstraints(e,@intCast(pe)))return false;}
            }
        }
        if(pe>=0)s.removeReturns(@intCast(pe));return true;
    }
    fn resolveSide(s:*State,e:usize)i32{if(s.reference[e]>=0){const r:usize=@intCast(s.reference[e]);s.side[e]*=s.resolveSide(r);s.reference[e]=-1;}return s.side[e];}
    fn before(s:*const State,a:i32,b:i32,depth:[M]i32)bool{return depth[@intCast(a)]<depth[@intCast(b)] or (depth[@intCast(a)]==depth[@intCast(b)] and s.head[@intCast(a)]<s.head[@intCast(b)]);}
    fn insert(s:*State,v:usize,w:i32,reference:i32,after:bool)void{
        const count=s.rotation_count[v];var pos:usize=0;if(count>0 and reference>=0){while(pos<count and s.rotation[v][pos]!=reference)pos+=1;if(pos==count)pos=count else if(after)pos=(pos+1)%count;}
        var i=count;while(i>pos){s.rotation[v][i]=s.rotation[v][i-1];i-=1;}s.rotation[v][pos]=w;s.rotation_count[v]=count+1;
    }
    fn embed(s:*State,v:usize)void{for(0..s.out_count[v])|i|{const e:usize=@intCast(s.out[v][i]);const w:usize=@intCast(s.head[e]);if(s.parent[w]==@as(i32,@intCast(e))){s.insert(w,@intCast(v),-1,false);s.left_ref[v]=@intCast(w);s.right_ref[v]=@intCast(w);s.embed(w);}else if(s.side[e]==1){s.insert(w,@intCast(v),s.right_ref[w],true);}else{s.insert(w,@intCast(v),s.left_ref[w],false);s.left_ref[w]=@intCast(v);}}}
};

pub export fn planar_embedding_lr(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 195) return -1;
    const n64=input[0];const m64=input[1];if(n64<1 or n64>32 or m64<0 or m64>96 or length!=2+2*@as(usize,@intCast(m64)))return -1;
    var s=State{.n=@intCast(n64),.m=@intCast(m64)};
    for(0..s.m)|e|{const u64=input[2+2*e];const v64=input[3+2*e];if(u64<0 or u64>=v64 or v64>=n64)return -1;const u:usize=@intCast(u64);const v:usize=@intCast(v64);if(s.edge_of[u][v]>=0)return -1;s.edge_of[u][v]=@intCast(e);s.edge_of[v][u]=@intCast(e);s.eu[e]=@intCast(u);s.ev[e]=@intCast(v);}
    for(0..s.n)|v|{for(0..s.n)|w|{if(s.edge_of[v][w]>=0){s.adj[v][s.degree[v]]=@intCast(w);s.degree[v]+=1;}}}
    for(0..s.n)|r|{if(s.height[r]<0){s.height[r]=0;s.roots[s.root_count]=@intCast(r);s.root_count+=1;s.orient(r);}}
    for(0..s.m)|e|{const v:usize=@intCast(s.tail[e]);s.out[v][s.out_count[v]]=@intCast(e);s.out_count[v]+=1;}
    for(0..s.n)|v|{var i:usize=1;while(i<s.out_count[v]){const e=s.out[v][i];var j=i;while(j>0 and s.before(e,s.out[v][j-1],s.nest)){s.out[v][j]=s.out[v][j-1];j-=1;}s.out[v][j]=e;i+=1;}}
    var planar=true;for(0..s.root_count)|i|{if(!s.test(@intCast(s.roots[i]))){planar=false;break;}}
    if(output==null)return -2;if(!planar){if(capacity<1)return -2;output[0]=0;return 1;}
    var depth:[M]i32=@splat(0);for(0..s.m)|e|depth[e]=s.nest[e]*s.resolveSide(e);
    for(0..s.n)|v|{var i:usize=1;while(i<s.out_count[v]){const e=s.out[v][i];var j=i;while(j>0 and s.before(e,s.out[v][j-1],depth)){s.out[v][j]=s.out[v][j-1];j-=1;}s.out[v][j]=e;i+=1;}}
    for(0..s.n)|v|{for(0..s.out_count[v])|i|{s.rotation[v][s.rotation_count[v]]=s.head[@intCast(s.out[v][i])];s.rotation_count[v]+=1;}}
    for(0..s.root_count)|i|s.embed(@intCast(s.roots[i]));
    const needed=1+2*s.m;if(capacity<needed)return -2;output[0]=1;var at:usize=1;
    for(0..s.n)|v|{for(0..s.rotation_count[v])|i|{output[at]=@intCast(s.rotation[v][i]);at+=1;}}
    return @intCast(needed);
}
