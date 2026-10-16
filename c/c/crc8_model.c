#include <stddef.h>
#include <stdint.h>
#define MAX_LENGTH 100001
static uint8_t reverse8(uint8_t x){x=(uint8_t)((x>>4)|(x<<4));x=(uint8_t)(((x&0xccu)>>2)|((x&0x33u)<<2));return (uint8_t)(((x&0xaau)>>1)|((x&0x55u)<<1));}
int64_t crc8_model(const int64_t *input,size_t length){
    if(input==NULL||length<6)return -1;
    int64_t poly=input[0],init=input[1],ref_in=input[2],ref_out=input[3],xor_out=input[4],count=input[5];
    if(poly<0||poly>255||init<0||init>255||xor_out<0||xor_out>255||(ref_in!=0&&ref_in!=1)||(ref_out!=0&&ref_out!=1)||count<0||count>MAX_LENGTH||length!=6+(size_t)count)return -1;
    uint8_t crc=(uint8_t)init;
    for(size_t i=0;i<(size_t)count;++i){int64_t value=input[6+i];if(value<0||value>255)return -1;uint8_t byte=(uint8_t)value;if(ref_in)byte=reverse8(byte);crc^=byte;
        for(int bit=0;bit<8;++bit){uint8_t top=(uint8_t)(crc&0x80u);crc=(uint8_t)(crc<<1);if(top)crc^=(uint8_t)poly;}}
    if(ref_out)crc=reverse8(crc);return (int64_t)(crc^(uint8_t)xor_out);
}
