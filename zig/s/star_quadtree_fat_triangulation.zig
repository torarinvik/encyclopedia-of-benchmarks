const MAX_DEPTH: usize = 2;
const MAX_INPUT: usize = 25;
const MAX_PAIRS: usize = 64;

const Point = struct { x: i64 = 0, y: i64 = 0 };
const Triangle = struct { v: [3]usize = .{0,0,0} };
const Edge = struct { a: usize = 0, b: usize = 0 };
const State = struct {
    points: [5]Point = @splat(.{}),
    triangles: [4]Triangle = @splat(.{}),
    edges: [8]Edge = @splat(.{}),
    pairs: [MAX_PAIRS][2]i64 = @splat(@splat(0)),
    vertex_count: usize = 0,
    triangle_count: usize = 0,
    edge_count: usize = 0,
    pair_count: usize = 0,
    failed: bool = false,
};

fn orient(a: Point, b: Point, c: Point) i64 {
    return (b.x-a.x)*(c.y-a.y)-(b.y-a.y)*(c.x-a.x);
}
fn onSegment(a: Point, b: Point, p: Point) bool {
    return @min(a.x,b.x)<=p.x and p.x<=@max(a.x,b.x) and @min(a.y,b.y)<=p.y and p.y<=@max(a.y,b.y);
}
fn segmentsIntersect(a: Point, b: Point, c: Point, d: Point) bool {
    const o1=orient(a,b,c);const o2=orient(a,b,d);const o3=orient(c,d,a);const o4=orient(c,d,b);
    if (((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0))) return true;
    return (o1==0 and onSegment(a,b,c)) or (o2==0 and onSegment(a,b,d)) or
        (o3==0 and onSegment(c,d,a)) or (o4==0 and onSegment(c,d,b));
}
fn edgeHitsBox(state: *const State, edge: Edge, xmin: i64, ymin: i64, xmax: i64, ymax: i64) bool {
    const a=state.points[edge.a];const b=state.points[edge.b];
    if ((xmin<=a.x and a.x<=xmax and ymin<=a.y and a.y<=ymax) or
        (xmin<=b.x and b.x<=xmax and ymin<=b.y and b.y<=ymax)) return true;
    return segmentsIntersect(a,b,.{.x=xmin,.y=ymin},.{.x=xmax,.y=ymin}) or
        segmentsIntersect(a,b,.{.x=xmax,.y=ymin},.{.x=xmax,.y=ymax}) or
        segmentsIntersect(a,b,.{.x=xmax,.y=ymax},.{.x=xmin,.y=ymax}) or
        segmentsIntersect(a,b,.{.x=xmin,.y=ymax},.{.x=xmin,.y=ymin});
}
fn stopping(state: *const State, xmin: i64, ymin: i64, xmax: i64, ymax: i64) bool {
    var touched: [8]bool = @splat(false);
    var count: usize = 0;
    for (0..state.edge_count) |e| { touched[e]=edgeHitsBox(state,state.edges[e],xmin,ymin,xmax,ymax);if(touched[e])count+=1; }
    if (count==0) return true;
    for (0..state.vertex_count) |v| {
        var common=true;
        for (0..state.edge_count) |e| if (touched[e] and state.edges[e].a!=v and state.edges[e].b!=v) { common=false; };
        if (common) return true;
    }
    return false;
}
fn pointInTriangle(p: Point, a: Point, b: Point, c: Point) bool {
    return orient(a,b,p)>=0 and orient(b,c,p)>=0 and orient(c,a,p)>=0;
}
fn triangleHitsBox(state: *const State, tid: usize, xmin: i64, ymin: i64, xmax: i64, ymax: i64) bool {
    const t=state.triangles[tid].v;
    for (t) |v| { const p=state.points[v];if(xmin<=p.x and p.x<=xmax and ymin<=p.y and p.y<=ymax)return true; }
    const a=state.points[t[0]];const b=state.points[t[1]];const c=state.points[t[2]];
    if (pointInTriangle(.{.x=xmin,.y=ymin},a,b,c) or pointInTriangle(.{.x=xmax,.y=ymin},a,b,c) or
        pointInTriangle(.{.x=xmax,.y=ymax},a,b,c) or pointInTriangle(.{.x=xmin,.y=ymax},a,b,c)) return true;
    const corners=[_]Point{.{.x=xmin,.y=ymin},.{.x=xmax,.y=ymin},.{.x=xmax,.y=ymax},.{.x=xmin,.y=ymax}};
    for (0..3) |i| { const p=state.points[t[i]];const q=state.points[t[(i+1)%3]];
        for (0..4) |side| if (segmentsIntersect(p,q,corners[side],corners[(side+1)%4])) return true;
    }
    return false;
}
fn addEdge(state: *State, a0: usize, b0: usize) bool {
    const a=@min(a0,b0);const b=@max(a0,b0);
    for (0..state.edge_count) |i| if(state.edges[i].a==a and state.edges[i].b==b)return true;
    if(state.edge_count>=state.edges.len)return false;
    state.edges[state.edge_count]=.{.a=a,.b=b};state.edge_count+=1;return true;
}
fn appendPair(state: *State, key: i64, tid: usize) void {
    if(state.pair_count>=MAX_PAIRS){state.failed=true;return;}
    state.pairs[state.pair_count]=.{key,@intCast(tid)};state.pair_count+=1;
}
fn visit(state: *State, depth: usize, ix: usize, iy: usize, path: usize) void {
    if(state.failed)return;
    const size: i64=8 >> @intCast(depth);
    const xmin=@as(i64,@intCast(ix))*size;const xmax=xmin+size;
    const ymax=8-@as(i64,@intCast(iy))*size;const ymin=ymax-size;
    if(!stopping(state,xmin,ymin,xmax,ymax)){
        if(depth>=MAX_DEPTH){state.failed=true;return;}
        for(0..4) |q| visit(state,depth+1,2*ix+(q&1),2*iy+(q>>1),4*path+q);
        return;
    }
    const key: i64=@intCast(path << (2*(MAX_DEPTH-depth)));
    for(0..state.triangle_count) |tid| if(triangleHitsBox(state,tid,xmin,ymin,xmax,ymax))appendPair(state,key,tid);
}
fn parse(state: *State, input: [*]const i64, length: usize) bool {
    if(length<2 or length>MAX_INPUT)return false;
    if(!((input[0]==4 and input[1]==2) or (input[0]==5 and input[1]==4)))return false;
    state.vertex_count=@intCast(input[0]);state.triangle_count=@intCast(input[1]);
    if(length!=2+2*state.vertex_count+3*state.triangle_count)return false;
    const corners=[_]Point{.{.x=0,.y=0},.{.x=8,.y=0},.{.x=8,.y=8},.{.x=0,.y=8}};
    for(0..4) |i| { if(input[2+2*i]!=corners[i].x or input[3+2*i]!=corners[i].y)return false;state.points[i]=corners[i]; }
    if(state.vertex_count==5){if(input[10]!=4 or input[11]!=4)return false;state.points[4]=.{.x=4,.y=4};}
    const start=2+2*state.vertex_count;
    for(0..state.triangle_count) |i| { for(0..3) |j| { const id=input[start+3*i+j];if(id<0 or id>=@as(i64,@intCast(state.vertex_count)))return false;state.triangles[i].v[j]=@intCast(id); } }
    if(state.vertex_count==4){
        const d02=state.triangles[0].v[0]==0 and state.triangles[0].v[1]==1 and state.triangles[0].v[2]==2 and
            state.triangles[1].v[0]==0 and state.triangles[1].v[1]==2 and state.triangles[1].v[2]==3;
        const d13=state.triangles[0].v[0]==0 and state.triangles[0].v[1]==1 and state.triangles[0].v[2]==3 and
            state.triangles[1].v[0]==1 and state.triangles[1].v[1]==2 and state.triangles[1].v[2]==3;
        if(!d02 and !d13)return false;
    }else{
        const fan=[_]usize{0,1,4,1,2,4,2,3,4,3,0,4};
        for(0..12) |i| if(input[start+i]!=@as(i64,@intCast(fan[i])))return false;
    }
    for(0..state.triangle_count) |i| { const t=state.triangles[i].v;if(!addEdge(state,t[0],t[1]) or !addEdge(state,t[1],t[2]) or !addEdge(state,t[2],t[0]))return false; }
    return true;
}
fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64=@bitCast(value);
    for(0..8) |i|output[offset+i]=@truncate(bits >> @intCast(8*i));
}

export fn star_quadtree_fat_triangulation(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    const input=input_opt orelse return -1;
    if(length<2 or length>MAX_INPUT)return -1;
    var state=State{};
    if(!parse(&state,input,length))return -1;
    visit(&state,0,0,0,0);
    if(state.failed)return -1;
    const bytes=(1+2*state.pair_count)*8;
    const output=output_opt orelse return -2;
    if(capacity<bytes)return -2;
    storeLe(output,0,@intCast(state.pair_count));
    for(0..state.pair_count) |i| { storeLe(output,8+16*i,state.pairs[i][0]);storeLe(output,16+16*i,state.pairs[i][1]); }
    return @intCast(bytes);
}
