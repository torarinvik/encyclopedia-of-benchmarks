proc tswCross(ax, ay, bx, by, px, py: int64): int64 {.inline.} =
  (bx-ax)*(py-ay)-(by-ay)*(px-ax)

proc tswSame(a, b, c, d: int): bool {.inline.} =
  (a == c and b == d) or (a == d and b == c)

proc tswOn(ax, ay, bx, by, px, py: int64): bool {.inline.} =
  tswCross(ax,ay,bx,by,px,py)==0 and px>=min(ax,bx) and px<=max(ax,bx) and py>=min(ay,by) and py<=max(ay,by)

proc tswIntersect(ax, ay, bx, by, cx, cy, dx, dy: int64): bool {.inline.} =
  let o1=tswCross(ax,ay,bx,by,cx,cy);let o2=tswCross(ax,ay,bx,by,dx,dy)
  let o3=tswCross(cx,cy,dx,dy,ax,ay);let o4=tswCross(cx,cy,dx,dy,bx,by)
  if (o1==0 and tswOn(ax,ay,bx,by,cx,cy)) or (o2==0 and tswOn(ax,ay,bx,by,dx,dy)) or (o3==0 and tswOn(cx,cy,dx,dy,ax,ay)) or (o4==0 and tswOn(cx,cy,dx,dy,bx,by)): return true
  ((o1<0 and o2>0) or (o1>0 and o2<0)) and ((o3<0 and o4>0) or (o3>0 and o4<0))

proc triangulation_stochastic_visibility_walk*(values: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "triangulation_stochastic_visibility_walk".} =
  if values == nil or length < 8 or length > 57: return -1
  let vr=values[0];let br=values[1];let tr=values[2];let sr=values[3]
  let px=values[4];let py=values[5];let capr=values[6];let kr=values[7]
  if vr<3 or vr>6 or br<3 or br>vr or tr!=2*vr-br-2 or tr<1 or tr>7 or sr<0 or sr>=tr or capr<0 or capr>12 or kr<0 or kr>12 or px< -200 or px>200 or py< -200 or py>200: return -1
  let v=int(vr);let bcount=int(br);let tcount=int(tr);let start=int(sr);let cap=int(capr);let k=int(kr)
  if int(length)!=8+2*v+bcount+3*tcount+k: return -1
  var xs: array[6,int64];var ys: array[6,int64]
  var boundary: array[6,int];var faces: array[21,int];var neighbors: array[21,int];var used: array[6,bool]
  var cursor=8
  for i in 0..<v:
    xs[i]=values[cursor];ys[i]=values[cursor+1];cursor+=2
    if xs[i]< -200 or xs[i]>200 or ys[i]< -200 or ys[i]>200: return -1
    for j in 0..<i:
      if xs[i]==xs[j] and ys[i]==ys[j]:return -1
  for i in 0..<bcount:
    let raw=values[cursor];cursor+=1
    if raw<0 or raw>=vr:return -1
    boundary[i]=int(raw)
    for j in 0..<i:if boundary[i]==boundary[j]:return -1
  for i in 0..<bcount:
    let a=boundary[i];let b=boundary[(i+1) mod bcount]
    for j in 0..<bcount:
      let c=boundary[j]
      if c!=a and c!=b and tswCross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0:return -1
  for p in 0..<v:
    var onBoundary=false
    for j in 0..<bcount:if boundary[j]==p:onBoundary=true
    if not onBoundary:
      for j in 0..<bcount:
        let a=boundary[j];let b=boundary[(j+1) mod bcount]
        if tswCross(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p])<=0:return -1
  var areaSum=0'i64
  for f in 0..<tcount:
    for e in 0..<3:
      let raw=values[cursor];cursor+=1
      if raw<0 or raw>=vr:return -1
      faces[f*3+e]=int(raw)
    let a=faces[f*3];let b=faces[f*3+1];let c=faces[f*3+2]
    if a==b or b==c or c==a or tswCross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])<=0:return -1
    used[a]=true;used[b]=true;used[c]=true
    areaSum+=tswCross(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c])
    for g in 0..<f:
      var same=true
      for e in 0..<3:
        var found=false
        for j in 0..<3:if faces[f*3+e]==faces[g*3+j]:found=true
        if not found:same=false
      if same:return -1
    for e in 0..<3:neighbors[f*3+e]= -1
  for i in 0..<v:if not used[i]:return -1
  var polygonArea=0'i64
  for i in 0..<bcount:
    let a=boundary[i];let b=boundary[(i+1) mod bcount]
    polygonArea+=xs[a]*ys[b]-ys[a]*xs[b]
  if polygonArea<=0 or polygonArea!=areaSum:return -1
  for i in 0..<bcount:
    let a=boundary[i];let b=boundary[(i+1) mod bcount];var owners=0
    for f in 0..<tcount:
      for e in 0..<3:if tswSame(a,b,faces[f*3+e],faces[f*3+(e+1) mod 3]):owners+=1
    if owners!=1:return -1
  for f in 0..<tcount:
    for e in 0..<3:
      let a=faces[f*3+e];let b=faces[f*3+(e+1) mod 3]
      var first=true
      for g in 0..f:
        for ge in 0..<3:
          if g==f and ge>=e:continue
          if tswSame(a,b,faces[g*3+ge],faces[g*3+(ge+1) mod 3]):first=false
      if first:
        for p in 0..<v:
          if p!=a and p!=b and tswOn(xs[a],ys[a],xs[b],ys[b],xs[p],ys[p]):return -1
        for g in f..<tcount:
          for ge in 0..<3:
            if g==f and ge<=e:continue
            let c=faces[g*3+ge];let d=faces[g*3+(ge+1) mod 3]
            if a==c or a==d or b==c or b==d:continue
            if tswIntersect(xs[a],ys[a],xs[b],ys[b],xs[c],ys[c],xs[d],ys[d]):return -1
  for f in 0..<tcount:
    for e in 0..<3:
      let a=faces[f*3+e];let b=faces[f*3+(e+1) mod 3]
      var boundaryEdge=false
      for i in 0..<bcount:if tswSame(a,b,boundary[i],boundary[(i+1) mod bcount]):boundaryEdge=true
      var owners=0;var other= -1;var firstU= -1;var firstV= -1
      for g in 0..<tcount:
        for ge in 0..<3:
          if tswSame(a,b,faces[g*3+ge],faces[g*3+(ge+1) mod 3]):
            if owners==0:firstU=faces[g*3+ge];firstV=faces[g*3+(ge+1) mod 3]
            elif faces[g*3+ge]!=firstV or faces[g*3+(ge+1) mod 3]!=firstU:return -1
            owners+=1
            if g!=f:other=g
      if owners!=(if boundaryEdge:1 else:2):return -1
      if not boundaryEdge:neighbors[f*3+e]=other
  for i in 0..<k:if values[cursor+i]<0 or values[cursor+i]>1:return -1
  for i in 0..<bcount:
    let a=boundary[i];let b=boundary[(i+1) mod bcount]
    if tswCross(xs[a],ys[a],xs[b],ys[b],px,py)<=0:return -1
  var containing=0
  for f in 0..<tcount:
    let a=faces[f*3];let b=faces[f*3+1];let c=faces[f*3+2]
    if tswCross(xs[a],ys[a],xs[b],ys[b],px,py)>0 and tswCross(xs[b],ys[b],xs[c],ys[c],px,py)>0 and tswCross(xs[c],ys[c],xs[a],ys[a],px,py)>0:containing+=1
  if containing!=1:return -1
  var face=start;var steps=0;var choiceIndex=0;var trace=int64(face+1);var predicates=0'i64;var status=0'i64
  while true:
    let a=faces[face*3];let b=faces[face*3+1];let c=faces[face*3+2]
    let eu=[a,b,c];let ev=[b,c,a];var eligible:array[3,int];var count=0
    for e in 0..<3:
      predicates+=1
      if tswCross(xs[eu[e]],ys[eu[e]],xs[ev[e]],ys[ev[e]],px,py)<0:eligible[count]=e;count+=1
    if count==0:status=0;break
    if steps==cap:status=2;break
    var selected=0
    if count==1:selected=eligible[0]
    elif count==2:
      if choiceIndex==k:status=1;break
      selected=eligible[int(values[cursor+choiceIndex])];choiceIndex+=1
    else:return -1
    if neighbors[face*3+selected]<0:return -1
    face=neighbors[face*3+selected]
    steps+=1;trace=trace*9+int64(face+1)
  (trace*40+predicates)*3+status
