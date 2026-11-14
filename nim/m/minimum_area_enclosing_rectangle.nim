proc projection(input: ptr UncheckedArray[int64], index: int, dx,dy: int64, axis: int): int64 =
  let x=input[1+2*index]; let y=input[2+2*index]
  if axis==2: dx*y-dy*x else: dx*x+dy*y

proc minimum_area_enclosing_rectangle*(input: ptr UncheckedArray[int64], length: csize_t,
    output: ptr UncheckedArray[uint8], capacity: csize_t): int64
    {.cdecl, exportc: "minimum_area_enclosing_rectangle".} =
  if input.isNil or length<7 or length>34 or input[0]<3 or input[0]>16: return -1
  let n=int(input[0])
  if length!=csize_t(1+2*n): return -1
  for i in 1 ..< int(length):
    if input[i]< -100 or input[i]>100: return -1
  for i in 0 ..< n:
    let next=(i+1) mod n
    let ax=input[1+2*i]; let ay=input[2+2*i]
    let dx=input[1+2*next]-ax; let dy=input[2+2*next]-ay
    for j in 0 ..< n:
      if j!=i and j!=next and dx*(input[2+2*j]-ay)-dy*(input[1+2*j]-ax)<=0: return -1
  let firstDx=input[3]-input[1]; let firstDy=input[4]-input[2]
  var supports: array[3,int]
  for i in 1 ..< n:
    for axis in 0 ..< 3:
      let current=projection(input,supports[axis],firstDx,firstDy,axis)
      let candidate=projection(input,i,firstDx,firstDy,axis)
      if (axis==1 and candidate<current) or (axis!=1 and candidate>current): supports[axis]=i
  var bestNum=0'i64; var bestDen=1'i64
  for i in 0 ..< n:
    let next=(i+1) mod n
    let ax=input[1+2*i]; let ay=input[2+2*i]
    let dx=input[1+2*next]-ax; let dy=input[2+2*next]-ay
    for axis in 0 ..< 3:
      for step in 0 ..< n:
        let following=(supports[axis]+1) mod n
        let current=projection(input,supports[axis],dx,dy,axis)
        let candidate=projection(input,following,dx,dy,axis)
        if (axis==1 and candidate<=current) or (axis!=1 and candidate>=current): supports[axis]=following
        else: break
    let span=projection(input,supports[0],dx,dy,0)-projection(input,supports[1],dx,dy,1)
    let thickness=projection(input,supports[2],dx,dy,2)-(dx*ay-dy*ax)
    let numerator=span*thickness; let denominator=dx*dx+dy*dy
    if i==0 or numerator*bestDen<bestNum*denominator:
      bestNum=numerator; bestDen=denominator
  var a=bestNum; var b=bestDen
  while b!=0:
    let remainder=a mod b
    a=b; b=remainder
  let words=[bestNum div a,bestDen div a]
  if output.isNil or capacity<16: return -2
  for i in 0 ..< 2:
    var bits=cast[uint64](words[i])
    for j in 0 ..< 8:
      output[8*i+j]=uint8(bits and 255'u64)
      bits=bits shr 8
  16
