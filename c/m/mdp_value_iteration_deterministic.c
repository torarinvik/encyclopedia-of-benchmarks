#include <stddef.h>
#include <stdint.h>

#define MAX_STATES 4
#define MAX_ACTIONS 3
#define MAX_INPUT 29
#define MAX_OUTPUT 72

static void put64(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)(bits&255U);bits>>=8;}}

int64_t mdp_value_iteration_deterministic(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<7||length>MAX_INPUT)return -1;
    int64_t s64=input[0],a64=input[1],h64=input[2],p=input[3],q=input[4];
    if(s64<1||s64>MAX_STATES||a64<1||a64>MAX_ACTIONS||h64<1||h64>8||q<1||q>4||p<0||p>=q||length!=5+2*(size_t)s64*(size_t)a64)return -1;
    size_t states=(size_t)s64,actions=(size_t)a64,horizon=(size_t)h64;
    int64_t reward[MAX_STATES][MAX_ACTIONS],target[MAX_STATES][MAX_ACTIONS];
    size_t at=5;
    for(size_t s=0;s<states;++s)for(size_t a=0;a<actions;++a){int64_t r=input[at++],next=input[at++];if(r< -100||r>100||next<0||next>=s64)return -1;reward[s][a]=r;target[s][a]=next;}
    int64_t scale=1;for(size_t i=0;i<horizon;++i)scale*=q;
    int64_t value[MAX_STATES]={0},next_value[MAX_STATES]={0};int64_t policy[MAX_STATES]={0};
    for(size_t step=0;step<horizon;++step){
        for(size_t s=0;s<states;++s){int64_t best=INT64_MIN;size_t best_action=0;
            for(size_t a=0;a<actions;++a){int64_t candidate=reward[s][a]*scale+p*(value[(size_t)target[s][a]]/q);if(candidate>best){best=candidate;best_action=a;}}
            next_value[s]=best;policy[s]=(int64_t)best_action;
        }
        for(size_t s=0;s<states;++s)value[s]=next_value[s];
    }
    size_t bytes=8*(1+2*states);if(output==NULL||capacity<bytes)return -2;
    uint8_t staged[MAX_OUTPUT];put64(staged,0,scale);for(size_t s=0;s<states;++s)put64(staged,8*(1+s),value[s]);for(size_t s=0;s<states;++s)put64(staged,8*(1+states+s),policy[s]);for(size_t b=0;b<bytes;++b)output[b]=staged[b];return (int64_t)bytes;
}
