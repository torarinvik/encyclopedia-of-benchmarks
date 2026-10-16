import std/strutils
proc diffie_hellman*(v: ptr UncheckedArray[int64], n: csize_t): int64 {.cdecl, exportc: "diffie_hellman".} =
  if v == nil or n != 4: return -1
  let g=v[0]; let a=v[1]; let b=v[2]; let p=v[3]
  if p<2 or p>6700417 or g<1 or g>=p or a<1 or a>=p or b<1 or b>=p:return -1
  var d=2'i64
  while d*d<=p:
    if p mod d==0:return -1
    d+=1
  proc mp(x0,e0,p:int64):int64 =
    var x=x0; var e=e0; var r=1'i64 mod p
    while e>0:
      if (e and 1)!=0:r=r*x mod p
      x=x*x mod p; e=e shr 1
    r
  mp(mp(g,a,p),b,p)
