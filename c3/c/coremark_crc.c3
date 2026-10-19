// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
// Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
// Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
module coremark_crc;
fn ushort crcu8(uchar data,ushort crc){for(int i=0;i<8;i++){uchar feedback=(uchar)((data&1)^((uchar)crc&1));data>>=1;uchar carry=0;if(feedback!=0){crc^=0x4002;carry=1;}crc>>=1;if(carry!=0)crc|=0x8000;else crc&=0x7fff;}return crc;}
fn ushort crcu16(ushort value,ushort crc){crc=crcu8((uchar)value,crc);return crcu8((uchar)(value>>8),crc);}
fn ushort crc16(short value,ushort crc){return crcu16((ushort)value,crc);}
fn ushort crcu32(uint value,ushort crc){crc=crc16((short)value,crc);return crc16((short)(value>>16),crc);}
fn long coremark_crc(long* values,usz length) @export("coremark_crc"){
 if(values==null||length<4||length>49)return -1;long count=values[0];if(count<1||count>16||length!=1+3*(usz)count)return -1;long total=0;
 for(usz i=0;i<(usz)count;i++){long tag=values[1+3*i],seed=values[2+3*i],value=values[3+3*i];if(seed<0||seed>65535)return -1;ushort crc;
  if(tag==0&&value>=0&&value<=255)crc=crcu8((uchar)value,(ushort)seed);
  else if(tag==1&&value>=0&&value<=65535)crc=crcu16((ushort)value,(ushort)seed);
  else if(tag==2&&value>=0&&value<=4294967295L)crc=crcu32((uint)value,(ushort)seed);
  else if(tag==3&&value>=-32768&&value<=32767)crc=crc16((short)value,(ushort)seed);else return -1;
  total+=(long)(i+1)*(long)crc;
 }return total;
}
