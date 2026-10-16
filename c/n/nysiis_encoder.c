#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define MAX_INPUT 64
#define MAX_WORK 256
static int vowel(char c){return c=='A'||c=='E'||c=='I'||c=='O'||c=='U';}
static void replace(char*s,size_t*n,size_t at,size_t old,const char*r,size_t nr){
    memmove(s+at+nr,s+at+old,*n-(at+old));
    for(size_t i=0;i<nr;i++)s[at+i]=r[i];
    *n=*n-old+nr;s[*n]=0;
}
static int starts(const char*s,size_t n,size_t at,const char*p,size_t m){if(at+m>n)return 0;for(size_t i=0;i<m;i++)if(s[at+i]!=p[i])return 0;return 1;}
static void prefix(char*s,size_t*n){
    const char*from[]={"MAC","KN","K","PH","PF","SCH"};
    const char*to[]={"MCC","NN","C","FF","FF","SSS"};
    for(size_t i=0;i<6;i++){size_t a=0,m=0,r=0;while(from[i][m])m++;while(to[i][r])r++;if(starts(s,*n,a,from[i],m)){replace(s,n,a,m,to[i],r);return;}}
}
static void suffix(char*s,size_t*n){
    const char*from[]={"EE","IE","DT","RT","NT","ND"};const char*to[]={"Y","Y","D","D","D","D"};
    for(size_t i=0;i<6;i++){size_t m=0,r=0;while(from[i][m])m++;while(to[i][r])r++;if(*n>=m&&starts(s,*n,*n-m,from[i],m)){replace(s,n,*n-m,m,to[i],r);return;}}
}
static int step(char*s,size_t*n,size_t at){
    const char*from[]={"EV","E","I","O","U","Q","Z","M","KN","K","SCH","PH"};
    const char*to[]={"AF","A","A","A","A","G","S","N","NN","C","SSS","FF"};
    for(size_t i=0;i<12;i++){size_t m=0,r=0;while(from[i][m])m++;while(to[i][r])r++;if(starts(s,*n,at,from[i],m)){replace(s,n,at,m,to[i],r);return 1;}}
    if(s[at]=='H'&&(!vowel(s[at-1])||(at+1<*n&&!vowel(s[at+1])))){s[at]=s[at-1];return 1;}
    if(s[at]=='W'&&vowel(s[at-1])){s[at]=s[at-1];return 1;}
    return 0;
}
int64_t nysiis_encoder(const int64_t*v,size_t n,uint8_t*out,size_t cap){
    if(!v||n<1||n>MAX_INPUT+1||v[0]<1||v[0]>MAX_INPUT||n!=(size_t)v[0]+1)return -1;
    char s[MAX_WORK];size_t len=0;
    for(size_t i=0;i<(size_t)v[0];i++){int c=(int)v[i+1];if(c>='a'&&c<='z')c-=32;if(c<'A'||c>'Z'||len+1>=MAX_WORK)return -1;s[len++]=(char)c;}
    if(!len)return -1;s[len]=0;prefix(s,&len);suffix(s,&len);
    for(size_t i=1;i<len;i++)step(s,&len,i);
    size_t w=0;for(size_t i=0;i<len;i++)if(i==0||s[i]!=s[i-1])s[w++]=s[i];len=w;s[len]=0;
    if(len&&s[len-1]=='S')len--;else if(len>=2&&s[len-2]=='A'&&s[len-1]=='Y'){s[len-2]='Y';len--;}else if(len&&s[len-1]=='A')len--;
    if(len>cap||(len&&!out))return -2;for(size_t i=0;i<len;i++)out[i]=(uint8_t)s[i];return (int64_t)len;
}
