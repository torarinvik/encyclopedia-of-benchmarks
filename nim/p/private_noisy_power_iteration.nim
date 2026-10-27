const S = 1_000_000'i64
const MaxN = 4
const MaxL = 4
const MaxInput = 39

proc truncDiv(value, denominator: int64): int64 =
  if value < 0: -((-value) div denominator) else: value div denominator

proc floorSqrt(value: int64): int64 =
  var low=0'i64; var high=13_000_001'i64
  while low+1<high:
    let middle=(low+high) div 2
    if middle<=value div middle: low=middle else: high=middle
  low

proc private_noisy_power_iteration*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"private_noisy_power_iteration".} =
  if input.isNil or length<csize_t(11) or length>csize_t(MaxInput): return -1
  let n64=input[0]; let rounds64=input[1]; let sigma=input[2]
  if n64<2 or n64>MaxN or rounds64<1 or rounds64>MaxL or sigma<0 or sigma>S: return -1
  let n=int(n64);let rounds=int(rounds64);let expected=3+n*n+n+rounds*n
  if int(length)!=expected: return -1
  let vectorStart=3+n*n;let noiseStart=vectorStart+n
  var matrix: array[MaxN*MaxN,int64]
  var x: array[MaxN,int64]
  var noise: array[MaxL*MaxN,int64]
  for i in 0..<n*n:
    matrix[i]=input[3+i]
    if matrix[i] < -S or matrix[i] > S: return -1
  for i in 0..<n:
    for j in 0..<n:
      if matrix[i*n+j]!=matrix[j*n+i]: return -1
  var initialNorm=0'i64
  for i in 0..<n:
    x[i]=input[vectorStart+i]
    if x[i] < -S or x[i] > S: return -1
    initialNorm += x[i]*x[i]
  if initialNorm!=S*S: return -1
  for i in 0..<rounds*n:
    noise[i]=input[noiseStart+i]
    if noise[i] < -2*S or noise[i] > 2*S: return -1
  var y: array[MaxN,int64]
  for step in 0..<rounds:
    var normSquared=0'i64
    for i in 0..<n:
      var accumulator=sigma*noise[step*n+i]
      for j in 0..<n: accumulator += matrix[i*n+j]*x[j]
      y[i]=truncDiv(accumulator,S)
      normSquared += y[i]*y[i]
    if normSquared==0: return -1
    let radius=floorSqrt(normSquared)
    for i in 0..<n: x[i]=truncDiv(y[i]*S,radius)
  let bytes=8*n
  if output.isNil or capacity<csize_t(bytes): return -2
  var staged: array[8*MaxN,uint8]
  for i in 0..<n:
    let bits=cast[uint64](x[i])
    for j in 0..<8: staged[8*i+j]=uint8((bits shr (8*j)) and 255)
  for i in 0..<bytes: output[i]=staged[i]
  int64(bytes)
