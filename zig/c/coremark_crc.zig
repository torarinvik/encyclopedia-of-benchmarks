// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
// Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
// Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
fn crcu8(data_in:u8,starting:u16)u16{var data=data_in;var crc=starting;for(0..8)|_|{const feedback=(data&1)^@as(u8,@truncate(crc&1));data>>=1;var carry:u16=0;if(feedback!=0){crc^=0x4002;carry=1;}crc>>=1;if(carry!=0){crc|=0x8000;}else{crc&=0x7fff;}}return crc;}
fn crcu16(value:u16,starting:u16)u16{const crc=crcu8(@truncate(value&0xff),starting);return crcu8(@truncate(value>>8),crc);}
fn crc16(value:i16,starting:u16)u16{return crcu16(@bitCast(value),starting);}
fn crcu32(value:u32,starting:u16)u16{const crc=crc16(@bitCast(@as(u16,@truncate(value&0xffff))),starting);return crc16(@bitCast(@as(u16,@truncate(value>>16))),crc);}
export fn coremark_crc(values:[*c]const i64,length:usize)i64{
 if(values==null or length<4 or length>49)return -1;const count=values[0];if(count<1 or count>16 or length!=1+3*@as(usize,@intCast(count)))return -1;var total:i64=0;
 for(0..@intCast(count))|i|{const tag=values[1+3*i];const seed=values[2+3*i];const value=values[3+3*i];if(seed<0 or seed>65535)return -1;const crc:u16=if(tag==0 and value>=0 and value<=255)crcu8(@intCast(value),@intCast(seed)) else if(tag==1 and value>=0 and value<=65535)crcu16(@intCast(value),@intCast(seed)) else if(tag==2 and value>=0 and value<=4294967295)crcu32(@intCast(value),@intCast(seed)) else if(tag==3 and value>=-32768 and value<=32767)crc16(@intCast(value),@intCast(seed)) else return -1;total+=@as(i64,@intCast(i+1))*@as(i64,crc);}
 return total;
}
