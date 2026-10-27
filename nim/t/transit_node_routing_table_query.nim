proc putI64(outp: ptr UncheckedArray[uint8], word: int, value: int64) =
  let bits = cast[uint64](value)
  for b in 0 ..< 8: outp[word*8+b] = uint8((bits shr (8*b)) and 255)

proc transit_node_routing_table_query*(input: ptr UncheckedArray[int64], length:csize_t,
    output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc.} =
  if input.isNil or length<11 or length>86:return -1
  let q0=input[0];let source=input[1];let target=input[2]
  if q0<1 or q0>8 or source<0 or source>=32 or target<0 or target>=32 or input[3]!=1:return -1
  let q=int(q0);var at=4;let nf0=input[at];inc at
  if nf0<1 or nf0>4 or nf0>q0 or at+2*int(nf0)>int(length):return -1
  let nf=int(nf0);var f:array[8,int];var ds:array[8,int64]
  for i in 0..<nf:
    let u=input[at];let d=input[at+1];at+=2
    if u<0 or u>=q0 or d<0 or d>1_000_000:return -1
    for j in 0..<i:if f[j]==int(u):return -1
    f[i]=int(u);ds[i]=d
  if at>=int(length):return -1
  let nb0=input[at];inc at
  if nb0<1 or nb0>4 or nb0>q0 or at+2*int(nb0)>int(length):return -1
  let nb=int(nb0);var b:array[8,int];var dt:array[8,int64]
  for i in 0..<nb:
    let v=input[at];let d=input[at+1];at+=2
    if v<0 or v>=q0 or d<0 or d>1_000_000:return -1
    for j in 0..<i:if b[j]==int(v):return -1
    b[i]=int(v);dt[i]=d
  if at+q*q!=int(length):return -1
  var table:array[8,array[8,int64]]
  for i in 0..<q:for j in 0..<q:let d=input[at];inc at;if d<0 or d>1_000_000:return -1;table[i][j]=d
  for i in 0..<q:if table[i][i]!=0:return -1
  var best=high(int64);var bestu=0;var bestv=0
  for i in 0..<nf:for j in 0..<nb:
    let d=ds[i]+table[f[i]][b[j]]+dt[j]
    if d<best or (d==best and (f[i]<bestu or (f[i]==bestu and b[j]<bestv))):best=d;bestu=f[i];bestv=b[j]
  if output.isNil or capacity<24:return -2
  putI64(output,0,best);putI64(output,1,int64(bestu));putI64(output,2,int64(bestv));24
