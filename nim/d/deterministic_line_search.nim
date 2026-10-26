proc putI64Le(out:ptr UncheckedArray[uint8],offset:int,x:int64)=
 let u=cast[uint64](x);for b in 0..<8:out[offset+b]=uint8((u shr (8*b)) and 255'u64)
proc deterministic_line_search*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"deterministic_line_search".}=
 if input.isNil or length!=1:return -1
 let target=input[0];if target==0 or target< -50_000 or target>50_000:return -1
 let distance=abs(target);var traveled=0'i64;var leg=0'i64;var depth=1'i64
 while true:
  let negative=(leg mod 2)==0
  if (target<0)==negative and distance<=depth:traveled+=distance;break
  traveled+=2*depth;depth*=2;inc leg
 if capacity<16 or output.isNil:return -2
 putI64Le(output,0,traveled);putI64Le(output,8,leg);16
