module ring_exact_covering_protocol;
const int SCALE=16;const int MAX_N=12;const int MAX_STEPS=64;const int MAX_INPUT=79;const int MAX_OUTPUT=208;
fn void put_i64(char* out,usz offset,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[offset+i]=(char)(bits&255);bits>>=8;}}
fn long ring_exact_covering_protocol(long* v,usz length,char* output,usz capacity) @export("ring_exact_covering_protocol") {
 if(v==null||length<3||length>MAX_INPUT||v[0]<2||v[0]>MAX_N||v[2]<0||v[2]>MAX_STEPS)return -1;
 int n=(int)v[0],steps=(int)v[2];if(length!=(usz)(3+n+steps))return -1;long circumference=SCALE*n,visibility=v[1];if(visibility<2*SCALE||visibility>circumference)return -1;
 long[MAX_N] position={};for(int i=0;i<n;i++){position[i]=v[3+i];if(position[i]<0||position[i]>=circumference||(i>0&&position[i-1]>=position[i]))return -1;}
 for(int j=0;j<steps;j++)if(v[3+n+j]<0||v[3+n+j]>=n)return -1;
 long moved=0;for(int j=0;j<steps;j++){int i=(int)v[3+n+j],next=(i+1)%n;long gap=(position[next]-position[i]+circumference)%circumference;long distance=gap>visibility?SCALE:(gap>SCALE?gap-SCALE:0);if(distance!=0){position[i]=(position[i]+distance)%circumference;moved++;}}
 usz words=(usz)(2+2*n),bytes=8*words;if(output==null||capacity<bytes)return -2;long[2+2*MAX_N] result={};result[0]=n;result[1]=moved;
 for(int i=0;i<n;i++)result[2+i]=position[i];for(int i=0;i<n;i++)result[2+n+i]=(position[(i+1)%n]-position[i]+circumference)%circumference;
 char[MAX_OUTPUT] staged={};for(usz i=0;i<words;i++)put_i64(staged,8*i,result[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
