# Clean-room bounded K-quadtree edge-distribution sweep.
from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime KQE_MAX_EDGES = 8
comptime KQE_MAX_CELLS = 46
comptime KQE_MAX_WORDS = 127
comptime KQE_DEPTH = 4

@fieldwise_init
struct KqeCell(Copyable):
    var depth: Int
    var prefix: Int
    var lo: Int
    var alternate_lo: Int
    var x0: Int
    var y0: Int
    var x1: Int
    var y1: Int
    var endpoint_count: Int

@fieldwise_init
struct KqeEdge(Copyable):
    var x0: Int
    var y0: Int
    var x1: Int
    var y1: Int
    var start_cell: Int
    var end_cell: Int
    var negative: Bool

@fieldwise_init
struct KqePoint(Copyable):
    var x: Int
    var y: Int

@fieldwise_init
struct KqeExit(Copyable):
    var edge: Int
    var side: Int
    var numerator: Int64
    var denominator: Int64

fn kqe_orient(a: KqePoint, b: KqePoint, c: KqePoint) -> Int64:
    Int64(b.x-a.x)*Int64(c.y-a.y)-Int64(b.y-a.y)*Int64(c.x-a.x)

fn kqe_on_segment(a: KqePoint, b: KqePoint, p: KqePoint) -> Bool:
    p.x >= min(a.x,b.x) and p.x <= max(a.x,b.x) and p.y >= min(a.y,b.y) and p.y <= max(a.y,b.y)

fn kqe_intersects(a: KqePoint, b: KqePoint, c: KqePoint, d: KqePoint) -> Bool:
    let o1 = kqe_orient(a,b,c)
    let o2 = kqe_orient(a,b,d)
    let o3 = kqe_orient(c,d,a)
    let o4 = kqe_orient(c,d,b)
    if o1 == 0 and kqe_on_segment(a,b,c): return True
    if o2 == 0 and kqe_on_segment(a,b,d): return True
    if o3 == 0 and kqe_on_segment(c,d,a): return True
    if o4 == 0 and kqe_on_segment(c,d,b): return True
    o1*o2 < 0 and o3*o4 < 0

fn kqe_remap(q: Int) -> Int:
    let mapping = InlineArray[Int,4](2,0,3,1)
    mapping[q]

fn kqe_key(x: Int, y: Int, alternate: Bool) -> Int:
    var key = 0
    for step in range(4):
        let bit = 7-step
        var quadrant = (((x >> bit)&1)<<1) | ((y >> bit)&1)
        if alternate: quadrant = kqe_remap(quadrant)
        key = (key << 2) | quadrant
    key

fn kqe_alt_prefix(depth: Int, prefix: Int) -> Int:
    var result = 0
    var shift = 2*(depth-1)
    while shift >= 0:
        result = (result << 2) | kqe_remap((prefix >> shift)&3)
        shift -= 2
    result

fn kqe_make_box(mut cell: KqeCell):
    var x = 0
    var y = 0
    var shift = 2*(cell.depth-1)
    while shift >= 0:
        let quadrant = (cell.prefix >> shift)&3
        x = (x << 1) | (quadrant >> 1)
        y = (y << 1) | (quadrant & 1)
        shift -= 2
    let side = 256 >> cell.depth
    cell.x0 = x*side
    cell.y0 = y*side
    cell.x1 = cell.x0+side
    cell.y1 = cell.y0+side

fn kqe_find_cell(mut cells: InlineArray[KqeCell,KQE_MAX_CELLS], count: Int, key: Int) -> Int:
    for i in range(count):
        let span = 1 << (2*(KQE_DEPTH-cells[i].depth))
        if key >= cells[i].lo and key < cells[i].lo+span: return i
    -1

fn kqe_sweep_box(cell: KqeCell, rotated: Bool) -> InlineArray[Int,4]:
    var box = InlineArray[Int,4](fill=0)
    if rotated:
        box[0]=256-cell.y1; box[1]=cell.x0; box[2]=256-cell.y0; box[3]=cell.x1
    else:
        box[0]=cell.x0; box[1]=cell.y0; box[2]=cell.x1; box[3]=cell.y1
    box

fn kqe_sweep_edge(edge: KqeEdge, rotated: Bool) -> InlineArray[KqePoint,2]:
    var result = InlineArray[KqePoint,2](fill=KqePoint(0,0))
    if rotated:
        result[0]=KqePoint(256-edge.y0,edge.x0)
        result[1]=KqePoint(256-edge.y1,edge.x1)
    else:
        result[0]=KqePoint(edge.x0,edge.y0)
        result[1]=KqePoint(edge.x1,edge.y1)
    result

fn kqe_segment_box(edge: KqeEdge, cell: KqeCell, rotated: Bool) -> Bool:
    let box = kqe_sweep_box(cell,rotated)
    let ab = kqe_sweep_edge(edge,rotated)
    let a=ab[0]; let b=ab[1]
    if a.x>=box[0] and a.x<=box[2] and a.y>=box[1] and a.y<=box[3]: return True
    if b.x>=box[0] and b.x<=box[2] and b.y>=box[1] and b.y<=box[3]: return True
    let corners=InlineArray[KqePoint,4](KqePoint(box[0],box[1]),KqePoint(box[2],box[1]),KqePoint(box[2],box[3]),KqePoint(box[0],box[3]))
    for i in range(4):
        if kqe_intersects(a,b,corners[i],corners[(i+1)&3]): return True
    False

fn kqe_append_point(mut path: InlineArray[KqePoint,33], mut count: Int, point: KqePoint) -> Bool:
    if count>0 and path[count-1].x==point.x and path[count-1].y==point.y: return True
    if count>=33: return False
    path[count]=point
    count+=1
    True

fn kqe_build_frontier(mut cells: InlineArray[KqeCell,KQE_MAX_CELLS], cell_count: Int,
    mut order: InlineArray[Int,KQE_MAX_CELLS], cut: Int, rotated: Bool,
    mut path: InlineArray[KqePoint,33], mut path_count: Int, mut corner: Int) -> Bool:
    var atom_cell=InlineArray[Int,256](fill=-1)
    var rank=InlineArray[Int,KQE_MAX_CELLS](fill=0)
    for i in range(cell_count):
        rank[order[i]]=i
        let id=order[i]
        let start=if rotated: cells[id].alternate_lo else: cells[id].lo
        let span=1 << (2*(KQE_DEPTH-cells[id].depth))
        for atom in range(start,start+span): atom_cell[atom]=id
    var processed=InlineArray[Bool,256](fill=False)
    for key in range(256):
        let id=atom_cell[key]
        if id<0: return False
        var x=0; var y=0
        for step in range(4):
            let q=(key >> (6-2*step))&3
            x=(x<<1)|(q>>1); y=(y<<1)|(q&1)
        processed[x*16+y]=rank[id]<cut
    var heights=InlineArray[Int,16](fill=0)
    for x in range(16):
        var height=0
        while height<16 and processed[x*16+height]: height+=1
        for y in range(16):
            if processed[x*16+y] != (y<height): return False
        heights[x]=height
        if x>0 and heights[x-1]<height: return False
    path_count=0
    if not kqe_append_point(mut path,mut path_count,KqePoint(0,256)): return False
    var y=15
    while y>=heights[0]:
        if not kqe_append_point(mut path,mut path_count,KqePoint(0,y*16)): return False
        y-=1
    for x in range(16):
        if not kqe_append_point(mut path,mut path_count,KqePoint((x+1)*16,heights[x]*16)): return False
        let next_height=if x<15: heights[x+1] else: 0
        y=heights[x]-1
        while y>=next_height:
            if not kqe_append_point(mut path,mut path_count,KqePoint((x+1)*16,y*16)): return False
            y-=1
    if path[0].x!=0 or path[0].y!=256 or path[path_count-1].x!=256 or path[path_count-1].y!=0: return False
    let next_box=kqe_sweep_box(cells[order[cut]],rotated)
    for i in range(path_count):
        if path[i].x==next_box[0] and path[i].y==next_box[1]:
            corner=i
            return True
    False

fn kqe_frontier_segment(a: KqePoint,b: KqePoint,mut path: InlineArray[KqePoint,33],count: Int) -> Int:
    var found=-1
    for i in range(count-1):
        if kqe_intersects(a,b,path[i],path[i+1]):
            if found>=0: return -2
            found=i
    found

fn kqe_exit_for_cell(a: KqePoint,b: KqePoint,box: InlineArray[Int,4],id: Int,
    mut output: KqeExit) -> Bool:
    let dx=Int64(b.x-a.x); let dy=Int64(b.y-a.y)
    var found=0
    if dy>0:
        let ydist=Int64(box[3]-a.y)
        let num=Int64(a.x)*dy+ydist*dx
        if ydist>0 and ydist<dy and Int64(box[0])*dy<num and num<Int64(box[2])*dy:
            output=KqeExit(id,0,num,dy); found+=1
    if dx>0:
        let xdist=Int64(box[2]-a.x)
        let num=Int64(a.y)*dx+xdist*dy
        if xdist>0 and xdist<dx and Int64(box[1])*dx<num and num<Int64(box[3])*dx:
            output=KqeExit(id,1,num,dx); found+=1
    found==1

fn kqe_exit_less(a: KqeExit,b: KqeExit) -> Bool:
    let lhs=a.numerator*b.denominator; let rhs=b.numerator*a.denominator
    lhs<rhs or (lhs==rhs and a.edge<b.edge)

fn kqe_run_sweep(mut cells: InlineArray[KqeCell,KQE_MAX_CELLS],cell_count: Int,
    mut edges: InlineArray[KqeEdge,KQE_MAX_EDGES],edge_count: Int,
    mut endpoints: InlineArray[Int,16],rotated: Bool,mut masks: InlineArray[Int64,KQE_MAX_CELLS]) -> Bool:
    var order=InlineArray[Int,KQE_MAX_CELLS](fill=0)
    for i in range(cell_count): order[i]=i
    if rotated:
        for i in range(1,cell_count):
            let value=order[i]; var j=i
            while j>0 and (cells[order[j-1]].alternate_lo>cells[value].alternate_lo or
                (cells[order[j-1]].alternate_lo==cells[value].alternate_lo and order[j-1]>value)):
                order[j]=order[j-1]; j-=1
            order[j]=value
    var edge_a=InlineArray[KqePoint,KQE_MAX_EDGES](fill=KqePoint(0,0))
    var edge_b=InlineArray[KqePoint,KQE_MAX_EDGES](fill=KqePoint(0,0))
    var ids=InlineArray[Int,KQE_MAX_EDGES](fill=0)
    var keys=InlineArray[Int,KQE_MAX_EDGES](fill=0)
    var m=0
    for id in range(edge_count):
        if edges[id].negative==rotated:
            let ab=kqe_sweep_edge(edges[id],rotated)
            edge_a[id]=ab[0]; edge_b[id]=ab[1]
            let key=kqe_key(ab[0].x,ab[0].y,False)
            var j=m; m+=1
            while j>0 and (keys[j-1]>key or (keys[j-1]==key and ids[j-1]>id)):
                keys[j]=keys[j-1]; ids[j]=ids[j-1]; j-=1
            keys[j]=key; ids[j]=id
    var sl=InlineArray[Int,KQE_MAX_EDGES](fill=0)
    var sb=InlineArray[Int,KQE_MAX_EDGES](fill=0)
    var sl_count=0; var sb_count=0
    for pos in range(cell_count):
        let cid=order[pos]
        let box=kqe_sweep_box(cells[cid],rotated)
        var candidates=InlineArray[Int,16](fill=0); var candidate_count=0
        while sl_count>0 and kqe_segment_box(edges[sl[sl_count-1]],cells[cid],rotated):
            sl_count-=1; candidates[candidate_count]=sl[sl_count]; candidate_count+=1
        while sb_count>0 and kqe_segment_box(edges[sb[sb_count-1]],cells[cid],rotated):
            sb_count-=1; candidates[candidate_count]=sb[sb_count]; candidate_count+=1
        for q in range(m):
            let id=ids[q]
            if endpoints[2*id]==cid:
                candidates[candidate_count]=id; candidate_count+=1
        var exits=InlineArray[KqeExit,16](fill=KqeExit(0,0,0,1)); var exit_count=0
        for q in range(candidate_count):
            let id=candidates[q]
            masks[cid] |= Int64(1) << id
            if endpoints[2*id+1]!=cid:
                if not kqe_exit_for_cell(edge_a[id],edge_b[id],box,id,mut exits[exit_count]): return False
                exit_count+=1
        for i in range(1,exit_count):
            let value=exits[i]; var j=i
            while j>0 and (exits[j-1].side>value.side or
                (exits[j-1].side==value.side and kqe_exit_less(value,exits[j-1]))):
                exits[j]=exits[j-1]; j-=1
            exits[j]=value
        for i in range(exit_count):
            if exits[i].side==0:
                if sl_count>=KQE_MAX_EDGES: return False
                sl[sl_count]=exits[i].edge; sl_count+=1
            else:
                if sb_count>=KQE_MAX_EDGES: return False
                sb[sb_count]=exits[i].edge; sb_count+=1
        if pos+1<cell_count:
            var path=InlineArray[KqePoint,33](fill=KqePoint(0,0))
            var path_count=0; var corner=0
            if not kqe_build_frontier(mut cells,cell_count,mut order,pos+1,rotated,mut path,mut path_count,mut corner): return False
            let next_box=kqe_sweep_box(cells[order[pos+1]],rotated)
            if next_box[1]>box[1]:
                while sl_count>0:
                    let id=sl[sl_count-1]
                    let crossing=kqe_frontier_segment(edge_a[id],edge_b[id],mut path,path_count)
                    if crossing<0: return False
                    if crossing<corner: break
                    if sb_count>=KQE_MAX_EDGES: return False
                    sb[sb_count]=sl[sl_count-1]; sb_count+=1; sl_count-=1
            else:
                while sb_count>0:
                    let id=sb[sb_count-1]
                    let crossing=kqe_frontier_segment(edge_a[id],edge_b[id],mut path,path_count)
                    if crossing<0: return False
                    if crossing>=corner: break
                    if sl_count>=KQE_MAX_EDGES: return False
                    sl[sl_count]=sb[sb_count-1]; sl_count+=1; sb_count-=1
    sl_count==0 and sb_count==0

fn kqe_put(output: UnsafePointer[UInt8,MutAnyOrigin],offset: Int,value: Int64):
    let bits=UInt64(value)
    for byte in range(8): output[offset+byte]=UInt8((bits >> (byte*8)) & UInt64(255))

@export("k_quadtree_edge_distribution")
fn k_quadtree_edge_distribution(input: UnsafePointer[Int64,ImmutAnyOrigin],length:c_size_t,
    output:UnsafePointer[UInt8,MutAnyOrigin],capacity:c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>c_size_t(KQE_MAX_WORDS): return -1
    let n_value=input[0]; let c_value=input[1]
    if n_value<0 or n_value>KQE_MAX_EDGES or c_value<1 or c_value>KQE_MAX_CELLS: return -1
    let n=Int(n_value); let c=Int(c_value)
    if Int(length)!=2+2*c+4*n: return -1
    var cells=InlineArray[KqeCell,KQE_MAX_CELLS](fill=KqeCell(0,0,0,0,0,0,0,0,0))
    var edges=InlineArray[KqeEdge,KQE_MAX_EDGES](fill=KqeEdge(0,0,0,0,0,0,False))
    var endpoints=InlineArray[Int,16](fill=0)
    var at=2; var previous=0
    for i in range(c):
        let d=input[at]; let p=input[at+1]; at+=2
        if d<0 or d>4 or p<0 or p >= (Int64(1) << (2*Int(d))): return -1
        cells[i].depth=Int(d); cells[i].prefix=Int(p)
        let span=1 << (2*(KQE_DEPTH-cells[i].depth))
        cells[i].lo=cells[i].prefix*span
        if cells[i].lo!=previous: return -1
        previous=cells[i].lo+span
        kqe_make_box(mut cells[i])
    if previous!=256 or (n==0 and (c!=1 or cells[0].depth!=0 or cells[0].prefix!=0)): return -1
    for i in range(c): cells[i].alternate_lo=kqe_alt_prefix(cells[i].depth,cells[i].prefix) << (2*(KQE_DEPTH-cells[i].depth))
    var points=InlineArray[KqePoint,16](fill=KqePoint(0,0))
    for i in range(n):
        var x0=input[at]; var y0=input[at+1]; var x1=input[at+2]; var y1=input[at+3]; at+=4
        if x0<0 or x0>255 or y0<0 or y0>255 or x1<0 or x1>255 or y1<0 or y1>255: return -1
        if x0%16==0 or y0%16==0 or x1%16==0 or y1%16==0 or (x0==x1 and y0==y1) or y0==y1: return -1
        if x0>x1 or (x0==x1 and y0>y1):
            let tx=x0; let ty=y0; x0=x1; y0=y1; x1=tx; y1=ty
        if x0==x1 and y1<=y0: return -1
        edges[i]=KqeEdge(Int(x0),Int(y0),Int(x1),Int(y1),0,0,y1<y0)
        points[2*i]=KqePoint(Int(x0),Int(y0)); points[2*i+1]=KqePoint(Int(x1),Int(y1))
        var gx=0
        while gx<=256:
            var gy=0
            while gy<=256:
                let p=KqePoint(gx,gy)
                if kqe_orient(points[2*i],points[2*i+1],p)==0 and kqe_on_segment(points[2*i],points[2*i+1],p): return -1
                gy+=16
            gx+=16
        for j in range(2*i):
            if points[j].x==Int(x0) and points[j].y==Int(y0): return -1
        for j in range(2*i+1):
            if points[j].x==Int(x1) and points[j].y==Int(y1): return -1
        for j in range(i):
            if kqe_intersects(points[2*i],points[2*i+1],points[2*j],points[2*j+1]): return -1
        let start=kqe_find_cell(mut cells,c,kqe_key(Int(x0),Int(y0),False))
        let finish=kqe_find_cell(mut cells,c,kqe_key(Int(x1),Int(y1),False))
        if start<0 or finish<0: return -1
        endpoints[2*i]=start; endpoints[2*i+1]=finish
        edges[i].start_cell=start; edges[i].end_cell=finish
        cells[start].endpoint_count+=1; cells[finish].endpoint_count+=1
    for i in range(c):
        if cells[i].endpoint_count>1: return -1
    var parent_depth=InlineArray[Int,85](fill=0)
    var parent_prefix=InlineArray[Int,85](fill=0)
    var parent_count=0
    for i in range(c):
        for d in range(cells[i].depth):
            let p=cells[i].prefix >> (2*(cells[i].depth-d))
            var exists=False
            for q in range(parent_count):
                if parent_depth[q]==d and parent_prefix[q]==p: exists=True
            if not exists:
                parent_depth[parent_count]=d; parent_prefix[parent_count]=p; parent_count+=1
    for q in range(parent_count):
        var occupied=0
        for i in range(c):
            if cells[i].endpoint_count==0 or cells[i].depth<=parent_depth[q]: continue
            if (cells[i].prefix >> (2*(cells[i].depth-parent_depth[q])))==parent_prefix[q]:
                let child=(cells[i].prefix >> (2*(cells[i].depth-parent_depth[q]-1)))&3
                occupied |= 1 << child
        if occupied==0 or (occupied&(occupied-1))==0: return -1
    for i in range(n):
        for direction in range(2):
            let rotated=direction==1
            if edges[i].negative!=rotated: continue
            var order=InlineArray[Int,KQE_MAX_CELLS](fill=0)
            for j in range(c): order[j]=j
            if rotated:
                for a in range(1,c):
                    let value=order[a]; var j=a
                    while j>0 and cells[order[j-1]].alternate_lo>cells[value].alternate_lo:
                        order[j]=order[j-1]; j-=1
                    order[j]=value
            var start_rank=0; var end_rank=0
            for j in range(c):
                if order[j]==endpoints[2*i]: start_rank=j
                if order[j]==endpoints[2*i+1]: end_rank=j
            if start_rank>end_rank: return -1
    var masks=InlineArray[Int64,KQE_MAX_CELLS](fill=0)
    if not kqe_run_sweep(mut cells,c,mut edges,n,mut endpoints,False,mut masks): return -1
    if not kqe_run_sweep(mut cells,c,mut edges,n,mut endpoints,True,mut masks): return -1
    let bytes=8*(1+c)
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes): return -2
    kqe_put(output,0,Int64(c))
    for i in range(c): kqe_put(output,8*(i+1),masks[i])
    Int64(bytes)
