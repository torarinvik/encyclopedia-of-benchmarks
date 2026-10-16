proc job_sequencing_with_deadline*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"job_sequencing_with_deadline".}=
 if v.isNil or n<1 or n>65:return -1
 let count=v[0]
 if count<1 or count>32 or n!=csize_t(1+2*count):return -1
 var d,p:array[32,int64];var order:array[32,int]
 for i in 0..<int(count):
  d[i]=v[1+2*i];p[i]=v[2+2*i]
  if d[i]<0 or d[i]>32 or p[i]<0 or p[i]>1000000:return -1
  order[i]=i
 for i in 1..<int(count):
  let key=order[i];var j=i
  while j>0 and p[order[j-1]]<p[key]:order[j]=order[j-1];dec j
  order[j]=key
 var slots:array[33,bool];var chosen=0'i64;var profit=0'i64
 for k in 0..<int(count):
  for s in countdown(int(d[order[k]]),1):
   if not slots[s]:slots[s]=true;inc chosen;profit+=p[order[k]];break
 chosen*32000001+profit
