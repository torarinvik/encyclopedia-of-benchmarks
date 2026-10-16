#include <stddef.h>
#include <stdint.h>
int64_t crc16(const int64_t *values,size_t length){
 if(length>100001||(length!=0&&values==NULL))return -1;int64_t crc=65535;
 for(size_t n=0;n<length;++n){int64_t byte=values[n];if(byte<0||byte>255)return -1;for(int bit=7;bit>=0;--bit){int64_t incoming=(byte>>bit)&1;int64_t top=(crc>>15)&1;crc=(crc<<1)&65535;if((top^incoming)!=0)crc^=4129;}}
 return crc;
}
