proc prefix_evaluator*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "prefix_evaluator".} =
 if v.isNil or n<2 or n>129 or v[0]<1 or v[0]>128 or n!=csize_t(v[0]+1):return -1
 var st:array[128,int32];var sp=0
 var i=int(n)
 while i>1:
  dec i;let t=v[i]
  if t in [-9000000000000000001'i64,-9000000000000000002'i64,-9000000000000000003'i64,-9000000000000000004'i64]:
   if sp<2:return -1
   let a=st[sp-1];let b=st[sp-2];sp-=2;var z:int32
   if t == -9000000000000000001'i64:z=cast[int32](cast[uint32](a)+%cast[uint32](b))
   elif t == -9000000000000000002'i64:z=cast[int32](cast[uint32](a)-%cast[uint32](b))
   elif t == -9000000000000000003'i64:z=cast[int32](cast[uint32](a)*%cast[uint32](b))
   else:
    if b==0:return -1
    z=if a==low(int32) and b == -1:low(int32) else:a div b
   st[sp]=z;inc sp
  else:
   if t<low(int32).int64 or t>high(int32).int64 or sp>=128:return -1
   st[sp]=int32(t);inc sp
 if sp==1:return st[0].int64
 -1
