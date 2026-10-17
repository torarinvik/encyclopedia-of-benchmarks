#include <stddef.h>
#include <stdint.h>
#define MAX_TEXT 256
#define MAX_INPUT (MAX_TEXT + 2)
int64_t split(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(input==NULL||length<2||length>MAX_INPUT+1)return -1;
 if(input[0]<0||input[0]>MAX_TEXT||input[1]<0||input[1]>127)return -1;
 size_t n=(size_t)input[0];if(length!=n+2)return -1;
 for(size_t i=0;i<n;i++)if(input[i+2]<0||input[i+2]>127)return -1;
 if(n>0&&input[n+1]==input[1])return -1;
 size_t separators=0;for(size_t i=0;i<n;i++)if(input[i+2]==input[1])separators++;
    if(n>0&&separators==0)return -1;
 size_t count=separators+1, required=2+2*count+n-separators;
 if(output==NULL||capacity<required)return -2;
 output[0]=(uint8_t)count;output[1]=(uint8_t)(count>>8);size_t pos=2,start=0;
 for(size_t i=0;i<=n;i++)if(i==n||input[i+2]==input[1]){size_t field=i-start;output[pos++]=(uint8_t)field;output[pos++]=(uint8_t)(field>>8);for(size_t j=start;j<i;j++)output[pos++]=(uint8_t)input[j+2];start=i+1;}
 return (int64_t)required;
}
