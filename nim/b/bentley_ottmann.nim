import std/algorithm
const N=24
const E=2*N+N*(N-1) div 2
const P=N*(N-1) div 2
type
  Seg=object
    x1,y1,x2,y2:int64
  Ev=object
    x,y:int64
    a,b,t:int
    done:bool
proc cross(ax,ay,bx,by:int64):int64=ax*by-ay*bx
proc intersection(a,b:Seg):tuple[ok:bool,x,y:int64]=
  let rx=a.x2-a.x1;let ry=a.y2-a.y1;let sx=b.x2-b.x1;let sy=b.y2-b.y1
  var d=cross(rx,ry,sx,sy);var t=cross(b.x1-a.x1,b.y1-a.y1,sx,sy);var u=cross(b.x1-a.x1,b.y1-a.y1,rx,ry)
  if d==0:return (false,0'i64,0'i64)
  if d<0:d= -d;t= -t;u= -u
  if t<=0 or t>=d or u<=0 or u>=d:return (false,0'i64,0'i64)
  let xn=a.x1*d+t*rx;let yn=a.y1*d+t*ry
  if xn mod d!=0 or yn mod d!=0:return (false,0'i64,0'i64)
  (true,xn div d,yn div d)
proc less(s:array[N,Seg],a,b:int,x:int64):bool=
  let da=s[a].x2-s[a].x1;let db=s[b].x2-s[b].x1
  let na=s[a].y1*da+(x-s[a].x1)*(s[a].y2-s[a].y1);let nb=s[b].y1*db+(x-s[b].x1)*(s[b].y2-s[b].y1)
  let c=na*db-nb*da
  if c!=0:return c<0
  let sl=(s[a].y2-s[a].y1)*db-(s[b].y2-s[b].y1)*da
  if sl!=0:return sl<0
  a<b
proc put(outp:ptr UncheckedArray[uint8],slot:int,v:int64)=
  let b=cast[uint64](v)
  for i in 0..<8:outp[slot*8+i]=uint8((b shr (i*8)) and 255)
proc bentley_ottmann*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"bentley_ottmann".}=
  if input==nil or length<1:return -1
  let n64=input[0];if n64<0 or n64>N or int(length)!=1+4*int(n64):return -1
  let n=int(n64);var s:array[N,Seg]
  for i in 0..<n:
    let x1=input[1+4*i];let y1=input[2+4*i];let x2=input[3+4*i];let y2=input[4+4*i]
    if x1< -1000 or x1>1000 or x2< -1000 or x2>1000 or y1< -1000 or y1>1000 or y2< -1000 or y2>1000 or x1==x2:return -1
    s[i]=if x1<x2:Seg(x1:x1,y1:y1,x2:x2,y2:y2) else:Seg(x1:x2,y1:y2,x2:x1,y2:y1)
  var ev:array[E,Ev];var ec=0
  for i in 0..<n:ev[ec]=Ev(x:s[i].x1,y:s[i].y1,a:i,t:0);inc ec;ev[ec]=Ev(x:s[i].x2,y:s[i].y2,a:i,t:1);inc ec
  var sched:array[N,array[N,bool]];var active:array[N,int];var ac=0;var pts:array[P,tuple[x,y:int64]];var pc=0
  while true:
    var ei=ec
    for j in 0..<ec:
      if not ev[j].done and (ei==ec or ev[j].x<ev[ei].x or (ev[j].x==ev[ei].x and ev[j].y<ev[ei].y)):ei=j
    if ei==ec:break
    let e=ev[ei];ev[ei].done=true
    if e.t==0:active[ac]=e.a;inc ac
    elif e.t==1:
      for j in 0..<ac:
        if active[j]==e.a:
          for k in j+1..<ac:active[k-1]=active[k]
          dec ac;break
    else:pts[pc]=(e.x,e.y);inc pc
    for i in 1..<ac:
      let v=active[i];var j=i
      while j>0 and less(s,v,active[j-1],e.x):active[j]=active[j-1];dec j
      active[j]=v
    for i in 1..<ac:
      let a=active[i-1];let b=active[i]
      if sched[a][b]:continue
      let hit=intersection(s[a],s[b])
      if hit.ok and hit.x>e.x:
        if ec>=E:return -1
        ev[ec]=Ev(x:hit.x,y:hit.y,a:a,b:b,t:2);inc ec;sched[a][b]=true;sched[b][a]=true
  pts.sort(proc(a,b:tuple[x,y:int64]):int=if a.x<b.x or (a.x==b.x and a.y<b.y):-1 elif a.x==b.x and a.y==b.y:0 else:1)
  let bytes=(1+2*pc)*8
  if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(pc));for i in 0..<pc:put(output,1+2*i,pts[i].x);put(output,2+2*i,pts[i].y)
  int64(bytes)
