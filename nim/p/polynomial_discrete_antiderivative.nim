const Modulus = 998244353'i64
proc polynomial_discrete_antiderivative*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc.} =
  if input == nil or length < 2 or length > 33 or input[0] < 1 or input[0] > 32: return -1
  let n=int(input[0])
  if length != csize_t(n+1): return -1
  for i in 0 ..< n:
    if input[1+i] < 0 or input[1+i] >= Modulus: return -1
  if output == nil or capacity < csize_t(8*(n+1)): return -2
  var choose: array[33,array[33,int64]]
  var inverse, g: array[33,int64]
  choose[0][0]=1
  for k in 1 .. n:
    choose[k][0]=1; choose[k][k]=1
    for j in 1 ..< k: choose[k][j]=(choose[k-1][j-1]+choose[k-1][j]) mod Modulus
  inverse[1]=1
  for k in 2 .. n: inverse[k]=Modulus-(Modulus div int64(k))*inverse[int(Modulus mod int64(k))] mod Modulus
  for j in countdown(n-1,0):
    var sum=0'i64
    for k in j+2 .. n: sum=(sum+choose[k][j]*g[k]) mod Modulus
    g[j+1]=((input[1+j]-sum+Modulus) mod Modulus)*inverse[j+1] mod Modulus
  for i in 0 .. n:
    let bits=uint64(g[i])
    for byte in 0 ..< 8: output[8*i+byte]=uint8((bits shr (8*byte)) and 255)
  int64(8*(n+1))
