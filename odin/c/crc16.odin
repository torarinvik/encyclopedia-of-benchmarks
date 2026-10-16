package crc16
import "core:c"
MAX_LENGTH::100_001
@(export)
crc16::proc "c"(values:[^]i64,length:c.size_t)->i64{
 if length>MAX_LENGTH||(length!=0&&values==nil) do return -1
 crc:=i64(65535)
 for n:=c.size_t(0);n<length;n+=1{byte:=values[n];if byte<0||byte>255 do return -1;for bit:=7;bit>=0;bit-=1{incoming:=(byte>>u64(bit))&1;top:=(crc>>15)&1;crc=(crc<<1)&65535;if (top^incoming)!=0 do crc=crc^4129}}
 return crc
}
