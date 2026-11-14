const Modulus = 998244353'i64

proc power(baseInput: int64, exponentInput: int): int64 =
  var base = baseInput
  var exponent = exponentInput
  result = 1
  while exponent > 0:
    if (exponent and 1) != 0: result = result*base mod Modulus
    base = base*base mod Modulus
    exponent = exponent shr 1

proc locate(q: array[15,int], count, value: int): int =
  var lo = 0; var hi = count
  while lo < hi:
    let mid = lo+(hi-lo) div 2
    if q[mid] < value: lo = mid+1
    else: hi = mid
  if lo < count and q[lo] == value: return lo
  -1

proc dirichlet_inverse_and_prefix_sums*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 16 or input[0] < 1 or input[0] > 64: return -1
  let n = int(input[0])
  var q: array[15,int]
  var count = 0
  for i in countdown(n,1):
    let value = n div i
    if count == 0 or q[count-1] != value: q[count] = value; inc count
  if length != csize_t(1+count) or input[1] == 0: return -1
  for i in 0 ..< count:
    if input[1+i] < 0 or input[1+i] >= Modulus: return -1
  if output == nil or capacity < csize_t(8*count): return -2
  let inverse = power(input[1], int(Modulus-2))
  var g: array[15,int64]
  for i in 0 ..< count:
    let x=q[i]
    var left=2
    var total=0'i64
    while left <= x:
      let quotient=x div left; let right=x div quotient
      let hi=locate(q,count,right); let lo=locate(q,count,left-1)
      let gi=locate(q,count,quotient)
      if hi < 0 or lo < 0 or gi < 0: return -1
      let interval=(input[1+hi]-input[1+lo]+Modulus) mod Modulus
      total=(total+interval*g[gi]) mod Modulus
      left=right+1
    g[i]=((1-total+Modulus) mod Modulus)*inverse mod Modulus
  for i in 0 ..< count:
    let bits=uint64(g[i])
    for byte in 0 ..< 8: output[8*i+byte]=uint8((bits shr (8*byte)) and 255)
  int64(8*count)
