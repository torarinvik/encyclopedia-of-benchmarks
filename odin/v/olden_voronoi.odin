package olden_voronoi
import "core:c"
import "core:math"
MAX_POINTS :: 5
MAX_EDGES :: 32
SCALE :: 1000.0
Point :: struct{x,y,norm:f64}
Edge_Pair :: struct{left,right:int}
State :: struct{points:[MAX_POINTS]Point,left_child,right_child:[MAX_POINTS]int,onext,origin:[MAX_EDGES*4]int,alive:[MAX_EDGES]bool,edge_count:int}
sym :: proc "contextless" (e:int)->int{return e~2}
rot :: proc "contextless" (e:int)->int{return (e & ~3) | ((e+1)&3)}
rotinv :: proc "contextless" (e:int)->int{return (e & ~3) | ((e+3)&3)}
lnext :: proc "contextless" (s:^State,e:int)->int{return rot(s.onext[rotinv(e)])}
oprev :: proc "contextless" (s:^State,e:int)->int{return rot(s.onext[rot(e)])}
rprev :: proc "contextless" (s:^State,e:int)->int{return s.onext[sym(e)]}
lprev :: proc "contextless" (s:^State,e:int)->int{return sym(s.onext[e])}
orig :: proc "contextless" (s:^State,e:int)->int{return s.origin[e]}
dest :: proc "contextless" (s:^State,e:int)->int{return s.origin[sym(e)]}
ccw :: proc "contextless" (s:^State,a,b,c:int)->bool{return (s.points[a].x-s.points[c].x)*(s.points[b].y-s.points[c].y)-(s.points[b].x-s.points[c].x)*(s.points[a].y-s.points[c].y)>0}
incircle :: proc "contextless" (s:^State,a,b,c,d:int)->bool{adx:=s.points[a].x-s.points[d].x;ady:=s.points[a].y-s.points[d].y;bdx:=s.points[b].x-s.points[d].x;bdy:=s.points[b].y-s.points[d].y;cdx:=s.points[c].x-s.points[d].x;cdy:=s.points[c].y-s.points[d].y;r:=(s.points[a].norm-s.points[d].norm)*(bdx*cdy-bdy*cdx)+(s.points[b].norm-s.points[d].norm)*(cdx*ady-cdy*adx)+(s.points[c].norm-s.points[d].norm)*(adx*bdy-ady*bdx);return r>0}
make_edge :: proc "contextless" (s:^State,a,b:int)->int{e:=s.edge_count*4;s.edge_count+=1;s.alive[e/4]=true;s.onext[e]=e;s.origin[e]=a;s.onext[e+1]=e+3;s.onext[e+2]=e+2;s.origin[e+2]=b;s.onext[e+3]=e+1;return e}
splice :: proc "contextless" (s:^State,a,b:int){alpha:=rot(s.onext[a]);beta:=rot(s.onext[b]);t1:=s.onext[beta];temp:=s.onext[alpha];s.onext[alpha]=t1;s.onext[beta]=temp;temp=s.onext[a];t1=s.onext[b];s.onext[b]=temp;s.onext[a]=t1}
connect_left :: proc "contextless" (s:^State,a,b:int)->int{e:=make_edge(s,dest(s,a),orig(s,b));splice(s,e,lnext(s,a));splice(s,sym(e),b);return e}
connect_right :: proc "contextless" (s:^State,a,b:int)->int{e:=make_edge(s,dest(s,a),orig(s,b));splice(s,e,sym(a));splice(s,sym(e),oprev(s,b));return e}
delete_edge :: proc "contextless" (s:^State,e:int){f:=oprev(s,e);splice(s,e,f);f=oprev(s,sym(e));splice(s,sym(e),f);s.alive[e/4]=false}
valid :: proc "contextless" (s:^State,l,base:int)->bool{return ccw(s,orig(s,base),dest(s,l),dest(s,base))}
do_merge :: proc "contextless" (s:^State,ldo,ldi0,rdi0,rdo0:int)->Edge_Pair{
 ldi:=ldi0;rdi:=rdi0;rdo:=rdo0
 for {t3:=orig(s,rdi);t1:=orig(s,ldi);t2:=dest(s,ldi);for ccw(s,t1,t2,t3){ldi=lnext(s,ldi);t1=orig(s,ldi);t2=dest(s,ldi)};t2=dest(s,rdi);if ccw(s,t2,t3,t1){rdi=rprev(s,rdi)}else{break}}
 basel:=connect_left(s,sym(rdi),ldi);lcand:=rprev(s,basel);rcand:=oprev(s,basel);left_outer:=ldo;t1:=orig(s,basel);t2:=dest(s,basel);if t1==orig(s,rdo){rdo=basel};if t2==orig(s,left_outer){left_outer=sym(basel)}
 for {t:=s.onext[lcand];if valid(s,t,basel){v4:=orig(s,basel);v1:=dest(s,lcand);v3:=orig(s,lcand);v2:=dest(s,t);for incircle(s,v1,v2,v3,v4){delete_edge(s,lcand);lcand=t;t=s.onext[lcand];v1=dest(s,lcand);v3=orig(s,lcand);v2=dest(s,t)}};t=oprev(s,rcand);if valid(s,t,basel){v4:=dest(s,basel);v1:=dest(s,t);v2:=dest(s,rcand);v3:=orig(s,rcand);for incircle(s,v1,v2,v3,v4){delete_edge(s,rcand);rcand=t;t=oprev(s,rcand);v2=dest(s,rcand);v3=orig(s,rcand);v1=dest(s,t)}};lv:=valid(s,lcand,basel);rv:=valid(s,rcand,basel);if !lv&&!rv{return Edge_Pair{left_outer,rdo}};v1:=dest(s,lcand);v2:=orig(s,lcand);v3:=orig(s,rcand);v4:=dest(s,rcand);if !lv||(rv&&incircle(s,v1,v2,v3,v4)){basel=connect_left(s,rcand,sym(basel));rcand=lnext(s,sym(basel))}else{basel=sym(connect_right(s,lcand,basel));lcand=rprev(s,basel)}}
}
get_low :: proc "contextless" (s:^State,node0:int)->int{node:=node0;for s.left_child[node]>=0{node=s.left_child[node]};return node}
build_delaunay :: proc "contextless" (s:^State,tree,extra:int)->Edge_Pair{
 if tree>=0&&s.right_child[tree]>=0{minx:=get_low(s,tree);dr:=build_delaunay(s,s.right_child[tree],extra);dl:=build_delaunay(s,s.left_child[tree],tree);r:=do_merge(s,dl.left,dl.right,dr.left,dr.right);for orig(s,r.left)!=minx{r.left=rprev(s,r.left)};for orig(s,r.right)!=extra{r.right=lprev(s,r.right)};return r}
 if tree<0{return Edge_Pair{-1,-1}};if s.left_child[tree]<0{e:=make_edge(s,tree,extra);return Edge_Pair{e,sym(e)}};s1:=s.left_child[tree];s2:=tree;s3:=extra;a:=make_edge(s,s1,s2);b:=make_edge(s,s2,s3);splice(s,sym(a),b);c:=connect_left(s,b,a);if ccw(s,s1,s3,s2){return Edge_Pair{sym(c),c}};r:=Edge_Pair{a,sym(b)};if !ccw(s,s1,s2,s3){delete_edge(s,c)};return r
}
center :: proc "contextless" (s:^State,a,b,c:int)->(f64,f64){vx:=s.points[b].x-s.points[a].x;vy:=s.points[b].y-s.points[a].y;wx:=s.points[c].x-s.points[a].x;wy:=s.points[c].y-s.points[a].y;d3:=vx*wy-vy*wx;d2:=-2.0*d3;d4:=(s.points[c].x-s.points[b].x)*wx+(s.points[c].y-s.points[b].y)*wy;return 0.5*(s.points[a].x+s.points[b].x)+(d4/d2)*vy,0.5*(s.points[a].y+s.points[b].y)-(d4/d2)*vx}
face_center :: proc "contextless" (s:^State,e:int)->(bool,f64,f64){e2:=lnext(s,e);e3:=lnext(s,e2);if lnext(s,e3)!=e{return false,0,0};a:=orig(s,e);b:=dest(s,e);c:=dest(s,e2);if a==b||b==c||a==c||!ccw(s,a,b,c){return false,0,0};x,y:=center(s,a,b,c);return true,x,y}
quantize :: proc "contextless" (v:f64)->i64{return i64(math.floor(v*SCALE+0.5))}
@(export)
olden_voronoi :: proc "c" (input:[^]i64,length:c.size_t)->i64{
 if input==nil||(length!=7&&length!=11) do return -1;n64:=input[0];if n64!=3&&n64!=5 do return -1;n:=int(n64);if length!=c.size_t(1+2*n) do return -1
 s:State;for i in 0..<MAX_POINTS{s.left_child[i]=-1;s.right_child[i]=-1};for i in 0..<n{x:=input[1+2*i];y:=input[2+2*i];if x< -8||x>8||y< -8||y>8 do return -1;if i>0&&input[1+2*(i-1)]>=x do return -1;s.points[i]=Point{f64(x),f64(y),f64(x*x+y*y)}}
 if n==3{s.left_child[1]=0}else{s.left_child[2]=1;s.right_child[2]=3;s.left_child[1]=0};for a in 0..<n{for b in a+1..<n{for c0 in b+1..<n{if !ccw(&s,a,b,c0)&&!ccw(&s,a,c0,b) do return -1}}};if n==5{for a in 0..<n{for b in a+1..<n{for c0 in b+1..<n{for d in c0+1..<n{if !incircle(&s,a,b,c0,d)&&!incircle(&s,a,c0,b,d) do return -1}}}}}
 _=build_delaunay(&s,if n==3{1}else{2},n-1);seen:[16][3]int;faces:=0;edges:=0;dual:=0;rays:=0;projection:i64=0
 for edge in 0..<s.edge_count{if s.alive[edge]{e:=edge*4;has_left,x,y:=face_center(&s,e);if has_left{a:=orig(&s,e);b:=dest(&s,e);c0:=dest(&s,lnext(&s,e));duplicate:=false;for f in 0..<faces{if (seen[f][0]==a||seen[f][1]==a||seen[f][2]==a)&&(seen[f][0]==b||seen[f][1]==b||seen[f][2]==b)&&(seen[f][0]==c0||seen[f][1]==c0||seen[f][2]==c0){duplicate=true}};if !duplicate{seen[faces]=[3]int{a,b,c0};faces+=1;projection+=quantize(x)+2*quantize(y)}};has_right,_,_:=face_center(&s,sym(e));if has_left||has_right{edges+=1;if has_left&&has_right{dual+=1}else{rays+=1}}}}
 return projection+100*faces+10*dual+rays+edges
}
