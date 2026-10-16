module bentley_ottmann
const nmax=24
const emax=2*nmax+nmax*(nmax-1)/2
const pmax=nmax*(nmax-1)/2
struct Seg{x1 i64;y1 i64;x2 i64;y2 i64}
struct Ev{x i64;y i64;a int;b int;t int;done bool}
fn cross(ax i64,ay i64,bx i64,by i64)i64{return ax*by-ay*bx}
fn intersect(a Seg,b Seg)(bool,i64,i64){rx:=a.x2-a.x1;ry:=a.y2-a.y1;sx:=b.x2-b.x1;sy:=b.y2-b.y1;mut d:=cross(rx,ry,sx,sy);mut t:=cross(b.x1-a.x1,b.y1-a.y1,sx,sy);mut u:=cross(b.x1-a.x1,b.y1-a.y1,rx,ry);if d==0{return false,0,0};if d<0{d= -d;t= -t;u= -u};if t<=0||t>=d||u<=0||u>=d{return false,0,0};xn:=a.x1*d+t*rx;yn:=a.y1*d+t*ry;if xn%d!=0||yn%d!=0{return false,0,0};return true,xn/d,yn/d}
fn less(s []Seg,a int,b int,x i64)bool{da:=s[a].x2-s[a].x1;db:=s[b].x2-s[b].x1;na:=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1);nb:=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1);c:=na*db-nb*da;if c!=0{return c<0};sl:=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da;if sl!=0{return sl<0};return a<b}
fn put(out &u8,slot int,v i64){bits:=u64(v);for i in 0..8{unsafe{out[slot*8+i]=u8(bits>>(i*8))}}}
@[export:'bentley_ottmann']
pub fn bentley_ottmann(input &i64,length usize,output &u8,capacity usize)i64{
 if isnil(input)||length<1{return -1};n64:=unsafe{input[0]};if n64<0||n64>nmax||length!=usize(1+4*n64){return -1};n:=int(n64);mut s:=[nmax]Seg{}
 for i in 0..n{x1:=unsafe{input[1+4*i]};y1:=unsafe{input[2+4*i]};x2:=unsafe{input[3+4*i]};y2:=unsafe{input[4+4*i]};if x1< -1000||x1>1000||x2< -1000||x2>1000||y1< -1000||y1>1000||y2< -1000||y2>1000||x1==x2{return -1};s[i]=if x1<x2{Seg{x1,y1,x2,y2}}else{Seg{x2,y2,x1,y1}}}
 mut ev:=[emax]Ev{};mut ec:=0;for i in 0..n{ev[ec]=Ev{s[i].x1,s[i].y1,i,0,0,false};ec++;ev[ec]=Ev{s[i].x2,s[i].y2,i,0,1,false};ec++};mut sched:=[nmax][nmax]bool{};mut active:=[nmax]int{};mut ac:=0;mut pts:=[pmax][2]i64{};mut pc:=0
 for{mut ei:=ec;for j in 0..ec{if !ev[j].done&&(ei==ec||ev[j].x<ev[ei].x||(ev[j].x==ev[ei].x&&ev[j].y<ev[ei].y)){ei=j}};if ei==ec{break};e:=ev[ei];ev[ei].done=true;if e.t==0{active[ac]=e.a;ac++}else if e.t==1{for j in 0..ac{if active[j]==e.a{for k in j+1..ac{active[k-1]=active[k]};ac--;break}}}else{pts[pc]=[e.x,e.y];pc++}
  for i in 1..ac{v:=active[i];mut j:=i;for j>0&&less(s[:],v,active[j-1],e.x){active[j]=active[j-1];j--};active[j]=v}
  for i in 1..ac{a:=active[i-1];b:=active[i];if sched[a][b]{continue};ok,x,y:=intersect(s[a],s[b]);if ok&&x>e.x{if ec>=emax{return -1};ev[ec]=Ev{x,y,a,b,2,false};ec++;sched[a][b]=true;sched[b][a]=true}}
 }
 for i in 1..pc{v:=pts[i];mut j:=i;for j>0&&(pts[j-1][0]>v[0]||(pts[j-1][0]==v[0]&&pts[j-1][1]>v[1])){pts[j]=pts[j-1];j--};pts[j]=v};bytes:=(1+2*pc)*8;if isnil(output)||capacity<usize(bytes){return -2};put(output,0,i64(pc));for i in 0..pc{put(output,1+2*i,pts[i][0]);put(output,2+2*i,pts[i][1])};return i64(bytes)
}
