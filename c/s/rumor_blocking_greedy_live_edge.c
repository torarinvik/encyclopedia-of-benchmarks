#include <stddef.h>
#include <stdint.h>

#define MAX_N 8
#define MAX_M 16
#define MAX_WORLDS 8
#define MAX_INPUT 61

static void put_i64(uint8_t *out,size_t word,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[word*8+b]=(uint8_t)(bits>>(8*b));}

static int infected_count(int n,int m,int world,uint16_t sources,uint16_t protectors,
                          const int eu[MAX_M],const int ev[MAX_M],const int masks[MAX_M]) {
    int status[MAX_N]={0},rumor_front[MAX_N]={0},protector_front[MAX_N]={0};
    for(int v=0;v<n;v++){if(sources&(1u<<v)){status[v]=1;rumor_front[v]=1;}if(protectors&(1u<<v)){status[v]=2;protector_front[v]=1;}}
    for(int step=0;step<n;step++){
        int rumor_proposal[MAX_N]={0},protector_proposal[MAX_N]={0};
        for(int e=0;e<m;e++){
            int u=eu[e],v=ev[e];if(status[v]!=0)continue;
            if(protector_front[u])protector_proposal[v]=1;
            if(rumor_front[u]&&(masks[e]&(1<<world)))rumor_proposal[v]=1;
        }
        int next_rumor[MAX_N]={0},next_protector[MAX_N]={0},changed=0;
        for(int v=0;v<n;v++)if(status[v]==0){
            if(protector_proposal[v]){status[v]=2;next_protector[v]=1;changed=1;}
            else if(rumor_proposal[v]){status[v]=1;next_rumor[v]=1;changed=1;}
        }
        for(int v=0;v<n;v++){rumor_front[v]=next_rumor[v];protector_front[v]=next_protector[v];}
        if(!changed)break;
    }
    int count=0;for(int v=0;v<n;v++)if(status[v]==1)count++;
    return count;
}

int64_t rumor_blocking_greedy_live_edge(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<5||length>MAX_INPUT)return -1;
    int64_t n0=input[0],m0=input[1],r0=input[2],k0=input[3],w0=input[4];
    if(n0<2||n0>MAX_N||m0<0||m0>MAX_M||r0<1||r0>=n0||k0<1||k0>3||w0<1||w0>MAX_WORLDS||k0>n0-r0||length!=5+(size_t)r0+3*(size_t)m0)return -1;
    int n=(int)n0,m=(int)m0,r=(int)r0,k=(int)k0,worlds=(int)w0;uint16_t source_mask=0;
    for(int i=0;i<r;i++){int64_t v=input[5+i];if(v<0||v>=n||(source_mask&(1u<<v)))return -1;source_mask|=(uint16_t)(1u<<v);}
    int eu[MAX_M]={0},ev[MAX_M]={0},masks[MAX_M]={0};int at=5+r;int valid_mask=(1<<worlds)-1;
    for(int e=0;e<m;e++){
        int64_t u=input[at+3*e],v=input[at+3*e+1],mask=input[at+3*e+2];
        if(u<0||u>=n||v<0||v>=n||u==v||mask<0||mask>valid_mask)return -1;
        for(int j=0;j<e;j++)if(eu[j]==u&&ev[j]==v)return -1;
        eu[e]=(int)u;ev[e]=(int)v;masks[e]=(int)mask;
    }
    int baseline[MAX_WORLDS]={0};
    for(int world=0;world<worlds;world++)baseline[world]=infected_count(n,m,world,source_mask,0,eu,ev,masks);
    uint16_t selected=0;int chosen[MAX_N]={0},scores[MAX_N]={0};
    for(int round=0;round<k;round++){
        int current[MAX_WORLDS]={0};
        for(int world=0;world<worlds;world++)current[world]=baseline[world]-infected_count(n,m,world,source_mask,selected,eu,ev,masks);
        int best_node=-1,best_score=-1;
        for(int candidate=0;candidate<n;candidate++){
            if((source_mask&(1u<<candidate))||(selected&(1u<<candidate)))continue;
            int score=0;
            for(int world=0;world<worlds;world++)score+=baseline[world]-infected_count(n,m,world,source_mask,(uint16_t)(selected|(1u<<candidate)),eu,ev,masks)-current[world];
            if(score>best_score){best_score=score;best_node=candidate;}
        }
        if(best_node<0)return -1;
        selected|=(uint16_t)(1u<<best_node);chosen[round]=best_node;scores[round]=best_score;
    }
    size_t bytes=(size_t)(1+2*k)*8;if(output==NULL||capacity<bytes)return -2;
    put_i64(output,0,k);for(int i=0;i<k;i++){put_i64(output,1+2*i,chosen[i]);put_i64(output,2+2*i,scores[i]);}
    return (int64_t)bytes;
}
