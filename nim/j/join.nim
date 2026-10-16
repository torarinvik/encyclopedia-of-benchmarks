const MaxOutput=3040
proc join*(v:ptr UncheckedArray[int64],n:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"join".}=
 if v.isNil or n<2 or n>2115:return -1
 let sl=v[0];let count=v[1]
 if sl<0 or sl>32 or count<0 or count>32:return -1
 var cursor=2
 if csize_t(sl)>n-cursor:return -1
 var sep:array[32,uint8]
 for i in 0..<int(sl):
  let x=v[cursor];inc cursor
  if x<0 or x>127:return -1
  sep[i]=uint8(x)
 var result:array[MaxOutput,uint8];var written=0
 for item in 0..<int(count):
  if csize_t(cursor)>=n:return -1
  let length=v[cursor];inc cursor
  if length<0 or length>64 or csize_t(length)>n-csize_t(cursor):return -1
  if item>0:
   for j in 0..<int(sl):
    result[written]=sep[j]
    inc written
  for _ in 0..<int(length):
   let x=v[cursor]
   inc cursor
   if x<0 or x>127:return -1
   result[written]=uint8(x)
   inc written
 if csize_t(cursor)!=n:return -1
 if output.isNil or capacity<csize_t(written):return -2
 for i in 0..<written:output[i]=result[i]
 int64(written)
