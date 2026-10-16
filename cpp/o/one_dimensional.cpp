#include <cstddef>
#include <cstdint>
extern "C" std::int64_t one_dimensional(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n!=1||v[0]<0||v[0]>11111111)return -1;std::uint8_t digits[8]={},rules[8]={};std::uint64_t x=static_cast<std::uint64_t>(v[0]);std::size_t count=0;do{auto d=x%10;if(d>1)return -1;digits[count++]=static_cast<std::uint8_t>(d);x/=10;}while(x&&count<8);if(x)return -1;for(std::size_t i=0;i<count;i++)rules[8-count+i]=digits[count-1-i];
 std::uint8_t cells[17][31]={};cells[0][15]=1;for(std::size_t r=0;r<16;r++)for(std::size_t c=0;c<31;c++){unsigned left=c?cells[r][c-1]:0,center=cells[r][c],right=c+1<31?cells[r][c+1]:0;unsigned pattern=(left<<2)|(center<<1)|right;cells[r+1][c]=rules[7-pattern];}
 constexpr std::size_t bytes=17*31*3;if(bytes>cap||(bytes&&!out))return -2;std::size_t pos=0;for(auto&row:cells)for(auto cell:row){std::uint8_t color=cell?0:255;out[pos++]=color;out[pos++]=color;out[pos++]=color;}return static_cast<std::int64_t>(pos);
}
