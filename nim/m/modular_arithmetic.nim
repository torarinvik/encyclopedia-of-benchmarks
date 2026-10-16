proc modular_arithmetic*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"modular_arithmetic".}=
  if values.isNil or length!=4:return -1
  let op=values[0];let m=values[1];let a=values[2];let b=values[3]
  if op<0 or op>2 or m<1 or m>1_000_000 or a<0 or a>=m or b<0 or b>=m:return -1
  case op
  of 0: ((a mod m)+(b mod m)) mod m
  of 1: ((a mod m)-(b mod m)+m) mod m
  else: ((a mod m)*(b mod m)) mod m
