#include <stddef.h>
#include <stdint.h>

#define MAX_N 3
#define MAX_M 3
#define MAX_CUTS 45
#define MAX_INPUT 12
#define MAX_OUTPUT 1112

static void put_i64(uint8_t *out,size_t word,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++)out[word*8+i]=(uint8_t)(b>>(8*i));}
static int bit_count(uint64_t x){int n=0;while(x){x&=x-1;++n;}return n;}
static uint64_t shift_cut(uint64_t cut,int n,int delay){uint64_t out=0;for(int bit=0;bit<3*n;bit++)if(cut&(UINT64_C(1)<<bit)){int node=bit/3,old=bit%3,newd=old+delay;if(newd>2)return UINT64_MAX;out|=UINT64_C(1)<<(3*node+newd);}return out;}
static void add_cut(uint64_t cuts[MAX_N][MAX_CUTS],int counts[MAX_N],int node,uint64_t mask,int k){if(bit_count(mask)>k)return;for(int i=0;i<counts[node];i++)if(cuts[node][i]==mask)return;if(counts[node]<MAX_CUTS)cuts[node][counts[node]++]=mask;}

int64_t sequential_lut_k_cut_enumeration(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<3||length>MAX_INPUT)return -1;
    int64_t n0=input[0],k0=input[1],m0=input[2];if(n0<1||n0>MAX_N||k0<1||k0>2||m0<0||m0>MAX_M||length!=3+3*(size_t)m0)return -1;
    int n=(int)n0,k=(int)k0,m=(int)m0;int eu[MAX_M],ev[MAX_M],ed[MAX_M];
    for(int e=0;e<m;e++){int64_t u=input[3+3*e],v=input[4+3*e],d=input[5+3*e];if(u<0||v<0||u>=v||v>=n||(d!=0&&d!=1))return -1;for(int j=0;j<e;j++)if(eu[j]==u&&ev[j]==v&&ed[j]==d)return -1;eu[e]=(int)u;ev[e]=(int)v;ed[e]=(int)d;}
    int in_u[MAX_N][MAX_M]={{0}},in_d[MAX_N][MAX_M]={{0}},in_count[MAX_N]={0};
    for(int e=0;e<m;e++){int v=ev[e],x=in_count[v]++;in_u[v][x]=eu[e];in_d[v][x]=ed[e];}
    uint64_t cuts[MAX_N][MAX_CUTS]={{0}};int counts[MAX_N]={0};
    for(int v=0;v<n;v++){
        add_cut(cuts,counts,v,UINT64_C(1)<<(3*v),k);
        if(in_count[v]>0){
            int c0=counts[in_u[v][0]];
            int c1=in_count[v]>1?counts[in_u[v][1]]:1;
            int c2=in_count[v]>2?counts[in_u[v][2]]:1;
            for(int a=0;a<c0;a++)for(int b=0;b<c1;b++)for(int c=0;c<c2;c++){
                uint64_t x=0;
                x|=shift_cut(cuts[in_u[v][0]][a],n,in_d[v][0]);
                if(in_count[v]>1)x|=shift_cut(cuts[in_u[v][1]][b],n,in_d[v][1]);
                if(in_count[v]>2)x|=shift_cut(cuts[in_u[v][2]][c],n,in_d[v][2]);
                if(x!=UINT64_MAX)add_cut(cuts,counts,v,x,k);
            }
        }
        for(int i=1;i<counts[v];i++){uint64_t x=cuts[v][i];int j=i;while(j>0&&cuts[v][j-1]>x){cuts[v][j]=cuts[v][j-1];--j;}cuts[v][j]=x;}
    }
    size_t words=1;for(int v=0;v<n;v++)words+=1+(size_t)counts[v];size_t bytes=8*words;
    if(output==NULL||capacity<bytes)return -2;
    put_i64(output,0,n);size_t at=1;for(int v=0;v<n;v++){put_i64(output,at++,counts[v]);for(int i=0;i<counts[v];i++)put_i64(output,at++,(int64_t)cuts[v][i]);}
    return (int64_t)bytes;
}
