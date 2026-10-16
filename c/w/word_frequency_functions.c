#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_TERM 128
#define MAX_TEXT 4096
#define MAX_COUNT INT64_C(1000000)
#define MAX_PACKED (1 + 1 + MAX_TERM + 1 + MAX_TEXT)

static int punct(uint8_t c) { return (c>=33&&c<=47)||(c>=58&&c<=64)||(c>=91&&c<=96)||(c>=123&&c<=126); }
static uint8_t lower_ascii(uint8_t c) { return c>='A'&&c<='Z'?(uint8_t)(c+32):c; }
static void put32(uint8_t *out,size_t *p,uint32_t x){for(size_t i=0;i<4;i++){out[(*p)++]=(uint8_t)x;x>>=8;}}
static void put64(uint8_t *out,size_t *p,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++){out[(*p)++]=(uint8_t)b;b>>=8;}}
static int64_t milli(double x){double y=x*1000.0,lo=floor(y),f=y-lo;if(f<0.5)return (int64_t)lo;if(f>0.5)return (int64_t)(lo+1.0);int64_t k=(int64_t)lo;return (k%2==0)?k:k+1;}

int64_t word_frequency_functions(const int64_t *in,size_t length,uint8_t *out,size_t capacity){
    if(!in||length<1||length>MAX_PACKED)return -1;
    int64_t op=in[0],kind=0,a=0,b=0;size_t outlen=12;
    if(op==0||op==1){
        if(length<3||in[1]<0||in[1]>MAX_TERM)return -1;
        size_t tn=(size_t)in[1],ti=2+tn;if(length<ti+1||in[ti]<0||in[ti]>MAX_TEXT)return -1;
        size_t dn=(size_t)in[ti],di=ti+1;if(length!=di+dn)return -1;
        uint8_t term[MAX_TERM],text[MAX_TEXT],clean[MAX_TEXT];
        for(size_t i=0;i<tn;i++){if(in[2+i]<0||in[2+i]>127)return -1;term[i]=lower_ascii((uint8_t)in[2+i]);}
        for(size_t i=0;i<dn;i++){if(in[di+i]<0||in[di+i]>127)return -1;text[i]=(uint8_t)in[di+i];}
        size_t cn=0;
        for(size_t i=0;i<dn;i++)if(!punct(text[i])&&(op!=0||text[i]!=10)){clean[cn++]=op==1?lower_ascii(text[i]):text[i];}
        if(op==0){
            size_t start=0;
            for(size_t i=0;i<=cn;i++)if(i==cn||clean[i]==32){size_t n=i-start;int same=n==tn;for(size_t j=0;same&&j<n;j++)if(lower_ascii(clean[start+j])!=term[j])same=0;if(same)a++;start=i+1;}
            kind=0;
        }else{
            kind=1;size_t start=0;
            for(size_t i=0;i<=cn;i++)if(i==cn||clean[i]==10){size_t n=i-start;int found=tn==0;
                for(size_t j=0;!found&&j+tn<=n;j++){size_t k=0;while(k<tn&&clean[start+j+k]==term[k])k++;if(k==tn)found=1;}
                if(found)a++;b++;start=i+1;
            }
            outlen=20;
        }
    }else if(op==2){
        if(length!=4)return -1;int64_t df=in[1],n=in[2],smooth=in[3];
        if(df<0||df>MAX_COUNT||n<0||n>MAX_COUNT||(smooth!=0&&smooth!=1))return -1;
        if(smooth&&n==0){kind=4;outlen=4;}
        else if(!smooth&&df==0){kind=3;outlen=4;}
        else if(!smooth&&n==0){kind=4;outlen=4;}
        else{double value=smooth?1.0+log10((double)n/(double)(1+df)):log10((double)n/(double)df);kind=2;a=milli(value);}
    }else if(op==3){
        if(length!=3||in[1]<0||in[1]>MAX_COUNT||in[2]<-MAX_COUNT||in[2]>MAX_COUNT)return -1;
        kind=2;a=in[1]*in[2];
    }else return -1;
    if(!out||capacity<outlen)return -2;size_t p=0;put32(out,&p,(uint32_t)kind);
    if(kind==0||kind==2)put64(out,&p,a);else if(kind==1){put64(out,&p,a);put64(out,&p,b);}
    return (int64_t)p;
}
