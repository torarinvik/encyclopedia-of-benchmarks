proc ewma_change_detector*(v:ptr UncheckedArray[int64],n:csize_t):int64 {.cdecl,exportc:"ewma_change_detector".} =
  if v.isNil or n<1 or n>16:return -1
  let count=v[0]
  if count<0 or count>15 or n!=csize_t(count+1):return -1
  var exponent=0'i64;var numerator=0'i64;var packed=0'i64
  for i in 0..<int(count):
    let sample=v[i+1]
    if sample < -8 or sample>8:return -1
    inc exponent;numerator+=sample*(1'i64 shl int(exponent-1))
    var signal=0'i64
    if 3*numerator*numerator>((1'i64 shl int(2*exponent))-1):
      if numerator>0: signal=1 else: signal=2
      exponent=0
      numerator=0
    packed=packed*4+signal
  packed
