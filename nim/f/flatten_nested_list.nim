const Open = low(int64)
const Close = low(int64) + 1
proc signedHash(hash: uint64): int64 =
 let sign = 1'u64 shl 63
 if hash < sign: return int64(hash)
 let magnitude = high(uint64) - hash + 1'u64
 if magnitude == sign: return low(int64)
 -int64(magnitude)

proc flatten_nested_list*(v: ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"flatten_nested_list".}=
 if v==nil or n==0 or n>255 or v[0]!=Open:return -1
 var depth=0;var closed=false;var h=0xcbf29ce484222325'u64
 for i in 0..<int(n):
  let x=v[i]
  if x==Open:
   if closed or (depth==0 and i!=0):return -1
   inc depth;if depth>16:return -1
  elif x==Close:
   if depth==0:return -1
   dec depth;if depth==0:closed=true;if i+1!=int(n):return -1
  else:
   if depth==0 or x< -1000000 or x>1000000:return -1
   let u=cast[uint64](x)
   for b in 0..7: h=(h xor ((u shr (8*b)) and 255'u64))*0x100000001b3'u64
 if depth!=0 or not closed:return -1
 signedHash(h)
