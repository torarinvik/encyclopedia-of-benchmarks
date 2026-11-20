/// Delaunay-rooted reverse search over convex polygon triangulations.
const MAX_N: usize = 8;
const MAX_D: usize = 20;
const MAX_STATES: usize = 132;

const Edge = struct { u: usize, v: usize };
const Opposites = struct { inside: usize, outside: usize };
const Context = struct { n: usize, d: usize, points: [16]i64, diagonals: [MAX_D]Edge };

fn orient(c: *const Context, a: usize, b: usize, z: usize) i64 {
    return (c.points[2*b]-c.points[2*a])*(c.points[2*z+1]-c.points[2*a+1])-(c.points[2*b+1]-c.points[2*a+1])*(c.points[2*z]-c.points[2*a]);
}
fn incircle(c: *const Context, a: usize, b: usize, z: usize, d: usize) i64 {
    const ax=c.points[2*a]-c.points[2*d]; const ay=c.points[2*a+1]-c.points[2*d+1];
    const bx=c.points[2*b]-c.points[2*d]; const by=c.points[2*b+1]-c.points[2*d+1];
    const cx=c.points[2*z]-c.points[2*d]; const cy=c.points[2*z+1]-c.points[2*d+1];
    const al=ax*ax+ay*ay; const bl=bx*bx+by*by; const cl=cx*cx+cy*cy;
    return al*(bx*cy-by*cx)-bl*(ax*cy-ay*cx)+cl*(ax*by-ay*bx);
}
fn boundary(n:usize,u:usize,v:usize) bool { return v==u+1 or (u==0 and v==n-1); }
fn edgeIndex(c:*const Context,u:usize,v:usize) ?usize {
    for(0..c.d)|i| { if(c.diagonals[i].u==u and c.diagonals[i].v==v)return i; }
    return null;
}
fn crosses(a:Edge,b:Edge) bool {
    return (a.u<b.u and b.u<a.v and a.v<b.v) or (b.u<a.u and a.u<b.v and b.v<a.v);
}
fn adjacency(c:*const Context,mask:u32) [MAX_N]u16 {
    var rows:[MAX_N]u16=@splat(0);
    for(0..c.n)|u| { const v=(u+1)%c.n; rows[u]|=@as(u16,1)<<@intCast(v); rows[v]|=@as(u16,1)<<@intCast(u); }
    for(0..c.d)|i| { if((mask&(@as(u32,1)<<@intCast(i)))!=0) { const e=c.diagonals[i]; rows[e.u]|=@as(u16,1)<<@intCast(e.v); rows[e.v]|=@as(u16,1)<<@intCast(e.u); } }
    return rows;
}
fn triangleCount(c:*const Context,mask:u32) usize {
    const rows=adjacency(c,mask); var count:usize=0;
    for(0..c.n)|a| { for(a+1..c.n)|b| { for(b+1..c.n)|z| {
        if((rows[a]&(@as(u16,1)<<@intCast(b)))!=0 and (rows[b]&(@as(u16,1)<<@intCast(z)))!=0 and (rows[a]&(@as(u16,1)<<@intCast(z)))!=0)count+=1;
    } } }
    return count;
}
fn commonOpposites(c:*const Context,mask:u32,edge:usize) ?Opposites {
    const rows=adjacency(c,mask); const e=c.diagonals[edge]; const common=rows[e.u]&rows[e.v];
    var inside:?usize=null; var outside:?usize=null; var found:usize=0;
    for(0..c.n)|w| { if((common&(@as(u16,1)<<@intCast(w)))!=0) { if(e.u<w and w<e.v)inside=w else outside=w; found+=1; } }
    if(found!=2)return null;
    return .{.inside=inside orelse return null,.outside=outside orelse return null};
}
fn flip(c:*const Context,mask:u32,edge:usize,requireLawson:bool) ?u32 {
    const e=c.diagonals[edge]; const opposite=commonOpposites(c,mask,edge) orelse return null;
    if(requireLawson and incircle(c,e.u,opposite.inside,e.v,opposite.outside)<=0)return null;
    const lo=@min(opposite.inside,opposite.outside); const hi=@max(opposite.inside,opposite.outside);
    const other=edgeIndex(c,lo,hi) orelse return null;
    return (mask&~(@as(u32,1)<<@intCast(edge)))|(@as(u32,1)<<@intCast(other));
}
fn parent(c:*const Context,mask:u32) ?u32 {
    for(0..c.d)|edge| { if((mask&(@as(u32,1)<<@intCast(edge)))!=0) { if(flip(c,mask,edge,true))|p|return p; } }
    return null;
}
fn validRoot(c:*const Context,mask:u32) bool {
    if(triangleCount(c,mask)!=c.n-2)return false;
    const rows=adjacency(c,mask);
    for(0..c.n)|a| { for(a+1..c.n)|b| { for(b+1..c.n)|z| {
        if((rows[a]&(@as(u16,1)<<@intCast(b)))!=0 and (rows[b]&(@as(u16,1)<<@intCast(z)))!=0 and (rows[a]&(@as(u16,1)<<@intCast(z)))!=0) {
            for(0..c.n)|q| { if(q!=a and q!=b and q!=z and incircle(c,a,b,z,q)>0)return false; }
        }
    } } }
    return true;
}
fn reverseSearch(c:*const Context,root:u32) i64 {
    var states:[MAX_STATES]u32=@splat(0); var cursor:[MAX_STATES]usize=@splat(0);
    var top:usize=0; var count:i64=1; states[0]=root;
    while(true) {
        if(cursor[top]>=c.d) { if(top==0)break; top-=1; continue; }
        const edge=cursor[top]; cursor[top]+=1;
        if((states[top]&(@as(u32,1)<<@intCast(edge)))==0)continue;
        const child=flip(c,states[top],edge,false) orelse continue;
        const p=parent(c,child) orelse continue;
        if(p!=states[top])continue;
        if(count>=@as(i64,MAX_STATES))return -1;
        count+=1; top+=1; states[top]=child; cursor[top]=0;
    }
    return count;
}

pub export fn delaunay_rooted_triangulation_reverse_search(input:[*c]const i64,length:usize)i64 {
    if(input==null or length<2 or length>29)return -1;
    const n64=input[0];
    if(n64<3 or n64>8 or length!=4*@as(usize,@intCast(n64))-4)return -1;
    const n:usize=@intCast(n64);
    var c=Context{.n=n,.d=0,.points=@splat(0),.diagonals=@splat(.{.u=0,.v=0})};
    for(0..n)|i| {
        const x=input[1+2*i]; const y=input[2+2*i];
        if(x< -50 or x>50 or y< -50 or y>50)return -1;
        c.points[2*i]=x; c.points[2*i+1]=y;
    }
    for(0..n)|a| { for(a+1..n)|b| { for(b+1..n)|z| { if(orient(&c,a,b,z)<=0)return -1; } } }
    for(0..n)|a| { for(a+1..n)|b| { for(b+1..n)|z| { for(z+1..n)|q| { if(incircle(&c,a,b,z,q)==0)return -1; } } } }
    for(0..n)|u| { for(u+1..n)|v| { if(!boundary(n,u,v)) { c.diagonals[c.d]=.{.u=u,.v=v}; c.d+=1; } } }
    const at=1+2*n;
    if(input[at]!=@as(i64,@intCast(n-3)))return -1;
    var root:u32=0; var previous:?Edge=null;
    for(0..n-3)|i| {
        const u64=input[at+1+2*i]; const v64=input[at+2+2*i];
        if(u64<0 or u64>=v64 or v64>=n64)return -1;
        const edge=Edge{.u=@intCast(u64),.v=@intCast(v64)};
        if(boundary(n,edge.u,edge.v))return -1;
        if(previous)|old| { if(edge.u<old.u or (edge.u==old.u and edge.v<=old.v))return -1; }
        const ix=edgeIndex(&c,edge.u,edge.v) orelse return -1;
        root|=@as(u32,1)<<@intCast(ix); previous=edge;
    }
    var seen:usize=0;
    for(0..c.d)|i| { if((root&(@as(u32,1)<<@intCast(i)))!=0) { seen+=1; for(i+1..c.d)|j| { if((root&(@as(u32,1)<<@intCast(j)))!=0 and crosses(c.diagonals[i],c.diagonals[j]))return -1; } } }
    if(seen!=n-3 or !validRoot(&c,root))return -1;
    return reverseSearch(&c,root);
}
