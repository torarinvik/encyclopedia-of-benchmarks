proc job_sequence_with_deadline*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"job_sequence_with_deadline".}=
 if v.isNil or n<1 or n>129:return -1
 let count=v[0]
 if count<0 or count>64 or n!=csize_t(1+2*count):return -1
 var d,r:array[64,int64];var order:array[64,int]
 for i in 0..<int(count):
  d[i]=v[1+2*i];r[i]=v[2+2*i]
  if d[i]< -1 or d[i]>64 or r[i]< -1000000 or r[i]>1000000:return -1
  order[i]=i
 for i in 1..<int(count):
  let key=order[i];var j=i
  while j>0 and r[order[j-1]]<r[key]:order[j]=order[j-1];dec j
  order[j]=key
 var kept=0'i64
 for i in 0..<int(count):if d[order[i]]>=int64(i+1):inc kept
 kept
