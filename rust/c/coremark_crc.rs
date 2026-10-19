// Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC)
// Licensed under the Apache License, Version 2.0: http://www.apache.org/licenses/LICENSE-2.0
// Original Author: Shay Gal-on. Derived algorithm port; no source blocks copied.
fn crcu8(mut data:u8,mut crc:u16)->u16{for _ in 0..8{let feedback=(data&1)^((crc&1)as u8);data>>=1;let carry=if feedback!=0{crc^=0x4002;1}else{0};crc>>=1;if carry!=0{crc|=0x8000}else{crc&=0x7fff}}crc}
fn crcu16(value:u16,mut crc:u16)->u16{crc=crcu8(value as u8,crc);crcu8((value>>8)as u8,crc)}
fn crc16(value:i16,crc:u16)->u16{crcu16(value as u16,crc)}
fn crcu32(value:u32,mut crc:u16)->u16{crc=crc16(value as i16,crc);crc16((value>>16)as i16,crc)}
#[no_mangle]
pub unsafe extern "C" fn coremark_crc(values:*const i64,length:usize)->i64{
 if values.is_null()||length<4||length>49{return -1;}let input=unsafe{std::slice::from_raw_parts(values,length)};let count=input[0];if !(1..=16).contains(&count)||length!=1+3*count as usize{return -1;}let mut total=0i64;
 for i in 0..count as usize{let tag=input[1+3*i];let seed=input[2+3*i];let value=input[3+3*i];if !(0..=65535).contains(&seed){return -1;}let crc=match tag{0 if (0..=255).contains(&value)=>crcu8(value as u8,seed as u16),1 if (0..=65535).contains(&value)=>crcu16(value as u16,seed as u16),2 if (0..=4294967295).contains(&value)=>crcu32(value as u32,seed as u16),3 if (-32768..=32767).contains(&value)=>crc16(value as i16,seed as u16),_=>return -1};total+=(i as i64+1)*crc as i64;}total
}
