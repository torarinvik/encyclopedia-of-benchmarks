#include <stddef.h>
#include <stdint.h>
int64_t palindrome_with_stack(const int64_t*v,size_t n){if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=(size_t)v[0]+1)return -1;unsigned char stack[128];size_t len=(size_t)v[0];for(size_t i=0;i<len;i++){if(v[i+1]<0||v[i+1]>127)return -1;unsigned char c=(unsigned char)v[i+1];if(c>='A'&&c<='Z')c+=32;stack[i]=c;}for(size_t i=0;i<len;i++)if(stack[i]!=stack[len-1-i])return 0;return 1;}
