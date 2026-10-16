proc line_sweep(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"line_sweep".}=
 if n<1 or n>17:return -1e300
 let count=v[0]
 if count<0 or count>8 or n!=csize_t(1+2*count):return -1e300
 if count==0:return 0.0
 var line:array[22,int]=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
 for i in 0..<int(count):
  let s=v[1+2*i];let e=v[2+2*i]
  if s<0 or e<s or e>20:return -1e300
  inc line[int(s)];dec line[int(e+1)]
 var c=0;var m=0
 for d in line:
  c+=d
  if c>m:m=c
 if m>1:1.0 else:0.0
