# BYTEmark (tm), BYTE's Native Mode Benchmarks; Rick Grehan, BYTE Magazine.
# Unix port: Uwe F. Mayer. Source notice/disclaimer is in package LICENSE.
const MaxText=128
const MaxStreamBytes=258
const Excluded=32000
type HuffNode=object
  c:uint8
  freq:float32
  parent:int
  left:int
  right:int

proc nbench_huffman_compression*(input:ptr UncheckedArray[int64],length:csize_t,
  output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"nbench_huffman_compression".} =
  if input==nil or length<2 or length>csize_t(MaxText+1):return -1
  let rawN=input[0]
  if rawN<1 or rawN>int64(MaxText) or length!=csize_t(rawN+1):return -1
  let n=int(rawN);let arraySize=n+1
  var text:array[MaxText+1,uint8]
  var seen:array[256,bool]
  var distinct=0
  for i in 0..<n:
    let x=input[i+1]
    if x<32 or x>47:return -1
    text[i]=uint8(x)
    if not seen[int(text[i])]:seen[int(text[i])]=true;inc distinct
  text[n]=0
  if not seen[0]:inc distinct
  if distinct<2:return -1
  var tree:array[512,HuffNode]
  for i in 0..<256:tree[i]=HuffNode(c:uint8(i),freq:0.0'f32,parent:-1,left:-1,right:-1)
  for i in 0..<arraySize:tree[int(text[i])].freq=tree[int(text[i])].freq+1.0'f32
  for i in 0..<256:if tree[i].freq!=0.0'f32:tree[i].freq=tree[i].freq/float32(arraySize)
  for i in 256..<512:tree[i]=HuffNode(c:0,freq:0.0'f32,parent:Excluded,left:0,right:0)
  for i in 0..<512:
    if tree[i].freq==0.0'f32:tree[i].parent=Excluded
    else:tree[i].parent = -1;tree[i].left = -1;tree[i].right = -1
  var root=255
  while true:
    var low1=2.0'f32;var low2=2.0'f32;var idx1 = -1;var idx2 = -1
    for i in 0..root:if tree[i].parent<0 and tree[i].freq<low1:low1=tree[i].freq;idx1=i
    if idx1<0:break
    for i in 0..root:if tree[i].parent<0 and i!=idx1 and tree[i].freq<low2:low2=tree[i].freq;idx2=i
    if idx2<0:break
    inc root;tree[idx1].parent=root;tree[idx2].parent=root;tree[root].freq=low1+low2;tree[root].left=idx1;tree[root].right=idx2;tree[root].parent = -2
  if root<256 or tree[root].left<0:return -1
  var stream:array[MaxStreamBytes,uint8]
  var bitCount=0
  for i in 0..<arraySize:
    var path:array[30,int]
    var count=0
    var node=int(text[i])
    while tree[node].parent != -2:
      let parent=tree[node].parent
      if parent<0 or parent>=512 or count>=30:return -1
      path[count]=if tree[parent].left==node:0 else:1
      inc count;node=parent
    while count>0:
      dec count
      if path[count]!=0:stream[bitCount div 8]=stream[bitCount div 8] or (1'u8 shl (bitCount mod 8))
      inc bitCount
  var decoded:array[MaxText+1,uint8]
  var bit=0;var pos=0
  while bit<bitCount:
    var node=root
    while tree[node].left != -1:
      let b=(stream[bit div 8] shr (bit mod 8)) and 1
      node=if b==0:tree[node].left else:tree[node].right
      inc bit
      if bit>bitCount:return -1
    if pos>=arraySize:return -1
    decoded[pos]=tree[node].c;inc pos
  if pos!=arraySize:return -1
  for i in 0..<arraySize:if decoded[i]!=text[i]:return -1
  let streamBytes=(bitCount+7) div 8;let total=4+streamBytes
  if output==nil or capacity<csize_t(total):return -2
  let bits=uint32(bitCount)
  for b in 0..<4:output[b]=uint8((bits shr (8*b)) and 255)
  for i in 0..<streamBytes:output[4+i]=stream[i]
  int64(total)
