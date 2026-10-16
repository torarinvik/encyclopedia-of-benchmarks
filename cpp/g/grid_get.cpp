#include <cstddef>
#include <cstdint>
namespace { constexpr std::int64_t MAX_COLUMNS=1000,MAX_INDEX=10000; }
extern "C" std::int64_t grid_get(const std::int64_t* values,std::size_t length) noexcept {
 if(values==nullptr||length<3||length>4)return -1;
 const auto op=values[0],columns=values[1],index=values[2];
 if((op!=0&&op!=1)||columns<1||columns>MAX_COLUMNS||index<0||index>MAX_INDEX)return -1;
 if(op==0){
  auto remaining=index;
  while(remaining+1>columns) remaining-=columns;
  return remaining+1;
 }
 return index/columns+1;
}
