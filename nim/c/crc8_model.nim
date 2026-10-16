const MaxLength=100001
proc reverse8(value: uint8): uint8 =
  var x=value
  x=uint8((x shr 4) or (x shl 4));x=uint8(((x and 0xcc'u8) shr 2) or ((x and 0x33'u8) shl 2));uint8(((x and 0xaa'u8) shr 1) or ((x and 0x55'u8) shl 1))
proc crc8_model*(input:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"crc8_model".}=
  if input.isNil or length<6:return -1
  let poly=input[0];let init=input[1];let rin=input[2];let rout=input[3];let xorOut=input[4];let count=input[5]
  if poly<0 or poly>255 or init<0 or init>255 or xorOut<0 or xorOut>255 or (rin!=0 and rin!=1) or (rout!=0 and rout!=1) or count<0 or count>MaxLength or length!=csize_t(6+count):return -1
  var crc=uint8(init)
  for i in 0..<int(count):
    let value=input[6+i];if value<0 or value>255:return -1
    var byte=uint8(value);if rin==1:byte=reverse8(byte);crc=crc xor byte
    for bit in 0..<8:
      let top=(crc and 0x80'u8)!=0;crc=crc shl 1;if top:crc=crc xor uint8(poly)
  if rout==1:crc=reverse8(crc)
  int64(crc xor uint8(xorOut))
