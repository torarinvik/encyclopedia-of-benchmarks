#include <cmath>
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t cbench_rsynth_impulsive_glottal_sample(const double* input,std::size_t n,double* output,std::size_t cap){
 if(!input||n==0||n>3)return -1;for(std::size_t i=0;i<n;i++)if(!std::isfinite(input[i]))return -1;
 if(n!=2||input[0]<40||input[0]>263||std::trunc(input[0])!=input[0]||input[1]<0||input[1]>299||std::trunc(input[1])!=input[1])return -1;
 const long open=static_cast<long>(input[0]),target=static_cast<long>(input[1]),rate=8000;
 const float minus_pi=static_cast<float>(-3.14159265358979323846264338327950288/rate);
 const float two_pi=static_cast<float>(-2.0*static_cast<double>(minus_pi));
 const long bw=rate/open;const float r=static_cast<float>(std::exp(static_cast<double>(minus_pi)*bw));
 const float c=-(r*r);const float b=static_cast<float>(static_cast<double>(r)*std::cos(static_cast<double>(two_pi)*0.0)*2.0);
 float a=static_cast<float>(1.0-static_cast<double>(b)-static_cast<double>(c));const float t=static_cast<float>(static_cast<double>(open)*0.00833);a=static_cast<float>(a*(t*t));
 float p1=0,p2=0,result=0;for(long i=0;i<=target;i++){const float impulse=i==0?0.0f:(i==1?13000000.0f:(i==2?-13000000.0f:0.0f));float x=static_cast<float>(a*impulse);x=static_cast<float>(x+static_cast<float>(b*p1));x=static_cast<float>(x+static_cast<float>(c*p2));p2=p1;p1=x;result=x;}
 if(!output||cap<1)return -2;output[0]=static_cast<double>(result);return 1;
}
