#include <stddef.h>
#include <stdint.h>

#define MAX_MACHINES 3
#define MAX_OLD_JOBS 8
#define MAX_INPUT 20
#define MAX_OUTPUT 88

static int64_t exact_optimum(size_t machines,const int64_t *sizes,size_t jobs){
    uint64_t assignments=1;for(size_t i=0;i<jobs;++i)assignments*=machines;
    int64_t best=0;for(size_t i=0;i<jobs;++i)best+=sizes[i];
    for(uint64_t code=0;code<assignments;++code){int64_t loads[MAX_MACHINES]={0};uint64_t remaining=code;
        for(size_t j=0;j<jobs;++j){size_t machine=(size_t)(remaining%machines);remaining/=machines;loads[machine]+=sizes[j];}
        int64_t makespan=loads[0];for(size_t m=1;m<machines;++m)if(loads[m]>makespan)makespan=loads[m];if(makespan<best)best=makespan;
    }
    return best;
}
static void put64(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t j=0;j<8;++j){out[at+j]=(uint8_t)(bits&255U);bits>>=8;}}

int64_t robust_scheduling_single_arrival_migration(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<6||length>MAX_INPUT)return -1;
    int64_t m64=input[0],n64=input[1],claimed=input[2],new_size=input[3];
    if(m64<2||m64>MAX_MACHINES||n64<1||n64>MAX_OLD_JOBS||claimed<1||new_size<1||new_size>20||length!=4+2*(size_t)n64)return -1;
    size_t machines=(size_t)m64,n=(size_t)n64;
    int64_t sizes[MAX_OLD_JOBS+1]={0};size_t assignment[MAX_OLD_JOBS+1]={0};int64_t loads[MAX_MACHINES]={0};
    for(size_t i=0;i<n;++i){int64_t size=input[4+2*i],machine=input[5+2*i];if(size<1||size>20||machine<0||machine>=m64)return -1;sizes[i]=size;assignment[i]=(size_t)machine;loads[machine]+=size;}
    sizes[n]=new_size;int64_t optimum=exact_optimum(machines,sizes,n+1);if(claimed!=optimum)return -1;
    int64_t moved=0;
    if(2*new_size<=optimum){size_t target=0;for(size_t machine=1;machine<machines;++machine)if(loads[machine]<loads[target])target=machine;assignment[n]=target;loads[target]+=new_size;}
    else{
        int64_t source=-1;
        for(size_t machine=0;machine<machines;++machine){int eligible=1;int64_t volume=0;for(size_t i=0;i<n;++i)if(assignment[i]==machine){if(2*sizes[i]>optimum)eligible=0;volume+=sizes[i];}if(eligible&&volume>=new_size){source=(int64_t)machine;break;}}
        if(source<0)return -1;
        uint8_t removed[MAX_OLD_JOBS]={0};int64_t volume=0;
        for(size_t i=0;i<n;++i)if(assignment[i]==(size_t)source){removed[i]=1;volume+=sizes[i];loads[source]-=sizes[i];if(volume>=new_size)break;}
        if(volume<new_size)return -1;
        assignment[n]=(size_t)source;loads[source]+=new_size;
        for(size_t i=0;i<n;++i)if(removed[i]){size_t target=0;for(size_t machine=1;machine<machines;++machine)if(loads[machine]<loads[target])target=machine;assignment[i]=target;loads[target]+=sizes[i];if(target!=(size_t)source)moved+=sizes[i];}
    }
    size_t bytes=8*(n+3);if(!output||capacity<bytes)return -2;
    uint8_t staged[MAX_OUTPUT];put64(staged,0,optimum);put64(staged,8,moved);for(size_t i=0;i<n+1;++i)put64(staged,8*(i+2),(int64_t)assignment[i]);for(size_t i=0;i<bytes;++i)output[i]=staged[i];return (int64_t)bytes;
}
