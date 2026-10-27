const MaxFacets=16
const MaxVertices=12
proc putI64(output:ptr UncheckedArray[uint8],word:int,value:int64)=
  var bits=cast[uint64](value)
  for b in 0..<8:output[word*8+b]=uint8((bits shr (b*8)) and 255'u64)
proc triLess(a,b:array[3,int]):bool=
  for i in 0..<3:
    if a[i]<b[i]:return true
    if a[i]>b[i]:return false
  false
proc equalTri(a,b:array[3,int]):bool=a[0]==b[0] and a[1]==b[1] and a[2]==b[2]

proc crust_pole_triangle_filter*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"crust_pole_triangle_filter".}=
  if input==nil or length<3 or length>51:return -1
  let ns0=input[0];let np0=input[1];let nf0=input[2]
  if ns0<3 or ns0>8 or np0<1 or np0>4 or ns0+np0>MaxVertices or nf0<0 or nf0>MaxFacets or length!=csize_t(3+3*nf0):return -1
  let ns=int(ns0);let total=int(ns0+np0);let nf=int(nf0);var facets:array[MaxFacets,array[3,int]];var count=0
  for i in 0..<nf:
    var tri:array[3,int]=[int(input[3+3*i]),int(input[4+3*i]),int(input[5+3*i])]
    if tri[0]<0 or tri[0]>=total or tri[1]<0 or tri[1]>=total or tri[2]<0 or tri[2]>=total or tri[0]==tri[1] or tri[0]==tri[2] or tri[1]==tri[2]:return -1
    if tri[0]>=ns or tri[1]>=ns or tri[2]>=ns:continue
    for a in 1..<3:
      let x=tri[a];var j=a
      while j>0 and tri[j-1]>x:tri[j]=tri[j-1];dec j
      tri[j]=x
    var duplicate=false
    for j in 0..<count:if equalTri(tri,facets[j]):duplicate=true
    if not duplicate:facets[count]=tri;inc count
  for i in 1..<count:
    let x=facets[i];var j=i
    while j>0 and triLess(x,facets[j-1]):facets[j]=facets[j-1];dec j
    facets[j]=x
  let bytes=(1+3*count)*8
  if output==nil or capacity<csize_t(bytes):return -2
  putI64(output,0,int64(count));var at=1
  for i in 0..<count:
    for j in 0..<3:
      putI64(output,at,int64(facets[i][j]))
      inc at
  int64(bytes)
