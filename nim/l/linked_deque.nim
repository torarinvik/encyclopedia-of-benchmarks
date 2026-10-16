proc linked_deque*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "linked_deque".} =
  if v.isNil or n<2 or n>20 or n mod 2!=0:return -1
  var q:array[40,int64]
  var h=16'i64;var t=16'i64;var outv=0'i64;var place=1'i64
  for p in countup(0,int(n)-1,2):
    let op=v[p];let a=v[p+1]
    if op<0 or op>6:return -1
    if op<2:
      if a< -15 or a>15:return -1
      if op==0:h-=1;q[int(h)]=a
      else:q[int(t)]=a;t+=1
      continue
    if a!=0:return -1
    var d=0'i64
    if op==2:
      if h<t:d=q[int(h)]+16;h+=1
    elif op==3:
      if h<t:t-=1;d=q[int(t)]+16
    elif op==4:
      if h<t:d=q[int(h)]+16
    elif op==5:
      if h<t:d=q[int(t-1)]+16
    else:
      if h==t:d=1 else:d=2
    outv+=d*place;place*=32
  outv
