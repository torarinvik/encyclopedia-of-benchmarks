#include <cstddef>
#include <cstdint>
#include <cmath>
static double round_even(double x,int p){double scale=1;for(int i=0;i<p;i++)scale*=10;double y=x*scale,lo=std::floor(y),frac=y-lo;if(frac>0.5||(frac==0.5&&std::fmod(lo,2.0)!=0.0))lo+=1;return lo/scale;}
extern "C" double integration_by_simpson_approx(const int64_t*v,size_t n){if(!v||n!=3)return -1.0e300;int64_t a=v[0],b=v[1],p=v[2];if(a < -10||a>10||b < -10||b>10||a>=b||p<0||p>4)return -1.0e300;double h=double(b-a)/1000.0,result=double(a*a)+double(b*b);for(int i=1;i<1000;i++){double x=double(a)+h*double(i);result+=x*x*(i%2?4.0:2.0);}result*=h/3.0;return round_even(result,int(p));}
