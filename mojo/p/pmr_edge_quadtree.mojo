from std.collections import InlineArray
from std.ffi import c_size_t
from std.memory import ImmutAnyOrigin, MutAnyOrigin, UnsafePointer

comptime PMR_MAX_SEGMENTS = 8
comptime PMR_MAX_DEPTH = 8
comptime PMR_MAX_NODES = 2048
comptime PMR_MAX_INPUT = 35

@fieldwise_init
struct PmrNode(Copyable):
    var parent: Int
    var quadrant: Int
    var depth: Int
    var xmin: Int64
    var ymin: Int64
    var xmax: Int64
    var ymax: Int64
    var child: InlineArray[Int, 4]
    var ids: InlineArray[Int, PMR_MAX_SEGMENTS]
    var id_count: Int

fn pmr_orient(ax: Int64, ay: Int64, bx: Int64, by: Int64, cx: Int64, cy: Int64) -> Int64:
    return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
fn pmr_between(a: Int64, b: Int64, p: Int64) -> Bool:
    return (a<=p and p<=b) or (b<=p and p<=a)
fn pmr_on_segment(ax: Int64, ay: Int64, bx: Int64, by: Int64, px: Int64, py: Int64) -> Bool:
    return pmr_between(ax,bx,px) and pmr_between(ay,by,py)
fn pmr_seg_intersects(ax: Int64, ay: Int64, bx: Int64, by: Int64,
    cx: Int64, cy: Int64, dx: Int64, dy: Int64) -> Bool:
    let o1=pmr_orient(ax,ay,bx,by,cx,cy);let o2=pmr_orient(ax,ay,bx,by,dx,dy)
    let o3=pmr_orient(cx,cy,dx,dy,ax,ay);let o4=pmr_orient(cx,cy,dx,dy,bx,by)
    if ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0)): return True
    return (o1==0 and pmr_on_segment(ax,ay,bx,by,cx,cy)) or
        (o2==0 and pmr_on_segment(ax,ay,bx,by,dx,dy)) or
        (o3==0 and pmr_on_segment(cx,cy,dx,dy,ax,ay)) or
        (o4==0 and pmr_on_segment(cx,cy,dx,dy,bx,by))
fn pmr_intersects_box(segments: InlineArray[Int64, PMR_MAX_SEGMENTS * 4], sid: Int, node: PmrNode) -> Bool:
    let offset=sid*4;let x0=2*segments[offset];let y0=2*segments[offset+1]
    let x1=2*segments[offset+2];let y1=2*segments[offset+3]
    if (node.xmin<=x0 and x0<=node.xmax and node.ymin<=y0 and y0<=node.ymax) or
       (node.xmin<=x1 and x1<=node.xmax and node.ymin<=y1 and y1<=node.ymax): return True
    return pmr_seg_intersects(x0,y0,x1,y1,node.xmin,node.ymin,node.xmax,node.ymin) or
        pmr_seg_intersects(x0,y0,x1,y1,node.xmax,node.ymin,node.xmax,node.ymax) or
        pmr_seg_intersects(x0,y0,x1,y1,node.xmax,node.ymax,node.xmin,node.ymax) or
        pmr_seg_intersects(x0,y0,x1,y1,node.xmin,node.ymax,node.xmin,node.ymin)

fn pmr_init_node(mut nodes: InlineArray[PmrNode, PMR_MAX_NODES], id: Int, parent: Int,
    quadrant: Int, depth: Int, xmin: Int64, ymin: Int64, xmax: Int64, ymax: Int64):
    nodes[id].parent=parent;nodes[id].quadrant=quadrant;nodes[id].depth=depth
    nodes[id].xmin=xmin;nodes[id].ymin=ymin;nodes[id].xmax=xmax;nodes[id].ymax=ymax
    nodes[id].id_count=0
    for q in range(4): nodes[id].child[q]=-1
    for j in range(PMR_MAX_SEGMENTS): nodes[id].ids[j]=0

fn pmr_insert(mut nodes: InlineArray[PmrNode, PMR_MAX_NODES],
    segments: InlineArray[Int64, PMR_MAX_SEGMENTS * 4], mut used: Int,
    node_id: Int, sid: Int, threshold: Int) -> Bool:
    if nodes[node_id].child[0]>=0:
        for q in range(4):
            let child=nodes[node_id].child[q]
            if pmr_intersects_box(segments,sid,nodes[child]) and
                not pmr_insert(mut nodes,segments,mut used,child,sid,threshold): return False
        return True
    if nodes[node_id].id_count>=PMR_MAX_SEGMENTS:return False
    let slot=nodes[node_id].id_count;nodes[node_id].ids[slot]=sid;nodes[node_id].id_count+=1
    if nodes[node_id].id_count<=threshold:return True
    if nodes[node_id].depth>=PMR_MAX_DEPTH or used+4>PMR_MAX_NODES:return False
    let previous=nodes[node_id].ids;let previous_count=nodes[node_id].id_count
    let xmin=nodes[node_id].xmin;let ymin=nodes[node_id].ymin;let xmax=nodes[node_id].xmax;let ymax=nodes[node_id].ymax
    let mx=xmin+(xmax-xmin)//2;let my=ymin+(ymax-ymin)//2;let base=used;let depth=nodes[node_id].depth+1
    for q in range(4):
        let x0=if q%2==0:xmin else:mx;let x1=if q%2==0:mx else:xmax
        let y0=if q<2:my else:ymin;let y1=if q<2:ymax else:my
        pmr_init_node(mut nodes,base+q,node_id,q,depth,x0,y0,x1,y1)
    used+=4
    for q in range(4):nodes[node_id].child[q]=base+q
    nodes[node_id].id_count=0
    for i in range(previous_count):
        for q in range(4):
            let child=base+q
            if pmr_intersects_box(segments,previous[i],nodes[child]) and
                not pmr_insert(mut nodes,segments,mut used,child,previous[i],threshold):return False
    return True

fn pmr_store_le(output: UnsafePointer[UInt8, MutAnyOrigin], offset: Int, value: Int64):
    let bits=UInt64(value)
    for byte in range(8):output[offset+byte]=UInt8((bits>>UInt(8*byte))&255)

@export("pmr_edge_quadtree")
fn pmr_edge_quadtree(input: UnsafePointer[Int64, ImmutAnyOrigin], length: c_size_t,
    output: UnsafePointer[UInt8, MutAnyOrigin], capacity: c_size_t) abi("C") -> Int64:
    if input==UnsafePointer[Int64,ImmutAnyOrigin]() or length<2 or length>PMR_MAX_INPUT:return -1
    if input[0]<0 or input[0]>PMR_MAX_SEGMENTS or input[1]<1 or input[1]>PMR_MAX_SEGMENTS:return -1
    let count=Int(input[0]);let threshold=Int(input[1])
    if length!=c_size_t(2+4*count):return -1
    var child_init=InlineArray[Int,4](fill=-1)
    var id_init=InlineArray[Int,PMR_MAX_SEGMENTS](fill=0)
    let empty_node=PmrNode(parent=-1,quadrant=-1,depth=0,xmin=0,ymin=0,xmax=0,ymax=0,child=child_init,ids=id_init,id_count=0)
    var nodes=InlineArray[PmrNode,PMR_MAX_NODES](fill=empty_node)
    var segments=InlineArray[Int64,PMR_MAX_SEGMENTS*4](fill=0)
    for sid in range(count):
        for k in range(4):
            let value=input[2+sid*4+k]
            if value<0 or value>255:return -1
            segments[sid*4+k]=value
        if segments[sid*4]==segments[sid*4+2] and segments[sid*4+1]==segments[sid*4+3]:return -1
    pmr_init_node(mut nodes,0,-1,-1,0,-1,-1,511,511)
    var used=1
    for sid in range(count):
        if not pmr_insert(mut nodes,segments,mut used,0,sid,threshold):return -1

    var order=InlineArray[Int,PMR_MAX_NODES](fill=0)
    var stack=InlineArray[Int,PMR_MAX_NODES](fill=0)
    var node_count=0;var top=1;stack[0]=0
    while top>0:
        top-=1;let id=stack[top];order[node_count]=id;node_count+=1
        if nodes[id].child[0]>=0:
            for step in range(4):
                let child=nodes[id].child[3-step];stack[top]=child;top+=1
    var bytes=16
    for i in range(node_count):bytes+=32+8*nodes[order[i]].id_count
    if output==UnsafePointer[UInt8,MutAnyOrigin]() or capacity<c_size_t(bytes):return -2
    var remap=InlineArray[Int,PMR_MAX_NODES](fill=0)
    for i in range(node_count):remap[order[i]]=i
    pmr_store_le(output,0,Int64(node_count));pmr_store_le(output,8,Int64(count));var cursor=16
    for i in range(node_count):
        let node=nodes[order[i]]
        let parent=if node.parent<0:Int64(-1) else:Int64(remap[node.parent])
        pmr_store_le(output,cursor,parent);cursor+=8
        pmr_store_le(output,cursor,Int64(node.quadrant));cursor+=8
        pmr_store_le(output,cursor,Int64(node.depth));cursor+=8
        pmr_store_le(output,cursor,Int64(node.id_count));cursor+=8
        for j in range(node.id_count):pmr_store_le(output,cursor,Int64(node.ids[j]));cursor+=8
    return Int64(bytes)
