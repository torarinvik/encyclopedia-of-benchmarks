import std/math
const freq:array[26,float64]=[0.08497,0.01492,0.02202,0.04253,0.11162,0.02228,0.02015,0.06094,0.07546,0.00153,0.01292,0.04025,0.02406,0.06749,0.07507,0.01929,0.00095,0.07587,0.06327,0.09356,0.02758,0.00978,0.02560,0.00150,0.01994,0.00077]
proc decrypt_caesar_with_chi_squared*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"decrypt_caesar_with_chi_squared".}=
  if input.isNil or length<1 or length>129 or input[0]<0 or input[0]>128 or input[0]!=int64(length-1):return -1
  let textLength=int(length-1)
  for i in 0..<textLength:
    if input[i+1]<0 or input[i+1]>127:return -1
  if output.isNil or capacity<csize_t(8+textLength):return -2
  var best:array[128,uint8];var candidate:array[128,uint8];var bestScore=1e300;var bestShift=0'i64
  for shift in 0..<26:
    var counts:array[26,int64]
    for i in 0..<textLength:
      let v=input[i+1];var decoded=v
      if v>=65 and v<=90:decoded=97+(v-65-shift+2600) mod 26
      elif v>=97 and v<=122:decoded=97+(v-97-shift+2600) mod 26
      candidate[i]=uint8(decoded)
      if decoded>=97 and decoded<=122:inc counts[int(decoded-97)]
    var score=0.0
    for j in 0..<26:
      let n=counts[j]
      if n>0:
        let expected=freq[j]*float64(n);let delta=float64(n)-expected
        score+=(delta*delta)/expected
    var less=score<bestScore
    if score==bestScore:
      for i in 0..<textLength:
        if candidate[i]<best[i]:
          less=true
          break
        if candidate[i]>best[i]:break
    if less:
      bestScore=score;bestShift=int64(shift)
      for i in 0..<textLength:best[i]=candidate[i]
  let bits=cast[uint64](bestScore)
  for b in 0..<8:output[b]=uint8((bits shr (8*b)) and 0xff'u64)
  for i in 0..<textLength:output[8+i]=best[i]
  bestShift
