const MaxInput=322
proc simple_keyword_cypher_decipher*(v: ptr UncheckedArray[int64], n:csize_t, output:ptr UncheckedArray[uint8], capacity:csize_t):int64 {.cdecl,exportc:"simple_keyword_cypher_decipher".} =
 if v.isNil or n<2 or n>323:return -1
 let kl=v[0];let ml=v[1]
 if kl<0 or kl>64 or ml<0 or ml>256 or n!=2+csize_t(kl+ml):return -1
 var key:array[26,uint8];var count=0
 for i in 0..<int(kl):
  let x=v[2+i]
  if not ((x>=65 and x<=90) or (x>=97 and x<=122)):return -1
  let c=uint8(if x>=97:x-32 else:x)
  var found=false
  for j in 0..<count:
   if key[j]==c:found=true
  if not found:key[count]=c;inc count
 var map:array[26,uint8];var k=0
 for i in 0..<count:map[k]=key[i];inc k
 for x in 65..90:
  var found=false
  for j in 0..<count:
   if key[j]==uint8(x):found=true
  if not found:map[k]=uint8(x);inc k
 var result:array[256,uint8]
 for i in 0..<int(ml):
  let x=v[2+int(kl)+i]
  if x<0 or x>127:return -1
  let c=uint8(if x>=97 and x<=122:x-32 else:x)
  if c>=65 and c<=90:
   var j=0
   while j<26 and map[j]!=c:inc j
   if j==26:return -1
   result[i]=uint8(65+j)
  else:result[i]=c
 if output.isNil or capacity<csize_t(ml):return -2
 for i in 0..<int(ml):output[i]=result[i]
 ml
