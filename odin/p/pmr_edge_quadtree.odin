package pmr_edge_quadtree

import "core:c"

MAX_SEGMENTS :: 8
MAX_DEPTH :: 8
MAX_NODES :: 2048
MAX_INPUT :: c.size_t(35)

Node :: struct {
	parent, quadrant, depth: int,
	xmin, ymin, xmax, ymax: i64,
	child: [4]int,
	ids: [MAX_SEGMENTS]int,
	id_count: int,
}
State :: struct {
	nodes: [MAX_NODES]Node,
	segments: [MAX_SEGMENTS][4]i64,
	used: int,
}

orient :: proc(ax, ay, bx, by, cx, cy: i64) -> i64 {
	return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
}
between :: proc(a, b, p: i64) -> bool { return (a <= p && p <= b) || (b <= p && p <= a) }
on_segment :: proc(ax, ay, bx, by, px, py: i64) -> bool { return between(ax,bx,px) && between(ay,by,py) }
seg_intersects :: proc(ax, ay, bx, by, cx, cy, dx, dy: i64) -> bool {
	o1:=orient(ax,ay,bx,by,cx,cy);o2:=orient(ax,ay,bx,by,dx,dy)
	o3:=orient(cx,cy,dx,dy,ax,ay);o4:=orient(cx,cy,dx,dy,bx,by)
	if ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0)) do return true
	return (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||
		(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))
}
intersects_box :: proc(s: ^State, sid: int, cell: Node) -> bool {
	segment:=s.segments[sid]
	x0:=2*segment[0];y0:=2*segment[1];x1:=2*segment[2];y1:=2*segment[3]
	if (cell.xmin<=x0&&x0<=cell.xmax&&cell.ymin<=y0&&y0<=cell.ymax)||(cell.xmin<=x1&&x1<=cell.xmax&&cell.ymin<=y1&&y1<=cell.ymax) do return true
	return seg_intersects(x0,y0,x1,y1,cell.xmin,cell.ymin,cell.xmax,cell.ymin)||
		seg_intersects(x0,y0,x1,y1,cell.xmax,cell.ymin,cell.xmax,cell.ymax)||
		seg_intersects(x0,y0,x1,y1,cell.xmax,cell.ymax,cell.xmin,cell.ymax)||
		seg_intersects(x0,y0,x1,y1,cell.xmin,cell.ymax,cell.xmin,cell.ymin)
}
init_node :: proc(s: ^State, id, parent, q, depth: int, xmin,ymin,xmax,ymax: i64) {
	node:=&s.nodes[id];node.parent=parent;node.quadrant=q;node.depth=depth
	node.xmin=xmin;node.ymin=ymin;node.xmax=xmax;node.ymax=ymax;node.id_count=0
	for k:=0;k<4;k+=1 { node.child[k]=-1 }
}
insert :: proc(s: ^State, id,sid,threshold: int) -> bool {
	if s.nodes[id].child[0]>=0 {
		for q:=0;q<4;q+=1 { child:=s.nodes[id].child[q];if intersects_box(s,sid,s.nodes[child])&&!insert(s,child,sid,threshold) do return false }
		return true
	}
	if s.nodes[id].id_count>=MAX_SEGMENTS do return false
	slot:=s.nodes[id].id_count;s.nodes[id].ids[slot]=sid;s.nodes[id].id_count+=1
	if s.nodes[id].id_count<=threshold do return true
	if s.nodes[id].depth>=MAX_DEPTH||s.used+4>MAX_NODES do return false
	previous:=s.nodes[id].ids;previous_count:=s.nodes[id].id_count
	xmin:=s.nodes[id].xmin;ymin:=s.nodes[id].ymin;xmax:=s.nodes[id].xmax;ymax:=s.nodes[id].ymax
	mx:=xmin+(xmax-xmin)/2;my:=ymin+(ymax-ymin)/2;base:=s.used;depth:=s.nodes[id].depth+1
	for q:=0;q<4;q+=1 {
		x0:=xmin;x1:=mx;if q%2==1{x0=mx;x1=xmax}
		y0:=my;y1:=ymax;if q>=2{y0=ymin;y1=my}
		init_node(s,base+q,id,q,depth,x0,y0,x1,y1)
	}
	s.used+=4;s.nodes[id].id_count=0
	for q:=0;q<4;q+=1{s.nodes[id].child[q]=base+q}
	for i:=0;i<previous_count;i+=1{for q:=0;q<4;q+=1{child:=base+q;if intersects_box(s,previous[i],s.nodes[child])&&!insert(s,child,previous[i],threshold) do return false}}
	return true
}
preorder :: proc(s: ^State,id: int,order: ^[MAX_NODES]int,count: ^int) {
	order[count^]=id;count^+=1
	if s.nodes[id].child[0]>=0 {for q:=0;q<4;q+=1{preorder(s,s.nodes[id].child[q],order,count)}}
}
store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits:=u64(value);for byte:=0;byte<8;byte+=1{output[offset+byte]=u8(bits>>(8*byte))}
}

@(export)
pmr_edge_quadtree :: proc "c" (input: [^]i64,length: c.size_t,output: [^]u8,capacity: c.size_t) -> i64 {
	if input==nil||length<2||length>MAX_INPUT do return -1
	if input[0]<0||input[0]>MAX_SEGMENTS||input[1]<1||input[1]>MAX_SEGMENTS do return -1
	count:=int(input[0]);threshold:=int(input[1]);if length!=c.size_t(2+4*count) do return -1
	state := State{used = 1}
	for sid:=0;sid<count;sid+=1{for k:=0;k<4;k+=1{value:=input[2+4*sid+k];if value<0||value>255 do return -1;state.segments[sid][k]=value}
		if state.segments[sid][0]==state.segments[sid][2]&&state.segments[sid][1]==state.segments[sid][3] do return -1}
	init_node(&state,0,-1,-1,0,-1,-1,511,511)
	for sid:=0;sid<count;sid+=1{if !insert(&state,0,sid,threshold) do return -1}
	order:[MAX_NODES]int;remap:[MAX_NODES]int;node_count:=0;preorder(&state,0,&order,&node_count)
	bytes:=16;for i:=0;i<node_count;i+=1{bytes+=32+8*state.nodes[order[i]].id_count}
	if output==nil||capacity<c.size_t(bytes) do return -2
	for i:=0;i<node_count;i+=1{remap[order[i]]=i}
	store_le(output,0,i64(node_count));store_le(output,8,i64(count));cursor:=16
	for i:=0;i<node_count;i+=1{node:=state.nodes[order[i]];parent:=i64(node.parent);if node.parent>=0{parent=i64(remap[node.parent])}
		store_le(output,cursor,parent);cursor+=8;store_le(output,cursor,i64(node.quadrant));cursor+=8;store_le(output,cursor,i64(node.depth));cursor+=8;store_le(output,cursor,i64(node.id_count));cursor+=8
		for j:=0;j<node.id_count;j+=1{store_le(output,cursor,i64(node.ids[j]));cursor+=8}}
	return i64(bytes)
}
