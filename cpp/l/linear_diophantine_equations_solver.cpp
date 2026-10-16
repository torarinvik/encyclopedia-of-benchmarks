#include <cstddef>
#include <cstdint>
static void eg(std::int64_t a,std::int64_t b,std::int64_t&g,std::int64_t&x,std::int64_t&y){if(!b){g=a;x=1;y=0;return;}std::int64_t g1,x1,y1;eg(b,a%b,g1,x1,y1);g=g1;x=y1;y=x1-(a/b)*y1;}
static std::int64_t pack(std::int64_t x,std::int64_t y){return (x+10000001)*20000003+(y+10000001);}
extern "C" std::int64_t linear_diophantine_equations_solver(const std::int64_t*v,std::size_t n){if(!v||n!=3)return -1;auto a=v[0],b=v[1],c=v[2];if(a< -1000||a>1000||b< -1000||b>1000||c< -10000||c>10000)return -1;if(a==0&&b==0)return c==0?-3:-2;if(a==0)return c%b==0?pack(0,c/b):-2;if(b==0)return c%a==0?pack(c/a,0):-2;std::int64_t g,x,y;eg(a,b,g,x,y);if(c%g)return -2;return pack(x*(c/g),y*(c/g));}
