const MaxLength = 1024
proc asciiSpace(c:int64):bool = c==9 or c==10 or c==11 or c==12 or c==13 or c==32
proc validate_email*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"validate_email".} =
  if values==nil or length<2 or length>MaxLength+1 or values[0]<1 or values[0]>MaxLength or int(values[0])+1!=int(length):return -1
  var finish=int(values[0])
  for i in 0..<finish:
    if values[i+1]<0 or values[i+1]>127:return -1
  if finish>0 and (values[finish]==10 or values[finish]==13):dec finish
  var at=finish
  for i in 0..<finish:
    let c=values[i+1]
    if asciiSpace(c):return 0
    if c==64:
      if at!=finish:return 0
      at=i
  if at==0 or at>=finish-1:return 0
  for i in at+2..<finish-1:
    if values[i+1]==46:return 1
  0
