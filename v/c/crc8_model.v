module crc8_model
const max_length = 100001
fn reverse8(value_in i64) i64 { mut value:=value_in;mut result:=i64(0);for _ in 0..8 {result=(result<<1)|(value&1);value>>=1};return result }
@[export: 'crc8_model']
pub fn crc8_model(input &i64,length usize)i64{
 if isnil(input)||length<6{return -1};poly:=unsafe{input[0]};init:=unsafe{input[1]};rin:=unsafe{input[2]};rout:=unsafe{input[3]};xo:=unsafe{input[4]};count:=unsafe{input[5]}
 if poly<0||poly>255||init<0||init>255||xo<0||xo>255||(rin!=0&&rin!=1)||(rout!=0&&rout!=1)||count<0||count>max_length||length!=usize(6+count){return -1}
 mut crc:=init
 for i in 0..int(count){value:=unsafe{input[6+i]};if value<0||value>255{return -1};mut byte:=value;if rin==1{byte=reverse8(byte)};crc^=byte;for _ in 0..8{top:=crc&128;crc=(crc<<1)&255;if top!=0{crc^=poly}}}
 if rout==1{crc=reverse8(crc)};return crc^xo
}
