proc put64(output:ptr UncheckedArray[uint8],pos:var int,x:int64)=
  let bits=cast[uint64](x)
  for j in 0..<8:output[pos]=uint8((bits shr (8*j)) and 255);inc pos
proc stack_tracking_min_max*(input:ptr UncheckedArray[int64],length:csize_t,output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"stack_tracking_min_max".}=
  if input==nil or length<2 or length>130:return -1
  let maxSize=input[0];let count=input[1]
  if maxSize<0 or maxSize>64 or count<0 or count>64:return -1
  var p=2
  for _ in 0..<int(count):
    if p>=int(length):return -1
    let op=input[p];inc p
    if op==1:
      if p>=int(length) or input[p]<int64(low(int32)) or input[p]>int64(high(int32)):return -1
      inc p
    elif op<2 or op>5:return -1
  if p!=int(length):return -1
  var vals,minima,maxima:array[64,int64]
  var records:array[64,array[3,int64]]
  var top=0;var rc=0;p=2
  for _ in 0..<int(count):
    let op=input[p];inc p;var tag=0'i64;var result=0'i64
    if op==1:
      let x=input[p];inc p
      if top==int(maxSize):records[rc]=[1'i64,4,1];inc rc;break
      vals[top]=x;minima[top]=if top==0:x else:minima[top-1].min(x);maxima[top]=if top==0:x else:maxima[top-1].max(x);inc top;tag=1;result=1
    elif op==2:
      if top>0:dec top;result=vals[top]
      else:tag=3
    elif op==3:
      if top>0:result=minima[top-1]
      else:tag=3
    elif op==4:
      if top>0:result=maxima[top-1]
      else:tag=3
    else:tag=1;result=if top>0:1 else:0
    records[rc]=[op,tag,result];inc rc
  let need=rc*24
  if output==nil or capacity<csize_t(need):return -2
  var pos=0
  for i in 0..<rc:
    for j in 0..<3:put64(output,pos,records[i][j])
  int64(pos)
