#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 51
#define MAX_FACETS 16
#define MAX_VERTICES 12

static void put_i64(uint8_t *out,size_t word,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[word*8+b]=(uint8_t)(bits>>(8*b));}
static int tri_less(const int a[3],const int b[3]){for(int i=0;i<3;i++){if(a[i]<b[i])return 1;if(a[i]>b[i])return 0;}return 0;}
static int tri_equal(const int a[3],const int b[3]){return a[0]==b[0]&&a[1]==b[1]&&a[2]==b[2];}

int64_t crust_pole_triangle_filter(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<3||length>MAX_INPUT)return -1;
    int64_t ns0=input[0],np0=input[1],nf0=input[2];
    if(ns0<3||ns0>8||np0<1||np0>4||ns0+np0>MAX_VERTICES||nf0<0||nf0>MAX_FACETS||length!=3+3*(size_t)nf0)return -1;
    int ns=(int)ns0,total=(int)(ns0+np0),nf=(int)nf0,facets[MAX_FACETS][3],count=0;
    for(int i=0;i<nf;i++){
        int64_t a0=input[3+3*i],b0=input[4+3*i],c0=input[5+3*i];
        if(a0<0||a0>=total||b0<0||b0>=total||c0<0||c0>=total||a0==b0||a0==c0||b0==c0)return -1;
        if(a0>=ns||b0>=ns||c0>=ns)continue;
        int t[3]={(int)a0,(int)b0,(int)c0};
        for(int a=1;a<3;a++){int x=t[a],j=a;while(j>0&&t[j-1]>x){t[j]=t[j-1];j--;}t[j]=x;}
        int duplicate=0;for(int j=0;j<count;j++)if(tri_equal(t,facets[j]))duplicate=1;
        if(!duplicate){for(int j=0;j<3;j++)facets[count][j]=t[j];count++;}
    }
    for(int i=1;i<count;i++){int t[3]={facets[i][0],facets[i][1],facets[i][2]},j=i;while(j>0&&tri_less(t,facets[j-1])){for(int z=0;z<3;z++)facets[j][z]=facets[j-1][z];j--;}for(int z=0;z<3;z++)facets[j][z]=t[z];}
    size_t bytes=(size_t)(1+3*count)*8;if(output==NULL||capacity<bytes)return -2;
    put_i64(output,0,count);size_t at=1;for(int i=0;i<count;i++)for(int j=0;j<3;j++)put_i64(output,at++,facets[i][j]);
    return (int64_t)bytes;
}
