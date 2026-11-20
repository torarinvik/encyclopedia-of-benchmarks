package convex_polygon_minimax_slope_edge_insertion
import "core:c"
MAX_N :: 4
MAX_LENGTH :: 14
Point :: struct { x,y,z: i64 }
Triangle :: struct { a,b,c: int }
Slope :: struct { num,den: i64 }
orient :: proc(p:[^]Point,a,b,c0:int)->i64{return (p[b].x-p[a].x)*(p[c0].y-p[a].y)-(p[b].y-p[a].y)*(p[c0].x-p[a].x)}
slope :: proc(p:[^]Point,t:Triangle)->Slope{a,b,c0:=p[t.a],p[t.b],p[t.c];dx1,dy1,dz1:=b.x-a.x,b.y-a.y,b.z-a.z;dx2,dy2,dz2:=c0.x-a.x,c0.y-a.y,c0.z-a.z;det:=dx1*dy2-dx2*dy1;gx:=dz1*dy2-dz2*dy1;gy:=dx1*dz2-dz1*dx2;return Slope{gx*gx+gy*gy,det*det}}
cmp :: proc(a,b:Slope)->int{x,y:=a.num*b.den,b.num*a.den;if x>y{return 1};if x<y{return -1};return 0}
maximum :: proc(p:[^]Point,a,b:Triangle)->Slope{x,y:=slope(p,a),slope(p,b);if cmp(x,y)>=0{return x};return y}
anchor :: proc(p:[^]Point,t:Triangle,q:int)->bool{a,b,c0:=p[t.a],p[t.b],p[t.c];dx1,dy1,dz1:=b.x-a.x,b.y-a.y,b.z-a.z;dx2,dy2,dz2:=c0.x-a.x,c0.y-a.y,c0.z-a.z;det:=dx1*dy2-dx2*dy1;gx:=dz1*dy2-dz2*dy1;gy:=dx1*dz2-dz1*dx2;if gx==0&&gy==0{return false};v:=[3]int{t.a,t.b,t.c};o:[2]int;used:=0;for x in v{if x!=q{o[used]=x;used+=1}};sign:=i64(1);if det<0{sign=-1};dx,dy:=-gx*sign,-gy*sign;ux,uy:=p[o[0]].x-p[q].x,p[o[0]].y-p[q].y;vx,vy:=p[o[1]].x-p[q].x,p[o[1]].y-p[q].y;turn:=ux*vy-uy*vx;side:=i64(1);if turn<0{side=-1};return side*(ux*dy-uy*dx)>=0&&side*(dx*vy-dy*vx)>=0}
crosses :: proc(p:[^]Point,a,b,c0,d:int)->bool{return orient(p,a,b,c0)*orient(p,a,b,d)<0&&orient(p,c0,d,a)*orient(p,c0,d,b)<0}
volume6 :: proc(p:[^]Point)->i64{ax,ay,az:=p[1].x-p[0].x,p[1].y-p[0].y,p[1].z-p[0].z;bx,by,bz:=p[2].x-p[0].x,p[2].y-p[0].y,p[2].z-p[0].z;cx,cy,cz:=p[3].x-p[0].x,p[3].y-p[0].y,p[3].z-p[0].z;return ax*(by*cz-bz*cy)-ay*(bx*cz-bz*cx)+az*(bx*cy-by*cx)}
rank :: proc(p:[^]Point,n:int,target:Slope)->i64{all:[4]Slope;count:=0;for a:=0;a<n;a+=1{for b:=a+1;b<n;b+=1{for c0:=b+1;c0<n;c0+=1{all[count]=slope(p,Triangle{a,b,c0});count+=1}}};distinct:=0;for i:=0;i<count;i+=1{if cmp(all[i],target)<0{seen:=false;for j:=0;j<i;j+=1{if cmp(all[j],all[i])==0{seen=true}};if !seen{distinct+=1}}};return i64(distinct+1)}
convex_polygon_minimax_slope_edge_insertion :: proc "c" (input:[^]i64,length:c.size_t)->i64{
 if input==nil||length<1||length>MAX_LENGTH{return -1};if input[0]<3||input[0]>4{return -1};n:=int(input[0]);if length!=c.size_t(1+3*n){return -1}
 var p:[MAX_N]Point;for i:=0;i<n;i+=1{p[i]=Point{input[1+3*i],input[2+3*i],input[3+3*i]};if p[i].x < -8||p[i].x>8||p[i].y < -8||p[i].y>8||p[i].z < -8||p[i].z>8{return -1}}
 area:i64=0;for i:=0;i<n;i+=1{j:=(i+1)%n;area+=p[i].x*p[j].y-p[i].y*p[j].x};if area==0{return -1};sign:=i64(1);if area<0{sign=-1}
 for a:=0;a<n;a+=1{for b:=a+1;b<n;b+=1{for c0:=b+1;c0<n;c0+=1{if orient(&p[0],a,b,c0)==0{return -1}}}}
 for e:=0;e<n;e+=1{j:=(e+1)%n;for k:=0;k<n;k+=1{if k!=e&&k!=j&&sign*orient(&p[0],e,j,k)<=0{return -1}}};if n==4&&volume6(&p[0])==0{return -1}
 fan:=[2]Triangle{Triangle{0,1,2},Triangle{0,2,3}};worst:=slope(&p[0],fan[0]);if n==4{worst=maximum(&p[0],fan[0],fan[1])}
 if n==4{done:=false;for ti:=0;ti<2;ti+=1{if done{break};t:=fan[ti];if cmp(slope(&p[0],t),worst)!=0{continue};v:=[3]int{t.a,t.b,t.c};for k:=0;k<3;k+=1{if done{break};q:=v[k];if !anchor(&p[0],t,q){continue};o:[2]int;u,s:=0,-1;for j:=0;j<3;j+=1{if j!=k{o[u]=v[j];u+=1}};for j:=0;j<4;j+=1{if j!=v[0]&&j!=v[1]&&j!=v[2]{s=j}};if !crosses(&p[0],q,s,o[0],o[1]){continue};candidate:=maximum(&p[0],Triangle{q,s,o[0]},Triangle{q,s,o[1]});if cmp(candidate,worst)<0{worst=candidate;done=true}}}}
 return rank(&p[0],n,worst)
}
