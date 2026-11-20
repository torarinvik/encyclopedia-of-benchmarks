const MaxEdges = 8
const MaxCells = 46
const MaxDepth = 4
const MaxWords = 127

type
  Cell = object
    depth, prefix, lo, altLo: int
    x0, y0, x1, y1: int
    endpoints: int
  Edge = object
    x0, y0, x1, y1: int
    startCell, endCell: int
    negative: bool
  Point = object
    x, y: int
  Exit = object
    edge, side: int
    num, den: int64
  Cells = array[MaxCells, Cell]
  Edges = array[MaxEdges, Edge]
  Points = array[33, Point]
  EndpointCells = array[MaxEdges, array[2, int]]
  Masks = array[MaxCells, uint64]

proc orient(a, b, c: Point): int64 =
  int64(b.x - a.x) * int64(c.y - a.y) - int64(b.y - a.y) * int64(c.x - a.x)
proc onSegment(a, b, p: Point): bool =
  p.x >= min(a.x,b.x) and p.x <= max(a.x,b.x) and p.y >= min(a.y,b.y) and p.y <= max(a.y,b.y)
proc intersects(a,b,c,d: Point): bool =
  let o1=orient(a,b,c);let o2=orient(a,b,d);let o3=orient(c,d,a);let o4=orient(c,d,b)
  if (o1==0 and onSegment(a,b,c)) or (o2==0 and onSegment(a,b,d)) or (o3==0 and onSegment(c,d,a)) or (o4==0 and onSegment(c,d,b)): return true
  o1*o2<0 and o3*o4<0
proc positiveKey(x,y:int): int =
  var key=0
  for bit in countdown(7,4): key=(key shl 2) or (((x shr bit) and 1) shl 1) or ((y shr bit) and 1)
  key
proc remap(q:int): int = [2,0,3,1][q]
proc altPrefix(depth,prefix:int): int =
  var result=0
  if depth>0:
    var shift=2*(depth-1)
    while shift>=0:
      result=(result shl 2) or remap((prefix shr shift) and 3)
      shift-=2
  result
proc makeBox(c: var Cell) =
  var x=0;var y=0
  if c.depth>0:
    var shift=2*(c.depth-1)
    while shift>=0:
      let q=(c.prefix shr shift) and 3;x=(x shl 1) or (q shr 1);y=(y shl 1) or (q and 1)
      shift-=2
  let side=256 shr c.depth;c.x0=x*side;c.y0=y*side;c.x1=c.x0+side;c.y1=c.y0+side
proc findCell(cells: var Cells,c,key:int): int =
  for i in 0..<c:
    let span=1 shl (2*(MaxDepth-cells[i].depth))
    if key>=cells[i].lo and key<cells[i].lo+span:return i
  -1
proc sweepBox(cell: Cell,rotated:bool): array[4,int] =
  if rotated: [256-cell.y1,cell.x0,256-cell.y0,cell.x1] else: [cell.x0,cell.y0,cell.x1,cell.y1]
proc sweepEdge(e: Edge,rotated:bool): array[2,Point] =
  if rotated: [Point(x:256-e.y0,y:e.x0),Point(x:256-e.y1,y:e.x1)] else: [Point(x:e.x0,y:e.y0),Point(x:e.x1,y:e.y1)]
proc segmentBox(e:Edge,cell:Cell,rotated:bool):bool =
  let box=sweepBox(cell,rotated);let ab=sweepEdge(e,rotated);let a=ab[0];let b=ab[1]
  if (a.x>=box[0] and a.x<=box[2] and a.y>=box[1] and a.y<=box[3]) or (b.x>=box[0] and b.x<=box[2] and b.y>=box[1] and b.y<=box[3]):return true
  let corners=[Point(x:box[0],y:box[1]),Point(x:box[2],y:box[1]),Point(x:box[2],y:box[3]),Point(x:box[0],y:box[3])]
  for i in 0..<4:if intersects(a,b,corners[i],corners[(i+1) and 3]):return true
  false
proc append(path: var Points,n:var int,p:Point):bool =
  if n>0 and path[n-1].x==p.x and path[n-1].y==p.y:return true
  if n>=33:return false
  path[n]=p;inc n;true
proc buildFrontier(cells:var Cells,c:int,order:var array[MaxCells,int],cut:int,rotated:bool,path:var Points,pathN:var int,corner:var int):bool =
  var rank:array[MaxCells,int];for i in 0..<c:rank[order[i]]=i
  var atom:array[256,int];for i in 0..<256:atom[i]= -1
  for pos in 0..<c:
    let id=order[pos];let start=if rotated:cells[id].altLo else:cells[id].lo;let span=1 shl (2*(MaxDepth-cells[id].depth))
    for k in start..<start+span:atom[k]=id
  var processed:array[16,array[16,bool]]
  for key in 0..<256:
    let id=atom[key];if id<0:return false
    var x=0;var y=0
    for shift in [6,4,2,0]:
      let q=(key shr shift) and 3;x=(x shl 1) or (q shr 1);y=(y shl 1) or (q and 1)
    processed[x][y]=rank[id]<cut
  var h:array[16,int]
  for x in 0..<16:
    var v=0;while v<16 and processed[x][v]:inc v
    for y in 0..<16:if processed[x][y]!=(y<v):return false
    h[x]=v;if x>0 and h[x-1]<v:return false
  pathN=0;if not append(path,pathN,Point(x:0,y:256)):return false
  for y in countdown(15,h[0]):if not append(path,pathN,Point(x:0,y:y*16)):return false
  for x in 0..<16:
    if not append(path,pathN,Point(x:(x+1)*16,y:h[x]*16)):return false
    let next=if x<15:h[x+1] else:0
    for y in countdown(h[x]-1,next):if not append(path,pathN,Point(x:(x+1)*16,y:y*16)):return false
  if path[0].x!=0 or path[0].y!=256 or path[pathN-1].x!=256 or path[pathN-1].y!=0:return false
  let box=sweepBox(cells[order[cut]],rotated)
  for i in 0..<pathN:if path[i].x==box[0] and path[i].y==box[1]:corner=i;return true
  false
proc frontierSegment(a,b:Point,path:var Points,n:int):int =
  var found= -1
  for i in 0..<n-1:if intersects(a,b,path[i],path[i+1]):if found>=0:return -2;found=i
  found
proc exitForCell(a,b:Point,box:array[4,int],id:int,outp:var Exit):bool =
  let dx=int64(b.x-a.x);let dy=int64(b.y-a.y);var found=0
  if dy>0:
    let yd=int64(box[3]-a.y);let num=int64(a.x)*dy+yd*dx
    if yd>0 and yd<dy and int64(box[0])*dy<num and num<int64(box[2])*dy:outp=Exit(edge:id,side:0,num:num,den:dy);inc found
  if dx>0:
    let xd=int64(box[2]-a.x);let num=int64(a.y)*dx+xd*dy
    if xd>0 and xd<dx and int64(box[1])*dx<num and num<int64(box[3])*dx:outp=Exit(edge:id,side:1,num:num,den:dx);inc found
  found==1
proc exitLess(a,b:Exit):bool = a.num*b.den<b.num*a.den or (a.num*b.den==b.num*a.den and a.edge<b.edge)
proc runSweep(cells:var Cells,c:int,edges:var Edges,n:int,endpoints:var EndpointCells,rotated:bool,masks:var Masks):bool =
  var order:array[MaxCells,int];for i in 0..<c:order[i]=i
  if rotated:
    for i in 1..<c:
      let v=order[i];var j=i
      while j>0 and cells[order[j-1]].altLo>cells[v].altLo:order[j]=order[j-1];dec j
      order[j]=v
  var ea:array[MaxEdges,Point];var eb:array[MaxEdges,Point];var ids:array[MaxEdges,int];var keys:array[MaxEdges,int];var m=0
  for id in 0..<n:if edges[id].negative==rotated:
    let ab=sweepEdge(edges[id],rotated);ea[id]=ab[0];eb[id]=ab[1];let key=positiveKey(ea[id].x,ea[id].y);var j=m;inc m
    while j>0 and (keys[j-1]>key or (keys[j-1]==key and ids[j-1]>id)):keys[j]=keys[j-1];ids[j]=ids[j-1];dec j
    keys[j]=key;ids[j]=id
  var sl:array[MaxEdges,int];var sb:array[MaxEdges,int];var sln=0;var sbn=0
  for pos in 0..<c:
    let cid=order[pos];let box=sweepBox(cells[cid],rotated);var candidates:array[16,int];var cn=0
    while sln>0 and segmentBox(edges[sl[sln-1]],cells[cid],rotated):dec sln;candidates[cn]=sl[sln];inc cn
    while sbn>0 and segmentBox(edges[sb[sbn-1]],cells[cid],rotated):dec sbn;candidates[cn]=sb[sbn];inc cn
    for q in 0..<m:let id=ids[q];if endpoints[id][0]==cid:candidates[cn]=id;inc cn
    var exits:array[16,Exit];var en=0
    for q in 0..<cn:
      let id=candidates[q];masks[cid]=masks[cid] or (1'u64 shl id);if endpoints[id][1]==cid:continue
      if not exitForCell(ea[id],eb[id],box,id,exits[en]):return false
      inc en
    for i in 1..<en:
      let v=exits[i];var j=i
      while j>0 and (exits[j-1].side>v.side or (exits[j-1].side==v.side and exitLess(v,exits[j-1]))):exits[j]=exits[j-1];dec j
      exits[j]=v
    for i in 0..<en:if exits[i].side==0:if sln>=MaxEdges:return false;sl[sln]=exits[i].edge;inc sln else:if sbn>=MaxEdges:return false;sb[sbn]=exits[i].edge;inc sbn
    if pos+1==c:continue
    var path:Points;var pn=0;var corner=0;if not buildFrontier(cells,c,order,pos+1,rotated,path,pn,corner):return false
    let nb=sweepBox(cells[order[pos+1]],rotated)
    if nb[1]>box[1]:
      while sln>0:
        let id=sl[sln-1];let where=frontierSegment(ea[id],eb[id],path,pn);if where<0:return false;if where<corner:break
        if sbn>=MaxEdges:return false;sb[sbn]=sl[sln-1];inc sbn;dec sln
    else:
      while sbn>0:
        let id=sb[sbn-1];let where=frontierSegment(ea[id],eb[id],path,pn);if where<0:return false;if where>=corner:break
        if sln>=MaxEdges:return false;sl[sln]=sb[sbn-1];inc sln;dec sbn
  sln==0 and sbn==0

proc putI64Le(output: ptr UncheckedArray[uint8],at:int,value:int64) =
  let bits=cast[uint64](value);for b in 0..<8:output[at+b]=uint8((bits shr (8*b)) and 255'u64)

proc k_quadtree_edge_distribution*(input: ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"k_quadtree_edge_distribution".} =
  if input.isNil or length<2 or length>MaxWords:return -1
  let nv=input[0];let cv=input[1];if nv<0 or nv>8 or cv<1 or cv>46:return -1
  let n=int(nv);let c=int(cv);if int(length)!=2+2*c+4*n:return -1
  var cells:Cells;var edges:Edges;var endpoints:EndpointCells;var at=2;var previous=0
  for i in 0..<c:
    let d=int(input[at]);let p=int(input[at+1]);at+=2;if d<0 or d>MaxDepth or p<0 or p>=(1 shl (2*d)):return -1
    cells[i].depth=d;cells[i].prefix=p;let span=1 shl (2*(MaxDepth-d));cells[i].lo=p*span;if cells[i].lo!=previous:return -1;previous=cells[i].lo+span;makeBox(cells[i])
  if previous!=256 or (n==0 and (c!=1 or cells[0].depth!=0 or cells[0].prefix!=0)):return -1
  for i in 0..<c:cells[i].altLo=altPrefix(cells[i].depth,cells[i].prefix) shl (2*(MaxDepth-cells[i].depth))
  var pts:array[16,Point]
  for i in 0..<n:
    var x0=input[at];var y0=input[at+1];var x1=input[at+2];var y1=input[at+3];at+=4
    if x0<0 or x0>255 or y0<0 or y0>255 or x1<0 or x1>255 or y1<0 or y1>255 or x0 mod 16==0 or y0 mod 16==0 or x1 mod 16==0 or y1 mod 16==0:return -1
    if (x0==x1 and y0==y1) or y0==y1:return -1
    if x0>x1 or (x0==x1 and y0>y1):swap(x0,x1);swap(y0,y1)
    if x0==x1 and y1<=y0:return -1
    edges[i]=Edge(x0:int(x0),y0:int(y0),x1:int(x1),y1:int(y1),negative:y1<y0)
    pts[2*i]=Point(x:int(x0),y:int(y0));pts[2*i+1]=Point(x:int(x1),y:int(y1))
    for gx in countup(0,256,16):for gy in countup(0,256,16):let p=Point(x:gx,y:gy);if orient(pts[2*i],pts[2*i+1],p)==0 and onSegment(pts[2*i],pts[2*i+1],p):return -1
    for j in 0..<2*i:if pts[j].x==int(x0) and pts[j].y==int(y0):return -1
    for j in 0..<2*i+1:if pts[j].x==int(x1) and pts[j].y==int(y1):return -1
    for j in 0..<i:if intersects(pts[2*i],pts[2*i+1],pts[2*j],pts[2*j+1]):return -1
    let a=findCell(cells,c,positiveKey(int(x0),int(y0)));let b=findCell(cells,c,positiveKey(int(x1),int(y1)));if a<0 or b<0:return -1
    endpoints[i]=[a,b];edges[i].startCell=a;edges[i].endCell=b;inc cells[a].endpoints;inc cells[b].endpoints
  for i in 0..<c:if cells[i].endpoints>1:return -1
  var pd:array[85,int];var pp:array[85,int];var pc=0
  for i in 0..<c:for d in 0..<cells[i].depth:let p=cells[i].prefix shr (2*(cells[i].depth-d));var found=false;for q in 0..<pc:if pd[q]==d and pp[q]==p:found=true;if not found:pd[pc]=d;pp[pc]=p;inc pc
  for q in 0..<pc:
    var occupied:uint32=0
    for i in 0..<c:
      if cells[i].endpoints==0 or cells[i].depth<=pd[q]:continue
      if (cells[i].prefix shr (2*(cells[i].depth-pd[q])))==pp[q]:occupied=occupied or (1'u32 shl ((cells[i].prefix shr (2*(cells[i].depth-pd[q]-1))) and 3))
    if occupied==0 or (occupied and (occupied-1))==0:return -1
  for i in 0..<n:for dir in 0..1:let rotated=dir==1;if edges[i].negative!=rotated:continue;var order:array[MaxCells,int];for j in 0..<c:order[j]=j;if rotated:for a in 1..<c:let v=order[a];var j=a;while j>0 and cells[order[j-1]].altLo>cells[v].altLo:order[j]=order[j-1];dec j;order[j]=v;var rs=0;var re=0;for j in 0..<c:if order[j]==endpoints[i][0]:rs=j;if order[j]==endpoints[i][1]:re=j;if rs>re:return -1
  var masks:Masks
  if not runSweep(cells,c,edges,n,endpoints,false,masks) or not runSweep(cells,c,edges,n,endpoints,true,masks):return -1
  let bytes=8*(1+c);if output.isNil or capacity<csize_t(bytes):return -2
  putI64Le(output,0,int64(c));for i in 0..<c:putI64Le(output,8*(i+1),int64(masks[i]))
  int64(bytes)
