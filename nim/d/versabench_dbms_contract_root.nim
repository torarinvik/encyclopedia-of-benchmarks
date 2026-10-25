proc putI64(outp: ptr UncheckedArray[byte], w: int, x: int64) =
  let u = cast[uint64](x)
  for b in 0 ..< 8: outp[w*8+b] = byte((u shr (8*b)) and 255)
proc versabench_dbms_contract_root*(values: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[byte], capacity: csize_t): int64 {.cdecl, exportc: "versabench_dbms_contract_root".} =
  if values == nil or length < 3 or length > 12: return -1
  let nv=values[0]
  if nv < 1 or nv > 5 or int(length) != 1+2*int(nv): return -1
  let count=int(nv)
  var levels: array[5,int64]
  var entries: array[5,int64]
  for i in 0 ..< count:
    levels[i]=values[1+2*i];entries[i]=values[2+2*i]
    if levels[i] < 0 or levels[i] > 4 or entries[i] < 0 or entries[i] > 4: return -1
    if i+1<count and (levels[i]==0 or entries[i]!=1 or levels[i+1]!=levels[i]-1): return -1
  if levels[count-1]>0 and entries[count-1]==1: return -1
  if levels[count-1]>0 and entries[count-1]==0 and count!=1: return -1
  var root=0;var promotions=0
  while levels[root]>0 and entries[root]==1: root+=1;promotions+=1
  var finalLevel=levels[root];var finalCount=entries[root]
  if finalLevel>0 and finalCount==0: finalLevel=0;finalCount=0
  if output==nil or capacity<24:return -2
  putI64(output,0,int64(promotions));putI64(output,1,finalLevel);putI64(output,2,finalCount);24
