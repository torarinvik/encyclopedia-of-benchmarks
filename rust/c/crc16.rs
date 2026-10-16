const MAX_LENGTH:usize=100_001;
#[no_mangle]
pub unsafe extern "C" fn crc16(values:*const i64,length:usize)->i64{
 if length>MAX_LENGTH||(length!=0&&values.is_null()){return -1;}if length==0{return 65535;}
 let values=unsafe{std::slice::from_raw_parts(values,length)};let mut crc:i64=65535;
 for &byte in values{if !(0..=255).contains(&byte){return -1;}for bit in (0..8).rev(){let incoming=(byte>>bit)&1;let top=(crc>>15)&1;crc=(crc<<1)&65535;if (top^incoming)!=0{crc^=4129;}}}crc
}
