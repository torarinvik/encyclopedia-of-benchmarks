#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

enum { MAX_N=16, MAX_M=64, MAX_Q=32, MAX_V=17, MAX_INPUT=276, MAX_OUTPUT=256 };
static const int64_t MAX_W=1000000;
static void store_le(uint8_t *out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;++i){out[at+i]=(uint8_t)(b&255u);b>>=8;}}
static int64_t stoer_wagner(size_t n,const int64_t *spokes,size_t m,const int64_t *eu,const int64_t *ev,const int64_t *ew){
    size_t vcount=n+1;int64_t w[MAX_V][MAX_V]={{0}};
    for(size_t e=0;e<m;++e){size_t u=(size_t)eu[e],v=(size_t)ev[e];w[u][v]+=ew[e];w[v][u]+=ew[e];}
    for(size_t u=0;u<n;++u){w[u][n]+=spokes[u];w[n][u]+=spokes[u];}
    size_t active[MAX_V],count=vcount;for(size_t i=0;i<vcount;++i)active[i]=i;
    int64_t best=INT64_MAX;
    while(count>1){bool used[MAX_V]={0};int64_t connection[MAX_V]={0};int previous=-1;
        for(size_t step=0;step<count;++step){int selected=-1;
            for(size_t z=0;z<count;++z){int u=(int)active[z];if(!used[u]&&(selected<0||connection[u]>connection[selected]||(connection[u]==connection[selected]&&u<selected)))selected=u;}
            if(step+1==count){if(connection[selected]<best)best=connection[selected];
                for(size_t z=0;z<count;++z){int u=(int)active[z];if(u!=selected&&u!=previous){w[previous][u]+=w[selected][u];w[u][previous]=w[previous][u];}}
                size_t pos=0;while(active[pos]!=(size_t)selected)++pos;for(size_t z=pos+1;z<count;++z)active[z-1]=active[z];--count;break;
            }
            used[selected]=1;previous=selected;for(size_t z=0;z<count;++z){int u=(int)active[z];if(!used[u])connection[u]+=w[selected][u];}
        }
    }
    return best;
}
int64_t global_minimum_cut_of_dynamic_star_augmented_graph(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<3||length>MAX_INPUT)return -1;int64_t n0=input[0],m0=input[1],q0=input[2];
    if(n0<1||n0>MAX_N||m0<0||m0>MAX_M||m0>n0*(n0-1)/2||q0<1||q0>MAX_Q)return -1;
    size_t n=(size_t)n0,m=(size_t)m0,q=(size_t)q0;if(length!=3+n+3*m+2*q)return -1;size_t pos=3;
    int64_t spokes[MAX_N],eu[MAX_M],ev[MAX_M],ew[MAX_M];for(size_t i=0;i<n;++i){spokes[i]=input[pos++];if(spokes[i]<0||spokes[i]>MAX_W)return -1;}
    uint8_t seen[MAX_N][MAX_N]={{0}};for(size_t e=0;e<m;++e){int64_t u=input[pos++],v=input[pos++],weight=input[pos++];if(u<0||u>=n0||v<0||v>=n0||u==v||weight<0||weight>MAX_W)return -1;size_t a=(size_t)(u<v?u:v),b=(size_t)(u<v?v:u);if(seen[a][b])return -1;seen[a][b]=1;eu[e]=u;ev[e]=v;ew[e]=weight;}
    int64_t ux[MAX_Q],uy[MAX_Q];for(size_t i=0;i<q;++i){ux[i]=input[pos++];uy[i]=input[pos++];if(ux[i]<0||ux[i]>=n0||uy[i]<0||uy[i]>MAX_W)return -1;}
    size_t bytes=8*q;if(bytes>MAX_OUTPUT)return -1;if(!output||capacity<bytes)return -2;
    int64_t answers[MAX_Q];for(size_t i=0;i<q;++i){spokes[(size_t)ux[i]]=uy[i];answers[i]=stoer_wagner(n,spokes,m,eu,ev,ew);}
    for(size_t i=0;i<q;++i)store_le(output,8*i,answers[i]);return (int64_t)bytes;
}
