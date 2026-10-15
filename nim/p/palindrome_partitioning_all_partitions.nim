const MaxLength=12
const OutCap=16000
type Context = object
  text: ptr UncheckedArray[int64]
  length: int
  ends: array[MaxLength,int]
  packed: array[OutCap,int64]
  used, partitions: int

proc isPalindrome(ctx: Context,start,finish:int):bool=
  var left=start;var right=finish
  while left<right:
    if ctx.text[left+1]!=ctx.text[right]:return false
    inc left;dec right
  true

proc enumerate(ctx:var Context,start,depth:int)=
  if start==ctx.length:
    inc ctx.partitions
    ctx.packed[ctx.used]=int64(depth);inc ctx.used
    for i in 0..<depth:ctx.packed[ctx.used]=int64(ctx.ends[i]);inc ctx.used
    return
  for finish in start+1..ctx.length:
    if isPalindrome(ctx,start,finish):
      ctx.ends[depth]=finish
      enumerate(ctx,finish,depth+1)

proc putI64(output:ptr UncheckedArray[uint8],offset:int,value:int64)=
  let bits=cast[uint64](value)
  for byte in 0..<8:output[offset+byte]=uint8((bits shr (8*byte)) and 255)

proc palindrome_partitioning_all_partitions*(input:ptr UncheckedArray[int64],length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"palindrome_partitioning_all_partitions".}=
  if input.isNil or length<1 or input[0]<0 or input[0]>MaxLength or int(length)!=int(input[0])+1:return -1
  let n=int(input[0])
  for i in 0..<n:if input[i+1]<0 or input[i+1]>127:return -1
  var ctx: Context
  ctx.text=input;ctx.length=n;ctx.used=1;ctx.partitions=0
  enumerate(ctx,0,0);ctx.packed[0]=int64(ctx.partitions)
  let required=ctx.used*8
  if output.isNil or int(capacity)<required:return -2
  for i in 0..<ctx.used:putI64(output,i*8,ctx.packed[i])
  int64(required)
