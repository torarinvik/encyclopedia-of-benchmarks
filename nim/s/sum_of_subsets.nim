import math
const MaxN=10
const MaxSolutions=1024
proc visit(nums: openArray[int64], target: int64, start: int, current: int64, remaining: int64, path: var seq[int64], solutions: var seq[seq[int64]]) =
  if current>target or remaining+current<target: return
  if current==target:
    var row=newSeq[int64](path.len)
    for i in 0..<path.len: row[i]=path[i]
    solutions.add(row);return
  for i in start..<nums.len:
    path.add(nums[i]);visit(nums,target,i+1,current+nums[i],remaining-nums[i],path,solutions);path.setLen(path.len-1)
proc put64(outp: ptr UncheckedArray[uint8],pos: var int,x:int64)=
  let bits=cast[uint64](x)
  for j in 0..<8: outp[pos]=uint8((bits shr (8*j)) and 255);inc pos
proc sum_of_subsets*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"sum_of_subsets".}=
  if input==nil or length<2:return -1
  let n0=input[0];let target=input[1]
  if n0<0 or n0>10 or length!=csize_t(n0+2) or target<0 or target>250:return -1
  let n=int(n0);var nums=newSeq[int64](n);var remaining:int64=0
  for i in 0..<n: let x=input[2+i];if x<0 or x>50:return -1;nums[i]=x;remaining+=x
  var path:seq[int64]=@[];var solutions:seq[seq[int64]]=@[];visit(nums,target,0,0,remaining,path,solutions)
  var need=8;for row in solutions:need+=8+8*row.len
  if output==nil or capacity<csize_t(need):return -2
  var pos=0;put64(output,pos,int64(solutions.len))
  for row in solutions:put64(output,pos,int64(row.len));for x in row:put64(output,pos,x)
  int64(pos)
