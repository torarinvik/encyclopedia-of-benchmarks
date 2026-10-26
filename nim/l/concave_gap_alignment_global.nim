const D=8
const L=26
const INF=1152921504606846976'i64
proc put64(output:ptr UncheckedArray[uint8],value:int64)=
  let bits=cast[uint64](value)
  for j in 0..<8:output[j]=uint8((bits shr (8*j)) and 255)
proc concave_gap_alignment_global*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"concave_gap_alignment_global".}=
  if input.isNil or length<csize_t(5) or length>csize_t(L):return -1
  let nr=input[0];let mr=input[1];if nr<1 or nr>D or mr<1 or mr>D:return -1
  let n=int(nr);let m=int(mr);let g=max(n,m);if int64(length)!=2+n+m+g:return -1
  var x,y,w:array[D,int64];var p=2
  for i in 0..<n:x[i]=input[p];inc p;if x[i]<0 or x[i]>3:return -1
  for j in 0..<m:y[j]=input[p];inc p;if y[j]<0 or y[j]>3:return -1
  var slope=INF
  for k in 0..<g:
    w[k]=input[p];inc p
    if w[k]<0 or w[k]>100:return -1
    let delta=w[k]-(if k>0:w[k-1] else:0)
    if k>0 and (w[k]<w[k-1] or delta>slope):return -1
    slope=delta
  if output.isNil or capacity<csize_t(8):return -2
  var dp:array[81,int64];for i in 0..<81:dp[i]=INF;dp[0]=0
  for i in 0..n:
    for j in 0..m:
      if i==0 and j==0:continue
      var best=INF
      if i>0 and j>0:best=min(best,dp[(i-1)*9+j-1]+(if x[i-1]==y[j-1]:0 else:1))
      if i>0:
        for gap in 1..i:best=min(best,dp[(i-gap)*9+j]+w[gap-1])
      if j>0:
        for gap in 1..j:best=min(best,dp[i*9+j-gap]+w[gap-1])
      dp[i*9+j]=best
  put64(output,dp[n*9+m]);8
