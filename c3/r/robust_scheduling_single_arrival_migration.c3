module robust_scheduling_single_arrival_migration;
const usz MAX_MACHINES=3; const usz MAX_OLD_JOBS=8; const usz MAX_INPUT=20; const usz MAX_OUTPUT=88;

fn long exact_optimum(usz machines,long*sizes,usz jobs){
    usz assignments=1;for(usz i=0;i<jobs;i+=1)assignments*=machines;
    long best=0;for(usz i=0;i<jobs;i+=1)best+=sizes[i];
    for(usz code=0;code<assignments;code+=1){long[MAX_MACHINES] loads=zeroed;usz rem=code;
        for(usz j=0;j<jobs;j+=1){usz target=rem%machines;rem/=machines;loads[target]+=sizes[j];}
        long makespan=loads[0];for(usz machine=1;machine<machines;machine+=1)if(loads[machine]>makespan)makespan=loads[machine];if(makespan<best)best=makespan;
    }
    return best;
}
fn void put64(char*out,usz pos,long value){ulong bits=(ulong)value;for(usz j=0;j<8;j+=1){out[pos+j]=(char)(bits&255);bits>>=8;}}

long robust_scheduling_single_arrival_migration(long*in,usz len,char*out,usz cap) @export("robust_scheduling_single_arrival_migration") {
    if(in==null||len<6||len>MAX_INPUT)return -1;
    long m64=in[0],n64=in[1],claim=in[2],new_size=in[3];if(m64<2||m64>(long)MAX_MACHINES||n64<1||n64>(long)MAX_OLD_JOBS||claim<1||new_size<1||new_size>20||len!=4+2*(usz)n64)return -1;
    usz machines=(usz)m64,n=(usz)n64;long[MAX_OLD_JOBS+1] sizes=zeroed;long[MAX_OLD_JOBS+1] assignment=zeroed;long[MAX_MACHINES] loads=zeroed;
    for(usz i=0;i<n;i+=1){long size=in[4+2*i],machine=in[5+2*i];if(size<1||size>20||machine<0||machine>=m64)return -1;sizes[i]=size;assignment[i]=machine;loads[(usz)machine]+=size;}
    sizes[n]=new_size;long optimum=exact_optimum(machines,&sizes[0],n+1);if(claim!=optimum)return -1;long moved=0;
    if(2*new_size<=optimum){usz target=0;for(usz machine=1;machine<machines;machine+=1)if(loads[machine]<loads[target])target=machine;assignment[n]=(long)target;loads[target]+=new_size;}
    else{long source=-1;for(usz machine=0;machine<machines;machine+=1){bool eligible=true;long volume=0;for(usz i=0;i<n;i+=1)if((usz)assignment[i]==machine){if(2*sizes[i]>optimum)eligible=false;volume+=sizes[i];}if(eligible&&volume>=new_size){source=(long)machine;break;}}if(source<0)return -1;
        char[MAX_OLD_JOBS] removed=zeroed;long volume=0;for(usz i=0;i<n;i+=1)if((usz)assignment[i]==(usz)source){removed[i]=1;volume+=sizes[i];loads[(usz)source]-=sizes[i];if(volume>=new_size)break;}if(volume<new_size)return -1;
        assignment[n]=source;loads[(usz)source]+=new_size;for(usz i=0;i<n;i+=1)if(removed[i]!=0){usz target=0;for(usz machine=1;machine<machines;machine+=1)if(loads[machine]<loads[target])target=machine;assignment[i]=(long)target;loads[target]+=sizes[i];if(target!=(usz)source)moved+=sizes[i];}
    }
    usz bytes=8*(n+3);if(out==null||cap<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put64(&staged[0],0,optimum);put64(&staged[0],8,moved);for(usz i=0;i<n+1;i+=1)put64(&staged[0],8*(i+2),assignment[i]);for(usz i=0;i<bytes;i+=1)out[i]=staged[i];return (long)bytes;
}
