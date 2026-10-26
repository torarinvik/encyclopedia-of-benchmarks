const MaxN = 16
const MaxInput = 50

proc power(base, exponent: int64): int64 =
  result = 1
  for i in 0'i64 ..< exponent: result *= base

proc put64(output: ptr UncheckedArray[uint8], pos: int, value: int64) =
  let bits = cast[uint64](value)
  for j in 0 ..< 8: output[pos+j] = uint8((bits shr (8*j)) and 255)

proc weighted_random_sampling*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"weighted_random_sampling".} =
  if input.isNil or length < csize_t(5) or length > csize_t(MaxInput): return -1
  let n64=input[0]; let m64=input[1]
  if n64<1 or n64>MaxN or m64<1 or m64>n64 or int64(length)!=2+3*n64: return -1
  let n=int(n64); let m=int(m64)
  var weights, nums, dens, available, chosen: array[MaxN,int64]
  for i in 0..<n:
    weights[i]=input[2+3*i]; nums[i]=input[3+3*i]; dens[i]=input[4+3*i]
    if weights[i]<1 or weights[i]>3 or nums[i]<1 or nums[i]>=dens[i] or dens[i]>100: return -1
  let bytes=8*m
  if output.isNil or capacity<csize_t(bytes): return -2
  for i in 0..<n: available[i]=int64(i)
  for rank in 0..<m:
    var best=0
    for i in 1 ..< (n-rank):
      let left=int(available[i]); let right=int(available[best])
      let lhs=power(nums[left],weights[right])*power(dens[right],weights[left])
      let rhs=power(nums[right],weights[left])*power(dens[left],weights[right])
      if lhs>rhs or (lhs==rhs and left<right): best=i
    chosen[rank]=available[best]
    for i in best ..< (n-rank-1): available[i]=available[i+1]
  for i in 0..<m: put64(output,8*i,chosen[i])
  int64(bytes)
