const MaxLength=100001
proc crc16*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"crc16".}=
  if length>csize_t(MaxLength) or (length!=0 and values==nil):return -1
  var crc=65535'i64
  for n in 0..<int(length):
    let byte=values[n];if byte<0 or byte>255:return -1
    for bit in countdown(7,0):
      let incoming=(byte shr bit) and 1;let top=(crc shr 15) and 1
      crc=(crc shl 1) and 65535
      if (top xor incoming)!=0:crc=crc xor 4129
  crc
