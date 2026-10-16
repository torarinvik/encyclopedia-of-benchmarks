type I64Input=ptr UncheckedArray[int64]
type U8Output=ptr UncheckedArray[uint8]
proc putI64Le(out:U8Output, offset:int, value:int64)=
  let bits=cast[uint64](value)
  for b in 0..<8: out[offset+b]=uint8((bits shr (8*b)) and 0xff'u64)
proc floor_and_ceiling*(input:I64Input, length:csize_t, output:U8Output, capacity:csize_t):int64 {.cdecl,exportc:"floor_and_ceiling".}=
  if input==nil or length<3 or length>384: return -1
  let rawN=input[0];let root=input[1];let key=input[2]
  if rawN<0 or rawN>127 or key < -1_000_000 or key>1_000_000 or length!=csize_t(3+3*rawN): return -1
  let n=int(rawN)
  if (n==0 and root != -1) or (n>0 and (root<0 or root>=rawN)): return -1
  var floor=low(int64);var ceiling=low(int64)
  var current=if n==0:n else:int(root)
  for step in 0..<n:
    if current>=n: break
    let base=3+3*current;let value=input[base];let left=input[base+1];let right=input[base+2]
    if value < -1_000_000 or value>1_000_000 or left < -1 or right < -1 or left>=rawN or right>=rawN: return -1
    if value==key: floor=value;ceiling=value;break
    if key<value: ceiling=value;current=if left<0:n else:int(left)
    else: floor=value;current=if right<0:n else:int(right)
  if output==nil or capacity<16: return -2
  putI64Le(output,0,floor);putI64Le(output,8,ceiling);16
