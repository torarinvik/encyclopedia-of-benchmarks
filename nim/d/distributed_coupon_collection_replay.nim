const MaxN = 8
const MaxInput = 76

proc put64(output: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits=cast[uint64](value)
  for j in 0..<8: output[pos+j]=uint8((bits shr (8*j)) and 255)

proc distributed_coupon_collection_replay*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"distributed_coupon_collection_replay".} =
  if input.isNil or length<4 or length>csize_t(MaxInput):return -1
  let n64=input[0];let c64=input[1];let copies=input[2];let steps64=input[3]
  if n64<2 or n64>8 or c64<1 or c64>8 or copies<1 or copies>n64 or steps64<1 or steps64>8 or int64(length)!=4+n64+n64*steps64:return -1
  let n=int(n64);let coupons=int(c64);let steps=int(steps64);let full=(1'u64 shl coupons)-1
  var bins:array[MaxN,uint64]
  for b in 0..<n:
    let raw=input[4+b]
    if raw<0 or (cast[uint64](raw) and not full)!=0:return -1
    bins[b]=cast[uint64](raw)
  for coupon in 0..<coupons:
    var count=0
    for b in 0..<n:if ((bins[b] shr coupon) and 1)!=0:inc count
    if count<int(copies):return -1
  let tapeAt=4+n
  for i in 0..<(n*steps):if input[tapeAt+i]!=0 and input[tapeAt+i]!=1:return -1
  if output.isNil or capacity<16:return -2
  var collected=0'u64;var singletonSteps=0'i64
  for step in 0..<steps:
    var openCount=0;var openedBin=0
    for bin in 0..<n:if input[tapeAt+step*n+bin]==1:inc openCount;openedBin=bin
    if openCount==1:inc singletonSteps;collected=collected or bins[openedBin]
  var staged:array[16,uint8]
  put64(addr staged[0],0,cast[int64](collected));put64(addr staged[0],8,singletonSteps)
  for b in 0..<16:output[b]=staged[b]
  16
