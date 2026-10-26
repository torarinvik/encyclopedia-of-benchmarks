#include <stddef.h>
#include <stdint.h>
static void put_i64(uint8_t*out,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;b++)out[b]=(uint8_t)(bits>>(8*b));}
int64_t dc_tree_k_server_path(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
    if(!input||length<5||length>18)return -1;int64_t k0=input[0],q0=input[1];if(k0<2||k0>4||q0<1||q0>12)return -1;
    size_t k=(size_t)k0,q=(size_t)q0;if(length!=2+k+q)return -1;int64_t pos[4];for(size_t i=0;i<k;i++){pos[i]=input[2+i];if(pos[i]<0||pos[i]>15)return -1;}for(size_t i=0;i<q;i++)if(input[2+k+i]<0||input[2+k+i]>15)return -1;
    int64_t staged[60];size_t at=0;
    for(size_t r=0;r<q;r++){int64_t target=input[2+k+r],nearest=INT64_MAX;uint8_t active[4]={0};size_t active_count=0;
        for(size_t i=0;i<k;i++){int first=1;for(size_t j=0;j<i;j++)if(pos[j]==pos[i]){first=0;break;}if(first){active[i]=1;active_count++;int64_t delta=pos[i]>target?pos[i]-target:target-pos[i];if(delta<nearest)nearest=delta;}}
        staged[at++]=nearest*(int64_t)active_count;
        for(size_t i=0;i<k;i++)if(active[i]){if(pos[i]<target)pos[i]+=nearest;else if(pos[i]>target)pos[i]-=nearest;}
        for(size_t i=0;i<k;i++)staged[at++]=pos[i];
    }
    size_t bytes=8*q*(k+1);if(!output||capacity<bytes)return -2;for(size_t i=0;i<at;i++)put_i64(output+8*i,staged[i]);return (int64_t)bytes;
}
