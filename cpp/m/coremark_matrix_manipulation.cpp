/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <cstddef>
#include <cstdint>

static std::uint16_t crc_byte(std::uint8_t value,std::uint16_t crc){for(unsigned i=0;i<8;++i){std::uint16_t mix=(value&1u)^(crc&1u);value>>=1;if(mix)crc^=0x4002u;crc>>=1;if(mix)crc|=0x8000u;else crc&=0x7fffu;}return crc;}
static std::uint16_t crc16(std::int16_t value,std::uint16_t crc){auto bits=static_cast<std::uint16_t>(value);crc=crc_byte(static_cast<std::uint8_t>(bits),crc);return crc_byte(static_cast<std::uint8_t>(bits>>8),crc);}
static std::int16_t matrix_sum(const std::int32_t *c,std::int16_t clip){std::int32_t tmp=0,prev=0,cur=0;std::int16_t ret=0;for(int i=0;i<9;++i){cur=c[i];tmp+=cur;if(tmp>clip){ret=static_cast<std::int16_t>(ret+10);tmp=0;}else if(cur>prev)ret=static_cast<std::int16_t>(ret+1);prev=cur;}return ret;}
static void put_i64(std::uint8_t *out,std::size_t at,std::int64_t value){auto bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));}

extern "C" std::int64_t coremark_matrix_manipulation(const std::int64_t *input,std::size_t length,std::uint8_t *output,std::size_t capacity){
    if(input==nullptr||length!=19)return -1;const auto raw=input[0];if(raw<0||raw>15)return -1;
    std::int16_t a[9],b[9];for(int i=0;i<9;++i){if(input[1+i]<0||input[1+i]>127||input[10+i]<0||input[10+i]>127)return -1;a[i]=static_cast<std::int16_t>(input[1+i]);b[i]=static_cast<std::int16_t>(input[10+i]);}
    if(output==nullptr||capacity<112)return -2;const auto value=static_cast<std::int16_t>(raw);const auto clip=static_cast<std::int16_t>(value-4096);std::int32_t c[9];std::int16_t sums[4];
    for(int i=0;i<9;++i)a[i]=static_cast<std::int16_t>(a[i]+value);
    for(int i=0;i<9;++i)c[i]=static_cast<std::int32_t>(a[i])*value;sums[0]=matrix_sum(c,clip);
    for(int i=0;i<3;++i){c[i]=0;for(int j=0;j<3;++j)c[i]+=static_cast<std::int32_t>(a[i*3+j])*b[j];}sums[1]=matrix_sum(c,clip);
    for(int i=0;i<3;++i)for(int j=0;j<3;++j){c[i*3+j]=0;for(int k=0;k<3;++k)c[i*3+j]+=static_cast<std::int32_t>(a[i*3+k])*b[k*3+j];}sums[2]=matrix_sum(c,clip);
    for(int i=0;i<3;++i)for(int j=0;j<3;++j){c[i*3+j]=0;for(int k=0;k<3;++k){std::int32_t t=static_cast<std::int32_t>(a[i*3+k])*b[k*3+j];c[i*3+j]+=((t>>2)&0xf)*((t>>5)&0x7f);}}sums[3]=matrix_sum(c,clip);
    std::uint16_t crc=0;for(auto s:sums)crc=crc16(s,crc);for(int i=0;i<9;++i)a[i]=static_cast<std::int16_t>(a[i]-value);
    std::int64_t result[14];result[0]=crc;for(int i=0;i<4;++i)result[i+1]=sums[i];for(int i=0;i<9;++i)result[i+5]=a[i];for(std::size_t i=0;i<14;++i)put_i64(output,i*8,result[i]);return 112;
}
