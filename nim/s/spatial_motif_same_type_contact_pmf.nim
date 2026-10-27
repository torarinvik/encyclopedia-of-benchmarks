const MaxLength = 16
const MaxSupport = 17

proc chooseValue(n, k0: int): int64 =
  if k0 < 0 or k0 > n: return 0
  let k = min(k0, n-k0)
  var result = 1'i64
  var i = 1
  while i <= k:
    result = result * int64(n-k+i) div int64(i)
    inc i
  result

proc gcdValue(a0, b0: int64): int64 =
  var a=a0; var b=b0
  while b != 0:
    let r=a mod b; a=b; b=r
  a

proc putI64Le(output: ptr UncheckedArray[uint8], word: int, value: int64) =
  var bits=cast[uint64](value)
  for byte in 0 ..< 8:
    output[word*8+byte]=uint8(bits and 255'u64)
    bits=bits shr 8

proc spatial_motif_same_type_contact_pmf*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "spatial_motif_same_type_contact_pmf".} =
  if input == nil or length != 3: return -1
  let l0=input[0]; let x10=input[1]; let x20=input[2]
  if l0 < 1 or l0 > MaxLength or x10 < 0 or x10 > l0 or x20 < 0 or x20 > l0: return -1
  let l=int(l0); let x1=int(x10); let x2=int(x20)
  let low=max(0,x1+x2-l); let high=min(x1,x2)
  let denominator=chooseValue(l,x2)
  var numerators: array[MaxSupport,int64]
  for i in low .. high:
    numerators[i-low]=chooseValue(x1,i)*chooseValue(l-x1,x2-i)
  var expectedNum=int64(x1*x2); var expectedDen=int64(l)
  let divisor=gcdValue(expectedNum,expectedDen)
  expectedNum=expectedNum div divisor; expectedDen=expectedDen div divisor
  let count=high-low+1; let words=3+count+2; let bytes=words*8
  if output == nil or capacity < csize_t(bytes): return -2
  putI64Le(output,0,int64(low));putI64Le(output,1,int64(high));putI64Le(output,2,denominator)
  for i in 0 ..< count: putI64Le(output,3+i,numerators[i])
  putI64Le(output,3+count,expectedNum);putI64Le(output,4+count,expectedDen)
  int64(bytes)
