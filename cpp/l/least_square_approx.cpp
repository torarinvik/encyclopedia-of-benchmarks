#include <cstddef>
#include <cstdint>
static std::int64_t rnd(std::int64_t a,std::int64_t b){auto q=(a<0?-a:a)*100000; q=(q+b/2)/b; return a<0?-q:q;}
extern "C" std::int64_t least_square_approx(const std::int64_t*v,std::size_t n){if(n<5||n>13)return -1;auto k=v[0];if(k<2||k>6||n!=1+2*k)return -1;std::int64_t sx=0,sy=0,sxx=0,sxy=0;for(std::int64_t i=0;i<k;i++){auto x=v[1+2*i],y=v[2+2*i];if(x < -20||x>20||y < -20||y>20)return -1;sx+=x;sy+=y;sxx+=x*x;sxy+=x*y;}auto den=k*sxx-sx*sx;if(den<=0)return -1;auto num=k*sxy-sx*sy;auto sl=rnd(num,den),it=rnd(sy*den-num*sx,k*den);constexpr std::int64_t o=100000001,r=200000003;if(sl<=-o||sl>=o||it<=-o||it>=o)return -1;return (sl+o)*r+(it+o);}
