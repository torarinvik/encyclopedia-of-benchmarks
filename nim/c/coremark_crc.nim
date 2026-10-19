## Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
## Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
## Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
const MaxOperations=16
proc crcu8(data_in:uint8,starting:uint16):uint16=
  var data=data_in;var crc=starting
  for _ in 0..<8:
    let feedback=(data and 1) xor uint8(crc and 1);data=data shr 1
    var carry:uint16=0
    if feedback!=0:crc=crc xor 0x4002'u16;carry=1
    crc=crc shr 1
    if carry!=0:crc=crc or 0x8000'u16 else:crc=crc and 0x7fff'u16
  crc
proc crcu16(value:uint16,starting:uint16):uint16=
  let crc=crcu8(uint8(value and 0xff),starting);crcu8(uint8(value shr 8),crc)
proc crc16(value:int16,starting:uint16):uint16=crcu16(cast[uint16](value),starting)
proc crcu32(value:uint32,starting:uint16):uint16=
  let crc=crc16(cast[int16](uint16(value and 0xffff)),starting);crc16(cast[int16](uint16(value shr 16)),crc)
proc coremark_crc*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"coremark_crc".}=
  if values==nil or length<4 or length>49:return -1
  let count=values[0];if count<1 or count>MaxOperations or length!=csize_t(1+3*count):return -1
  var total=0'i64
  for i in 0..<int(count):
    let tag=values[1+3*i];let seed=values[2+3*i];let value=values[3+3*i]
    if seed<0 or seed>65535:return -1
    var crc:uint16
    if tag==0 and value>=0 and value<=255:crc=crcu8(uint8(value),uint16(seed))
    elif tag==1 and value>=0 and value<=65535:crc=crcu16(uint16(value),uint16(seed))
    elif tag==2 and value>=0 and value<=4294967295'i64:crc=crcu32(uint32(value),uint16(seed))
    elif tag==3 and value>= -32768 and value<=32767:crc=crc16(int16(value),uint16(seed))
    else:return -1
    total+=int64(i+1)*int64(crc)
  total
