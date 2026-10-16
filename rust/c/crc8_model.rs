const MAX_LENGTH: usize = 100_001;
fn reverse8(mut x:u8)->u8{x=x.rotate_left(4);x=((x&0xcc)>>2)|((x&0x33)<<2);((x&0xaa)>>1)|((x&0x55)<<1)}
#[no_mangle]
pub unsafe extern "C" fn crc8_model(input:*const i64,length:usize)->i64{
 if input.is_null()||length<6{return -1;}let v=unsafe{std::slice::from_raw_parts(input,length)};let(poly,init,rin,rout,xo,count)=(v[0],v[1],v[2],v[3],v[4],v[5]);
 if poly<0||poly>255||init<0||init>255||xo<0||xo>255||(rin!=0&&rin!=1)||(rout!=0&&rout!=1)||count<0||count>MAX_LENGTH as i64||length!=6+count as usize{return -1;}
 let mut crc=init as u8;for &value in &v[6..]{if !(0..=255).contains(&value){return -1;}let mut byte=value as u8;if rin==1{byte=reverse8(byte);}crc^=byte;for _ in 0..8{let top=crc&0x80!=0;crc=crc.wrapping_shl(1);if top{crc^=poly as u8;}}}
 if rout==1{crc=reverse8(crc);}i64::from(crc^(xo as u8))
}
