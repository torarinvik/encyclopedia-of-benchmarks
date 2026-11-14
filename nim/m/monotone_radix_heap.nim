proc bucketOf(key,last: uint32): int =
  var difference=key xor last
  while difference!=0:
    inc result
    difference=difference shr 1

proc monotone_radix_heap*(input: ptr UncheckedArray[int64], length: csize_t): int64
    {.cdecl, exportc: "monotone_radix_heap".} =
  if input.isNil or length<1 or length>130 or input[0]<0 or input[0]>64: return -1
  let q=int(input[0])
  if length!=csize_t(1+2*q): return -1
  var heads: array[32,int]
  var next: array[64,int]
  var keys: array[64,uint32]
  for i in 0 ..< 32: heads[i] = -1
  var used=0; var removals=0'i64; var last=0'u32; var total=0'i64
  for i in 0 ..< q:
    let op=input[1+2*i]; let key=input[2+2*i]
    if op==0:
      if key<int64(last) or key>2147483647'i64: return -1
      let value=uint32(key)
      let bucket=bucketOf(value,last)
      keys[used]=value; next[used]=heads[bucket]; heads[bucket]=used; inc used
    elif op==1 and key==0:
      if heads[0]<0:
        var bucket=1
        while bucket<32 and heads[bucket]<0: inc bucket
        if bucket==32: return -1
        var smallest=high(uint32)
        var node=heads[bucket]
        while node>=0:
          smallest=min(smallest,keys[node])
          node=next[node]
        last=smallest
        node=heads[bucket]; heads[bucket] = -1
        while node>=0:
          let following=next[node]
          let destination=bucketOf(keys[node],last)
          next[node]=heads[destination]; heads[destination]=node
          node=following
      let node=heads[0]
      heads[0]=next[node]
      inc removals
      total+=removals*int64(keys[node])
    else: return -1
  total
