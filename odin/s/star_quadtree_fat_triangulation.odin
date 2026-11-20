package star_quadtree_fat_triangulation

import "core:c"

MAX_DEPTH :: 2
MAX_INPUT :: c.size_t(25)
MAX_PAIRS :: 64

State :: struct {
	vertices: [5][2]int,
	triangles: [4][3]int,
	edges: [8][2]int,
	pairs: [MAX_PAIRS][2]int,
	vertex_count, triangle_count, edge_count, pair_count: int,
	failed: bool,
}

orient :: proc(ax, ay, bx, by, cx, cy: int) -> int {
	return (bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
}
between :: proc(a, b, p: int) -> bool { return (a <= p && p <= b) || (b <= p && p <= a) }
on_segment :: proc(ax, ay, bx, by, px, py: int) -> bool { return between(ax,bx,px) && between(ay,by,py) }
segments_intersect :: proc(ax, ay, bx, by, cx, cy, dx, dy: int) -> bool {
	o1:=orient(ax,ay,bx,by,cx,cy);o2:=orient(ax,ay,bx,by,dx,dy)
	o3:=orient(cx,cy,dx,dy,ax,ay);o4:=orient(cx,cy,dx,dy,bx,by)
	if ((o1<0&&o2>0)||(o1>0&&o2<0))&&((o3<0&&o4>0)||(o3>0&&o4<0)) do return true
	return (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||
		(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by))
}

edge_hits_box :: proc(s: ^State, e, xmin, ymin, xmax, ymax: int) -> bool {
	a:=s.edges[e][0];b:=s.edges[e][1]
	ax:=s.vertices[a][0];ay:=s.vertices[a][1];bx:=s.vertices[b][0];by:=s.vertices[b][1]
	if (xmin<=ax&&ax<=xmax&&ymin<=ay&&ay<=ymax)||(xmin<=bx&&bx<=xmax&&ymin<=by&&by<=ymax) do return true
	return segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin)||segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax)||
		segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax)||segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin)
}

stopping :: proc(s: ^State, xmin, ymin, xmax, ymax: int) -> bool {
	touched: [8]bool
	count:=0
	for e:=0;e<s.edge_count;e+=1{touched[e]=edge_hits_box(s,e,xmin,ymin,xmax,ymax);if touched[e]{count+=1}}
	if count==0 do return true
	for v:=0;v<s.vertex_count;v+=1{
		common:=true
		for e:=0;e<s.edge_count;e+=1{if touched[e]&&s.edges[e][0]!=v&&s.edges[e][1]!=v{common=false}}
		if common do return true
	}
	return false
}

point_in_triangle :: proc(s: ^State, px, py, a, b, c: int) -> bool {
	return orient(s.vertices[a][0],s.vertices[a][1],s.vertices[b][0],s.vertices[b][1],px,py)>=0&&
		orient(s.vertices[b][0],s.vertices[b][1],s.vertices[c][0],s.vertices[c][1],px,py)>=0&&
		orient(s.vertices[c][0],s.vertices[c][1],s.vertices[a][0],s.vertices[a][1],px,py)>=0
}

triangle_hits_box :: proc(s: ^State, tid, xmin, ymin, xmax, ymax: int) -> bool {
	t:=s.triangles[tid]
	for k:=0;k<3;k+=1{v:=t[k];x:=s.vertices[v][0];y:=s.vertices[v][1];if xmin<=x&&x<=xmax&&ymin<=y&&y<=ymax do return true}
	if point_in_triangle(s,xmin,ymin,t[0],t[1],t[2])||point_in_triangle(s,xmax,ymin,t[0],t[1],t[2])||
		point_in_triangle(s,xmax,ymax,t[0],t[1],t[2])||point_in_triangle(s,xmin,ymax,t[0],t[1],t[2]) do return true
	for k:=0;k<3;k+=1{
		a:=t[k];b:=t[(k+1)%3];ax:=s.vertices[a][0];ay:=s.vertices[a][1];bx:=s.vertices[b][0];by:=s.vertices[b][1]
		if segments_intersect(ax,ay,bx,by,xmin,ymin,xmax,ymin)||segments_intersect(ax,ay,bx,by,xmax,ymin,xmax,ymax)||
			segments_intersect(ax,ay,bx,by,xmax,ymax,xmin,ymax)||segments_intersect(ax,ay,bx,by,xmin,ymax,xmin,ymin) do return true
	}
	return false
}

add_edge :: proc(s: ^State, a0, b0: int) -> bool {
	a:=min(a0,b0);b:=max(a0,b0)
	for i:=0;i<s.edge_count;i+=1{if s.edges[i][0]==a&&s.edges[i][1]==b do return true}
	if s.edge_count>=8 do return false
	s.edges[s.edge_count]=.{a,b};s.edge_count+=1
	return true
}

append_pair :: proc(s: ^State, key, tid: int) {
	if s.pair_count>=MAX_PAIRS{s.failed=true;return}
	s.pairs[s.pair_count]=.{key,tid};s.pair_count+=1
}

visit :: proc(s: ^State, depth, ix, iy, path: int) {
	if s.failed do return
	size:=8>>depth;xmin:=ix*size;xmax:=xmin+size;ymax:=8-iy*size;ymin:=ymax-size
	if !stopping(s,xmin,ymin,xmax,ymax){
		if depth>=MAX_DEPTH{s.failed=true;return}
		for q:=0;q<4;q+=1{visit(s,depth+1,2*ix+(q&1),2*iy+(q>>1),4*path+q)}
		return
	}
	key:=path<<(2*(MAX_DEPTH-depth))
	for tid:=0;tid<s.triangle_count;tid+=1{if triangle_hits_box(s,tid,xmin,ymin,xmax,ymax){append_pair(s,key,tid)}}
}

parse :: proc(s: ^State, input: [^]i64, length: c.size_t) -> bool {
	if input==nil||length<2||length>MAX_INPUT do return false
	if !((input[0]==4&&input[1]==2)||(input[0]==5&&input[1]==4)) do return false
	s.vertex_count=int(input[0]);s.triangle_count=int(input[1])
	if length!=c.size_t(2+2*s.vertex_count+3*s.triangle_count) do return false
	corners: [8]i64={0,0,8,0,8,8,0,8}
	for i:=0;i<4;i+=1{
		if input[2+2*i]!=corners[2*i]||input[3+2*i]!=corners[2*i+1] do return false
		s.vertices[i]=.{int(corners[2*i]),int(corners[2*i+1])}
	}
	if s.vertex_count==5{if input[10]!=4||input[11]!=4 do return false;s.vertices[4]=.{4,4}}
	start:=2+2*s.vertex_count
	for i:=0;i<s.triangle_count;i+=1{for j:=0;j<3;j+=1{id:=input[start+3*i+j];if id<0||id>=i64(s.vertex_count) do return false;s.triangles[i][j]=int(id)}}
	if s.vertex_count==4{
		d02:=s.triangles[0]==.{0,1,2}&&s.triangles[1]==.{0,2,3}
		d13:=s.triangles[0]==.{0,1,3}&&s.triangles[1]==.{1,2,3}
		if !d02&&!d13 do return false
	}else{
		fan: [12]i64={0,1,4,1,2,4,2,3,4,3,0,4}
		for i:=0;i<12;i+=1{if input[start+i]!=fan[i] do return false}
	}
	for i:=0;i<s.triangle_count;i+=1{t:=s.triangles[i];if !add_edge(s,t[0],t[1])||!add_edge(s,t[1],t[2])||!add_edge(s,t[2],t[0]) do return false}
	return true
}

store_le :: proc(output: [^]u8, offset: int, value: i64) {
	bits:=u64(value)
	for b:=0;b<8;b+=1{output[offset+b]=u8(bits>>(8*b))}
}

@(export)
star_quadtree_fat_triangulation :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input==nil||length<2||length>MAX_INPUT do return -1
	s:=State{}
	if !parse(&s,input,length) do return -1
	visit(&s,0,0,0,0)
	if s.failed do return -1
	bytes:=c.size_t(8*(1+2*s.pair_count))
	if output==nil||capacity<bytes do return -2
	store_le(output,0,i64(s.pair_count));cursor:=8
	for i:=0;i<s.pair_count;i+=1{store_le(output,cursor,i64(s.pairs[i][0]));cursor+=8;store_le(output,cursor,i64(s.pairs[i][1]));cursor+=8}
	return i64(bytes)
}
