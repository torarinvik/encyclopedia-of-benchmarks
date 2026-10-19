const NMax = 8
const Cells = NMax*NMax
const MaxAdjust = 2048
proc firstAssignments(a: var array[Cells,int64], mark: var array[Cells,uint8], n:int): int =
  for x in 0 ..< n*n: mark[x]=0
  var total=0
  while true:
    var made=0
    for i in 0 ..< n:
      var count=0;var selected=0
      for j in 0 ..< n:
        if a[i*n+j]==0 and mark[i*n+j]==0: inc count;selected=j
      if count==1:
        inc made;inc total;mark[i*n+selected]=1
        for k in 0 ..< n:
          if k!=i and a[k*n+selected]==0:mark[k*n+selected]=2
    for j in 0 ..< n:
      var count=0;var selected=0
      for i in 0 ..< n:
        if a[i*n+j]==0 and mark[i*n+j]==0:inc count;selected=i
      if count==1:
        inc made;inc total;mark[selected*n+j]=1
        for k in 0 ..< n:
          if k!=j and a[selected*n+k]==0:mark[selected*n+k]=2
    if made==0:break
  if total==n:return total
  for i in 0 ..< n:
    var selected=n
    for j in 0 ..< n:
      if a[i*n+j]==0 and mark[i*n+j]==0:selected=j;break
    if selected<n:
      mark[i*n+selected]=1;inc total
      for k in 0 ..< n:
        if k!=selected and a[i*n+k]==0:mark[i*n+k]=2
      for k in 0 ..< n:
        if k!=i and a[k*n+selected]==0:mark[k*n+selected]=2
  total
proc secondAssignments(a: var array[Cells,int64],mark: array[Cells,uint8],n:int): bool =
  var rows: array[NMax,uint8];var cols: array[NMax,uint8]
  for i in 0 ..< n:
    var has=false
    for j in 0 ..< n:
      if mark[i*n+j]==1:has=true;break
    rows[i]=if has:0 else:1
  while true:
    var newRows=0
    for i in 0 ..< n:
      if rows[i]==1:
        for j in 0 ..< n:
          if a[i*n+j]==0:cols[j]=1
    for j in 0 ..< n:
      if cols[j]==1:
        for i in 0 ..< n:
          if mark[i*n+j]==1 and rows[i]!=1:rows[i]=1;inc newRows
    if newRows==0:break
  var smallest=high(int64)
  for i in 0 ..< n:
    if rows[i]==1:
      for j in 0 ..< n:
        if cols[j]==0 and a[i*n+j]<smallest:smallest=a[i*n+j]
  if smallest==high(int64):return false
  for i in 0 ..< n:
    for j in 0 ..< n:
      if rows[i]==1 and cols[j]==0:a[i*n+j]-=smallest
      elif rows[i]==0 and cols[j]==1:a[i*n+j]+=smallest
  true
proc nbench_resource_assignment*(values:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"nbench_resource_assignment".}=
  if values==nil or length<2 or length>csize_t(Cells+2):return -1
  let rawN=values[0]
  if rawN<1 or rawN>NMax:return -1
  let n=int(rawN)
  if length!=csize_t(1+n*n):return -1
  var a:array[Cells,int64]
  for i in 0 ..< n*n:
    if values[i+1]<0 or values[i+1]>1000:return -1
    a[i]=values[i+1]
  for i in 0 ..< n:
    var m=a[i*n]
    for j in 1 ..< n:m=min(m,a[i*n+j])
    for j in 0 ..< n:a[i*n+j]-=m
  for j in 0 ..< n:
    var m=a[j]
    for i in 1 ..< n:m=min(m,a[i*n+j])
    if m!=0:
      for i in 0 ..< n:a[i*n+j]-=m
  var mark:array[Cells,uint8]
  var done=false
  for _ in 0 .. MaxAdjust:
    if firstAssignments(a,mark,n)==n:done=true;break
    if not secondAssignments(a,mark,n):return -1
  if not done:return -1
  var assignments:array[NMax,int32]
  var seen:array[NMax,bool]
  for i in 0 ..< n:
    var col=n
    for j in 0 ..< n:
      if mark[i*n+j]==1:
        if col!=n:return -1
        col=j
    if col==n or seen[col]:return -1
    assignments[i]=int32(col);seen[col]=true
  let byteCount=n*4
  if output==nil or capacity<csize_t(byteCount):return -2
  for i in 0 ..< n:
    let x=cast[uint32](assignments[i])
    for b in 0 ..< 4:output[4*i+b]=uint8((x shr (8*b)) and 255)
  int64(byteCount)
