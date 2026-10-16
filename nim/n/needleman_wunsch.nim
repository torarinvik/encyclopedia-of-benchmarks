const Invalid = low(int64)
proc needleman_wunsch*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "needleman_wunsch".} =
  if v.isNil or n < 5 or n > 261: return Invalid
  let a=v[0];let b=v[1];let matchScore=v[2];let mismatch=v[3];let gap=v[4]
  if a<0 or a>128 or b<0 or b>128 or matchScore<0 or matchScore>10 or mismatch< -10 or mismatch>0 or gap< -10 or gap>0 or n!=csize_t(5+a+b):return Invalid
  for i in 0 ..< int(a+b):
    if v[i+5]<65 or v[i+5]>90:return Invalid
  var dp: array[129,int64]
  for j in 0 .. int(b):dp[j]=int64(j)*gap
  for i in 1 .. int(a):
    var diagonal=dp[0];dp[0]=int64(i)*gap
    for j in 1 .. int(b):
      let old=dp[j];let score=if v[5+i-1]==v[5+int(a)+j-1]:matchScore else:mismatch
      dp[j]=max(max(diagonal+score,old+gap),dp[j-1]+gap);diagonal=old
  dp[int(b)]
