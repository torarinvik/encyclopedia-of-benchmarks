package k_quadtree_edge_distribution

import "core:c"

MAX_EDGES :: 8
MAX_CELLS :: 46
DEPTH :: 4
MAX_WORDS :: 127

Cell :: struct { depth, prefix, lo, alt_lo, x0, y0, x1, y1, endpoints: i32 }
Edge :: struct { x0, y0, x1, y1, start, end: i32, negative: bool }
Point :: struct { x, y: i32 }
Exit :: struct { edge, side: i32, num, den: i64 }

orient :: proc(a, b, c0: Point) -> i64 {
	return i64(b.x-a.x)*i64(c0.y-a.y)-i64(b.y-a.y)*i64(c0.x-a.x)
}
on_segment :: proc(a,b,p: Point) -> bool {
	return p.x>=min(a.x,b.x)&&p.x<=max(a.x,b.x)&&p.y>=min(a.y,b.y)&&p.y<=max(a.y,b.y)
}
intersects :: proc(a,b,c0,d: Point) -> bool {
	o1,o2,o3,o4:=orient(a,b,c0),orient(a,b,d),orient(c0,d,a),orient(c0,d,b)
	if (o1==0&&on_segment(a,b,c0))||(o2==0&&on_segment(a,b,d))||(o3==0&&on_segment(c0,d,a))||(o4==0&&on_segment(c0,d,b)){return true}
	return o1*o2<0&&o3*o4<0
}
positive_key :: proc(x,y:i32)->i32{key:i32=0;for bit:=7;bit>=4;bit-=1{key=(key<<2)|(((x>>bit)&1)<<1)|((y>>bit)&1)};return key}
remap :: proc(q:i32)->i32{map:=[4]i32{2,0,3,1};return map[q]}
alt_prefix :: proc(depth,prefix:i32)->i32{out:i32=0;for shift:=2*(depth-1);shift>=0;shift-=2{out=(out<<2)|remap((prefix>>shift)&3)};return out}
make_box :: proc(c: ^Cell){x,y:i32=0;for shift:=2*(c.depth-1);shift>=0;shift-=2{q:=(c.prefix>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1)};side:=i32(256)>>c.depth;c.x0=x*side;c.y0=y*side;c.x1=c.x0+side;c.y1=c.y0+side}
find_cell :: proc(cells: ^[MAX_CELLS]Cell,c:i32,key:i32)->i32{for i in 0..<c{span:=i32(1)<<(2*(DEPTH-cells[i].depth));if key>=cells[i].lo&&key<cells[i].lo+span{return i}};return -1}
sweep_box :: proc(cell:Cell,rotated:bool)->(i32,i32,i32,i32){if rotated{return 256-cell.y1,cell.x0,256-cell.y0,cell.x1};return cell.x0,cell.y0,cell.x1,cell.y1}
sweep_edge :: proc(e:Edge,rotated:bool)->(Point,Point){if rotated{return Point{256-e.y0,e.x0},Point{256-e.y1,e.x1}};return Point{e.x0,e.y0},Point{e.x1,e.y1}}
segment_box :: proc(e:Edge,cell:Cell,rotated:bool)->bool{x0,y0,x1,y1:=sweep_box(cell,rotated);a,b:=sweep_edge(e,rotated);if (a.x>=x0&&a.x<=x1&&a.y>=y0&&a.y<=y1)||(b.x>=x0&&b.x<=x1&&b.y>=y0&&b.y<=y1){return true};corners:=[4]Point{{x0,y0},{x1,y0},{x1,y1},{x0,y1}};for i in 0..<4{if intersects(a,b,corners[i],corners[(i+1)&3]){return true}};return false}
append_point :: proc(path: ^[33]Point,n: ^i32,p:Point)->bool{if n^>0&&path[n^-1].x==p.x&&path[n^-1].y==p.y{return true};if n^>=33{return false};path[n^]=p;n^+=1;return true}
build_frontier :: proc(cells: ^[MAX_CELLS]Cell,c:i32,order: ^[MAX_CELLS]i32,cut:i32,rotated:bool,path: ^[33]Point,path_n: ^i32,corner: ^i32)->bool{
	atom_cell:=[256]i32{};for i in 0..<256{atom_cell[i]=-1};rank:=[MAX_CELLS]i32{};for i in 0..<c{rank[order[i]]=i}
	for pos in 0..<c{id:=order[pos];start:=cells[id].lo;if rotated{start=cells[id].alt_lo};span:=i32(1)<<(2*(DEPTH-cells[id].depth));for k in start..<start+span{atom_cell[k]=id}}
	processed:=[16][16]bool{};for key in 0..<256{id:=atom_cell[key];if id<0{return false};x,y:i32=0;for shift:=6;shift>=0;shift-=2{q:=(key>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1)};processed[x][y]=rank[id]<cut}
	h:=[16]i32{};for x in 0..<16{v:i32=0;for v<16&&processed[x][v]{v+=1};for y in 0..<16{if processed[x][y]!=(y<v){return false}};h[x]=v;if x>0&&h[x-1]<v{return false}}
	path_n^=0;if !append_point(path,path_n,Point{0,256}){return false};for y:=15;y>=h[0];y-=1{if !append_point(path,path_n,Point{0,y*16}){return false}};for x in 0..<16{if !append_point(path,path_n,Point{(x+1)*16,h[x]*16}){return false};next:i32=0;if x<15{next=h[x+1]};for y:=h[x]-1;y>=next;y-=1{if !append_point(path,path_n,Point{(x+1)*16,y*16}){return false}}}
	if path[0].x!=0||path[0].y!=256||path[path_n^-1].x!=256||path[path_n^-1].y!=0{return false};x0,y0,_,_:=sweep_box(cells[order[cut]],rotated);for i in 0..<path_n^{if path[i].x==x0&&path[i].y==y0{corner^=i;return true}};return false
}
frontier_segment :: proc(a,b:Point,path: ^[33]Point,n:i32)->i32{found:i32=-1;for i in 0..<n-1{if intersects(a,b,path[i],path[i+1]){if found>=0{return -2};found=i}};return found}
exit_for_cell :: proc(a,b:Point,x0,y0,x1,y1:i32,id:i32,out:^Exit)->bool{dx,dy:=i64(b.x-a.x),i64(b.y-a.y);found:=0;if dy>0{yd:=i64(y1-a.y);num:=i64(a.x)*dy+yd*dx;if yd>0&&yd<dy&&i64(x0)*dy<num&&num<i64(x1)*dy{out^=Exit{id,0,num,dy};found+=1}};if dx>0{xd:=i64(x1-a.x);num:=i64(a.y)*dx+xd*dy;if xd>0&&xd<dx&&i64(y0)*dx<num&&num<i64(y1)*dx{out^=Exit{id,1,num,dx};found+=1}};return found==1}
exit_less :: proc(a,b:Exit)->bool{l,r:=a.num*b.den,b.num*a.den;return l<r||(l==r&&a.edge<b.edge)}
run_sweep :: proc(cells: ^[MAX_CELLS]Cell,c:i32,edges: ^[MAX_EDGES]Edge,n:i32,endpoints: ^[MAX_EDGES][2]i32,rotated:bool,masks: ^[MAX_CELLS]u64)->bool{
	order:=[MAX_CELLS]i32{};for i in 0..<c{order[i]=i};if rotated{for i:=1;i<c;i+=1{v:=order[i];j:=i;for j>0&&(cells[order[j-1]].alt_lo>cells[v].alt_lo||(cells[order[j-1]].alt_lo==cells[v].alt_lo&&order[j-1]>v)){order[j]=order[j-1];j-=1};order[j]=v}}
	ea,eb:=[MAX_EDGES]Point{},[MAX_EDGES]Point{};ids,keys:=[MAX_EDGES]i32{},[MAX_EDGES]i32{};m:=i32(0);for id in 0..<n{if edges[id].negative==rotated{ea[id],eb[id]=sweep_edge(edges[id],rotated);key:=positive_key(ea[id].x,ea[id].y);j:=m;m+=1;for j>0&&(keys[j-1]>key||(keys[j-1]==key&&ids[j-1]>id)){keys[j]=keys[j-1];ids[j]=ids[j-1];j-=1};keys[j]=key;ids[j]=id}}
	sl,sb:=[MAX_EDGES]i32{},[MAX_EDGES]i32{};sln,sbn:=i32(0),i32(0);for pos in 0..<c{cid:=order[pos];x0,y0,x1,y1:=sweep_box(cells[cid],rotated);cand:=[16]i32{};cn:=i32(0);for sln>0&&segment_box(edges[sl[sln-1]],cells[cid],rotated){sln-=1;cand[cn]=sl[sln];cn+=1};for sbn>0&&segment_box(edges[sb[sbn-1]],cells[cid],rotated){sbn-=1;cand[cn]=sb[sbn];cn+=1};for q in 0..<m{id:=ids[q];if endpoints[id][0]==cid{cand[cn]=id;cn+=1}}
		exits:=[16]Exit{};en:=i32(0);for q in 0..<cn{id:=cand[q];masks[cid]|=u64(1)<<u64(id);if endpoints[id][1]==cid{continue};if !exit_for_cell(ea[id],eb[id],x0,y0,x1,y1,id,&exits[en]){return false};en+=1};for i:=1;i<en;i+=1{v:=exits[i];j:=i;for j>0&&(exits[j-1].side>v.side||(exits[j-1].side==v.side&&exit_less(v,exits[j-1]))){exits[j]=exits[j-1];j-=1};exits[j]=v};for i in 0..<en{if exits[i].side==0{if sln>=MAX_EDGES{return false};sl[sln]=exits[i].edge;sln+=1}else{if sbn>=MAX_EDGES{return false};sb[sbn]=exits[i].edge;sbn+=1}}
		if pos+1==c{continue};path:=[33]Point{};pn,corner:=i32(0),i32(0);if !build_frontier(cells,c,&order,pos+1,rotated,&path,&pn,&corner){return false};_,ny,_,_:=sweep_box(cells[order[pos+1]],rotated);if ny>y0{for sln>0{id:=sl[sln-1];where:=frontier_segment(ea[id],eb[id],&path,pn);if where<0{return false};if where<corner{break};if sbn>=MAX_EDGES{return false};sbn+=1;sb[sbn-1]=sl[sln-1];sln-=1}}else{for sbn>0{id:=sb[sbn-1];where:=frontier_segment(ea[id],eb[id],&path,pn);if where<0{return false};if where>=corner{break};if sln>=MAX_EDGES{return false};sln+=1;sl[sln-1]=sb[sbn-1];sbn-=1}}
	};return sln==0&&sbn==0
}
put_i64 :: proc(output:[^]u8,at:usize,value:i64){bits:=u64(value);for b:=0;b<8;b+=1{output[at+usize(b)]=u8((bits>>u64(8*b))&255)}}

@(export)
k_quadtree_edge_distribution :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
	if input==nil||length<2||length>MAX_WORDS{return -1};nv,cv:=input[0],input[1];if nv<0||nv>8||cv<1||cv>46{return -1};n,c:=i32(nv),i32(cv);if length!=c.size_t(2+2*c+4*n){return -1}
	cells:=[MAX_CELLS]Cell{};edges:=[MAX_EDGES]Edge{};endpoints:=[MAX_EDGES][2]i32{};at:=c.size_t(2);previous:=i32(0)
	for i in 0..<c{d,p:=input[at],input[at+1];at+=2;if d<0||d>DEPTH||p<0||p>=(i64(1)<<(2*d)){return -1};cells[i].depth=i32(d);cells[i].prefix=i32(p);span:=i32(1)<<(2*(DEPTH-cells[i].depth));cells[i].lo=cells[i].prefix*span;if cells[i].lo!=previous{return -1};previous=cells[i].lo+span;make_box(&cells[i])}
	if previous!=256||(n==0&&(c!=1||cells[0].depth!=0||cells[0].prefix!=0)){return -1};for i in 0..<c{cells[i].alt_lo=alt_prefix(cells[i].depth,cells[i].prefix)<<(2*(DEPTH-cells[i].depth))}
	pts:=[2*MAX_EDGES]Point{};for i in 0..<n{x0,y0,x1,y1:=input[at],input[at+1],input[at+2],input[at+3];at+=4;if x0<0||x0>255||y0<0||y0>255||x1<0||x1>255||y1<0||y1>255||x0%16==0||y0%16==0||x1%16==0||y1%16==0{return -1};if x0==x1&&y0==y1||y0==y1{return -1};if x0>x1||(x0==x1&&y0>y1){x0,x1=x1,x0;y0,y1=y1,y0};if x0==x1&&y1<=y0{return -1};edges[i]=Edge{i32(x0),i32(y0),i32(x1),i32(y1),-1,-1,y1<y0};pts[2*i]=Point{i32(x0),i32(y0)};pts[2*i+1]=Point{i32(x1),i32(y1)}
		for gx:=i64(0);gx<=256;gx+=16{for gy:=i64(0);gy<=256;gy+=16{p:=Point{i32(gx),i32(gy)};if orient(pts[2*i],pts[2*i+1],p)==0&&on_segment(pts[2*i],pts[2*i+1],p){return -1}}};for j in 0..<2*i{if pts[j].x==i32(x0)&&pts[j].y==i32(y0){return -1}};for j in 0..<2*i+1{if pts[j].x==i32(x1)&&pts[j].y==i32(y1){return -1}};for j in 0..<i{if intersects(pts[2*i],pts[2*i+1],pts[2*j],pts[2*j+1]){return -1}}
		a,b:=find_cell(&cells,c,positive_key(i32(x0),i32(y0))),find_cell(&cells,c,positive_key(i32(x1),i32(y1)));if a<0||b<0{return -1};endpoints[i][0]=a;endpoints[i][1]=b;edges[i].start=a;edges[i].end=b;cells[a].endpoints+=1;cells[b].endpoints+=1
	};for i in 0..<c{if cells[i].endpoints>1{return -1}}
	pd,pp:=[85]i32{},[85]i32{};pc:=i32(0);for i in 0..<c{for d in 0..<cells[i].depth{p:=cells[i].prefix>>(2*(cells[i].depth-d));found:=false;for q in 0..<pc{if pd[q]==d&&pp[q]==p{found=true}};if !found{pd[pc]=d;pp[pc]=p;pc+=1}}};for q in 0..<pc{occupied:=u32(0);for i in 0..<c{if cells[i].endpoints==0||cells[i].depth<=pd[q]{continue};if cells[i].prefix>>(2*(cells[i].depth-pd[q]))==pp[q]{occupied|=u32(1)<<u32((cells[i].prefix>>(2*(cells[i].depth-pd[q]-1)))&3)}};if occupied==0||(occupied&(occupied-1))==0{return -1}}
	for i in 0..<n{for dir:=0;dir<2;dir+=1{if edges[i].negative!=(dir!=0){continue};order:=[MAX_CELLS]i32{};for j in 0..<c{order[j]=j};if dir!=0{for a:=1;a<c;a+=1{v:=order[a];j:=a;for j>0&&cells[order[j-1]].alt_lo>cells[v].alt_lo{order[j]=order[j-1];j-=1};order[j]=v}};rs,re:=i32(0),i32(0);for j in 0..<c{if order[j]==endpoints[i][0]{rs=j};if order[j]==endpoints[i][1]{re=j}};if rs>re{return -1}}}
	masks:=[MAX_CELLS]u64{};if !run_sweep(&cells,c,&edges,n,&endpoints,false,&masks)||!run_sweep(&cells,c,&edges,n,&endpoints,true,&masks){return -1};bytes:=8*(1+c);if output==nil||capacity<c.size_t(bytes){return -2};put_i64(output,0,i64(c));for i in 0..<c{put_i64(output,c.size_t(8*(1+i)),i64(masks[i]))};return i64(bytes)
}
