const MAX_LENGTH:usize=100_001;
export fn crc16(values:[*c]const i64,length:usize)i64{
 if(length>MAX_LENGTH or (length!=0 and values==null))return -1;var crc:i64=65535;
 for(0..length)|n|{const byte=values[n];if(byte<0 or byte>255)return -1;var bit:usize=8;while(bit>0){bit-=1;const incoming=(byte>>@intCast(bit))&1;const top=(crc>>15)&1;crc=(crc<<1)&65535;if((top^incoming)!=0)crc^=4129;}}
 return crc;
}
