module crc16
const max_length=100001
@[export:'crc16']
pub fn crc16(values &i64,length usize)i64{
 if length>max_length||(length!=0&&values==nil){return -1};mut crc:=i64(65535)
 for n in 0..length{byte:=unsafe{values[n]};if byte<0||byte>255{return -1};for bit in 0..8{shift:=7-bit;incoming:=(byte>>shift)&1;top:=(crc>>15)&1;crc=(crc<<1)&65535;if (top^incoming)!=0{crc^=4129}}}
 return crc
}
