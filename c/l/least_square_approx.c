#include <stddef.h>
#include <stdint.h>
static int64_t rnd(int64_t a,int64_t b){int64_t q=(a<0?-a:a)*100000; q=(q+b/2)/b; return a<0?-q:q;}
int64_t least_square_approx(const int64_t*v,size_t n){if(n<5||n>13)return -1;int64_t k=v[0];if(k<2||k>6||n!=(size_t)(1+2*k))return -1;int64_t sx=0,sy=0,sxx=0,sxy=0;for(int64_t i=0;i<k;i++){int64_t x=v[1+2*i],y=v[2+2*i];if(x < -20||x>20||y < -20||y>20)return -1;sx+=x;sy+=y;sxx+=x*x;sxy+=x*y;}int64_t den=k*sxx-sx*sx;if(den<=0)return -1;int64_t sl=rnd(k*sxy-sx*sy,den),it=rnd(sy*den-(k*sxy-sx*sy)*sx,k*den);const int64_t o=100000001,r=200000003;if(sl<=-o||sl>=o||it<=-o||it>=o)return -1;return (sl+o)*r+(it+o);}
