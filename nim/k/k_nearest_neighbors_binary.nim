const MaxDim=8
const MaxPoints=128
proc putI64(output:ptr UncheckedArray[uint8],value:int64)=
  let bits=cast[uint64](value)
  for byte in 0..<8:output[byte]=uint8((bits shr (8*byte)) and 255)

proc k_nearest_neighbors_binary*(input:ptr UncheckedArray[int64],length:csize_t,
  output:ptr UncheckedArray[uint8],capacity:csize_t):int64 {.cdecl,exportc:"k_nearest_neighbors_binary".}=
  if input.isNil or length<3 or length>1163:return -1
  let d64=input[0];let n64=input[1];let k64=input[2]
  if d64<1 or d64>MaxDim or n64<1 or n64>MaxPoints or k64<1 or k64>n64 or k64 mod 2==0 or int(length)!=3+int(d64)+int(n64)*(int(d64)+1):return -1
  let d=int(d64);let n=int(n64);let k=int(k64)
  for axis in 0..<d:if input[3+axis]< -1000 or input[3+axis]>1000:return -1
  var distances:array[MaxPoints,int64];var labels:array[MaxPoints,int64]
  for point in 0..<n:
    let base=3+d+point*(d+1);var distance=0'i64
    for axis in 0..<d:
      let x=input[base+axis]
      if x< -1000 or x>1000:return -1
      let delta=x-input[3+axis];distance+=delta*delta
    let label=input[base+d]
    if label!=0 and label!=1:return -1
    for prev in 0..<point:if distances[prev]==distance:return -1
    distances[point]=distance;labels[point]=label
  for i in 1..<n:
    let distance=distances[i];let label=labels[i];var j=i
    while j>0 and distances[j-1]>distance:distances[j]=distances[j-1];labels[j]=labels[j-1];dec j
    distances[j]=distance;labels[j]=label
  var ones=0'i64
  for i in 0..<k:ones+=labels[i]
  let prediction=if ones>int64(k div 2):1'i64 else:0'i64
  if output.isNil or capacity<8:return -2
  putI64(output,prediction);8
