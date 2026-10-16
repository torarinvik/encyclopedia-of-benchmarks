proc boundShift(x0:int64):int64=
  int64(high(int32))
proc leftRun(a:ptr UncheckedArray[int64],k,b,h:int64):(int64,int64)=
 let m=h+1;var x=1'i64;var t=0'i64
 while x<m and k<a[b+h-x]:t=x;x=boundShift(x)
 if x>m:x=m
 (h-t,h-x)
proc rightRun(a:ptr UncheckedArray[int64],k,b,n,h:int64):(int64,int64)=
 var x=1'i64;var last=0'i64;let m=n-h
 while x<m and k>a[b+h+x]:last=x;x=boundShift(x)
 if x>m:x=m
 (x+h,last+h)
proc finalOffset(a:ptr UncheckedArray[int64],k,b,o0,l0:int64,lt:int64):int64=
 var o=o0;var l=l0+1
 while l<o:
  let mid=l+int64((uint64(o-l)) shr 1)
  let value=a[b+mid]
  if (if k<value:-1 elif k>value:1 else:0)<lt:o=mid else:l=mid+1
 o
proc galloping_strategy*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"galloping_strategy".}=
 if v==nil or n<5 or n>69:return -1
 let op=v[0];let count=v[1];let base=v[2];let len=v[3];let key=v[4]
 if (op!=0 and op!=1) or count<0 or count>64 or n!=5+count or base<0 or len<0 or base>count or len>count-base or key< -2147483648 or key>2147483647:return -1
 for i in 0..<count:if v[5+i]< -2147483648 or v[5+i]>2147483647:return -1
 if count==0:return 0
 if len==0 or base>=count:return -1
 for i in base..<(base+len-1):if v[5+i]>v[5+i+1]:return -1
 var o,l:int64
 if op==0:
  if key>v[5+base]: (o,l)=rightRun(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,len,0) else: (o,l)=leftRun(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,0)
  return finalOffset(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,o,l,1)
 if key<v[5+base]:(o,l)=leftRun(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,len) else:(o,l)=rightRun(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,len,0)
 finalOffset(cast[ptr UncheckedArray[int64]](addr v[5]),key,base,o,l,0)
