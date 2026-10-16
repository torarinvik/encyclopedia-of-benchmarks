## Trace Lua-style directed graph updates and queries.
proc putI64Le(output: ptr UncheckedArray[uint8], index: int, value: int64) =
  let bits=cast[uint64](value)
  for b in 0..<8:output[index*8+b]=uint8((bits shr (8*b)) and 0xFF'u64)
proc graph_lua_directed_weighted*(input: ptr UncheckedArray[int64],length: csize_t,output: ptr UncheckedArray[uint8],capacity: csize_t): int64 {.cdecl,exportc:"graph_lua_directed_weighted".}=
  if input.isNil or length<2:return -1
  let nv=input[0];let ov=input[1]
  if nv<1 or nv>16 or ov<0 or ov>63 or length!=csize_t(2+4*ov):return -1
  let n=int(nv);let ops=int(ov);var kind:array[16,array[16,int64]];var weight:array[16,array[16,int64]];var resultKind:array[63,int64];var resultValue:array[63,int64]
  for i in 0..<ops:
    let op=input[2+4*i];let a=input[3+4*i];let b=input[4+4*i];let v=input[5+4*i]
    if op<0 or op>5 or a<0 or a>=nv or b<0 or b>=nv:return -1
    let x=int(a);let y=int(b)
    if op==0:
      if v< -1000 or v>1000:return -1
      kind[x][y]=2;weight[x][y]=v;resultKind[i]= -1
    elif op==1:
      if v!=0:return -1
      kind[x][y]=1;weight[x][y]=0;resultKind[i]= -1
    elif op==2:
      if v!=0:return -1
      kind[x][y]=0;weight[x][y]=0;resultKind[i]= -1
    elif op==3:
      if v!=0 or kind[x][y]!=0:return -1
      kind[x][y]=1;weight[x][y]=0;resultKind[i]= -1
    elif op==4:
      if v!=0:return -1
      resultKind[i]=kind[x][y]
      if kind[x][y]==2:resultValue[i]=weight[x][y]
    else:
      if v!=0:return -1
      resultKind[i]=if kind[x][y]!=0:1 else:0
  var edges=0
  for a in 0..<n:for b in 0..<n:if kind[a][b]!=0:inc edges
  let words=2+2*ops+4*edges
  if output.isNil or capacity<csize_t(words*8):return -2
  var k=0;putI64Le(output,k,int64(ops));inc k
  for i in 0..<ops:putI64Le(output,k,resultKind[i]);inc k;putI64Le(output,k,resultValue[i]);inc k
  putI64Le(output,k,int64(edges));inc k
  for a in 0..<n:for b in 0..<n:if kind[a][b]!=0:putI64Le(output,k,int64(a));inc k;putI64Le(output,k,int64(b));inc k;putI64Le(output,k,kind[a][b]);inc k;putI64Le(output,k,weight[a][b]);inc k
  int64(words*8)
