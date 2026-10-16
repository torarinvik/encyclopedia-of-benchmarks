const MaxInput=256
proc storeLe(output:ptr UncheckedArray[uint8],offset:int,x:int64)=
 let bits=cast[uint64](x)
 for b in 0..<8:output[offset+b]=uint8((bits shr (b*8)) and 255)
proc double_ended_selection_sort*(v:ptr UncheckedArray[int64],n:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"double_ended_selection_sort".}=
 if (v.isNil and n>0) or n>257:return -1
 if n>MaxInput:return -1
 var work,starts,ends,result:array[MaxInput,int64]
 for i in 0..<int(n):work[i]=v[i]
 var count=int(n);var used=0;var endCount=0
 while count>1:
  var minI=0;var maxI=0
  for i in 1..<count:
   if work[i]<work[minI]:minI=i
   if work[i]>work[maxI]:maxI=i
  let minV=work[minI];let maxV=work[maxI]
  starts[used]=minV;inc used;ends[endCount]=maxV;inc endCount
  for i in minI..<count-1:work[i]=work[i+1]
  dec count
  var maxPos=0
  while maxPos<count and work[maxPos]!=maxV:inc maxPos
  if maxPos==count:return -1
  for i in maxPos..<count-1:work[i]=work[i+1]
  dec count
 var outN=0
 for i in 0..<used:result[outN]=starts[i];inc outN
 for i in 0..<count:result[outN]=work[i];inc outN
 var i=endCount
 while i>0:dec i;result[outN]=ends[i];inc outN
 let bytes=8*outN
 if output.isNil or capacity<csize_t(bytes):return -2
 for i in 0..<outN:storeLe(output,8*i,result[i])
 int64(bytes)
