proc feed(h0:uint64,x:int64):uint64=
 var h=h0;let u=cast[uint64](x)
 for b in 0..7:h=cast[uint64](cast[int64](h xor ((u shr (8*b)) and 255'u64))*%cast[int64](0x100000001b3'u64))
 h
proc product(a,b:array[3,int64],o:var array[6,int64])=
 o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2]
proc first_fundamental_form*(v:ptr UncheckedArray[int64],n:uint64):int64 {.cdecl,exportc:"first_fundamental_form".}=
 if v==nil or n!=18:return -1
 for i in 0..<18:
  if v[i]< -100'i64 or v[i]>100'i64:return -1
 var ru,rv:array[3,array[3,int64]];var e,f,g:array[6,int64]
 for k in 0..2:
  let i=6*k;ru[k]=[v[i+1],2*v[i+3],v[i+4]];rv[k]=[v[i+2],v[i+4],2*v[i+5]]
 for k in 0..2:product(ru[k],ru[k],e);product(ru[k],rv[k],f);product(rv[k],rv[k],g)
 var h=0xcbf29ce484222325'u64
 for x in e:h=feed(h,x)
 for x in f:h=feed(h,x)
 for x in g:h=feed(h,x)
 cast[int64](h)
