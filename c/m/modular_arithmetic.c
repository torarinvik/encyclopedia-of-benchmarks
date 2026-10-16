#include <stddef.h>
#include <stdint.h>
int64_t modular_arithmetic(const int64_t *v,size_t n){
 if(!v||n!=4)return -1;int64_t op=v[0],m=v[1],a=v[2],b=v[3];
 if(op<0||op>2||m<1||m>1000000||a<0||a>=m||b<0||b>=m)return -1;
 if(op==0)return ((a%m)+(b%m))%m;
 if(op==1)return ((a%m)-(b%m)+m)%m;
 return ((a%m)*(b%m))%m;
}
