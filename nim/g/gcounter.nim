proc hashValue(h0:uint64,value:int64):uint64=
  var h=h0
  let bits=cast[uint64](value)
  for i in 0..7:h=(h xor ((bits shr (8*i)) and 255'u64))*0x100000001b3'u64
  h
proc gcounter*(a:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"gcounter".}=
  if a==nil or n<2 or n>386 or a[0]<1 or a[0]>8 or a[1]<0 or a[1]>128 or n!=csize_t(2+3*a[1]):return -1
  let nodes=int(a[0])
  var s:array[8,array[8,int64]]
  var h=0xcbf29ce484222325'u64
  for i in 0..<int(a[1]):
    let op=a[2+3*i];let aa=a[3+3*i];let bb=a[4+3*i]
    if aa<0 or aa>=a[0]:return -1
    if op==0:
      if bb!=0 or s[aa][aa]>=1000000:return -1
      inc s[aa][aa]
    elif op==1:
      if bb!=0:return -1
      var total:int64=0
      for j in 0..<nodes:total+=s[aa][j]
      h=hashValue(h,total)
    elif op==2:
      if bb<0 or bb>=a[0]:return -1
      var yes=true
      for j in 0..<nodes:
        if s[aa][j]>s[bb][j]:yes=false
      h=hashValue(h,int64(ord(yes)))
    elif op==3:
      if bb<0 or bb>=a[0]:return -1
      for j in 0..<nodes:
        if s[bb][j]>s[aa][j]:s[aa][j]=s[bb][j]
    else:return -1
  for i in 0..<nodes:
    for j in 0..<nodes:h=hashValue(h,s[i][j])
  cast[int64](h)
