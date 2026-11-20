module convex_polygon_minimax_slope_edge_insertion

const max_n = 4
const max_length = 14
struct Point { x i64; y i64; z i64 }
struct Triangle { a int; b int; c int }
struct Slope { num i64; den i64 }
fn orient(p [max_n]Point, a int, b int, c int) i64 { return (p[b].x-p[a].x)*(p[c].y-p[a].y)-(p[b].y-p[a].y)*(p[c].x-p[a].x) }
fn slope(p [max_n]Point, t Triangle) Slope {
	a,b,c := p[t.a],p[t.b],p[t.c]
	dx1,dy1,dz1 := b.x-a.x,b.y-a.y,b.z-a.z
	dx2,dy2,dz2 := c.x-a.x,c.y-a.y,c.z-a.z
	det := dx1*dy2-dx2*dy1; gx := dz1*dy2-dz2*dy1; gy := dx1*dz2-dz1*dx2
	return Slope{num:gx*gx+gy*gy,den:det*det}
}
fn cmp(a Slope,b Slope) int { x,y:=a.num*b.den,b.num*a.den; if x>y{return 1};if x<y{return -1};return 0 }
fn maximum(p [max_n]Point,a Triangle,b Triangle) Slope { x,y:=slope(p,a),slope(p,b);if cmp(x,y)>=0{return x};return y }
fn anchor(p [max_n]Point,t Triangle,q int) bool {
	a,b,c:=p[t.a],p[t.b],p[t.c];dx1,dy1,dz1:=b.x-a.x,b.y-a.y,b.z-a.z;dx2,dy2,dz2:=c.x-a.x,c.y-a.y,c.z-a.z
	det:=dx1*dy2-dx2*dy1;gx:=dz1*dy2-dz2*dy1;gy:=dx1*dz2-dz1*dx2;if gx==0&&gy==0{return false}
	v:=[3]int{t.a,t.b,t.c};mut o:=[2]int{};mut used:=0;for x in v{if x!=q{o[used]=x;used++}}
	sign:=if det>0{i64(1)}else{i64(-1)};dx,dy:=-gx*sign,-gy*sign;ux,uy:=p[o[0]].x-p[q].x,p[o[0]].y-p[q].y;vx,vy:=p[o[1]].x-p[q].x,p[o[1]].y-p[q].y
	turn:=ux*vy-uy*vx;side:=if turn>0{i64(1)}else{i64(-1)};return side*(ux*dy-uy*dx)>=0&&side*(dx*vy-dy*vx)>=0
}
fn crosses(p [max_n]Point,a int,b int,c int,d int) bool { return orient(p,a,b,c)*orient(p,a,b,d)<0&&orient(p,c,d,a)*orient(p,c,d,b)<0 }
fn volume6(p [max_n]Point) i64 { ax,ay,az:=p[1].x-p[0].x,p[1].y-p[0].y,p[1].z-p[0].z;bx,by,bz:=p[2].x-p[0].x,p[2].y-p[0].y,p[2].z-p[0].z;cx,cy,cz:=p[3].x-p[0].x,p[3].y-p[0].y,p[3].z-p[0].z;return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx) }
fn rank(p [max_n]Point,n int,target Slope) i64 { mut all:=[4]Slope{};mut count:=0;for a in 0..n{for b in a+1..n{for c in b+1..n{all[count]=slope(p,Triangle{a,b,c});count++}}};mut distinct:=0;for i in 0..count{if cmp(all[i],target)<0{mut seen:=false;for j in 0..i{if cmp(all[j],all[i])==0{seen=true}};if !seen{distinct++}}};return i64(distinct+1) }
@[export: 'convex_polygon_minimax_slope_edge_insertion']
pub fn convex_polygon_minimax_slope_edge_insertion(input &i64,length usize) i64 {
	unsafe {
		if input==nil||length<1||length>max_length{return -1};if input[0]<3||input[0]>4{return -1};n:=int(input[0]);if length!=usize(1+3*n){return -1}
		mut p:=[max_n]Point{};for i in 0..n{p[i]=Point{x:input[1+3*i],y:input[2+3*i],z:input[3+3*i]};if p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8{return -1}}
		mut area:=i64(0);for i in 0..n{j:=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x};if area==0{return -1};sign:=if area>0{i64(1)}else{i64(-1)}
		for a in 0..n{for b in a+1..n{for c in b+1..n{if orient(p,a,b,c)==0{return -1}}}}
		for e in 0..n{j:=(e+1)%n;for k in 0..n{if k!=e&&k!=j&&sign*orient(p,e,j,k)<=0{return -1}}};if n==4&&volume6(p)==0{return -1}
		fan:=[2]Triangle{Triangle{0,1,2},Triangle{0,2,3}};mut worst:=slope(p,fan[0]);if n==4{worst=maximum(p,fan[0],fan[1])}
		if n==4{mut done:=false;for t in fan{if done{break};if cmp(slope(p,t),worst)!=0{continue};v:=[3]int{t.a,t.b,t.c};for k in 0..3{if done{break};q:=v[k];if !anchor(p,t,q){continue};mut o:=[2]int{};mut u:=0;s:= -1;for j in 0..3{if j!=k{o[u]=v[j];u++}};for j in 0..4{if j!=v[0]&&j!=v[1]&&j!=v[2]{s=j}};if !crosses(p,q,s,o[0],o[1]){continue};candidate:=maximum(p,Triangle{q,s,o[0]},Triangle{q,s,o[1]});if cmp(candidate,worst)<0{worst=candidate;done=true}}}}
		return rank(p,n,worst)
	}
}
