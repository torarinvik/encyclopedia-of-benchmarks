const MaxVertices=16
const MaxLevels=4
const MaxFaces=8
const MaxInput=268
type XY=array[MaxVertices*2,int64]

proc cross(ax,ay,bx,by,cx,cy:int64):int64=(bx-ax)*(cy-ay)-(by-ay)*(cx-ax)
proc onSegment(ax,ay,bx,by,px,py:int64):bool=
  cross(ax,ay,bx,by,px,py)==0 and px>=min(ax,bx) and px<=max(ax,bx) and py>=min(ay,by) and py<=max(ay,by)
proc inside(qx,qy,a,b,c:int64,xy:XY):bool=
  let aa=2*a;let bb=2*b;let cc=2*c
  cross(xy[aa],xy[aa+1],xy[bb],xy[bb+1],qx,qy)>0 and cross(xy[bb],xy[bb+1],xy[cc],xy[cc+1],qx,qy)>0 and cross(xy[cc],xy[cc+1],xy[aa],xy[aa+1],qx,qy)>0
proc boundary(qx,qy,a,b,c:int64,xy:XY):bool=
  let ids=[a,b,c]
  for e in 0..<3:
    let aa=2*ids[e];let bb=2*ids[(e+1) mod 3]
    if onSegment(xy[aa],xy[aa+1],xy[bb],xy[bb+1],qx,qy):return true
  false
proc segHit(ax,ay,bx,by,cx,cy,dx,dy:int64):bool=
  let o1=cross(ax,ay,bx,by,cx,cy);let o2=cross(ax,ay,bx,by,dx,dy)
  let o3=cross(cx,cy,dx,dy,ax,ay);let o4=cross(cx,cy,dx,dy,bx,by)
  if o1==0 and onSegment(ax,ay,bx,by,cx,cy):return true
  if o2==0 and onSegment(ax,ay,bx,by,dx,dy):return true
  if o3==0 and onSegment(cx,cy,dx,dy,ax,ay):return true
  if o4==0 and onSegment(cx,cy,dx,dy,bx,by):return true
  o1*o2<0 and o3*o4<0
proc closedInside(px,py,a,b,c:int64,xy:XY):bool=
  let ids=[a,b,c]
  for e in 0..<3:
    let aa=2*ids[e];let bb=2*ids[(e+1) mod 3]
    if cross(xy[aa],xy[aa+1],xy[bb],xy[bb+1],px,py)<0:return false
  true
proc triHit(a,b,c,d,e,f:int64,xy:XY):bool=
  let first=[a,b,c];let second=[d,e,f]
  for i in 0..<3:
    let p=2*first[i]
    if closedInside(xy[p],xy[p+1],d,e,f,xy):return true
    let q=2*second[i]
    if closedInside(xy[q],xy[q+1],a,b,c,xy):return true
  for i in 0..<3:
    for j in 0..<3:
      let a0=2*first[i];let a1=2*first[(i+1) mod 3]
      let b0=2*second[j];let b1=2*second[(j+1) mod 3]
      if segHit(xy[a0],xy[a0+1],xy[a1],xy[a1+1],xy[b0],xy[b0+1],xy[b1],xy[b1+1]):return true
  false
proc put64(outp:ptr UncheckedArray[uint8],pos:int,value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:outp[pos+j]=uint8((bits shr (8*j)) and 255)

proc kirkpatrick_hierarchical_point_location*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"kirkpatrick_hierarchical_point_location".}=
  if input.isNil or length<csize_t(14) or length>csize_t(MaxInput):return -1
  let nv64=input[0];let nl64=input[1];let qx=input[2];let qy=input[3]
  if nv64<3 or nv64>MaxVertices or nl64<1 or nl64>MaxLevels or qx< -1000 or qx>1000 or qy< -1000 or qy>1000:return -1
  let nv=int(nv64);let nl=int(nl64)
  var xy:XY
  var faces:array[MaxLevels*MaxFaces*3,int64]
  var faceCount:array[MaxLevels,int]
  var candidateCount:array[MaxLevels*MaxFaces,int]
  var candidateIds:array[MaxLevels*MaxFaces*MaxFaces,int]
  var pos=4
  for v in 0..<nv:
    xy[2*v]=input[pos];xy[2*v+1]=input[pos+1];pos+=2
    if xy[2*v]< -1000 or xy[2*v]>1000 or xy[2*v+1]< -1000 or xy[2*v+1]>1000:return -1
  for level in 0..<nl:
    if pos>=int(length):return -1
    let count64=input[pos];inc pos
    if count64<1 or count64>MaxFaces or (level==0 and count64!=1):return -1
    let count=int(count64);faceCount[level]=count
    for f in 0..<count:
      if pos+3>int(length):return -1
      let base=(level*MaxFaces+f)*3
      for k in 0..<3:
        faces[base+k]=input[pos];inc pos
        if faces[base+k]<0 or faces[base+k]>=nv64:return -1
      let a=faces[base];let b=faces[base+1];let c=faces[base+2]
      if a==b or a==c or b==c:return -1
      let aa=2*a;let bb=2*b;let cc=2*c
      if cross(xy[aa],xy[aa+1],xy[bb],xy[bb+1],xy[cc],xy[cc+1])<=0:return -1
    if level+1<nl:
      for f in 0..<count:
        if pos>=int(length):return -1
        let n64=input[pos];inc pos
        if n64<1 or n64>MaxFaces or pos+int(n64)>int(length):return -1
        let n=int(n64);candidateCount[level*MaxFaces+f]=n
        for j in 0..<n:
          let child64=input[pos];inc pos
          if child64<0 or child64>=MaxFaces:return -1
          let child=int(child64);let slot=(level*MaxFaces+f)*MaxFaces+j
          if j>0 and child<=candidateIds[slot-1]:return -1
          candidateIds[slot]=child
  if pos!=int(length):return -1
  for level in 0..<(nl-1):
    for f in 0..<faceCount[level]:
      for j in 0..<candidateCount[level*MaxFaces+f]:
        let child=candidateIds[(level*MaxFaces+f)*MaxFaces+j]
        if child>=faceCount[level+1]:return -1
        let a=(level*MaxFaces+f)*3;let b=((level+1)*MaxFaces+child)*3
        if not triHit(faces[a],faces[a+1],faces[a+2],faces[b],faces[b+1],faces[b+2],xy):return -1
  for level in 0..<nl:
    var hits=0
    for f in 0..<faceCount[level]:
      let base=(level*MaxFaces+f)*3
      if boundary(qx,qy,faces[base],faces[base+1],faces[base+2],xy):return -1
      if inside(qx,qy,faces[base],faces[base+1],faces[base+2],xy):inc hits
    if hits!=1:return -1
  var face=0;var predicates=1'i64
  for level in 0..<(nl-1):
    var found= -1
    for j in 0..<candidateCount[level*MaxFaces+face]:
      let child=candidateIds[(level*MaxFaces+face)*MaxFaces+j];inc predicates
      let base=((level+1)*MaxFaces+child)*3
      if inside(qx,qy,faces[base],faces[base+1],faces[base+2],xy):found=child;break
    if found<0:return -1
    face=found
  if output.isNil or capacity<csize_t(16):return -2
  var staged:array[16,uint8]
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),0,int64(face))
  put64(cast[ptr UncheckedArray[uint8]](addr staged[0]),8,predicates)
  for i in 0..<16:output[i]=staged[i]
  16
