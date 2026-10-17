const dr:array[8,int]=[1,-1,1,-1,2,2,-2,-2]
const dc:array[8,int]=[2,2,-2,-2,1,-1,1,-1]
proc search(b:var array[25,int32],n,r,c,step:int):bool=
 if step==n*n:return true
 for k in 0..<8:
  let nr=r+dr[k];let nc=c+dc[k]
  if nr>=0 and nr<n and nc>=0 and nc<n:
   let at=nr*n+nc
   if b[at]==0:
    b[at]=int32(step+1)
    if search(b,n,nr,nc,step+1):return true
    b[at]=0
 false
proc put(outp:ptr UncheckedArray[uint8],off:int,x:int32)=
 let bits=cast[uint32](x)
 for k in 0..<4:outp[off+k]=uint8((bits shr (8*k)) and 255)
proc open_knight_tour*(v:ptr UncheckedArray[int64],n:csize_t,outp:ptr UncheckedArray[uint8],cap:csize_t):int64 {.cdecl,exportc:"open_knight_tour".}=
 if v==nil or n!=1 or (v[0]!=1 and v[0]!=5):return -1
 let d=int(v[0]);let bytes=d*d*4
 if outp==nil or cap<csize_t(bytes):return -2
 var b:array[25,int32]
 block starts:
  for r in 0..<d:
   for c in 0..<d:
    b[r*d+c]=1
    if search(b,d,r,c,1):break starts
    b[r*d+c]=0
 for i in 0..<d*d:put(outp,i*4,b[i])
 int64(bytes)
