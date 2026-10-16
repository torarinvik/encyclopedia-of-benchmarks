#include <stddef.h>
#include <stdint.h>
#include <string.h>
static void put_double(uint8_t *out,size_t offset,double x){uint64_t bits;memcpy(&bits,&x,8);for(size_t b=0;b<8;b++)out[offset+b]=(uint8_t)(bits>>(8*b));}
int64_t ordinary_least_squares_regression(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<5||v[0]<2||v[0]>32||n!=1+2*(size_t)v[0])return -1;size_t count=(size_t)v[0];double xs[32],ys[32],xm=0,ym=0;
 for(size_t i=0;i<count;i++){int64_t x=v[1+2*i],y=v[2+2*i];if(x < -10000||x>10000||y < -10000||y>10000)return -1;xs[i]=(double)x;ys[i]=(double)y;xm+=xs[i];ym+=ys[i];}
 xm/=(double)count;ym/=(double)count;double numerator=0,denominator=0;for(size_t i=0;i<count;i++){double dx=xs[i]-xm;numerator+=dx*(ys[i]-ym);denominator+=dx*dx;}if(denominator==0)return -1;double slope=numerator/denominator,intercept=ym-slope*xm;
 if(!out||cap<16)return -2;put_double(out,0,intercept);put_double(out,8,slope);return 16;
}
