#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t max_length=100001; std::uint8_t reverse8(std::uint8_t x){x=static_cast<std::uint8_t>((x>>4)|(x<<4));x=static_cast<std::uint8_t>(((x&0xccu)>>2)|((x&0x33u)<<2));return static_cast<std::uint8_t>(((x&0xaau)>>1)|((x&0x55u)<<1));} }
extern "C" std::int64_t crc8_model(const std::int64_t*input,std::size_t length){
 if(!input||length<6)return -1;auto poly=input[0],init=input[1],rin=input[2],rout=input[3],xo=input[4],count=input[5];if(poly<0||poly>255||init<0||init>255||xo<0||xo>255||(rin!=0&&rin!=1)||(rout!=0&&rout!=1)||count<0||count>static_cast<std::int64_t>(max_length)||length!=6+static_cast<std::size_t>(count))return -1;
 std::uint8_t crc=static_cast<std::uint8_t>(init);for(std::size_t i=0;i<static_cast<std::size_t>(count);++i){auto value=input[6+i];if(value<0||value>255)return -1;auto byte=static_cast<std::uint8_t>(value);if(rin)byte=reverse8(byte);crc^=byte;for(int bit=0;bit<8;++bit){bool top=(crc&0x80u)!=0;crc=static_cast<std::uint8_t>(crc<<1);if(top)crc^=static_cast<std::uint8_t>(poly);}}
 if(rout)crc=reverse8(crc);return static_cast<std::int64_t>(crc^static_cast<std::uint8_t>(xo));
}
