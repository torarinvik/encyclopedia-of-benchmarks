proc dsa_verify*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "dsa_verify".} =
  if v.isNil or n < 7 or n > 15: return -1
  let p=v[0];let q=v[1];let g=v[2];let y=v[3];let r=v[4];let s=v[5];let ml=v[6]
  if ml<0 or ml>8 or n!=csize_t(7+ml):return -1
  if p<5 or p>251:return -1
  var d=2'i64
  while d*d<=p:
    if p mod d==0:return -1
    inc d
  if q<2 or q>=p or (p-1) mod q!=0:return -1
  d=2
  while d*d<=q:
    if q mod d==0:return -1
    inc d
  proc mpow(a0,e0,m:int64):int64 =
    var a=a0 mod m;var e=e0;var res=1'i64
    while e>0:
      if (e and 1)!=0:res=res*a mod m
      a=a*a mod m;e=e shr 1
    res
  if g<2 or g>=p or mpow(g,q,p)!=1 or y<1 or y>=p or mpow(y,q,p)!=1 or r<1 or r>=q or s<1 or s>=q:return -1
  var h=0'i64
  for i in 0..<int(ml):
    if v[7+i]<0 or v[7+i]>255:return -1
    h=(h*256+v[7+i]) mod q
  let w=mpow(s,q-2,q);let u1=h*w mod q;let u2=r*w mod q
  result = (if (mpow(g,u1,p)*mpow(y,u2,p) mod p) mod q == r: 1 else: 0)
