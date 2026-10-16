proc paranthesis_matching*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "paranthesis_matching".} =
 if v.isNil or n<2 or n>100:return -1
 let count=v[0]
 if count<1 or count>99 or n!=csize_t(count+1):return -1
 var st:array[99,int64];var sp=0
 for i in 1..<int(n):
  let x=v[i]
  if x<33 or x>126:return -1
  if x in [40'i64,123'i64,91'i64,60'i64]:st[sp]=x;inc sp
  elif x in [41'i64,125'i64,93'i64,62'i64]:
   let want=if x==41:40'i64 elif x==125:123'i64 elif x==93:91'i64 else:60'i64
   if sp==0:return 0
   dec sp
   if st[sp]!=want:return 0
  else:return 0
 if sp==0:1 else:0
