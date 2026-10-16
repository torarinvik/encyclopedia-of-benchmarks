proc kth_lexicographic_permutation*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"kth_lexicographic_permutation".}=
 if v.isNil or n!=2:return -1
 let k0=v[0];let m=v[1]
 if m<2 or m>9 or k0<0:return -1
 var fact=1'i64
 for i in 2..m:fact*=i
 if k0>=fact:return -1
 var k=k0;var a:array[9,int64];var code=m
 for i in 0..<m:a[i]=i
 for block in countdown(m-1,1):
  var f=1'i64
  for j in 2..block:f*=j
  let idx=k div f;k=k mod f;code=code*10+a[idx]+1
  for j in idx..<block:a[j]=a[j+1]
 code*10+a[0]+1
