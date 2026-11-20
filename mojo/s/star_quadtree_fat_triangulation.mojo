from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime STAR_MAX_DEPTH = 2
comptime STAR_MAX_INPUT = 25
comptime STAR_MAX_EDGES = 8
comptime STAR_MAX_PAIRS = 64

@fieldwise_init
struct StarState(Copyable):
    var vertices: InlineArray[Int, 10]
    var triangles: InlineArray[Int, 12]
    var edges: InlineArray[Int, 16]
    var pairs: InlineArray[Int, 128]
    var vertex_count: Int
    var triangle_count: Int
    var edge_count: Int
    var pair_count: Int
    var failed: Bool

fn star_orient(ax: Int, ay: Int, bx: Int, by: Int, cx: Int, cy: Int) -> Int:
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)

fn star_between(a: Int, b: Int, p: Int) -> Bool:
    return (a <= p and p <= b) or (b <= p and p <= a)

fn star_on_segment(ax: Int, ay: Int, bx: Int, by: Int, px: Int, py: Int) -> Bool:
    return star_between(ax,bx,px) and star_between(ay,by,py)

fn star_segments_intersect(ax: Int, ay: Int, bx: Int, by: Int,
    cx: Int, cy: Int, dx: Int, dy: Int) -> Bool:
    let o1=star_orient(ax,ay,bx,by,cx,cy); let o2=star_orient(ax,ay,bx,by,dx,dy)
    let o3=star_orient(cx,cy,dx,dy,ax,ay); let o4=star_orient(cx,cy,dx,dy,bx,by)
    if ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0)): return True
    return (o1==0 and star_on_segment(ax,ay,bx,by,cx,cy)) or
        (o2==0 and star_on_segment(ax,ay,bx,by,dx,dy)) or
        (o3==0 and star_on_segment(cx,cy,dx,dy,ax,ay)) or
        (o4==0 and star_on_segment(cx,cy,dx,dy,bx,by))

fn star_edge_hits_box(state: StarState, edge_id: Int, xmin: Int, ymin: Int,
    xmax: Int, ymax: Int) -> Bool:
    let a=state.edges[edge_id*2]; let b=state.edges[edge_id*2+1]
    let ax=state.vertices[a*2]; let ay=state.vertices[a*2+1]
    let bx=state.vertices[b*2]; let by=state.vertices[b*2+1]
    if (xmin<=ax and ax<=xmax and ymin<=ay and ay<=ymax) or
       (xmin<=bx and bx<=xmax and ymin<=by and by<=ymax): return True
    return star_segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin) or
        star_segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax) or
        star_segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax) or
        star_segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin)

fn star_stops(state: StarState, xmin: Int, ymin: Int, xmax: Int, ymax: Int) -> Bool:
    var touched = InlineArray[Bool, STAR_MAX_EDGES](fill=False)
    var touched_count = 0
    for e in range(state.edge_count):
        touched[e] = star_edge_hits_box(state,e,xmin,ymin,xmax,ymax)
        if touched[e]: touched_count += 1
    if touched_count == 0: return True
    for v in range(state.vertex_count):
        var common = True
        for e in range(state.edge_count):
            if touched[e] and state.edges[2*e] != v and state.edges[2*e+1] != v: common = False
        if common: return True
    return False

fn star_point_in_triangle(state: StarState, px: Int, py: Int, tid: Int) -> Bool:
    let a=state.triangles[3*tid]; let b=state.triangles[3*tid+1]; let c=state.triangles[3*tid+2]
    return star_orient(state.vertices[2*a],state.vertices[2*a+1],state.vertices[2*b],state.vertices[2*b+1],px,py)>=0 and
        star_orient(state.vertices[2*b],state.vertices[2*b+1],state.vertices[2*c],state.vertices[2*c+1],px,py)>=0 and
        star_orient(state.vertices[2*c],state.vertices[2*c+1],state.vertices[2*a],state.vertices[2*a+1],px,py)>=0

fn star_triangle_hits_box(state: StarState, tid: Int, xmin: Int, ymin: Int,
    xmax: Int, ymax: Int) -> Bool:
    for k in range(3):
        let v=state.triangles[3*tid+k]; let x=state.vertices[2*v]; let y=state.vertices[2*v+1]
        if xmin<=x and x<=xmax and ymin<=y and y<=ymax: return True
    if star_point_in_triangle(state,xmin,ymin,tid) or star_point_in_triangle(state,xmax,ymin,tid) or
       star_point_in_triangle(state,xmax,ymax,tid) or star_point_in_triangle(state,xmin,ymax,tid): return True
    for k in range(3):
        let a=state.triangles[3*tid+k]; let b=state.triangles[3*tid+(k+1)%3]
        let ax=state.vertices[2*a]; let ay=state.vertices[2*a+1]
        let bx=state.vertices[2*b]; let by=state.vertices[2*b+1]
        if star_segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin) or
           star_segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax) or
           star_segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax) or
           star_segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin): return True
    return False

fn star_add_edge(mut state: StarState, a0: Int, b0: Int) -> Bool:
    let a=min(a0,b0); let b=max(a0,b0)
    for i in range(state.edge_count):
        if state.edges[2*i]==a and state.edges[2*i+1]==b: return True
    if state.edge_count >= STAR_MAX_EDGES: return False
    state.edges[2*state.edge_count]=a; state.edges[2*state.edge_count+1]=b
    state.edge_count += 1
    return True

fn star_append_pair(mut state: StarState, key: Int, tid: Int):
    if state.pair_count >= STAR_MAX_PAIRS:
        state.failed=True
        return
    state.pairs[2*state.pair_count]=key; state.pairs[2*state.pair_count+1]=tid
    state.pair_count += 1

fn star_visit(mut state: StarState, depth: Int, ix: Int, iy: Int, path: Int):
    if state.failed: return
    let size=8 >> depth
    let xmin=ix*size; let xmax=xmin+size
    let ymax=8-iy*size; let ymin=ymax-size
    if not star_stops(state,xmin,ymin,xmax,ymax):
        if depth >= STAR_MAX_DEPTH:
            state.failed=True
            return
        for q in range(4):
            star_visit(mut state,depth+1,2*ix+(q&1),2*iy+(q>>1),4*path+q)
        return
    let key=path << (2*(STAR_MAX_DEPTH-depth))
    for tid in range(state.triangle_count):
        if star_triangle_hits_box(state,tid,xmin,ymin,xmax,ymax): star_append_pair(mut state,key,tid)

fn star_parse(mut state: StarState, input: UnsafePointer[Int64, ImmutAnyOrigin], length: Int) -> Bool:
    if length<2 or length>STAR_MAX_INPUT: return False
    if not ((input[0]==4 and input[1]==2) or (input[0]==5 and input[1]==4)): return False
    state.vertex_count=Int(input[0]); state.triangle_count=Int(input[1])
    if length != 2+2*state.vertex_count+3*state.triangle_count: return False
    let corners=InlineArray[Int,8](0,0,8,0,8,8,0,8)
    for i in range(8):
        if input[2+i] != Int64(corners[i]): return False
        state.vertices[i]=corners[i]
    if state.vertex_count==5:
        if input[10]!=4 or input[11]!=4: return False
        state.vertices[8]=4; state.vertices[9]=4
    let start=2+2*state.vertex_count
    for i in range(3*state.triangle_count):
        if input[start+i]<0 or input[start+i]>=Int64(state.vertex_count): return False
        state.triangles[i]=Int(input[start+i])
    if state.vertex_count==4:
        let d02=state.triangles[0]==0 and state.triangles[1]==1 and state.triangles[2]==2 and state.triangles[3]==0 and state.triangles[4]==2 and state.triangles[5]==3
        let d13=state.triangles[0]==0 and state.triangles[1]==1 and state.triangles[2]==3 and state.triangles[3]==1 and state.triangles[4]==2 and state.triangles[5]==3
        if not d02 and not d13: return False
    else:
        let fan=InlineArray[Int,12](0,1,4,1,2,4,2,3,4,3,0,4)
        for i in range(12):
            if state.triangles[i]!=fan[i]: return False
    for tid in range(state.triangle_count):
        if not star_add_edge(mut state,state.triangles[3*tid],state.triangles[3*tid+1]) or
           not star_add_edge(mut state,state.triangles[3*tid+1],state.triangles[3*tid+2]) or
           not star_add_edge(mut state,state.triangles[3*tid+2],state.triangles[3*tid]): return False
    return True

fn star_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=UInt64(value)
    for byte in range(8): output[offset+byte]=UInt8((bits >> (8*byte)) & 255)

@export("star_quadtree_fat_triangulation")
fn star_quadtree_fat_triangulation(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>c_size_t(STAR_MAX_INPUT): return -1
    var state=StarState(
        vertices=InlineArray[Int,10](fill=0), triangles=InlineArray[Int,12](fill=0),
        edges=InlineArray[Int,16](fill=0), pairs=InlineArray[Int,128](fill=0),
        vertex_count=0,triangle_count=0,edge_count=0,pair_count=0,failed=False)
    if not star_parse(mut state,input,Int(length)): return -1
    star_visit(mut state,0,0,0,0)
    if state.failed: return -1
    let bytes=8*(1+2*state.pair_count)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    star_store_le(output,0,Int64(state.pair_count))
    for i in range(state.pair_count):
        star_store_le(output,8+16*i,Int64(state.pairs[2*i]))
        star_store_le(output,16+16*i,Int64(state.pairs[2*i+1]))
    return Int64(bytes)
