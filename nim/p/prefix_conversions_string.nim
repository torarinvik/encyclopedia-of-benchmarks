proc appendI64(outp:ptr UncheckedArray[uint8],at0:int,x0:int64):int=
  var at=at0;var x=x0
  if x<0:outp[at]=uint8(ord('-'));inc at;x= -x
  if x==0:outp[at]=uint8(ord('0'));return at+1
  var rev:array[24,uint8];var n=0
  while x>0:rev[n]=uint8(ord('0')+int(x mod 10));inc n;x=x div 10
  while n>0:dec n;outp[at]=rev[n];inc at
  at
proc raw(outp:ptr UncheckedArray[uint8],x:int64):int64=int64(appendI64(outp,0,x))
proc scaled(outp:ptr UncheckedArray[uint8],x,scale:int64,prefixName:string):int64=
  if x mod scale!=0:return -1
  var at=appendI64(outp,0,x div scale)
  for c in ".0 ":outp[at]=uint8(ord(c));inc at
  for c in prefixName:outp[at]=uint8(ord(c));inc at
  int64(at)
proc prefix_conversions_string*(v:ptr UncheckedArray[int64],n:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"prefix_conversions_string".}=
  if v.isNil or n!=2 or (v[0]!=0 and v[0]!=1) or v[1]< -1_000_000_000_000'i64 or v[1]>1_000_000_000_000'i64:return -1
  if output.isNil or capacity<8192:return -2
  let x=v[1];if x<=0:return raw(output,x)
  if v[0]==0:
    if x>1_000_000_000:return scaled(output,x,1_000_000_000,"giga")
    if x>1_000_000:return scaled(output,x,1_000_000,"mega")
    if x>1000:return scaled(output,x,1000,"kilo")
    if x>100:return scaled(output,x,100,"hecto")
    if x>10:return scaled(output,x,10,"deca")
  else:
    if x>1_073_741_824:return scaled(output,x,1_073_741_824,"giga")
    if x>1_048_576:return scaled(output,x,1_048_576,"mega")
    if x>1024:return scaled(output,x,1024,"kilo")
  raw(output,x)
