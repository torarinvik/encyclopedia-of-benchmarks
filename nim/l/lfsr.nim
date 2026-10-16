const MaxTaps=63
const MaxClocks=256
proc put(outp:ptr UncheckedArray[uint8],slot:int,value:int64)=
  let bits=cast[uint64](value)
  for i in 0..<8:outp[slot*8+i]=uint8((bits shr (8*i)) and 255)
proc feedback(state:uint64,input:ptr UncheckedArray[int64],count:int):uint64=
  var bit=0'u64
  for i in 0..<count:bit=bit xor ((state shr int(input[6+i])) and 1'u64)
  bit
proc step(state:var uint64,width:int,mask:uint64,input:ptr UncheckedArray[int64],count:int):uint64=
  let output=(state shr (width-1)) and 1'u64
  state=((state shl 1) or feedback(state,input,count)) and mask
  output
proc lfsr*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"lfsr".}=
  if input==nil or length<6 or input[0]<1 or input[0]>63 or input[1]<0 or input[1]>=input[0] or input[2]<0 or input[2]>MaxTaps or input[3]<0 or input[3]>MaxClocks or input[5]<0 or input[5]>4194303:return -1
  let width=int(input[0]);let count=int(input[2]);let clocks=int(input[3]);if int(length)!=6+count:return -1
  for i in 0..<count:if input[6+i]<0 or input[6+i]>=input[0]:return -1
  var state=0'u64;let key=cast[uint64](input[4]);let frame=uint64(input[5]);let mask=(1'u64 shl width)-1
  for bit in countdown(63,0):state=((state shl 1) or (((key shr bit) and 1'u64) xor feedback(state,input,count))) and mask
  for bit in countdown(21,0):state=((state shl 1) or (((frame shr bit) and 1'u64) xor feedback(state,input,count))) and mask
  let bytes=(clocks+2)*8;if output==nil or int(capacity)<bytes:return -2
  put(output,0,int64(clocks));for i in 0..<clocks:put(output,1+i,int64(step(state,width,mask,input,count)))
  put(output,1+clocks,int64(state))
  int64(bytes)
