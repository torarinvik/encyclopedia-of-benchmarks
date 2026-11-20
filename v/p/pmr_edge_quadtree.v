module pmr_edge_quadtree

const max_segments = 8
const max_depth = 8
const max_nodes = 2048
const max_input = 35

struct Node {
	parent int
	quadrant int
	depth int
	xmin i64
	ymin i64
	xmax i64
	ymax i64
	children [4]int
	ids [max_segments]int
	id_count int
}
struct State {
	nodes [max_nodes]Node
	segments [max_segments][4]i64
	used int
}

fn orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
}
fn between(a i64, b i64, p i64) bool { return (a<=p&&p<=b)||(b<=p&&p<=a) }
fn on_segment(ax i64, ay i64, bx i64, by i64, px i64, py i64) bool { return between(ax,bx,px)&&between(ay,by,py) }
fn seg_intersects(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) bool {
	o1:=orient(ax,ay,bx,by,cx,cy);o2:=orient(ax,ay,bx,by,dx,dy);o3:=orient(cx,cy,dx,dy,ax,ay);o4:=orient(cx,cy,dx,dy,bx,by)
	if ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0)){return true}
	return (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||
		(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))
}
fn intersects_box(s &State, sid int, cell Node) bool {
	segment:=s.segments[sid];x0:=2*segment[0];y0:=2*segment[1];x1:=2*segment[2];y1:=2*segment[3]
	if (cell.xmin<=x0&&x0<=cell.xmax&&cell.ymin<=y0&&y0<=cell.ymax)||(cell.xmin<=x1&&x1<=cell.xmax&&cell.ymin<=y1&&y1<=cell.ymax){return true}
	return seg_intersects(x0,y0,x1,y1,cell.xmin,cell.ymin,cell.xmax,cell.ymin)||
		seg_intersects(x0,y0,x1,y1,cell.xmax,cell.ymin,cell.xmax,cell.ymax)||
		seg_intersects(x0,y0,x1,y1,cell.xmax,cell.ymax,cell.xmin,cell.ymax)||
		seg_intersects(x0,y0,x1,y1,cell.xmin,cell.ymax,cell.xmin,cell.ymin)
}
fn init_node(mut s &State, id int, parent int, q int, depth int, xmin i64, ymin i64, xmax i64, ymax i64) {
	s.nodes[id].parent=parent;s.nodes[id].quadrant=q;s.nodes[id].depth=depth
	s.nodes[id].xmin=xmin;s.nodes[id].ymin=ymin;s.nodes[id].xmax=xmax;s.nodes[id].ymax=ymax;s.nodes[id].id_count=0
	for k in 0..4{s.nodes[id].children[k]=-1}
}
fn insert(mut s &State, id int, sid int, threshold int) bool {
	if s.nodes[id].children[0]>=0 {
		for q in 0..4{child:=s.nodes[id].children[q];if intersects_box(s,sid,s.nodes[child])&&!insert(mut s,child,sid,threshold){return false}}
		return true
	}
	if s.nodes[id].id_count>=max_segments{return false}
	slot:=s.nodes[id].id_count;s.nodes[id].ids[slot]=sid;s.nodes[id].id_count++
	if s.nodes[id].id_count<=threshold{return true}
	if s.nodes[id].depth>=max_depth||s.used+4>max_nodes{return false}
	previous:=s.nodes[id].ids;previous_count:=s.nodes[id].id_count
	xmin:=s.nodes[id].xmin;ymin:=s.nodes[id].ymin;xmax:=s.nodes[id].xmax;ymax:=s.nodes[id].ymax
	mx:=xmin+(xmax-xmin)/2;my:=ymin+(ymax-ymin)/2;base:=s.used;depth:=s.nodes[id].depth+1
	for q in 0..4{x0:=xmin;x1:=mx;if q%2==1{x0=mx;x1=xmax};y0:=my;y1:=ymax;if q>=2{y0=ymin;y1=my};init_node(mut s,base+q,id,q,depth,x0,y0,x1,y1)}
	s.used+=4;s.nodes[id].id_count=0
	for q in 0..4{s.nodes[id].children[q]=base+q}
	for i in 0..previous_count{for q in 0..4{child:=base+q;if intersects_box(s,previous[i],s.nodes[child])&&!insert(mut s,child,previous[i],threshold){return false}}}
	return true
}
fn preorder(s &State,id int,mut order [max_nodes]int,mut count int) {
	order[count]=id;count++
	if s.nodes[id].children[0]>=0{for q in 0..4{preorder(s,s.nodes[id].children[q],mut order,mut count)}}
}
fn store_le(mut output &u8, offset int, value i64) {
	unsafe{mut bits:=u64(value);for byte in 0..8{output[offset+byte]=u8(bits>>(8*byte))}}
}

@[export: 'pmr_edge_quadtree']
pub fn pmr_edge_quadtree(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input==nil||length<2||length>max_input{return -1}
		if input[0]<0||input[0]>max_segments||input[1]<1||input[1]>max_segments{return -1}
		count:=int(input[0]);threshold:=int(input[1]);if length!=usize(2+4*count){return -1}
		mut state:=State{used:1}
		for sid in 0..count{for k in 0..4{value:=input[2+4*sid+k];if value<0||value>255{return -1};state.segments[sid][k]=value}
			if state.segments[sid][0]==state.segments[sid][2]&&state.segments[sid][1]==state.segments[sid][3]{return -1}}
		init_node(mut state,0,-1,-1,0,-1,-1,511,511)
		for sid in 0..count{if !insert(mut state,0,sid,threshold){return -1}}
		mut order:=[max_nodes]int{};mut remap:=[max_nodes]int{};mut node_count:=0;preorder(state,0,mut order,mut node_count)
		mut bytes:=16;for i in 0..node_count{bytes+=32+8*state.nodes[order[i]].id_count}
		if output==nil||capacity<usize(bytes){return -2}
		for i in 0..node_count{remap[order[i]]=i}
		store_le(mut output,0,i64(node_count));store_le(mut output,8,i64(count));mut cursor:=16
		for i in 0..node_count{node:=state.nodes[order[i]];parent:=i64(node.parent);if node.parent>=0{parent=i64(remap[node.parent])}
			store_le(mut output,cursor,parent);cursor+=8;store_le(mut output,cursor,i64(node.quadrant));cursor+=8;store_le(mut output,cursor,i64(node.depth));cursor+=8;store_le(mut output,cursor,i64(node.id_count));cursor+=8
			for j in 0..node.id_count{store_le(mut output,cursor,i64(node.ids[j]));cursor+=8}}
		return i64(bytes)
	}
}
