import std/math
type Node = object
  left,right:int
  rep:int
  mask:uint64
  cx,cy,r,span:float64
type Ctx = object
  x,y:array[8,float64]
  nodes:array[15,Node]
  used,n,ec:int
  sep:float64
  edges:array[56,float64]
proc less(c:Ctx,a,b,axis:int):bool =
  let (a0,b0,a1,b1)=if axis==0:(c.x[a],c.x[b],c.y[a],c.y[b]) else:(c.y[a],c.y[b],c.x[a],c.x[b])
  a0<b0 or (a0==b0 and (a1<b1 or (a1==b1 and a<b)))
proc build(c:var Ctx,mask:uint64):int =
  result=c.used;inc c.used
  var ids:array[8,int];var n=0;var rep=8
  var xmin,xmax,ymin,ymax:float64
  for i in 0..<c.n:
    if (mask and (1'u64 shl i))!=0:
      if n==0:xmin=c.x[i];xmax=xmin;ymin=c.y[i];ymax=ymin
      else:xmin=min(xmin,c.x[i]);xmax=max(xmax,c.x[i]);ymin=min(ymin,c.y[i]);ymax=max(ymax,c.y[i])
      ids[n]=i;inc n;rep=min(rep,i)
  let cx=(xmin+xmax)/2;let cy=(ymin+ymax)/2;let rx=(xmax-xmin)/2;let ry=(ymax-ymin)/2
  c.nodes[result]=Node(left:-1,right:-1,rep:rep,mask:mask,cx:cx,cy:cy,r:sqrt(rx*rx+ry*ry),span:max(xmax-xmin,ymax-ymin))
  if n==1:return
  let axis=if xmax-xmin>=ymax-ymin:0 else:1
  for i in 1..<n:
    let v=ids[i];var j=i
    while j>0 and less(c,v,ids[j-1],axis):ids[j]=ids[j-1];dec j
    ids[j]=v
  var lm,rm:uint64
  for i in 0..<n:
    if i<n div 2:lm=lm or (1'u64 shl ids[i]) else:rm=rm or (1'u64 shl ids[i])
  let l=build(c,lm);let r=build(c,rm);c.nodes[result].left=l;c.nodes[result].right=r
proc separated(c:Ctx,a,b:int):bool =
  let u=c.nodes[a];let v=c.nodes[b];let dx=u.cx-v.cx;let dy=u.cy-v.cy
  sqrt(dx*dx+dy*dy)-u.r-v.r>=c.sep*max(u.r,v.r)
proc crossNodes(c:var Ctx,a,b:int) =
  if separated(c,a,b):
    var u=c.nodes[a].rep;var v=c.nodes[b].rep;if u>v:swap(u,v)
    c.edges[2*c.ec]=float64(u);c.edges[2*c.ec+1]=float64(v);inc c.ec;return
  let u=c.nodes[a];let v=c.nodes[b]
  if u.left<0:crossNodes(c,v.left,a);crossNodes(c,v.right,a)
  elif v.left<0:crossNodes(c,u.left,b);crossNodes(c,u.right,b)
  elif u.span>v.span:crossNodes(c,u.left,b);crossNodes(c,u.right,b)
  else:crossNodes(c,a,v.left);crossNodes(c,a,v.right)
proc visit(c:var Ctx,at:int) =
  let n=c.nodes[at];if n.left<0:return
  visit(c,n.left);visit(c,n.right);crossNodes(c,n.left,n.right)
proc euclidean_t_spanner*(input:ptr UncheckedArray[float64],inputLength:csize_t,output:ptr UncheckedArray[float64],outputCapacity:csize_t):int64 {.cdecl,exportc:"euclidean_t_spanner".} =
  if input.isNil or inputLength<6 or inputLength>18:return -1
  let raw=input[0];let t=input[1]
  if raw<2 or raw>8 or raw!=floor(raw) or t<1.5 or t>4 or t.classify in {fcNan,fcInf,fcNegInf}:return -1
  let n=int(raw);if inputLength!=csize_t(2+2*n):return -1
  var c=Ctx(n:n,sep:4*(t+1)/(t-1))
  for i in 0..<n:
    let x=input[2+2*i];let y=input[3+2*i]
    if x.classify in {fcNan,fcInf,fcNegInf} or y.classify in {fcNan,fcInf,fcNegInf} or abs(x)>1000 or abs(y)>1000 or x!=floor(x) or y!=floor(y):return -1
    for j in 0..<i:if c.x[j]==x and c.y[j]==y:return -1
    c.x[i]=x;c.y[i]=y
  let root=build(c,(1'u64 shl n)-1);visit(c,root)
  let needed=1+2*c.ec
  if output.isNil or outputCapacity<csize_t(needed):return -2
  output[0]=float64(c.ec);for i in 0..<2*c.ec:output[i+1]=c.edges[i]
  int64(needed)
