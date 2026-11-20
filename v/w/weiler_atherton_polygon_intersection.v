module weiler_atherton_polygon_intersection

const (
	max_v = 6
	max_cross = 36
	max_nodes = 42
	max_words = 210
)

struct Rat { n i64; d i64 }
struct Point { xn i64; xd i64; yn i64; yd i64 }
struct Crossing { p Point; ta Rat; tb Rat; ae bool; ax bool; be bool; bx bool }
struct Node { p Point; cross int }
struct Ring { mut: points [48]Point; count int }

fn gcd64(a0 i64, b0 i64) i64 {
	mut a := if a0 < 0 { -a0 } else { a0 }
	mut b := if b0 < 0 { -b0 } else { b0 }
	for b != 0 { r := a % b; a = b; b = r }
	return if a == 0 { 1 } else { a }
}
fn make_rat(n0 i64, d0 i64) Rat {
	mut n := n0
	mut d := d0
	if d < 0 { n = -n; d = -d }
	g := gcd64(n, d)
	return Rat{n / g, d / g}
}
fn less_rat(a Rat, b Rat) bool { return a.n * b.d < b.n * a.d }
fn less_point(a Point, b Point) bool {
	if a.xn * b.xd != b.xn * a.xd { return a.xn * b.xd < b.xn * a.xd }
	return a.yn * b.yd < b.yn * a.yd
}
fn int_point(x i64, y i64) Point { return Point{x, 1, y, 1} }
fn orient(ax i64, ay i64, bx i64, by i64, cx i64, cy i64) i64 {
	return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax)
}
fn on_segment(ax i64, ay i64, bx i64, by i64, px i64, py i64) bool {
	return orient(ax, ay, bx, by, px, py) == 0 && px >= min(ax,bx) && px <= max(ax,bx) && py >= min(ay,by) && py <= max(ay,by)
}
// 0 means disjoint, 1 proper crossing, and 2 contact or collinear overlap.
fn relation(ax i64, ay i64, bx i64, by i64, cx i64, cy i64, dx i64, dy i64) int {
	o1 := orient(ax,ay,bx,by,cx,cy); o2 := orient(ax,ay,bx,by,dx,dy)
	o3 := orient(cx,cy,dx,dy,ax,ay); o4 := orient(cx,cy,dx,dy,bx,by)
	if ((o1>0&&o2<0)||(o1<0&&o2>0))&&((o3>0&&o4<0)||(o3<0&&o4>0)) { return 1 }
	if (o1==0&&on_segment(ax,ay,bx,by,cx,cy))||(o2==0&&on_segment(ax,ay,bx,by,dx,dy))||(o3==0&&on_segment(cx,cy,dx,dy,ax,ay))||(o4==0&&on_segment(cx,cy,dx,dy,bx,by)) { return 2 }
	return 0
}
fn valid_poly(p [12]i64, n int) bool {
	mut area := i64(0)
	for i in 0 .. n {
		prev := (i+n-1)%n; next := (i+1)%n
		area += p[2*i]*p[2*next+1]-p[2*i+1]*p[2*next]
		if orient(p[2*prev],p[2*prev+1],p[2*i],p[2*i+1],p[2*next],p[2*next+1])==0 { return false }
		for j in 0 .. i { if p[2*i]==p[2*j]&&p[2*i+1]==p[2*j+1] { return false } }
	}
	if area<=0 { return false }
	for i in 0 .. n { for j in i+1 .. n {
		if j==i+1||(i==0&&j==n-1) { continue }
		k:=(i+1)%n; l:=(j+1)%n
		if relation(p[2*i],p[2*i+1],p[2*k],p[2*k+1],p[2*j],p[2*j+1],p[2*l],p[2*l+1])!=0 { return false }
	} }
	return true
}
fn inside(x i64, y i64, p [12]i64, n int) bool {
	mut winding := 0
	for i in 0 .. n {
		j:=(i+1)%n
		side:=orient(p[2*i],p[2*i+1],p[2*j],p[2*j+1],x,y)
		if p[2*i+1]<=y&&y<p[2*j+1]&&side>0 { winding++ }
		else if p[2*j+1]<=y&&y<p[2*i+1]&&side<0 { winding-- }
	}
	return winding!=0
}
fn crossing_point(ax i64,ay i64,bx i64,by i64,cx i64,cy i64,dx i64,dy i64) (Rat,Rat,Point) {
	rx:=bx-ax;ry:=by-ay;sx:=dx-cx;sy:=dy-cy
	mut den:=rx*sy-ry*sx;mut tn:=(cx-ax)*sy-(cy-ay)*sx;mut un:=(cx-ax)*ry-(cy-ay)*rx
	if den<0 {den=-den;tn=-tn;un=-un}
	ta:=make_rat(tn,den);ttb:=make_rat(un,den)
	x:=make_rat(ax*den+rx*tn,den);y:=make_rat(ay*den+ry*tn,den)
	return tta,ttb,Point{x.n,x.d,y.n,y.d}
}
fn store_i64_le(mut out &u8, offset int, value i64) {
	bits:=u64(value)
	for byte in 0 .. 8 { unsafe { out[offset+byte]=u8((bits>>(8*byte))&255) } }
}
fn canonicalize(mut rings [16]Ring, count int) {
	for r in 0 .. count {
		mut pivot:=0
		for i in 1 .. rings[r].count { if less_point(rings[r].points[i],rings[r].points[pivot]) {pivot=i} }
		if pivot>0 { mut temp:=[48]Point{};for i in 0..rings[r].count {temp[i]=rings[r].points[(pivot+i)%rings[r].count]};for i in 0..rings[r].count {rings[r].points[i]=temp[i]} }
	}
	for i in 1 .. count { key:=rings[i];mut j:=i;for j>0&&less_point(key.points[0],rings[j-1].points[0]) {rings[j]=rings[j-1];j--};rings[j]=key }
}

@[export: 'weiler_atherton_polygon_intersection']
pub fn weiler_atherton_polygon_intersection(input &i64, length usize, mut output &u8, capacity usize) i64 {
	unsafe {
		if input==nil||length<2||length>27 {return -1}
		na0:=input[0];nb0:=input[1]
		if na0<3||na0>max_v||nb0<3||nb0>max_v||length!=usize(2+2*na0+2*nb0) {return -1}
		na:=int(na0);nb:=int(nb0);mut a:=[12]i64{};mut b:=[12]i64{};mut cursor:=2
		for i in 0..2*na {v:=input[cursor];cursor++;if v < -16||v>16{return -1};a[i]=v}
		for i in 0..2*nb {v:=input[cursor];cursor++;if v < -16||v>16{return -1};b[i]=v}
		if !valid_poly(a,na)||!valid_poly(b,nb){return -1}
		mut crossings:=[max_cross]Crossing{};mut ea:=[max_v][max_v]int{};mut eb:=[max_v][max_v]int{};mut ca:=[max_v]int{};mut cb:=[max_v]int{};mut xc:=0
		for i in 0..na {for j in 0..nb {ai:=(i+1)%na;bj:=(j+1)%nb;rel:=relation(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1]);if rel==2{return -1};if rel==1 {
			ta,ttb,p:=crossing_point(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1],b[2*bj],b[2*bj+1])
			ab:=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*i],a[2*i+1]);aa:=orient(b[2*j],b[2*j+1],b[2*bj],b[2*bj+1],a[2*ai],a[2*ai+1]);bb:=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*j],b[2*j+1]);ba:=orient(a[2*i],a[2*i+1],a[2*ai],a[2*ai+1],b[2*bj],b[2*bj+1])
			c:=Crossing{p,tta,ttb,ab<0&&aa>0,ab>0&&aa<0,bb<0&&ba>0,bb>0&&ba<0};if(!c.ae&&!c.ax)||(!c.be&&!c.bx)||c.ae==c.be{return -1};crossings[xc]=c;ea[i][ca[i]]=xc;eb[j][cb[j]]=xc;ca[i]++;cb[j]++;xc++
		} } }
		mut rings:=[16]Ring{};mut rc:=0
		if xc==0 {if inside(a[0],a[1],b,nb){rings[0].count=na;for i in 0..na{rings[0].points[i]=int_point(a[2*i],a[2*i+1])};rc=1}else if inside(b[0],b[1],a,na){rings[0].count=nb;for i in 0..nb{rings[0].points[i]=int_point(b[2*i],b[2*i+1])};rc=1}} else {
			mut nodes_a:=[max_nodes]Node{};mut nodes_b:=[max_nodes]Node{};mut pos_a:=[max_cross]int{};mut pos_b:=[max_cross]int{};mut nca:=0;mut ncb:=0
			for e in 0..na {nodes_a[nca]=Node{int_point(a[2*e],a[2*e+1]),-1};nca++;for z in 1..ca[e]{id:=ea[e][z];mut k:=z;for k>0&&less_rat(crossings[id].ta,crossings[ea[e][k-1]].ta){ea[e][k]=ea[e][k-1];k--};ea[e][k]=id};for z in 0..ca[e]{id:=ea[e][z];nodes_a[nca]=Node{crossings[id].p,id};pos_a[id]=nca;nca++}}
			for e in 0..nb {nodes_b[ncb]=Node{int_point(b[2*e],b[2*e+1]),-1};ncb++;for z in 1..cb[e]{id:=eb[e][z];mut k:=z;for k>0&&less_rat(crossings[id].tb,crossings[eb[e][k-1]].tb){eb[e][k]=eb[e][k-1];k--};eb[e][k]=id};for z in 0..cb[e]{id:=eb[e][z];nodes_b[ncb]=Node{crossings[id].p,id};pos_b[id]=ncb;ncb++}}
			mut visited:=[max_cross]bool{}
			for start in 0..nca {sid:=nodes_a[start].cross;if sid<0||!crossings[sid].ae||visited[sid]{continue};if rc>=16{return -1};mut ring:=Ring{};ring.points[0]=nodes_a[start].p;ring.count=1;visited[sid]=true;mut active_a:=true;mut index:=start;mut guard:=0
				for {guard++;if guard>2*xc+na+nb+1{return -1};node_count:=if active_a{nca}else{ncb};next:=(index+1)%node_count;node:=if active_a{nodes_a[next]}else{nodes_b[next]};if node.cross>=0{visited[node.cross]=true;if active_a&&node.cross==sid{break};exits:=if active_a{crossings[node.cross].ax}else{crossings[node.cross].bx};if exits{if node.cross==sid{break};active_a=!active_a;index=if active_a{pos_a[node.cross]}else{pos_b[node.cross]};continue}};if ring.count>=48{return -1};ring.points[ring.count]=node.p;ring.count++;index=next}
				if ring.count<3{return -1};rings[rc]=ring;rc++}
			for id in 0..xc{if !visited[id]{return -1}}
		}
		canonicalize(mut rings,rc);mut words:=[max_words]i64{};mut wc:=0;words[wc]=i64(rc);wc++
		for r in 0..rc {words[wc]=i64(rings[r].count);wc++;for i in 0..rings[r].count{p:=rings[r].points[i];words[wc]=p.xn;words[wc+1]=p.xd;words[wc+2]=p.yn;words[wc+3]=p.yd;wc+=4}}
		byte_count:=wc*8;if byte_count>1680{return -1};if output==nil||capacity<byte_count{return -2};mut staged:=[1680]u8{};for i in 0..wc{store_i64_le(mut staged[0],8*i,words[i])};for i in 0..byte_count{output[i]=staged[i]};return i64(byte_count)
	}
}
