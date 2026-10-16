#include <math.h>
#include <stddef.h>
#include <stdint.h>
int64_t star_delta_conversions(const int64_t *v,size_t n){
 if(!v||n!=4||(v[0]!=0&&v[0]!=1))return -1;
 for(size_t i=1;i<4;i++)if(v[i]<1000||v[i]>100000)return -1;
 double a=(double)v[1],b=(double)v[2],c=(double)v[3],out[3];
 if(v[0]==0){double p=a*b+b*c+c*a;out[0]=p/a;out[1]=p/b;out[2]=p/c;}
 else{double s=a+b+c;out[0]=b*c/s;out[1]=c*a/s;out[2]=a*b/s;}
 uint64_t h=UINT64_C(0xcbf29ce484222325);
 for(int i=0;i<3;i++){int64_t q=(int64_t)floor(out[i]+0.5);uint64_t u=(uint64_t)q;for(int j=0;j<8;j++){h^=(uint8_t)(u>>(8*j));h*=UINT64_C(0x100000001b3);}}
 return (int64_t)h;
}
