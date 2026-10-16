const invalidResult = -1.0e300
proc sample(id:int64,x:float64):float64 =
  if id==0: x*x else: x*x*x-x*x+378.0
proc integral_approximation*(v:ptr UncheckedArray[int64],n:csize_t):float64 {.cdecl,exportc:"integral_approximation".} =
  if v.isNil or n!=4:return invalidResult
  let id=v[0];let li=v[1];let ui=v[2];let di=v[3]
  if id<0 or id>1 or li<0 or ui>32 or li>=ui or di<1 or di>8:return invalidResult
  let lo=float64(li)/8.0;let hi=float64(ui)/8.0;let d=float64(di)/8.0
  let count=uint64((hi-lo)/d)
  if count>32:return invalidResult
  var total=0.0
  for i in 0..<int(count):
    let begin=lo+float64(i)*d;let finish=lo+float64(i+1)*d
    total+=d*(sample(id,begin)+sample(id,finish))/2.0
  total
