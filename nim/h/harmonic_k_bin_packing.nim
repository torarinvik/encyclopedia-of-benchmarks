const MaxN=32
const MaxK=8
const MaxInput=34
const Capacity=10000'i64
proc storeI64LE(outp: ptr UncheckedArray[uint8], off: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8: outp[off+b]=uint8((bits shr (b*8)) and 255)
proc harmonic_k_bin_packing*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "harmonic_k_bin_packing".} =
  if input.isNil or length<csize_t(3) or length>csize_t(MaxInput): return -1
  let k64=input[0];let n64=input[1]
  if k64<3 or k64>MaxK or n64<1 or n64>MaxN or int64(length)!=2+n64: return -1
  let k=int(k64);let n=int(n64)
  for i in 0..<n:
    if input[2+i] < 1 or input[2+i] > Capacity: return -1
  let bytes=8*(n+1);if output.isNil or capacity<csize_t(bytes): return -2
  var current: array[MaxK,int64]=[-1'i64,-1,-1,-1,-1,-1,-1,-1]
  var remaining: array[MaxK,int64]
  var assignment: array[MaxN,int64]
  var bins=0'i64
  for i in 0..<n:
    let size=input[2+i]
    var kind=k-1
    for c in 0..<k-1:
      if size*int64(c+2) > Capacity:
        kind = c
        break
    if current[kind]<0 or size>remaining[kind]: current[kind]=bins;inc bins;remaining[kind]=Capacity
    assignment[i]=current[kind];remaining[kind]-=size
  storeI64LE(output,0,bins)
  for i in 0..<n: storeI64LE(output,8*(i+1),assignment[i])
  int64(bytes)
