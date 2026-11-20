const max_edges = 8
const max_cells = 46
const max_depth = 4
const max_words = 127

struct Cell {
	mut:
	depth int
	prefix int
	lo int
	alt_lo int
	x0 int
	y0 int
	x1 int
	y1 int
	endpoints int
}
struct Edge { x0 int; y0 int; x1 int; y1 int; start_cell int; end_cell int; negative bool }
struct Point { x int; y int }
struct Exit { edge int; side int; num i64; den i64 }

fn orient(a Point,b Point,c Point) i64 { return i64(b.x-a.x)*i64(c.y-a.y)-i64(b.y-a.y)*i64(c.x-a.x) }
fn on_segment(a Point,b Point,p Point) bool { return p.x>=min(a.x,b.x)&&p.x<=max(a.x,b.x)&&p.y>=min(a.y,b.y)&&p.y<=max(a.y,b.y) }
fn intersects(a Point,b Point,c Point,d Point) bool {
	o1,o2,o3,o4:=orient(a,b,c),orient(a,b,d),orient(c,d,a),orient(c,d,b)
	if (o1==0&&on_segment(a,b,c))||(o2==0&&on_segment(a,b,d))||(o3==0&&on_segment(c,d,a))||(o4==0&&on_segment(c,d,b)){return true}
	return o1*o2<0&&o3*o4<0
}
fn positive_key(x int,y int) int { mut key:=0;for bit:=7;bit>=4;bit--{key=(key<<2)|(((x>>bit)&1)<<1)|((y>>bit)&1)};return key }
fn remap(q int) int { map:=[4]int{init:0}; map[0]=2;map[1]=0;map[2]=3;map[3]=1;return map[q] }
fn alt_prefix(depth int,prefix int) int { mut out:=0;if depth>0{mut shift:=2*(depth-1);for shift>=0{out=(out<<2)|remap((prefix>>shift)&3);shift-=2}};return out }
fn make_box(mut c Cell) { mut x:=0;mut y:=0;if c.depth>0{mut shift:=2*(c.depth-1);for shift>=0{q:=(c.prefix>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1);shift-=2}};side:=256>>c.depth;c.x0=x*side;c.y0=y*side;c.x1=c.x0+side;c.y1=c.y0+side }
fn find_cell(cells []Cell,c int,key int) int { for i in 0..c{span:=1<<(2*(max_depth-cells[i].depth));if key>=cells[i].lo&&key<cells[i].lo+span{return i}};return -1 }
fn sweep_box(cell Cell,rotated bool) [4]int { if rotated{return [4]int{256-cell.y1,cell.x0,256-cell.y0,cell.x1}};return [4]int{cell.x0,cell.y0,cell.x1,cell.y1} }
fn sweep_edge(e Edge,rotated bool) [2]Point { if rotated{return [2]Point{Point{256-e.y0,e.x0},Point{256-e.y1,e.x1}}};return [2]Point{Point{e.x0,e.y0},Point{e.x1,e.y1}} }
fn segment_box(e Edge,cell Cell,rotated bool) bool { box:=sweep_box(cell,rotated);ab:=sweep_edge(e,rotated);a,b:=ab[0],ab[1];if (a.x>=box[0]&&a.x<=box[2]&&a.y>=box[1]&&a.y<=box[3])||(b.x>=box[0]&&b.x<=box[2]&&b.y>=box[1]&&b.y<=box[3]){return true};corners:=[4]Point{Point{box[0],box[1]},Point{box[2],box[1]},Point{box[2],box[3]},Point{box[0],box[3]}};for i in 0..4{if intersects(a,b,corners[i],corners[(i+1)&3]){return true}};return false }
fn append_point(mut path [33]Point,mut n int,p Point) bool { if n>0&&path[n-1].x==p.x&&path[n-1].y==p.y{return true};if n>=33{return false};path[n]=p;n++;return true }
fn build_frontier(cells []Cell,c int,order [46]int,cut int,rotated bool,mut path [33]Point,mut path_n int,mut corner int) bool {
	mut rank:=[46]int{};for i in 0..c{rank[order[i]]=i};mut atom:=[256]int{};for i in 0..256{atom[i]= -1}
	for pos in 0..c{id:=order[pos];start:=if rotated{cells[id].alt_lo}else{cells[id].lo};span:=1<<(2*(max_depth-cells[id].depth));for k in start..start+span{atom[k]=id}}
	mut processed:=[16][16]bool{};for key in 0..256{id:=atom[key];if id<0{return false};mut x:=0;mut y:=0;for shift in [6,4,2,0]{q:=(key>>shift)&3;x=(x<<1)|(q>>1);y=(y<<1)|(q&1)};processed[x][y]=rank[id]<cut}
	mut h:=[16]int{};for x in 0..16{mut v:=0;for v<16&&processed[x][v]{v++};for y in 0..16{if processed[x][y]!=(y<v){return false}};h[x]=v;if x>0&&h[x-1]<v{return false}}
	path_n=0;if !append_point(mut path,mut path_n,Point{0,256}){return false};mut y:=15;for y>=h[0]{if !append_point(mut path,mut path_n,Point{0,y*16}){return false};y--};for x in 0..16{if !append_point(mut path,mut path_n,Point{(x+1)*16,h[x]*16}){return false};next:=if x<15{h[x+1]}else{0};mut yy:=h[x]-1;for yy>=next{if !append_point(mut path,mut path_n,Point{(x+1)*16,yy*16}){return false};yy--}}
	if path[0].x!=0||path[0].y!=256||path[path_n-1].x!=256||path[path_n-1].y!=0{return false};box:=sweep_box(cells[order[cut]],rotated);for i in 0..path_n{if path[i].x==box[0]&&path[i].y==box[1]{corner=i;return true}};return false
}
fn frontier_segment(a Point,b Point,path [33]Point,n int) int { mut found:= -1;for i in 0..n-1{if intersects(a,b,path[i],path[i+1]){if found>=0{return -2};found=i}};return found }
fn exit_for_cell(a Point,b Point,box [4]int,id int) ?Exit { dx:=i64(b.x-a.x);dy:=i64(b.y-a.y);mut found:=0;mut out:=Exit{};if dy>0{yd:=i64(box[3]-a.y);num:=i64(a.x)*dy+yd*dx;if yd>0&&yd<dy&&i64(box[0])*dy<num&&num<i64(box[2])*dy{out=Exit{id,0,num,dy};found++}};if dx>0{xd:=i64(box[2]-a.x);num:=i64(a.y)*dx+xd*dy;if xd>0&&xd<dx&&i64(box[1])*dx<num&&num<i64(box[3])*dx{out=Exit{id,1,num,dx};found++}};if found==1{return out};return none }
fn exit_less(a Exit,b Exit) bool { return a.num*b.den<b.num*a.den||(a.num*b.den==b.num*a.den&&a.edge<b.edge) }
fn run_sweep(cells []Cell,c int,edges []Edge,n int,endpoints [8][2]int,rotated bool,mut masks [46]u64) bool {
	mut order:=[46]int{};for i in 0..c{order[i]=i};if rotated{for i:=1;i<c;i++{v:=order[i];mut j:=i;for j>0&&cells[order[j-1]].alt_lo>cells[v].alt_lo{order[j]=order[j-1];j--};order[j]=v}}
	mut ea:=[8]Point{};mut eb:=[8]Point{};mut ids:=[8]int{};mut keys:=[8]int{};mut m:=0;for id in 0..n{if edges[id].negative==rotated{ab:=sweep_edge(edges[id],rotated);ea[id]=ab[0];eb[id]=ab[1];key:=positive_key(ea[id].x,ea[id].y);mut j:=m;m++;for j>0&&(keys[j-1]>key||(keys[j-1]==key&&ids[j-1]>id)){keys[j]=keys[j-1];ids[j]=ids[j-1];j--};keys[j]=key;ids[j]=id}}
	mut sl:=[8]int{};mut sb:=[8]int{};mut sln:=0;mut sbn:=0;for pos in 0..c{cid:=order[pos];box:=sweep_box(cells[cid],rotated);mut cand:=[16]int{};mut cn:=0;for sln>0&&segment_box(edges[sl[sln-1]],cells[cid],rotated){sln--;cand[cn]=sl[sln];cn++};for sbn>0&&segment_box(edges[sb[sbn-1]],cells[cid],rotated){sbn--;cand[cn]=sb[sbn];cn++};for q in 0..m{id:=ids[q];if endpoints[id][0]==cid{cand[cn]=id;cn++}}
		mut exits:=[16]Exit{};mut en:=0;for q in 0..cn{id:=cand[q];masks[cid]|=u64(1)<<id;if endpoints[id][1]==cid{continue};e:=exit_for_cell(ea[id],eb[id],box,id) or{return false};exits[en]=e;en++};for i:=1;i<en;i++{v:=exits[i];mut j:=i;for j>0&&(exits[j-1].side>v.side||(exits[j-1].side==v.side&&exit_less(v,exits[j-1]))){exits[j]=exits[j-1];j--};exits[j]=v};for i in 0..en{if exits[i].side==0{if sln>=max_edges{return false};sl[sln]=exits[i].edge;sln++}else{if sbn>=max_edges{return false};sb[sbn]=exits[i].edge;sbn++}}
		if pos+1==c{continue};mut path:=[33]Point{};mut pn:=0;mut corner:=0;if !build_frontier(cells,c,order,pos+1,rotated,mut path,mut pn,mut corner){return false};next_box:=sweep_box(cells[order[pos+1]],rotated);if next_box[1]>box[1]{for sln>0{id:=sl[sln-1];where:=frontier_segment(ea[id],eb[id],path,pn);if where<0{return false};if where<corner{break};if sbn>=max_edges{return false};sb[sbn]=sl[sln-1];sbn++;sln--}}else{for sbn>0{id:=sb[sbn-1];where:=frontier_segment(ea[id],eb[id],path,pn);if where<0{return false};if where>=corner{break};if sln>=max_edges{return false};sl[sln]=sb[sbn-1];sln++;sbn--}}
	};return sln==0&&sbn==0
}
fn put_i64_le(mut out &u8,at int,value i64){bits:=u64(value);unsafe{for b in 0..8{out[at+b]=u8((bits>>(b*8))&255)}}}

@[export: 'k_quadtree_edge_distribution']
pub fn k_quadtree_edge_distribution(input &i64,length usize,mut output &u8,capacity usize) i64 {
	if isnil(input)||length<2||length>max_words{return -1};nv:=unsafe{input[0]};cv:=unsafe{input[1]};if nv<0||nv>8||cv<1||cv>46{return -1};n:=int(nv);c:=int(cv);if length!=2+2*c+4*n{return -1}
	mut cells:=[max_cells]Cell{};mut edges:=[max_edges]Edge{};mut endpoints:=[max_edges][2]int{};mut at:=2;mut previous:=0
	for i in 0..c{d:=unsafe{input[at]};p:=unsafe{input[at+1]};at+=2;if d<0||d>4||p<0||p>=(i64(1)<<(2*d)){return -1};cells[i].depth=int(d);cells[i].prefix=int(p);span:=1<<(2*(max_depth-cells[i].depth));cells[i].lo=cells[i].prefix*span;if cells[i].lo!=previous{return -1};previous=cells[i].lo+span;make_box(mut cells[i])}
	if previous!=256||(n==0&&(c!=1||cells[0].depth!=0||cells[0].prefix!=0)){return -1};for i in 0..c{cells[i].alt_lo=alt_prefix(cells[i].depth,cells[i].prefix)<<(2*(max_depth-cells[i].depth))}
	mut pts:=[16]Point{};for i in 0..n{x0:=unsafe{input[at]};y0:=unsafe{input[at+1]};x1:=unsafe{input[at+2]};y1:=unsafe{input[at+3]};at+=4;if x0<0||x0>255||y0<0||y0>255||x1<0||x1>255||y1<0||y1>255||x0%16==0||y0%16==0||x1%16==0||y1%16==0{return -1};if (x0==x1&&y0==y1)||y0==y1{return -1};if x0>x1||(x0==x1&&y0>y1){x0,x1=x1,x0;y0,y1=y1,y0};if x0==x1&&y1<=y0{return -1};edges[i]=Edge{int(x0),int(y0),int(x1),int(y1),-1,-1,y1<y0};pts[2*i]=Point{int(x0),int(y0)};pts[2*i+1]=Point{int(x1),int(y1)};for gx:=i64(0);gx<=256;gx+=16{for gy:=i64(0);gy<=256;gy+=16{p:=Point{int(gx),int(gy)};if orient(pts[2*i],pts[2*i+1],p)==0&&on_segment(pts[2*i],pts[2*i+1],p){return -1}}};for j in 0..2*i{if pts[j].x==int(x0)&&pts[j].y==int(y0){return -1}};for j in 0..2*i+1{if pts[j].x==int(x1)&&pts[j].y==int(y1){return -1}};for j in 0..i{if intersects(pts[2*i],pts[2*i+1],pts[2*j],pts[2*j+1]){return -1}};a:=find_cell(cells,c,positive_key(int(x0),int(y0)));b:=find_cell(cells,c,positive_key(int(x1),int(y1)));if a<0||b<0{return -1};endpoints[i]=[2]int{a,b};edges[i].start_cell=a;edges[i].end_cell=b;cells[a].endpoints++;cells[b].endpoints++}
	for i in 0..c{if cells[i].endpoints>1{return -1}}
	mut pd:=[85]int{};mut pp:=[85]int{};mut pc:=0;for i in 0..c{for d in 0..cells[i].depth{p:=cells[i].prefix>>(2*(cells[i].depth-d));mut found:=false;for q in 0..pc{if pd[q]==d&&pp[q]==p{found=true}};if !found{pd[pc]=d;pp[pc]=p;pc++}}};for q in 0..pc{mut occupied:=u32(0);for i in 0..c{if cells[i].endpoints==0||cells[i].depth<=pd[q]{continue};if cells[i].prefix>>(2*(cells[i].depth-pd[q]))==pp[q]{occupied|=u32(1)<<((cells[i].prefix>>(2*(cells[i].depth-pd[q]-1)))&3)}};if occupied==0||(occupied&(occupied-1))==0{return -1}}
	for i in 0..n{for dir in 0..2{rotated:=dir==1;if edges[i].negative!=rotated{continue};mut order:=[max_cells]int{};for j in 0..c{order[j]=j};if rotated{for a in 1..c{v:=order[a];mut j:=a;for j>0&&cells[order[j-1]].alt_lo>cells[v].alt_lo{order[j]=order[j-1];j--};order[j]=v}};mut rs:=0;mut re:=0;for j in 0..c{if order[j]==endpoints[i][0]{rs=j};if order[j]==endpoints[i][1]{re=j}};if rs>re{return -1}}}
	mut masks:=[max_cells]u64{};if !run_sweep(cells,c,edges,n,endpoints,false,mut masks)||!run_sweep(cells,c,edges,n,endpoints,true,mut masks){return -1};bytes:=8*(1+c);if isnil(output)||capacity<usize(bytes){return -2};put_i64_le(mut output,0,i64(c));for i in 0..c{put_i64_le(mut output,8*(1+i),i64(masks[i]))};return i64(bytes)
}
