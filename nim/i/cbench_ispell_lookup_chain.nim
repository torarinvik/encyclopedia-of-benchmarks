const MaxM=8
const MaxE=8

proc ihash(a: ptr UncheckedArray[int64], start, size, modulus: int): int =
  var h=0'u32
  let first=min(size,4)
  for i in 0..<first: h=(h shl 8) or uint32(a[start+i]-32)
  for i in first..<size: h=((h shl 5) or (h shr 27)) xor uint32(a[start+i]-32)
  int(h mod uint32(modulus))

proc cbench_ispell_lookup_chain(input: ptr UncheckedArray[int64], length: int): int64 {.exportc.} =
  if input.isNil or length<3 or length>108: return -1
  if input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8 or input[2]<0 or input[2]>8: return -1
  let m=int(input[0]);let q=int(input[1]);let n=int(input[2])
  if length<3+q+m+2*n:return -1
  let h0=3+q;let nx0=h0+m;let l0=nx0+n;var p=l0+n
  for j in 0..<q:if input[3+j]<97 or input[3+j]>122:return -1
  var heads,next:array[MaxE,int64]
  var lens,offs:array[MaxE,int]
  for b in 0..<m:heads[b]=input[h0+b];if heads[b]< -1 or heads[b]>=int64(n):return -1
  for i in 0..<n:
    next[i]=input[nx0+i]
    if next[i]< -1 or next[i]>=int64(n) or input[l0+i]<1 or input[l0+i]>8:return -1
    lens[i]=int(input[l0+i]);if p+lens[i]>length:return -1;offs[i]=p
    for j in 0..<lens[i]:if input[p+j]<97 or input[p+j]>122:return -1
    p+=lens[i]
  if p!=length:return -1
  var seen:array[MaxE,bool];var count=0
  for b in 0..<m:
    var x=heads[b]
    while x != -1:
      let i=int(x);if seen[i]:return -1;seen[i]=true;inc count
      if ihash(input,offs[i],lens[i],m)!=b:return -1
      x=next[i]
  if count!=n:return -1
  let b=ihash(input,3,q,m);var x=heads[b]
  while x != -1:
    let i=int(x)
    if lens[i]==q:
      var j=0;while j<q and input[offs[i]+j]==input[3+j]:inc j
      if j==q:return int64(i+1)
    x=next[i]
  0
