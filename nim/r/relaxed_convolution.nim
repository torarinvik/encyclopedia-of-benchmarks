# New bounded relaxed-convolution schedule; see benchmarks/r/relaxed_convolution/README.md and LICENSE.txt.
const Modulus = 998244353'i64
proc relaxed_convolution*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64
    {.cdecl, exportc: "relaxed_convolution".} =
  if input.isNil or inputLength < 3 or inputLength > 33: return -1
  let nValue = input[0]
  if nValue < 1 or nValue > 16 or inputLength != (1 + 2*nValue).csize_t: return -1
  let n = int(nValue)
  var a, b, c: array[16, int64]
  for i in 0 ..< n:
    a[i] = input[1+i]; b[i] = input[1+n+i]
    if a[i] < 0 or a[i] >= Modulus or b[i] < 0 or b[i] >= Modulus: return -1
  if output.isNil or outputCapacity < (4*n).csize_t: return -2
  for index in 0 ..< n:
    c[index] = (c[index] + a[index]*b[0] + (if index > 0: b[index]*a[0] else: 0)) mod Modulus
    let q = index + 1
    var d = 1
    while d <= q:
      if q mod (2*d) == d:
        let endIndex = min(q+d, n)
        if q == d:
          for i in q ..< endIndex:
            let target = d+i-q
            for r in 0 ..< d:
              let y = target-r
              if y < d: c[i] = (c[i] + a[r]*b[y]) mod Modulus
        else:
          for i in q ..< endIndex:
            let target = d+i-q
            for r in 0 ..< d:
              let y = target-r
              if y < 2*d: c[i] = (c[i] + a[q-d+r]*b[y] + b[q-d+r]*a[y]) mod Modulus
      d *= 2
  for i in 0 ..< n:
    let x = uint32(c[i])
    for j in 0 ..< 4: output[4*i+j] = uint8((x shr (8*j)) and 0xff)
  int64(4*n)
