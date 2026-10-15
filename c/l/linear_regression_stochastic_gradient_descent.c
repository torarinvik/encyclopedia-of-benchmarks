#include <stddef.h>
#include <stdint.h>
#define MAX_N 64
#define INVALID_RESULT (-1.0e300)
#define SCALE 1000000.0

double linear_regression_stochastic_gradient_descent(const int64_t *v,size_t length){
 if(!v||length<9||length>133)return INVALID_RESULT;
 int64_t n=v[0],epochs=v[1],rate=v[2],m0=v[3],b0=v[4];
 if(n<2||n>MAX_N||length!=(size_t)(5+2*n)||epochs<1||epochs>200||rate<1||rate>10000||m0< -10000000||m0>10000000||b0< -10000000||b0>10000000)return INVALID_RESULT;
 for(int64_t i=0;i<n;i++){int64_t x=v[5+2*i],y=v[6+2*i];if(x< -10000000||x>10000000||y< -100000000||y>100000000)return INVALID_RESULT;}
 double alpha=(double)rate/SCALE,w=(double)m0/SCALE,b=(double)b0/SCALE;
 for(int64_t epoch=0;epoch<epochs;epoch++)for(int64_t i=0;i<n;i++){
  double x=(double)v[5+2*i]/SCALE,y=(double)v[6+2*i]/SCALE;
  double error=w*x+b-y;double grad_w=error*x/(double)n,grad_b=error/(double)n;
  w-=alpha*grad_w;b-=alpha*grad_b;
 }
 return w;
}
