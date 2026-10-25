import std/math
const MaxPoints=5
const MaxEdges=32
const Scale=1000.0
type
  Point=object
    x,y,norm:float64
  EdgePair=object
    left,right:int
  State=object
    points:array[MaxPoints,Point]
    leftChild,rightChild:array[MaxPoints,int]
    onext,origin:array[MaxEdges*4,int]
    alive:array[MaxEdges,bool]
    edgeCount:int
proc sym(e:int):int=e xor 2
proc rot(e:int):int=(e and not 3) or ((e+1) and 3)
proc rotinv(e:int):int=(e and not 3) or ((e+3) and 3)
proc lnext(s:State,e:int):int=rot(s.onext[rotinv(e)])
proc oprev(s:State,e:int):int=rot(s.onext[rot(e)])
proc rprev(s:State,e:int):int=s.onext[sym(e)]
proc lprev(s:State,e:int):int=sym(s.onext[e])
proc orig(s:State,e:int):int=s.origin[e]
proc dest(s:State,e:int):int=s.origin[sym(e)]
proc ccw(s:State,a,b,c:int):bool=
  (s.points[a].x-s.points[c].x)*(s.points[b].y-s.points[c].y)-
  (s.points[b].x-s.points[c].x)*(s.points[a].y-s.points[c].y)>0.0
proc incircle(s:State,a,b,c,d:int):bool=
  let adx=s.points[a].x-s.points[d].x;let ady=s.points[a].y-s.points[d].y
  let bdx=s.points[b].x-s.points[d].x;let bdy=s.points[b].y-s.points[d].y
  let cdx=s.points[c].x-s.points[d].x;let cdy=s.points[c].y-s.points[d].y
  let r=(s.points[a].norm-s.points[d].norm)*(bdx*cdy-bdy*cdx)+
    (s.points[b].norm-s.points[d].norm)*(cdx*ady-cdy*adx)+
    (s.points[c].norm-s.points[d].norm)*(adx*bdy-ady*bdx)
  r>0.0
proc makeEdge(s:var State,a,b:int):int=
  result=s.edgeCount*4;inc s.edgeCount;s.alive[result div 4]=true
  s.onext[result]=result;s.origin[result]=a;s.onext[result+1]=result+3
  s.onext[result+2]=result+2;s.origin[result+2]=b;s.onext[result+3]=result+1
proc splice(s:var State,a,b:int)=
  let alpha=rot(s.onext[a]);let beta=rot(s.onext[b])
  var t1=s.onext[beta];var temp=s.onext[alpha];s.onext[alpha]=t1;s.onext[beta]=temp
  temp=s.onext[a];t1=s.onext[b];s.onext[b]=temp;s.onext[a]=t1
proc connectLeft(s:var State,a,b:int):int=
  result=s.makeEdge(s.dest(a),s.orig(b));s.splice(result,s.lnext(a));s.splice(sym(result),b)
proc connectRight(s:var State,a,b:int):int=
  result=s.makeEdge(s.dest(a),s.orig(b));s.splice(result,sym(a));s.splice(sym(result),s.oprev(b))
proc deleteEdge(s:var State,e:int)=
  var f=s.oprev(e);s.splice(e,f);f=s.oprev(sym(e));s.splice(sym(e),f);s.alive[e div 4]=false
proc valid(s:State,l,base:int):bool=s.ccw(s.orig(base),s.dest(l),s.dest(base))
proc doMerge(s:var State,ldo,ldi0,rdi0,rdo0:int):EdgePair=
  var ldi=ldi0;var rdi=rdi0;var rdo=rdo0
  while true:
    let t3=s.orig(rdi);var t1=s.orig(ldi);var t2=s.dest(ldi)
    while s.ccw(t1,t2,t3):ldi=s.lnext(ldi);t1=s.orig(ldi);t2=s.dest(ldi)
    t2=s.dest(rdi);if s.ccw(t2,t3,t1):rdi=s.rprev(rdi) else:break
  var basel=s.connectLeft(sym(rdi),ldi);var lcand=s.rprev(basel);var rcand=s.oprev(basel);var leftOuter=ldo
  let t1=s.orig(basel);let t2=s.dest(basel);if t1==s.orig(rdo):rdo=basel
  if t2==s.orig(leftOuter):leftOuter=sym(basel)
  while true:
    var t=s.onext[lcand]
    if s.valid(t,basel):
      let v4=s.orig(basel);var v1=s.dest(lcand);let v3=s.orig(lcand);var v2=s.dest(t)
      while s.incircle(v1,v2,v3,v4):s.deleteEdge(lcand);lcand=t;t=s.onext[lcand];v1=s.dest(lcand);v2=s.dest(t)
    t=s.oprev(rcand)
    if s.valid(t,basel):
      let v4=s.dest(basel);var v1=s.dest(t);var v2=s.dest(rcand);let v3=s.orig(rcand)
      while s.incircle(v1,v2,v3,v4):s.deleteEdge(rcand);rcand=t;t=s.oprev(rcand);v2=s.dest(rcand);v1=s.dest(t)
    let lv=s.valid(lcand,basel);let rv=s.valid(rcand,basel)
    if not lv and not rv:return EdgePair(left:leftOuter,right:rdo)
    let v1=s.dest(lcand);let v2=s.orig(lcand);let v3=s.orig(rcand);let v4=s.dest(rcand)
    if not lv or (rv and s.incircle(v1,v2,v3,v4)):
      basel=s.connectLeft(rcand,sym(basel));rcand=s.lnext(sym(basel))
    else:
      basel=sym(s.connectRight(lcand,basel));lcand=s.rprev(basel)
proc getLow(s:State,node0:int):int=
  var node=node0
  while s.leftChild[node]>=0:node=s.leftChild[node]
  node
proc build(s:var State,tree,extra:int):EdgePair=
  if tree>=0 and s.rightChild[tree]>=0:
    let minx=s.getLow(tree);let dr=s.build(s.rightChild[tree],extra);let dl=s.build(s.leftChild[tree],tree)
    var r=s.doMerge(dl.left,dl.right,dr.left,dr.right)
    while s.orig(r.left)!=minx:r.left=s.rprev(r.left)
    while s.orig(r.right)!=extra:r.right=s.lprev(r.right)
    return r
  if tree<0:return EdgePair(left: -1,right: -1)
  if s.leftChild[tree]<0:
    let e=s.makeEdge(tree,extra);return EdgePair(left:e,right:sym(e))
  let s1=s.leftChild[tree];let s2=tree;let s3=extra
  let a=s.makeEdge(s1,s2);let b=s.makeEdge(s2,s3);s.splice(sym(a),b);let c=s.connectLeft(b,a)
  if s.ccw(s1,s3,s2):return EdgePair(left:sym(c),right:c)
  result=EdgePair(left:a,right:sym(b));if not s.ccw(s1,s2,s3):s.deleteEdge(c)
proc center(s:State,a,b,c:int):tuple[x,y:float64]=
  let vx=s.points[b].x-s.points[a].x;let vy=s.points[b].y-s.points[a].y
  let wx=s.points[c].x-s.points[a].x;let wy=s.points[c].y-s.points[a].y
  let d3=vx*wy-vy*wx;let d2= -2.0*d3;let d4=(s.points[c].x-s.points[b].x)*wx+(s.points[c].y-s.points[b].y)*wy
  (0.5*(s.points[a].x+s.points[b].x)+(d4/d2)*vy,0.5*(s.points[a].y+s.points[b].y)-(d4/d2)*vx)
proc faceCenter(s:State,e:int):tuple[ok:bool,x,y:float64]=
  let e2=s.lnext(e);let e3=s.lnext(e2)
  if s.lnext(e3)!=e:return (false,0.0,0.0)
  let a=s.orig(e);let b=s.dest(e);let c=s.dest(e2)
  if a==b or b==c or a==c or not s.ccw(a,b,c):return (false,0.0,0.0)
  let q=s.center(a,b,c);(true,q.x,q.y)
proc quantize(v:float64):int64=int64(floor(v*Scale+0.5))

proc olden_voronoi*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"olden_voronoi".}=
  if input==nil or (length!=7 and length!=11):return -1
  let n64=input[0];if n64!=3 and n64!=5:return -1
  let n=int(n64);if int(length)!=1+2*n:return -1
  var s:State
  for i in 0..<MaxPoints:s.leftChild[i]= -1;s.rightChild[i]= -1
  for i in 0..<n:
    let x=input[1+2*i];let y=input[2+2*i]
    if x< -8 or x>8 or y< -8 or y>8:return -1
    if i>0 and input[1+2*(i-1)]>=x:return -1
    s.points[i]=Point(x:float64(x),y:float64(y),norm:float64(x*x+y*y))
  if n==3:s.leftChild[1]=0
  else:s.leftChild[2]=1;s.rightChild[2]=3;s.leftChild[1]=0
  for a in 0..<n:
    for b in a+1..<n:
      for c in b+1..<n:
        if not s.ccw(a,b,c) and not s.ccw(a,c,b):return -1
  if n==5:
    for a in 0..<n:
      for b in a+1..<n:
        for c in b+1..<n:
          for d in c+1..<n:
            if not s.incircle(a,b,c,d) and not s.incircle(a,c,b,d):return -1
  discard s.build(if n==3:1 else:2,n-1)
  var seen:array[16,array[3,int]];var faces=0;var edges=0;var dual=0;var rays=0;var projection:int64=0
  for edge in 0..<s.edgeCount:
    if s.alive[edge]:
      let e=edge*4;let left=s.faceCenter(e)
      if left.ok:
        let a=s.orig(e);let b=s.dest(e);let c=s.dest(s.lnext(e));var duplicate=false
        for f in 0..<faces:
          if (seen[f][0]==a or seen[f][1]==a or seen[f][2]==a) and (seen[f][0]==b or seen[f][1]==b or seen[f][2]==b) and (seen[f][0]==c or seen[f][1]==c or seen[f][2]==c):duplicate=true
        if not duplicate:seen[faces]=[a,b,c];inc faces;projection+=quantize(left.x)+2*quantize(left.y)
      let right=s.faceCenter(sym(e))
      if left.ok or right.ok:inc edges;if left.ok and right.ok:inc dual else:inc rays
  projection+100*faces+10*dual+rays+edges
