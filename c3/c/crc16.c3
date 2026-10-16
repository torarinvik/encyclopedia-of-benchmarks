module crc16;
const usz MAX_LENGTH=100001;
fn long crc16(long* values,usz length) @export("crc16"){
 if(length>MAX_LENGTH||(length!=0&&values==null))return -1;long crc=65535;
 for(usz n=0;n<length;n++){long byte=values[n];if(byte<0||byte>255)return -1;for(int bit=7;bit>=0;bit--){long incoming=(byte>>bit)&1;long top=(crc>>15)&1;crc=(crc<<1)&65535;if((top^incoming)!=0)crc=crc^4129;}}
 return crc;
}
