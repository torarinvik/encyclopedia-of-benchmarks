#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, int64_t value) {
    uint64_t bits=(uint64_t)value;
    for(size_t b=0;b<8;b++)out[b]=(uint8_t)(bits>>(8*b));
}

int64_t counting_triangles_stream_reservoir(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(!input||length<6||length>114)return -1;
    int64_t n0=input[0],m0=input[1];
    if(n0<2||n0>8||m0<1||m0>28||length!=2+4*(size_t)m0)return -1;
    size_t n=(size_t)n0,m=(size_t)m0;
    uint8_t seen[8][8]={{0}};int64_t edges[28][2];
    for(size_t i=0;i<m;i++){
        int64_t u=input[2+2*i],v=input[3+2*i];
        if(u<0||v<=u||v>=n0||seen[u][v])return -1;
        seen[u][v]=seen[v][u]=1;edges[i][0]=u;edges[i][1]=v;
    }
    size_t draw_base=2+2*m;
    for(size_t t=1;t<=m;t++)for(size_t s=0;s<2;s++){
        int64_t r=input[draw_base+2*(t-1)+s];if(r<0||r>=(int64_t)t)return -1;
    }
    int64_t slot[2][2]={{-1,-1},{-1,-1}},staged[112];size_t at=0;
    for(size_t t=1;t<=m;t++){
        for(size_t s=0;s<2;s++)if(input[draw_base+2*(t-1)+s]==0){slot[s][0]=edges[t-1][0];slot[s][1]=edges[t-1][1];}
        for(size_t s=0;s<2;s++){staged[at++]=slot[s][0];staged[at++]=slot[s][1];}
    }
    size_t bytes=16*m;if(!output||capacity<bytes)return -2;
    for(size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);
    return (int64_t)bytes;
}
