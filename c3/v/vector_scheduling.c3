// Clean-room explicit-choice profile of randomized vector scheduling.
module vector_scheduling;
const MAX_N:usz=16,MAX_M:usz=8,MAX_D:usz=4,MAX_INPUT:usz=83,MAX_FIELDS:usz=35;
fn void put(char* out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;++i){out[at+i]=(char)(b&255ul);b>>=8;}}
fn long vector_scheduling(long* input,usz length,char* output,usz capacity) @export("vector_scheduling"){
 if(input==null||length<3||length>MAX_INPUT)return -1;long n64=input[0],m64=input[1],d64=input[2];if(n64<1||n64>16||m64<1||m64>8||d64<1||d64>4||length!=3+(usz)n64+(usz)(n64*d64))return -1;usz n=(usz)n64,m=(usz)m64,d=(usz)d64;
 for(usz j=0;j<n;++j){if(input[3+j]<0||input[3+j]>=m64)return -1;}for(usz i=0;i<n*d;++i){long x=input[3+n+i];if(x<0||x>1000)return -1;}
 long[MAX_M*MAX_D] loads={};for(usz j=0;j<n;++j){usz machine=(usz)input[3+j];for(usz q=0;q<d;++q)loads[machine*MAX_D+q]+=input[3+n+j*d+q];}
 long span=0;for(usz i=0;i<m;++i){for(usz q=0;q<d;++q){if(loads[i*MAX_D+q]>span)span=loads[i*MAX_D+q];}}long[MAX_FIELDS] staged={};usz count=0;staged[count++]=m64;staged[count++]=d64;staged[count++]=span;for(usz i=0;i<m;++i){for(usz q=0;q<d;++q)staged[count++]=loads[i*MAX_D+q];}if(output==null||capacity<8*count)return -2;for(usz i=0;i<count;++i)put(output,8*i,staged[i]);return (long)(8*count);
}
