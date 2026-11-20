module star_quadtree_fat_triangulation

const max_depth = 2
const max_input = 25
const max_pairs = 64

struct StarState {
	vertices [5][2]int
	triangles [4][3]int
	edges [8][2]int
	pairs [max_pairs][2]int
	vertex_count int
	triangle_count int
	edge_count int
	pair_count int
	failed bool
}

fn orient(ax int, ay int, bx int, by int, cx int, cy int) int {
	return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
}
fn between(a int, b int, p int) bool { return (a<=p&&p<=b)||(b<=p&&p<=a) }
fn on_segment(ax int, ay int, bx int, by int, px int, py int) bool { return between(ax,bx,px)&&between(ay,by,py) }
fn segments_intersect(ax int, ay int, bx int, by int, cx int, cy int, dx int, dy int) bool {
	o1:=orient(ax,ay,bx,by,cx,cy);o2:=orient(ax,ay,bx,by,dx,dy)
	o3:=orient(cx,cy,dx,dy,ax,ay);o4:=orient(cx,cy,dx,dy,bx,by)
	if ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0)){return true}
	return (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||
		(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))
}

fn edge_hits_box(s &StarState, edge_id int, xmin int, ymin int, xmax int, ymax int) bool {
	a:=s.edges[edge_id][0];b:=s.edges[edge_id][1]
	ax:=s.vertices[a][0];ay:=s.vertices[a][1];bx:=s.vertices[b][0];by:=s.vertices[b][1]
	if (xmin<=ax&&ax<=xmax&&ymin<=ay&&ay<=ymax)||(xmin<=bx&&bx<=xmax&&ymin<=by&&by<=ymax){return true}
	return segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin)||segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax)||
		segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax)||segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin)
}
fn stopping(s &StarState, xmin int, ymin int, xmax int, ymax int) bool {
	mut touched:=[8]bool{};mut count:=0
	for e in 0..s.edge_count{touched[e]=edge_hits_box(s,e,xmin,ymin,xmax,ymax);if touched[e]{count++}}
	if count==0{return true}
	for v in 0..s.vertex_count{mut common:=true;for e in 0..s.edge_count{if touched[e]&&s.edges[e][0]!=v&&s.edges[e][1]!=v{common=false}};if common{return true}}
	return false
}
fn point_in_triangle(s &StarState, px int, py int, a int, b int, c int) bool {
	return orient(s.vertices[a][0],s.vertices[a][1],s.vertices[b][0],s.vertices[b][1],px,py)>=0&&
		orient(s.vertices[b][0],s.vertices[b][1],s.vertices[c][0],s.vertices[c][1],px,py)>=0&&
		orient(s.vertices[c][0],s.vertices[c][1],s.vertices[a][0],s.vertices[a][1],px,py)>=0
}
fn triangle_hits_box(s &StarState, tid int, xmin int, ymin int, xmax int, ymax int) bool {
	t:=s.triangles[tid]
	for k in 0..3{v:=t[k];x:=s.vertices[v][0];y:=s.vertices[v][1];if xmin<=x&&x<=xmax&&ymin<=y&&y<=ymax{return true}}
	if point_in_triangle(s,xmin,ymin,t[0],t[1],t[2])||point_in_triangle(s,xmax,ymin,t[0],t[1],t[2])||
		point_in_triangle(s,xmax,ymax,t[0],t[1],t[2])||point_in_triangle(s,xmin,ymax,t[0],t[1],t[2]){return true}
	for k in 0..3{a:=t[k];b:=t[(k+1)%3];ax:=s.vertices[a][0];ay:=s.vertices[a][1];bx:=s.vertices[b][0];by:=s.vertices[b][1]
		if segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin)||segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax)||
			segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax)||segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin){return true}}
	return false
}
fn add_edge(mut s StarState, a0 int, b0 int) bool {
	a:=min(a0,b0);b:=max(a0,b0)
	for i in 0..s.edge_count{if s.edges[i][0]==a&&s.edges[i][1]==b{return true}}
	if s.edge_count>=8{return false};s.edges[s.edge_count]=[2]int{a,b};s.edge_count++;return true
}
fn append_pair(mut s StarState, key int, tid int) {
	if s.pair_count>=max_pairs{s.failed=true;return};s.pairs[s.pair_count]=[2]int{key,tid};s.pair_count++
}
fn visit(mut s StarState, depth int, ix int, iy int, path int) {
	if s.failed{return};size:=8>>depth;xmin:=ix*size;xmax:=xmin+size;ymax:=8-iy*size;ymin:=ymax-size
	if !stopping(s,xmin,ymin,xmax,ymax){if depth>=max_depth{s.failed=true;return};for q in 0..4{visit(mut s,depth+1,2*ix+(q&1),2*iy+(q>>1),4*path+q)};return}
	key:=path<<(2*(max_depth-depth));for tid in 0..s.triangle_count{if triangle_hits_box(s,tid,xmin,ymin,xmax,ymax){append_pair(mut s,key,tid)}}
}

fn parse(mut s StarState, input &i64, length usize) bool {
	unsafe{
		if input==nil||length<2||length>max_input{return false}
		if !((input[0]==4&&input[1]==2)||(input[0]==5&&input[1]==4)){return false}
		s.vertex_count=int(input[0]);s.triangle_count=int(input[1])
		if length!=usize(2+2*s.vertex_count+3*s.triangle_count){return false}
		corners:=[8]i64{0,0,8,0,8,8,0,8}
		for i in 0..4{if input[2+2*i]!=corners[2*i]||input[3+2*i]!=corners[2*i+1]{return false};s.vertices[i]=[2]int{int(corners[2*i]),int(corners[2*i+1])}}
		if s.vertex_count==5{if input[10]!=4||input[11]!=4{return false};s.vertices[4]=[2]int{4,4}}
		start:=2+2*s.vertex_count
		for i in 0..s.triangle_count{for j in 0..3{id:=input[start+3*i+j];if id<0||id>=i64(s.vertex_count){return false};s.triangles[i][j]=int(id)}}
		if s.vertex_count==4{
			d02:=s.triangles[0][0]==0&&s.triangles[0][1]==1&&s.triangles[0][2]==2&&s.triangles[1][0]==0&&s.triangles[1][1]==2&&s.triangles[1][2]==3
			d13:=s.triangles[0][0]==0&&s.triangles[0][1]==1&&s.triangles[0][2]==3&&s.triangles[1][0]==1&&s.triangles[1][1]==2&&s.triangles[1][2]==3
			if !d02&&!d13{return false}
		}else{fan:=[12]i64{0,1,4,1,2,4,2,3,4,3,0,4};for i in 0..12{if input[start+i]!=fan[i]{return false}}}
		for i in 0..s.triangle_count{t:=s.triangles[i];if !add_edge(mut s,t[0],t[1])||!add_edge(mut s,t[1],t[2])||!add_edge(mut s,t[2],t[0]){return false}}
		return true
	}
}
fn store_le(mut output &u8, offset int, value i64) {
	unsafe{bits:=u64(value);for b in 0..8{output[offset+b]=u8(bits>>(8*b))}}
}

@[export: 'star_quadtree_fat_triangulation']
pub fn star_quadtree_fat_triangulation(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe{
		if input==nil||length<2||length>max_input{return -1}
		mut s:=StarState{}
		if !parse(mut s,input,length){return -1}
		visit(mut s,0,0,0,0);if s.failed{return -1}
		bytes:=8*(1+2*s.pair_count)
		if output==nil||capacity<usize(bytes){return -2}
		store_le(mut output,0,i64(s.pair_count));mut cursor:=8
		for i in 0..s.pair_count{store_le(mut output,cursor,i64(s.pairs[i][0]));cursor+=8;store_le(mut output,cursor,i64(s.pairs[i][1]));cursor+=8}
		return i64(bytes)
	}
}
