proc jaro_similarity*(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"jaro_similarity".} =
  if v.isNil or n<2 or n>66:return -1.0e300
  if v[0]<0 or v[0]>32:return -1.0e300
  let n1=int(v[0]);let p=1+n1
  if p>=int(n):return -1.0e300
  if v[p]<0 or v[p]>32 or n1<int(v[p]) or n!=csize_t(p+1+int(v[p])):return -1.0e300
  let n2=int(v[p])
  for i in 0..<n1:if v[1+i]<0 or v[1+i]>127:return -1.0e300
  for i in 0..<n2:if v[p+1+i]<0 or v[p+1+i]>127:return -1.0e300
  var equal=n1==n2
  for i in 0..<n1:if v[1+i]!=v[p+1+i]:equal=false
  if equal:return 1.0
  if n2==0:return 0.0
  let radius=max(n1 div 2-1,0)
  var m1,m2:array[32,bool]
  var matches=0
  for i in 0..<n1:
    let start=max(i-radius,0);let finish=min(i+radius,n2-1)
    if start<=finish:
      for j in start..finish:
        if v[1+i]==v[p+1+j] and not m2[j]:matches+=1;m1[i]=true;m2[j]=true;break
  if matches==0:return 0.0
  var trans=0;var j=0
  for i in 0..<n1:
    if m1[i]:
      while not m2[j]:inc j
      if v[1+i]!=v[p+1+j]:inc trans
      inc j
  trans=trans div 2
  ((float64(matches)/float64(n1))+(float64(matches)/float64(n2))+(float64(matches-trans)/float64(matches)))/3.0
