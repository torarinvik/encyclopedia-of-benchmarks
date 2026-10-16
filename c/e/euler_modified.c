#include <stddef.h>
#include <stdint.h>
#include <string.h>
static void put64(uint8_t *o,size_t i,double x){uint64_t b;memcpy(&b,&x,8);for(size_t k=0;k<8;k++)o[i*8+k]=(uint8_t)(b>>(8*k));}
int64_t euler_modified(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n!=2||v[0]<1||v[0]>8||v[1]<1||v[1]>4)return -1;
 size_t steps=(size_t)v[0];if(!out||cap<(steps+1)*8)return -2;
 const double h=0.25;double x=0.0,y=(double)v[1];put64(out,0,y);
 for(size_t i=0;i<steps;i++){double f0=-2.0*x*y*y;double predictor=y+h*f0;double f1=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(out,i+1,y);}
 return (int64_t)((steps+1)*8);
}
