const Modulus=998244353'i64
proc power(xInput:int64, exponentInput:int):int64 =
  var x=xInput; var exponent=exponentInput
  result=1
  while exponent>0:
    if (exponent and 1)!=0: result=result*x mod Modulus
    x=x*x mod Modulus; exponent=exponent shr 1
proc inv_of_formal_power_series_2d*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc.} =
  if input==nil or length<3 or length>66 or input[0]<1 or input[0]>8 or input[1]<1 or input[1]>8: return -1
  let n=int(input[0]); let m=int(input[1])
  if length!=csize_t(2+n*m) or input[2]==0: return -1
  for i in 0 ..< n*m:
    if input[2+i]<0 or input[2+i]>=Modulus: return -1
  if output==nil or capacity<csize_t(8*n*m): return -2
  var g:array[64,int64]
  let inverse=power(input[2],998244351); g[0]=inverse
  for i in 0 ..< n:
    for j in 0 ..< m:
      if i==0 and j==0: continue
      var sum=0'i64
      for a in 0 .. i:
        for b in 0 .. j:
          if a!=0 or b!=0: sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b]) mod Modulus
      g[i*m+j]=((Modulus-sum) mod Modulus)*inverse mod Modulus
  for i in 0 ..< n*m:
    let bits=uint64(g[i])
    for byte in 0 ..< 8: output[8*i+byte]=uint8((bits shr (8*byte)) and 255)
  int64(8*n*m)
