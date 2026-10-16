#include <cstddef>
#include <cstdint>
extern "C" std::int64_t langtons_ant(const std::int64_t*v,std::size_t n){if(!v||n!=1||v[0]<0||v[0]>6)return -1;bool b[25];for(auto&x:b)x=true;int x=2,y=2,d=3;const int dx[4]={-1,0,1,0},dy[4]={0,1,0,-1};for(int s=0;s<v[0];s++){int old=x*5+y;d=b[old]?(d+1)%4:(d+3)%4;x+=dx[d];y+=dy[d];b[old]=!b[old];}std::int64_t mask=0;for(int i=0;i<25;i++)if(!b[i])mask|=std::int64_t(1)<<i;return mask|(std::int64_t(x*5+y)<<25)|(std::int64_t(d)<<30);}
