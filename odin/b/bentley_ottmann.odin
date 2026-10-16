package bentley_ottmann
import "core:c"
N :: 24
E :: 2*N+N*(N-1)/2
P :: N*(N-1)/2
Seg :: struct{x1,y1,x2,y2:i64}
Ev :: struct{x,y:i64,a,b,t:int,done:bool}
cross :: proc "contextless" (ax,ay,bx,by:i64)->i64{return ax*by-ay*bx}
intersect :: proc "contextless" (a,b:Seg,x,y:^i64)->bool{rx:=a.x2-a.x1;ry:=a.y2-a.y1;sx:=b.x2-b.x1;sy:=b.y2-b.y1;d:=cross(rx,ry,sx,sy);if d==0{return false};t:=cross(b.x1-a.x1,b.y1-a.y1,sx,sy);u:=cross(b.x1-a.x1,b.y1-a.y1,rx,ry);if d<0{d= -d;t= -t;u= -u};if t<=0||t>=d||u<=0||u>=d{return false};xn:=a.x1*d+t*rx;yn:=a.y1*d+t*ry;if xn%d!=0||yn%d!=0{return false};x^=xn/d;y^=yn/d;return true}
less :: proc "contextless" (s:[N]Seg,a,b:int,x:i64)->bool{da:=s[a].x2-s[a].x1;db:=s[b].x2-s[b].x1;na:=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1);nb:=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1);c:=na*db-nb*da;if c!=0{return c<0};sl:=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;if sl!=0{return sl<0};return a<b}
put :: proc "contextless" (out:[^]u8,slot:int,v:i64){b:=u64(v);for i:=0;i<8;i+=1{out[slot*8+i]=u8(b>>u64(i*8))}}
@(export)
bentley_ottmann :: proc "c" (input:[^]i64,length:c.size_t,output:[^]u8,capacity:c.size_t)->i64{
 if input==nil||length<1||input[0]<0||input[0]>N do return -1;n:=int(input[0]);if int(length)!=1+4*n do return -1;s:[N]Seg
 for i:=0;i<n;i+=1{x1:=input[1+4*i];y1:=input[2+4*i];x2:=input[3+4*i];y2:=input[4+4*i];if x1< -1000||x1>1000||x2< -1000||x2>1000||y1< -1000||y1>1000||y2< -1000||y2>1000||x1==x2 do return -1;if x1<x2{s[i]=Seg{x1,y1,x2,y2}}else{s[i]=Seg{x2,y2,x1,y1}}}
 ev:[E]Ev;ec:=0;for i:=0;i<n;i+=1{ev[ec]=Ev{s[i].x1,s[i].y1,i,-1,0,false};ec+=1;ev[ec]=Ev{s[i].x2,s[i].y2,i,-1,1,false};ec+=1};sched:[N][N]bool;active:[N]int;ac:=0;pts:[P][2]i64;pc:=0
 for {ei:=ec;for j:=0;j<ec;j+=1{if !ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)){ei=j}};if ei==ec do break;e:=ev[ei];ev[ei].done=true;if e.t==0{active[ac]=e.a;ac+=1}else if e.t==1{for j:=0;j<ac;j+=1{if active[j]==e.a{for k:=j+1;k<ac;k+=1{active[k-1]=active[k]};ac-=1;break}}}else{pts[pc]=[2]i64{e.x,e.y};pc+=1}
  for i:=1;i<ac;i+=1{v:=active[i];j:=i;for j>0&&less(s,v,active[j-1],e.x){active[j]=active[j-1];j-=1};active[j]=v}
  for i:=1;i<ac;i+=1{a:=active[i-1];b:=active[i];if sched[a][b] do continue;x:i64;y:i64;if intersect(s[a],s[b],&x,&y)&&x>e.x{if ec>=E do return -1;ev[ec]=Ev{x,y,a,b,2,false};ec+=1;sched[a][b]=true;sched[b][a]=true}}
 }
 for i:=1;i<pc;i+=1{x:=pts[i][0];y:=pts[i][1];j:=i;for j>0&&(pts[j-1][0]>x||(pts[j-1][0]==x&&pts[j-1][1]>y)){pts[j]=pts[j-1];j-=1};pts[j]=[2]i64{x,y}};bytes:=(1+2*pc)*8;if output==nil||int(capacity)<bytes do return -2;put(output,0,i64(pc));for i:=0;i<pc;i+=1{put(output,1+2*i,pts[i][0]);put(output,2+2*i,pts[i][1])};return i64(bytes)
}
