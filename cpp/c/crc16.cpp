#include <cstddef>
#include <cstdint>
extern "C" std::int64_t crc16(const std::int64_t*values,std::size_t length){
 if(length>100001||(length!=0&&values==nullptr))return -1;std::int64_t crc=65535;
 for(std::size_t n=0;n<length;++n){auto byte=values[n];if(byte<0||byte>255)return -1;for(int bit=7;bit>=0;--bit){auto incoming=(byte>>bit)&1;auto top=(crc>>15)&1;crc=(crc<<1)&65535;if((top^incoming)!=0)crc^=4129;}}
 return crc;
}
