## Three-sample Hampel filter using the Java default threshold 3.0.
proc median(a: array[3,float64], size: int): float64 =
  let m=size div 2
  if size mod 2 == 1: return a[m]
  0.5*(a[m-1]+a[m])
proc mad(a: array[3,float64], size: int, med: float64): float64 =
  var split=0
  while split<size and a[split]<=med: inc split
  var left=split-1; var right=split
  var d: array[3,float64]
  for i in 0..<size:
    let takeLeft=right>=size or (left>=0 and med-a[left]<=a[right]-med)
    if takeLeft: d[i]=med-a[left]; dec left
    else: d[i]=a[right]-med; inc right
  let m=size div 2
  if size mod 2 == 1: d[m] else: 0.5*(d[m-1]+d[m])
proc putI64Le(output: ptr UncheckedArray[uint8], offset: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: output[offset+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc hampel_filter*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "hampel_filter".} =
  if input.isNil or length<1 or input[0]<0 or input[0]>128: return -1
  let n=int(input[0])
  if length!=csize_t(n+1): return -1
  for i in 0..<n:
    if input[i+1]< -1000 or input[i+1]>1000: return -1
  if capacity<csize_t(n*8) or (n>0 and output.isNil): return -2
  var arrival: array[3,float64]
  var sorted: array[3,float64]
  var size=0; var oldest=0
  for i in 0..<n:
    let value=float64(input[i+1])
    if size==3:
      var pos=0
      while pos<size and sorted[pos]!=arrival[oldest]: inc pos
      for j in pos+1..<size: sorted[j-1]=sorted[j]
      dec size
    var pos=0
    while pos<size and sorted[pos]<value: inc pos
    var j=size
    while j>pos:
      sorted[j]=sorted[j-1]
      dec j
    sorted[pos]=value; inc size
    arrival[oldest]=value; oldest=(oldest+1) mod 3
    let med=median(sorted,size); let mdev=mad(sorted,size,med)
    let filtered=if abs(value-med)>3.0*1.4826*mdev: med else: value
    putI64Le(output,i*8,int64(filtered))
  int64(n*8)
