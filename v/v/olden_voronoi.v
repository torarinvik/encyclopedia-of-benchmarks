module main
import math
const max_points = 5
const max_edges = 32
const scale = 1000.0
struct Point { x f64; y f64; norm f64 }
struct EdgePair { left int; right int }
struct State {
mut:
 points [5]Point
 left_child [5]int
 right_child [5]int
 onext [128]int
 origin [128]int
 alive [32]bool
 edge_count int
}
fn sym(e int) int { return e ^ 2 }
fn rot(e int) int { return (e & ~3) | ((e + 1) & 3) }
fn rotinv(e int) int { return (e & ~3) | ((e + 3) & 3) }
fn lnext(s State, e int) int { return rot(s.onext[rotinv(e)]) }
fn oprev(s State, e int) int { return rot(s.onext[rot(e)]) }
fn rprev(s State, e int) int { return s.onext[sym(e)] }
fn lprev(s State, e int) int { return sym(s.onext[e]) }
fn orig(s State, e int) int { return s.origin[e] }
fn dest(s State, e int) int { return s.origin[sym(e)] }
fn ccw(s State, a int, b int, c int) bool {
 return (s.points[a].x-s.points[c].x)*(s.points[b].y-s.points[c].y)-(s.points[b].x-s.points[c].x)*(s.points[a].y-s.points[c].y)>0
}
fn incircle(s State, a int, b int, c int, d int) bool {
 adx:=s.points[a].x-s.points[d].x;ady:=s.points[a].y-s.points[d].y
 bdx:=s.points[b].x-s.points[d].x;bdy:=s.points[b].y-s.points[d].y
 cdx:=s.points[c].x-s.points[d].x;cdy:=s.points[c].y-s.points[d].y
 r:=(s.points[a].norm-s.points[d].norm)*(bdx*cdy-bdy*cdx)+(s.points[b].norm-s.points[d].norm)*(cdx*ady-cdy*adx)+(s.points[c].norm-s.points[d].norm)*(adx*bdy-ady*bdx)
 return r>0
}
fn make_edge(mut s State, a int, b int) int {
 e:=s.edge_count*4;s.edge_count++;s.alive[e/4]=true;s.onext[e]=e;s.origin[e]=a;s.onext[e+1]=e+3;s.onext[e+2]=e+2;s.origin[e+2]=b;s.onext[e+3]=e+1;return e
}
fn splice(mut s State, a int, b int) {
 alpha:=rot(s.onext[a]);beta:=rot(s.onext[b]);mut t1:=s.onext[beta];mut temp:=s.onext[alpha];s.onext[alpha]=t1;s.onext[beta]=temp;temp=s.onext[a];t1=s.onext[b];s.onext[b]=temp;s.onext[a]=t1
}
fn connect_left(mut s State, a int, b int) int { e:=make_edge(mut s,dest(s,a),orig(s,b));splice(mut s,e,lnext(s,a));splice(mut s,sym(e),b);return e }
fn connect_right(mut s State, a int, b int) int { e:=make_edge(mut s,dest(s,a),orig(s,b));splice(mut s,e,sym(a));splice(mut s,sym(e),oprev(s,b));return e }
fn delete_edge(mut s State, e int) { mut f:=oprev(s,e);splice(mut s,e,f);f=oprev(s,sym(e));splice(mut s,sym(e),f);s.alive[e/4]=false }
fn valid(s State,l int,base int) bool { return ccw(s,orig(s,base),dest(s,l),dest(s,base)) }
fn do_merge(mut s State,ldo int,ldi0 int,rdi0 int,rdo0 int) EdgePair {
 mut ldi:=ldi0;mut rdi:=rdi0;mut rdo:=rdo0
 for { t3:=orig(s,rdi);mut t1:=orig(s,ldi);mut t2:=dest(s,ldi);for ccw(s,t1,t2,t3){ldi=lnext(s,ldi);t1=orig(s,ldi);t2=dest(s,ldi)};t2=dest(s,rdi);if ccw(s,t2,t3,t1){rdi=rprev(s,rdi)}else{break} }
 mut basel:=connect_left(mut s,sym(rdi),ldi);mut lcand:=rprev(s,basel);mut rcand:=oprev(s,basel);mut left_outer:=ldo;t1:=orig(s,basel);t2:=dest(s,basel);if t1==orig(s,rdo){rdo=basel};if t2==orig(s,left_outer){left_outer=sym(basel)}
 for { mut t:=s.onext[lcand];if valid(s,t,basel){v4:=orig(s,basel);mut v1:=dest(s,lcand);v3:=orig(s,lcand);mut v2:=dest(s,t);for incircle(s,v1,v2,v3,v4){delete_edge(mut s,lcand);lcand=t;t=s.onext[lcand];v1=dest(s,lcand);v3=orig(s,lcand);v2=dest(s,t)} };t=oprev(s,rcand);if valid(s,t,basel){v4:=dest(s,basel);mut v1:=dest(s,t);mut v2:=dest(s,rcand);v3:=orig(s,rcand);for incircle(s,v1,v2,v3,v4){delete_edge(mut s,rcand);rcand=t;t=oprev(s,rcand);v2=dest(s,rcand);v3=orig(s,rcand);v1=dest(s,t)}};lv:=valid(s,lcand,basel);rv:=valid(s,rcand,basel);if !lv&&!rv{return EdgePair{left_outer,rdo}};v1:=dest(s,lcand);v2:=orig(s,lcand);v3:=orig(s,rcand);v4:=dest(s,rcand);if !lv||(rv&&incircle(s,v1,v2,v3,v4)){basel=connect_left(mut s,rcand,sym(basel));rcand=lnext(s,sym(basel))}else{basel=sym(connect_right(mut s,lcand,basel));lcand=rprev(s,basel)} }
}
fn get_low(s State,node0 int) int { mut node:=node0;for s.left_child[node]>=0{node=s.left_child[node]};return node }
fn build_delaunay(mut s State,tree int,extra int) EdgePair {
 if tree>=0&&s.right_child[tree]>=0{minx:=get_low(s,tree);dr:=build_delaunay(mut s,s.right_child[tree],extra);dl:=build_delaunay(mut s,s.left_child[tree],tree);mut r:=do_merge(mut s,dl.left,dl.right,dr.left,dr.right);for orig(s,r.left)!=minx{r.left=rprev(s,r.left)};for orig(s,r.right)!=extra{r.right=lprev(s,r.right)};return r}
 if tree<0{return EdgePair{-1,-1}};if s.left_child[tree]<0{e:=make_edge(mut s,tree,extra);return EdgePair{e,sym(e)}};s1:=s.left_child[tree];s2:=tree;s3:=extra;a:=make_edge(mut s,s1,s2);b:=make_edge(mut s,s2,s3);splice(mut s,sym(a),b);c:=connect_left(mut s,b,a);if ccw(s,s1,s3,s2){return EdgePair{sym(c),c}};r:=EdgePair{a,sym(b)};if !ccw(s,s1,s2,s3){delete_edge(mut s,c)};return r
}
fn center(s State,a int,b int,c int) (f64,f64) { vx:=s.points[b].x-s.points[a].x;vy:=s.points[b].y-s.points[a].y;wx:=s.points[c].x-s.points[a].x;wy:=s.points[c].y-s.points[a].y;d3:=vx*wy-vy*wx;d2:=-2.0*d3;d4:=(s.points[c].x-s.points[b].x)*wx+(s.points[c].y-s.points[b].y)*wy;return 0.5*(s.points[a].x+s.points[b].x)+(d4/d2)*vy,0.5*(s.points[a].y+s.points[b].y)-(d4/d2)*vx }
fn face_center(s State,e int) (bool,f64,f64) { e2:=lnext(s,e);e3:=lnext(s,e2);if lnext(s,e3)!=e{return false,0,0};a:=orig(s,e);b:=dest(s,e);c:=dest(s,e2);if a==b||b==c||a==c||!ccw(s,a,b,c){return false,0,0};x,y:=center(s,a,b,c);return true,x,y }
fn quantize(v f64) i64 { return i64(math.floor(v*scale+0.5)) }

@[export: 'olden_voronoi']
pub fn olden_voronoi(input &i64,length usize) i64 {
 if unsafe{input==nil}||(length!=7&&length!=11){return -1};n64:=unsafe{input[0]};if n64!=3&&n64!=5{return -1};n:=int(n64);if length!=usize(1+2*n){return -1}
 mut s:=State{};for i in 0..max_points{s.left_child[i]= -1;s.right_child[i]= -1};for i in 0..n{x:=unsafe{input[1+2*i]};y:=unsafe{input[2+2*i]};if x< -8||x>8||y< -8||y>8{return -1};if i>0&&unsafe{input[1+2*(i-1)]}>=x{return -1};s.points[i]=Point{f64(x),f64(y),f64(x*x+y*y)}}
 if n==3{s.left_child[1]=0}else{s.left_child[2]=1;s.right_child[2]=3;s.left_child[1]=0};for a in 0..n{for b in a+1..n{for c in b+1..n{if !ccw(s,a,b,c)&&!ccw(s,a,c,b){return -1}}}};if n==5{for a in 0..n{for b in a+1..n{for c in b+1..n{for d in c+1..n{if !incircle(s,a,b,c,d)&&!incircle(s,a,c,b,d){return -1}}}}}}
 _=build_delaunay(mut s,if n==3{1}else{2},n-1);mut seen:=[16][3]int{};mut faces:=0;mut edges:=0;mut dual:=0;mut rays:=0;mut projection:=i64(0)
 for edge in 0..s.edge_count{if s.alive[edge]{e:=edge*4;has_left,x,y:=face_center(s,e);if has_left{a:=orig(s,e);b:=dest(s,e);c:=dest(s,lnext(s,e));mut duplicate:=false;for f in 0..faces{if (seen[f][0]==a||seen[f][1]==a||seen[f][2]==a)&&(seen[f][0]==b||seen[f][1]==b||seen[f][2]==b)&&(seen[f][0]==c||seen[f][1]==c||seen[f][2]==c){duplicate=true}};if !duplicate{seen[faces]=[3]int{a,b,c};faces++;projection+=quantize(x)+2*quantize(y)}};has_right,_,_:=face_center(s,sym(e));if has_left||has_right{edges++;if has_left&&has_right{dual++}else{rays++}}}}
 return projection+100*faces+10*dual+rays+edges
}
