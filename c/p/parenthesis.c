#include <stddef.h>
#include <stdint.h>
int64_t parenthesis(const int64_t*v,size_t n){if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=(size_t)v[0]+1)return -1;int64_t balance=0;for(size_t i=1;i<n;i++){if(v[i]<0||v[i]>127)return -1;if(v[i]=='(')balance++;else if(v[i]==')'){if(--balance<0)return 0;}}return balance==0;}
