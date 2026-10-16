const A: array[11,int64] = [1073741824, -3875279605, 7242592440, -9849938776, 11019995787, -10310050823, 8022431451, -5130046574, 2558322377, -874363774, 153873500]
const B: array[11,int64] = [60930872, -44894685, -5549718, -9621322, -7681698, 30506759, -32060412, 22380311, -4826655, 8028337, -4488672]
const HA: array[11,int64] = [1089966811, -2146993250, 1057516837, 0, 0, 0, 0, 0, 0, 0, 0]
const HB: array[11,int64] = [1073619225, -2147238449, 1073619225, 0, 0, 0, 0, 0, 0, 0, 0]
proc step(sample:int64,a,b:openArray[int64],order:int,x,y:var openArray[int64]):int64 =
  var acc=b[0]*sample
  for i in 1..order: acc += b[i]*x[i-1]-a[i]*y[i-1]
  let outputValue=acc div a[0]
  for i in countdown(order-1,1): x[i]=x[i-1];y[i]=y[i-1]
  if order>0: x[0]=sample;y[0]=outputValue
  outputValue
proc equal_loudness_filter*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"equal_loudness_filter".} =
  if v.isNil or n<1 or n>33:return -1
  let count=v[0]
  if count<0 or count>32 or n!=csize_t(count+1):return -1
  var x,y:array[10,int64];var hx,hy:array[2,int64]
  var output=0'i64
  for i in 0..<int(count):
    let sample=v[i+1]
    if sample < -1000000 or sample>1000000:return -1
    let mid=step(sample,A,B,10,x,y)
    output=step(mid,HA,HB,2,hx,hy)
  output
