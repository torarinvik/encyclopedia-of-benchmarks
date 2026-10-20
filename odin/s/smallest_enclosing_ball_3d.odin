package smallest_enclosing_ball_3d
import "core:math"
Point :: struct{x,y,z:f64}
Sphere :: struct{c:Point,r:f64}
sub :: proc(a,b:Point)->Point{return Point{a.x-b.x,a.y-b.y,a.z-b.z}}
add :: proc(a,b:Point)->Point{return Point{a.x+b.x,a.y+b.y,a.z+b.z}}
mul :: proc(a:Point,k:f64)->Point{return Point{a.x*k,a.y*k,a.z*k}}
dot :: proc(a,b:Point)->f64{return a.x*b.x+a.y*b.y+a.z*b.z}
cross :: proc(a,b:Point)->Point{return Point{a.y*b.z-a.z*b.y,a.z*b.x-a.x*b.z,a.x*b.y-a.y*b.x}}
det :: proc(a,b,c:Point)->f64{return dot(a,cross(b,c))}
invalid :: proc()->Sphere{return Sphere{Point{},-1}}
through :: proc(p:^([4]Point),n:int)->Sphere{if n==1{return Sphere{p[0],0}};if n==2{c:=mul(add(p[0],p[1]),0.5);d:=sub(p[0],c);return Sphere{c,math.sqrt_f64(dot(d,d))}};if n==3{u:=sub(p[1],p[0]);v:=sub(p[2],p[0]);w:=cross(u,v);den:=2*dot(w,w);if den<1e-24{return invalid()};off:=mul(add(mul(cross(v,w),dot(u,u)),mul(cross(w,u),dot(v,v))),1/den);c:=add(p[0],off);d:=sub(c,p[0]);return Sphere{c,math.sqrt_f64(dot(d,d))}};a:=mul(sub(p[1],p[0]),2);b:=mul(sub(p[2],p[0]),2);c:=mul(sub(p[3],p[0]),2);qa:=dot(p[1],p[1])-dot(p[0],p[0]);qb:=dot(p[2],p[2])-dot(p[0],p[0]);qc:=dot(p[3],p[3])-dot(p[0],p[0]);d:=det(a,b,c);if math.abs(d)<1e-18{return invalid()};center:=mul(add(add(mul(cross(b,c),qa),mul(cross(c,a),qb)),mul(cross(a,b),qc)),1/d);delta:=sub(center,p[0]);return Sphere{center,math.sqrt_f64(dot(delta,delta))}}
contains :: proc(s:Sphere,p:Point)->bool{if s.r<0{return false};d:=sub(p,s.c);return dot(d,d)<=(s.r+1e-10)*(s.r+1e-10)}
fit :: proc(r:^([4]Point),m:int)->Sphere{best:=invalid();for mask:=1;mask<(1<<m);mask+=1{q:[4]Point;n:=0;for i:=0;i<m;i+=1{if mask&(1<<i)!=0{q[n]=r[i];n+=1}};s:=through(&q,n);if s.r<0{continue};ok:=true;for i:=0;i<m;i+=1{if !contains(s,r[i]){ok=false}};if ok&&(best.r<0||s.r<best.r-1e-12){best=s}};return best}
welzl :: proc(p:^([8]Point),n:int,r:^([4]Point),m:int)->Sphere{if n==0||m==4{return fit(r,m)};s:=welzl(p,n-1,r,m);if contains(s,p[n-1]){return s};r[m]=p[n-1];return welzl(p,n-1,r,m+1)}
@(export)
smallest_enclosing_ball_3d :: proc "c" (input:[^]f64,length:uintptr,output:[^]f64,capacity:uintptr)->i64{if input==nil||length<4||length>25{return -1};raw:=input[0];if math.is_nan(raw)||math.is_inf(raw)||raw<1||raw>8||math.trunc(raw)!=raw{return -1};n:=int(raw);if length!=uintptr(1+3*n){return -1};p:[8]Point;for i:=0;i<n;i+=1{p[i]=Point{input[1+3*i],input[2+3*i],input[3+3*i]};if math.is_nan(p[i].x)||math.is_inf(p[i].x)||math.is_nan(p[i].y)||math.is_inf(p[i].y)||math.is_nan(p[i].z)||math.is_inf(p[i].z)||math.abs(p[i].x)>10||math.abs(p[i].y)>10||math.abs(p[i].z)>10{return -1}};for i:=1;i<n;i+=1{v:=p[i];j:=i;for j>0&&(p[j-1].x>v.x||(p[j-1].x==v.x&&(p[j-1].y>v.y||(p[j-1].y==v.y&&p[j-1].z>v.z)))){p[j]=p[j-1];j-=1};p[j]=v};r:[4]Point;s:=welzl(&p,n,&r,0);if s.r<0||math.is_nan(s.r)||math.is_inf(s.r){return -1};if output==nil||capacity<4{return -2};output[0]=s.c.x;output[1]=s.c.y;output[2]=s.c.z;output[3]=s.r;return 4}
