#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[b]=(uint8_t)(bits>>(8*b));}
static int pow_int(int base,int exp){int r=1;for(int i=0;i<exp;i++)r*=base;return r;}
static int make_wedge(const int64_t a[2],const int64_t b[2],int64_t out[2]){
    int64_t shared=-1,x=-1,y=-1;
    for(int i=0;i<2;i++)for(int j=0;j<2;j++)if(a[i]==b[j])shared=a[i];
    if(shared<0)return 0;
    x=a[0]==shared?a[1]:a[0];y=b[0]==shared?b[1]:b[0];
    if(x==y)return 0;if(x>y){int64_t t=x;x=y;y=t;}out[0]=x;out[1]=y;return 1;
}

int64_t streaming_triangles(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<10||length>340)return -1;
    int64_t n0=input[0],m0=input[1],se0=input[2],sw0=input[3];
    if(n0<2||n0>8||m0<1||m0>28||se0<2||se0>4||sw0<1||sw0>4)return -1;
    size_t n=(size_t)n0,m=(size_t)m0,se=(size_t)se0,sw=(size_t)sw0,stride=2+2*sw;
    if(length!=4+2*m+m*stride)return -1;
    int64_t edges[28][2];uint8_t seen[8][8]={{0}};
    for(size_t i=0;i<m;i++){int64_t u=input[4+2*i],v=input[5+2*i];if(u<0||v<=u||v>=n0||seen[u][v])return -1;seen[u][v]=seen[v][u]=1;edges[i][0]=u;edges[i][1]=v;}
    int edge_res[4]={-1,-1,-1,-1};int64_t wedge[4][2]={{0}};uint8_t wedge_valid[4]={0},closed[4]={0};
    int64_t total=0,staged[84];size_t at=0,tape=4+2*m;
    for(size_t ti=0;ti<m;ti++){
        size_t t=ti+1,rec=tape+ti*stride;
        for(size_t s=0;s<sw;s++)if(wedge_valid[s]&&wedge[s][0]==edges[ti][0]&&wedge[s][1]==edges[ti][1])closed[s]=1;
        int64_t draw=input[rec],slot0=input[rec+1];int limit=pow_int((int)t,(int)se),threshold=limit-pow_int((int)t-1,(int)se);
        if(draw<0||draw>=limit)return -1;int update=draw<threshold;int fresh_count=0,removed_count=0;int64_t fresh[4][2]={{0}};
        if(update){if(slot0<0||slot0>=se)return -1;size_t slot=(size_t)slot0;int old_id=edge_res[slot];
            if(old_id>=0)for(size_t j=0;j<se;j++)if(j!=slot&&edge_res[j]>=0){int64_t old_wedge[2];if(make_wedge(edges[old_id],edges[edge_res[j]],old_wedge))removed_count++;}
            edge_res[slot]=(int)ti;
            for(size_t j=0;j<se;j++)if(j!=slot&&edge_res[j]>=0){int64_t out[2];if(make_wedge(edges[ti],edges[edge_res[j]],out)){fresh[fresh_count][0]=out[0];fresh[fresh_count][1]=out[1];fresh_count++;}}
        }else if(slot0!=0)return -1;
        total+=fresh_count-removed_count;if(total<0)return -1;
        for(size_t s=0;s<sw;s++){
            int64_t wd=input[rec+2+2*s],pick=input[rec+3+2*s];
            if(fresh_count){if(wd<0||wd>=total)return -1;if(wd<fresh_count){if(pick<0||pick>=fresh_count)return -1;wedge[s][0]=fresh[pick][0];wedge[s][1]=fresh[pick][1];wedge_valid[s]=1;closed[s]=0;}else if(pick!=0)return -1;}
            else if(wd!=0||pick!=0)return -1;
        }
        int closed_count=0;for(size_t s=0;s<sw;s++)closed_count+=closed[s]!=0;
        staged[at++]=total;staged[at++]=(int64_t)(3*closed_count*1000000/sw);
        staged[at++]=(int64_t)(((int64_t)closed_count*(int64_t)t*(int64_t)t*total*1000000)/(int64_t)(sw*se*(se-1)));
    }
    size_t bytes=24*m;if(!output||capacity<bytes)return -2;for(size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);return (int64_t)bytes;
}
