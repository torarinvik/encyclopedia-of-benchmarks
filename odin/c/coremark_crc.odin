// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
// Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
// Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
package coremark_crc
import "core:c"
crcu8 :: proc(data_in:u8,starting:u16)->u16{data:=data_in;crc:=starting;for _ in 0..<8{feedback:=(data&1)^u8(crc&1);data>>=1;carry:=u16(0);if feedback!=0{crc^=0x4002;carry=1};crc>>=1;if carry!=0{crc|=0x8000}else{crc&=0x7fff}};return crc}
crcu16 :: proc(value,starting:u16)->u16{crc:=crcu8(u8(value&0xff),starting);return crcu8(u8(value>>8),crc)}
crc16 :: proc(value:i16,starting:u16)->u16{return crcu16(u16(value),starting)}
crcu32 :: proc(value:u32,starting:u16)->u16{crc:=crc16(i16(u16(value&0xffff)),starting);return crc16(i16(u16(value>>16)),crc)}
@(export)
coremark_crc::proc "c"(values:[^]i64,length:c.size_t)->i64{
 if values==nil||length<4||length>49 do return -1;count:=values[0];if count<1||count>16||length!=c.size_t(1+3*count) do return -1;total:=i64(0)
 for i:=c.size_t(0);i<c.size_t(count);i+=1{tag:=values[1+3*i];seed:=values[2+3*i];value:=values[3+3*i];if seed<0||seed>65535 do return -1;crc:=u16(0)
  if tag==0&&value>=0&&value<=255{crc=crcu8(u8(value),u16(seed))}else if tag==1&&value>=0&&value<=65535{crc=crcu16(u16(value),u16(seed))}else if tag==2&&value>=0&&value<=4294967295{crc=crcu32(u32(value),u16(seed))}else if tag==3&&value>=-32768&&value<=32767{crc=crc16(i16(value),u16(seed))}else{return -1};total+=i64(i+1)*i64(crc)
 }return total
}
