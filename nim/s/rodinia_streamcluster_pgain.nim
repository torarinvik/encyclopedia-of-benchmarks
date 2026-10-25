proc put64(outp: ptr UncheckedArray[uint8], index: int, value: int64) =
  let raw = cast[uint64](value)
  for b in 0 ..< 8: outp[index * 8 + b] = uint8((raw shr (b * 8)) and 255)

proc rodinia_streamcluster_pgain*(values: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc: "rodinia_streamcluster_pgain".} =
  if values.isNil or length < 5 or length > 53: return -1
  let pn=values[0]; let dim=values[1]; let candidate=values[2]; let z=values[3]; let mask=values[4]
  if pn<2 or pn>8 or dim<1 or dim>3 or length!=csize_t(5+pn*(3+dim)) or candidate<0 or candidate>=pn or z<1 or z>64 or mask<=0 or cast[uint64](mask)>=(1'u64 shl int(pn)) or (mask and (1'i64 shl int(candidate)))!=0: return -1
  let p=int(pn);let d=int(dim);let x=int(candidate);var q=5
  var ass:array[8,int];var weights:array[8,int64];var costs:array[8,int64];var points:array[8,array[3,int64]]
  for i in 0 ..< p:
    if values[q]<0 or values[q]>=pn:return -1
    ass[i]=int(values[q]);q+=1
    if (mask and (1'i64 shl ass[i]))==0:return -1
  for i in 0 ..< p:
    if values[q]<1 or values[q]>4:return -1
    weights[i]=values[q];q+=1
  for i in 0 ..< p: costs[i]=values[q];q+=1
  for i in 0 ..< p:
    for k in 0 ..< d:
      if values[q] < -8 or values[q]>8:return -1
      points[i][k]=values[q];q+=1
  for i in 0 ..< p:
    var ds=0'i64
    for k in 0 ..< d:
      let delta=points[i][k]-points[ass[i]][k];ds+=delta*delta
    if costs[i]!=weights[i]*ds or ((mask and (1'i64 shl i))!=0 and (ass[i]!=i or costs[i]!=0)):return -1
  var switched:array[8,bool];var closing:array[8,bool];var lower:array[8,int64];var opening=z
  for i in 0 ..< p:
    var ds=0'i64
    for k in 0 ..< d:
      let delta=points[i][k]-points[x][k];ds+=delta*delta
    let xc=weights[i]*ds
    if xc<costs[i]:switched[i]=true;opening+=xc-costs[i]
    else:lower[ass[i]]+=costs[i]-xc
  for j in 0 ..< p:
    if (mask and (1'i64 shl j))!=0:
      let low=z+lower[j]
      if low>0:closing[j]=true;opening-=low
  let opened=opening<0;var outMask=mask;var outAss=ass;var outCost=costs
  if opened:
    for i in 0 ..< p:
      if switched[i] or closing[ass[i]]:
        var ds=0'i64
        for k in 0 ..< d:
          let delta=points[i][k]-points[x][k];ds+=delta*delta
        outAss[i]=x;outCost[i]=weights[i]*ds
    for j in 0 ..< p:
      if closing[j]:outMask=outMask and not (1'i64 shl j)
    outMask=outMask or (1'i64 shl x)
  var count=0'i64;var objective=0'i64
  for j in 0 ..< p:if (outMask and (1'i64 shl j))!=0:count+=1
  objective=count*z
  for i in 0 ..< p:objective+=outCost[i]
  if output.isNil or capacity<csize_t(8*(5+2*p)):return -2
  put64(output,0,if opened:1 else:0);put64(output,1,if opened:-opening else:0);put64(output,2,count);put64(output,3,outMask);put64(output,4,objective)
  for i in 0 ..< p:put64(output,5+i,int64(outAss[i]));put64(output,5+p+i,outCost[i])
  int64(5+2*p)
