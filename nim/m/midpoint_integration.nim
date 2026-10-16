import std/math
proc store(x:int64,out:ptr UncheckedArray[uint8])=let u=cast[uint64](x);for b in 0..<8:out[b]=uint8((u shr (8*b)) and 255)
proc midpoint_integration*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"midpoint_integration".}=
  if input.isNil or length!=4:return -1
  let f=input[0];let steps=input[1];let aa=input[2];let bb=input[3]
  if f<0 or f>2 or steps<1 or steps>256 or aa< -1_000_000 or aa>1_000_000 or bb<aa or bb>1_000_000:return -1
  if output.isNil or capacity<8:return -2
  let a=float64(aa)/1_000_000.0;let b=float64(bb)/1_000_000.0;let h=(b-a)/float64(steps);var sum=0.0
  for i in 0..<int(steps):let x=a+float64(i)*h+h/2;let y=if f==0:1.0 elif f==1:x else:x*x;sum+=y
  let result=int64(floor(h*sum*1_000_000_000.0+0.5));store(result,output);8
