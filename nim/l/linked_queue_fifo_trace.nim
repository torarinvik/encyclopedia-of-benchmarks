## Run a linked FIFO trace and then drain the remaining queue.
proc putI32Le(output: ptr UncheckedArray[uint8], index: int, value: int32) =
  let bits = cast[uint32](value)
  for b in 0..<4: output[index*4+b] = uint8((bits shr (8*b)) and 0xFF'u32)
proc linked_queue_fifo_trace*(input: ptr UncheckedArray[int64], length: csize_t, output: ptr UncheckedArray[uint8], capacity: csize_t): int64 {.cdecl, exportc:"linked_queue_fifo_trace".} =
  if input.isNil or length<1:return -1
  let ops64=input[0]
  if ops64<0 or ops64>127 or length!=csize_t(1+2*ops64):return -1
  let ops=int(ops64)
  var values:array[127,int32];var next:array[127,int];var result:array[127,int32]
  for i in 0..<127:next[i] = -1
  var head = -1;var rear = -1;var nodes=0;var count=0;var closed=false
  for i in 0..<ops:
    let operation=input[1+2*i];let value=input[2+2*i]
    if operation==0:
      if closed or value<low(int32).int64 or value>high(int32).int64 or nodes>=127:return -1
      values[nodes]=int32(value);next[nodes] = -1
      if head<0:head=nodes else:next[rear]=nodes
      rear=nodes;inc nodes
    elif operation==1:
      if value!=0 or head<0:return -1
      result[count]=values[head];inc count;head=next[head]
      if head<0:rear = -1;closed=true
    else:return -1
  while head>=0:result[count]=values[head];inc count;head=next[head]
  let bytes=count*4
  if bytes>0 and (output.isNil or capacity<csize_t(bytes)):return -2
  for i in 0..<count:putI32Le(output,i,result[i])
  int64(bytes)
