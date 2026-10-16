#include <stddef.h>
#include <stdint.h>

#define MAX_OUTPUT 256
static const char *small[] = {"Zero","One","Two","Three","Four","Five","Six","Seven","Eight","Nine","Ten","Eleven","Twelve","Thirteen","Fourteen","Fifteen","Sixteen","Seventeen","Eighteen","Nineteen"};
static const char *tens[] = {"","","Twenty","Thirty","Forty","Fifty","Sixty","Seventy","Eighty","Ninety"};
static const char *scale[] = {"","Thousand","Million","Billion","Trillion"};
static void emit(char *b,size_t *n,const char *s){if(*n&&s[0])b[(*n)++]=' ';while(*s)b[(*n)++]=*s++;}
static void chunk_words(char *b,size_t *n,unsigned x){if(x>=100){emit(b,n,small[x/100]);emit(b,n,"Hundred");x%=100;}if(x>=20){emit(b,n,tens[x/10]);x%=10;}if(x>0&&x<20)emit(b,n,small[x]);}
int64_t number_to_words(const int64_t *v,size_t n,uint8_t *out,size_t cap){
 if(!v||n<3||n>9||v[0]<-1||v[0]>1||v[1]<0||v[1]>999999999999999LL||v[2]<0||v[2]>6||n!=(size_t)v[2]+3)return -1;
 int nonzero=v[1]!=0;for(size_t i=3;i<n;i++){if(v[i]<0||v[i]>9)return -1;if(v[i])nonzero=1;}
 if((nonzero&&v[0]==0)||(!nonzero&&v[0]!=0))return -1;
 uint8_t scratch[MAX_OUTPUT];char b[MAX_OUTPUT];size_t used=0; (void)scratch;
 if(v[0]<0)emit(b,&used,"Negative");
 uint64_t whole=(uint64_t)v[1];unsigned groups[5]={0};for(int i=0;i<5;i++){groups[i]=(unsigned)(whole%1000);whole/=1000;}
 int any=0;for(int i=4;i>=0;i--)if(groups[i]){chunk_words(b,&used,groups[i]);if(i)emit(b,&used,scale[i]);any=1;}
 if(!any)emit(b,&used,"Zero");
 int frac_nonzero=0;for(size_t i=3;i<n;i++)if(v[i])frac_nonzero=1;
 if(frac_nonzero){emit(b,&used,"Point");for(size_t i=3;i<n;i++)emit(b,&used,small[(unsigned)v[i]]);}
 if(used>cap||(used&&!out))return -2;for(size_t i=0;i<used;i++)out[i]=(uint8_t)b[i];return (int64_t)used;
}
