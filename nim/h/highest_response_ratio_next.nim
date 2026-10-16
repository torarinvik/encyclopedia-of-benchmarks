proc put64(outp: ptr UncheckedArray[uint8], slot: int, value: int64) =
  var bits = cast[uint64](value)
  for b in 0 ..< 8:
    outp[slot * 8 + b] = uint8(bits and 255)
    bits = bits shr 8
proc highest_response_ratio_next*(v: ptr UncheckedArray[int64], n: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "highest_response_ratio_next".} =
  if v == nil or n < 3 or n > 129: return -1
  let count = v[0]
  if count < 1 or count > 64 or n != csize_t(1 + 2 * count): return -1
  var a, b, tat: array[64, int64]
  var done: array[64, bool]
  for i in 0 ..< int(count):
    a[i]=v[1+2*i]; b[i]=v[2+2*i]
    if a[i]<0 or a[i]>100000 or b[i]<1 or b[i]>1000:return -1
  for i in 1 ..< int(count):
    var j=i
    while j>0 and a[j]<a[j-1]:
      swap(a[j],a[j-1]); swap(b[j],b[j-1]); dec j
  if int(count)*8>int(capacity) or (count>0 and output==nil): return -2
  var now=0'i64; var finished=0
  while finished<int(count):
    var best = -1; var bestNum=0'i64
    for i in 0 ..< int(count):
      if not done[i] and a[i]<=now:
        let candidate=now-a[i]+b[i]
        if best<0 or candidate*b[best]>bestNum*b[i]: best=i;bestNum=candidate
    if best<0:
      for i in 0 ..< int(count):
        if not done[i] and (best<0 or a[i]<a[best]):best=i
      now=a[best]
    else:
      tat[best]=now+b[best]-a[best];now+=b[best];done[best]=true;inc finished
  for i in 0 ..< int(count):put64(output,i,tat[i])
  int64(count*8)
