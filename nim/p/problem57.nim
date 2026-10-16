proc addScaled(a: array[5000, int], alen: int, b: array[5000, int], blen: int,
                multiplier: int, output: var array[5000, int]): int =
  var length = max(alen, blen)
  var carry = 0
  for i in 0 ..< length:
    let value = (if i < alen: a[i] else: 0) + multiplier * (if i < blen: b[i] else: 0) + carry
    output[i] = value mod 10
    carry = value div 10
  while carry > 0:
    output[length] = carry mod 10
    inc length
    carry = carry div 10
  length

proc problem57*(n: int64): int64 {.cdecl, exportc: "problem57".} =
  if n > 10_000: return -1
  if n < 1: return 0
  var prevN, prevD, curN, curD: array[5000, int]
  prevN[0] = 1; prevD[0] = 1
  var nlen = 1; var dlen = 1; var count = 0'i64
  for _ in 0 ..< int(n):
    let cn = addScaled(prevN,nlen,prevD,dlen,2,curN)
    let cd = addScaled(prevN,nlen,prevD,dlen,1,curD)
    if cn > cd: inc count
    for i in 0 ..< cn: prevN[i] = curN[i]
    for i in 0 ..< cd: prevD[i] = curD[i]
    nlen = cn; dlen = cd
  count
