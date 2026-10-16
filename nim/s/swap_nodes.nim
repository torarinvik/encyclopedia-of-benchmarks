proc put64(outp:ptr UncheckedArray[uint8],pos:var int,x:int64)=
  let bits=cast[uint64](x);for j in 0..<8:outp[pos]=uint8((bits shr (8*j)) and 255);inc pos
proc swap_nodes*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"swap_nodes".}=
  if input==nil or length<3:return -1
  let n0=input[0];if n0<0 or n0>64 or length!=csize_t(n0+3):return -1
  let n=int(n0);for i in 0..<n:if input[1+i]<int64(low(int32)) or input[1+i]>int64(high(int32)):return -1
  let a=input[1+n];let b=input[2+n];if a<int64(low(int32)) or a>int64(high(int32)) or b<int64(low(int32)) or b>int64(high(int32)):return -1
  let need=8+8*n;if output==nil or capacity<csize_t(need):return -2
  var ia=n;var ib=n;if a!=b:for i in 0..<n:if ia==n and input[1+i]==a:ia=i;if ib==n and input[1+i]==b:ib=i
  var pos=0;put64(output,pos,n0);for i in 0..<n:var x=input[1+i];if ia<n and ib<n:if i==ia:x=b elif i==ib:x=a;put64(output,pos,x)
  int64(pos)
