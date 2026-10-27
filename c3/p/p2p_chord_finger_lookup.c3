module p2p_chord_finger_lookup;
const int MAX_NODES=16; const int MAX_BITS=6; const int MAX_INPUT=116; const int MAX_OUTPUT=128;
fn void put_i64(char *out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;}}
fn long p2p_chord_finger_lookup(long *input,usz length,char *output,usz capacity) @export("p2p_chord_finger_lookup"){
 if(input==null||length<(usz)4||length>(usz)MAX_INPUT||input[0]<1||input[0]>MAX_BITS||input[1]<2||input[1]>MAX_NODES)return -1;
 int bits=(int)input[0],n=(int)input[1],ring=1<<bits;if(n>ring||input[2]<0||input[2]>=(long)n||input[3]<0||input[3]>=(long)ring||length!=(usz)(4+n+n*bits))return -1;
 int[MAX_NODES] ids=zeroed;int[MAX_NODES*MAX_BITS] fingers=zeroed;
 for(int i=0;i<n;i++){long raw=input[4+i];if(raw<0||raw>=(long)ring||(i>0&&raw<=ids[i-1]))return -1;ids[i]=(int)raw;}
 for(int u=0;u<n;u++)for(int level=0;level<bits;level++){int target=(ids[u]+(1<<level))%ring,successor=0;while(successor<n&&ids[successor]<target)successor++;if(successor==n)successor=0;long raw=input[4+n+u*bits+level];if(raw<0||raw>=(long)n||raw!=successor)return -1;fingers[u*bits+level]=(int)raw;}
 int owner=0;while(owner<n&&ids[owner]<input[3])owner++;if(owner==n)owner=0;
 int[MAX_NODES] route=zeroed;int route_len=1,current=(int)input[2];route[0]=current;
 for(int step=0;step<n&&current!=owner;step++){int distance=(ids[owner]-ids[current]+ring)%ring,chosen=-1;for(int level=bits-1;level>=0;level--){int candidate=fingers[current*bits+level],progress=(ids[candidate]-ids[current]+ring)%ring;if(progress>0&&progress<=distance){chosen=candidate;break;}}if(chosen<0||route_len>=n)return -1;for(int j=0;j<route_len;j++)if(route[j]==chosen)return -1;current=chosen;route[route_len++]=current;}
 if(current!=owner)return -1;usz bytes=(usz)(8*route_len);if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;for(int i=0;i<route_len;i++)put_i64(&staged[0],(usz)(8*i),(long)ids[route[i]]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
