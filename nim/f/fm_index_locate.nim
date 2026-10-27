const MaxText=32
const MaxPattern=8
const MaxInput=43
const Alphabet=5
proc suffixLess(s: ptr UncheckedArray[int64], n,a0,b0:int):bool =
  var a=a0;var b=b0
  while a<n and b<n:
    if s[a]!=s[b]:return s[a]<s[b]
    inc a;inc b
  a==n and b!=n
proc storeI64LE(outp:ptr UncheckedArray[uint8],off:int,value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8:outp[off+b]=uint8((bits shr (8*b)) and 255)
proc fm_index_locate*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"fm_index_locate".}=
  if input.isNil or length<csize_t(5) or length>csize_t(MaxInput):return -1
  let n64=input[0]
  if n64<1 or n64>32 or int64(length)<n64+4:return -1
  let n=int(n64);let mAt=n+1;let m64=input[mAt]
  if m64<1 or m64>8 or length!=csize_t(mAt+2+int(m64))+1:return -1
  let m=int(m64);let stride64=input[int(length)-1]
  if stride64<1 or stride64>n64:return -1
  let stride=int(stride64);let total=n+1
  var s:array[MaxText+1,int64];var pat:array[MaxPattern,int64]
  for i in 0..<n:
    let x=input[i+1];if x<1 or x>4:return -1;s[i]=x
  for i in 0..<m:
    let x=input[mAt+1+i];if x<1 or x>4:return -1;pat[i]=x
  s[n]=0
  var sa:array[MaxText+1,int]
  for i in 0..<total:sa[i]=i
  for i in 1..<total:
    let key=sa[i];var j=i
    while j>0 and suffixLess(addr s[0],total,key,sa[j-1]):sa[j]=sa[j-1];dec j
    sa[j]=key
  var bwt:array[MaxText+1,int];var freq:array[Alphabet,int]
  for i in 0..<total:bwt[i]=int(s[(sa[i]+total-1) mod total]);inc freq[bwt[i]]
  var c:array[Alphabet,int];var acc=0
  for i in 0..<Alphabet:c[i]=acc;acc+=freq[i]
  var left=0;var right=total
  for j in countdown(m-1,0):
    let sym=int(pat[j]);var rl=0;var rr=0
    for x in 0..<left:
      if bwt[x]==sym: inc rl
    for x in 0..<right:
      if bwt[x]==sym: inc rr
    left=c[sym]+rl;right=c[sym]+rr
    if left==right:break
  var lf:array[MaxText+1,int];var sampled:array[MaxText+1,bool];var samples:array[MaxText+1,int]
  for row in 0..<total:
    let sym=bwt[row];var rank=0
    for x in 0..<row:
      if bwt[x]==sym: inc rank
    lf[row]=c[sym]+rank;sampled[row]=(sa[row] mod stride==0);samples[row]=sa[row]
  var loc:array[MaxText,int64];var count=0
  for origin in left..<right:
    var row=origin;var steps=0
    while not sampled[row] and steps<total:row=lf[row];inc steps
    if not sampled[row]:return -1
    let pos=(samples[row]+steps) mod total
    if pos>=n:return -1
    loc[count]=int64(pos);inc count
  let bytes=8*(count+1)
  if output.isNil or capacity<csize_t(bytes):return -2
  storeI64LE(output,0,int64(count))
  for i in 0..<count:storeI64LE(output,8*(i+1),loc[i])
  int64(bytes)
