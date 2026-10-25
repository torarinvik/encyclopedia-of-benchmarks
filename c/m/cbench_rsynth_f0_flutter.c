#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t cbench_rsynth_f0_flutter(const int64_t *input,size_t n){
    if(input==NULL||n==0||n>4)return -1;
    if(n!=3||input[0]<0||input[0]>20000||input[1]<0||input[1]>100||input[2]<0||input[2]>1000000)return -1;
    const int64_t f0=input[0],flutter=input[1],time=input[2];
    const int64_t original_f0=f0/10;
    const double pi=3.1415927;
    const double fla=(double)flutter/50.0;
    const double flb=(double)original_f0/100.0;
    const double flc=sin(2.0*pi*12.7*(double)time);
    const double fld=sin(2.0*pi*7.1*(double)time);
    const double fle=sin(2.0*pi*4.7*(double)time);
    const double delta=fla*flb*(flc+fld+fle)*10.0;
    return f0+(int64_t)delta;
}
