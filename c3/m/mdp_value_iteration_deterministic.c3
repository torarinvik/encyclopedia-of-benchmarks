module mdp_value_iteration_deterministic;
const usz MAX_STATES=4;const usz MAX_ACTIONS=3;const usz MAX_INPUT=29;const usz MAX_OUTPUT=72;
fn void put64(char*out,usz at,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b+=1){out[at+b]=(char)(bits&255);bits>>=8;}}
long mdp_value_iteration_deterministic(long*input,usz length,char*output,usz capacity) @export("mdp_value_iteration_deterministic"){
    if(input==null||length<7||length>MAX_INPUT)return -1;
    long s64=input[0],a64=input[1],h64=input[2],p=input[3],q=input[4];
    if(s64<1||s64>4||a64<1||a64>3||h64<1||h64>8||q<1||q>4||p<0||p>=q||length!=5+2*(usz)s64*(usz)a64)return -1;
    usz states=(usz)s64,actions=(usz)a64,horizon=(usz)h64;
    long[MAX_STATES][MAX_ACTIONS] rewards=zeroed;long[MAX_STATES][MAX_ACTIONS] targets=zeroed;usz at=5;
    for(usz s=0;s<states;s+=1)for(usz a=0;a<actions;a+=1){long r=input[at],next=input[at+1];at+=2;if(r< -100||r>100||next<0||next>=s64)return -1;rewards[s][a]=r;targets[s][a]=next;}
    long scale=1;for(usz i=0;i<horizon;i+=1)scale*=q;
    long[MAX_STATES] value=zeroed;long[MAX_STATES] next_value=zeroed;long[MAX_STATES] policy=zeroed;
    for(usz step=0;step<horizon;step+=1){for(usz s=0;s<states;s+=1){long best=-9223372036854775807-1;usz best_action=0;for(usz a=0;a<actions;a+=1){long candidate=rewards[s][a]*scale+p*(value[(usz)targets[s][a]]/q);if(candidate>best){best=candidate;best_action=a;}}next_value[s]=best;policy[s]=(long)best_action;}for(usz s=0;s<states;s+=1)value[s]=next_value[s];}
    usz bytes=8*(1+2*states);if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put64(&staged[0],0,scale);for(usz s=0;s<states;s+=1)put64(&staged[0],8*(1+s),value[s]);for(usz s=0;s<states;s+=1)put64(&staged[0],8*(1+states+s),policy[s]);for(usz b=0;b<bytes;b+=1)output[b]=staged[b];return (long)bytes;
}
