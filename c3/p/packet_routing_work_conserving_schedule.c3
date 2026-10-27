module packet_routing_work_conserving_schedule;
const int N=8,M=12,P=8,HOPS=56,MAX_INPUT=99;
fn void put_i64(char* out,usz word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[word*8+b]=(char)((bits>>(8*b))&255);}
fn long packet_routing_work_conserving_schedule(long* input,usz input_length,char* output,usz output_capacity) @export("packet_routing_work_conserving_schedule"){
 if(input==null||input_length<3||input_length>MAX_INPUT)return -1;long n0=input[0],m0=input[1],p0=input[2];if(n0<2||n0>N||m0<1||m0>M||p0<1||p0>P)return -1;int n=(int)n0,m=(int)m0,p=(int)p0;usz at=3;if(at+(usz)(2*m)>input_length)return -1;
 int[M] eu={0},ev={0};bool[N][N] seen={false};
 for(int e=0;e<m;e++){long u0=input[at++],v0=input[at++];if(u0<0||u0>=n0||v0<0||v0>=n0||u0==v0)return -1;int u=(int)u0,v=(int)v0,lo=u<v?u:v,hi=u<v?v:u;if(seen[lo][hi])return -1;seen[lo][hi]=true;eu[e]=u;ev[e]=v;}
 int[P] plen={0};int[P][N] paths={0};
 for(int q=0;q<p;q++){if(at+2>input_length)return -1;long start=input[at++],k0=input[at++];if(start<0||start>=n0||k0<1||k0>=n0||at+(usz)k0>input_length)return -1;int k=(int)k0;plen[q]=k;int cur=(int)start;bool[N] usedv={false};bool[M] usede={false};usedv[cur]=true;
  for(int j=0;j<k;j++){long e0=input[at++];if(e0<0||e0>=m0)return -1;int e=(int)e0;if(usede[e])return -1;usede[e]=true;paths[q][j]=e;if(eu[e]==cur)cur=ev[e];else if(ev[e]==cur)cur=eu[e];else return -1;if(usedv[cur])return -1;usedv[cur]=true;}}
 if(at!=input_length)return -1;int[P] pos={0};long[HOPS] tt={0},te={0},tp={0};int count=0,time=0;
 while(true){bool active=false;int[M] chosen={0};for(int e=0;e<m;e++)chosen[e]=-1;for(int q=0;q<p;q++)if(pos[q]<plen[q]){active=true;int e=paths[q][pos[q]];if(chosen[e]<0)chosen[e]=q;}if(!active)break;
  for(int e=0;e<m;e++)if(chosen[e]>=0){if(count>=HOPS)return -1;tt[count]=time;te[count]=e;tp[count]=chosen[e];count++;pos[chosen[e]]++;}time++;if(time>N*P)return -1;
 }
 usz words=(usz)(2+3*count),bytes=words*8;if(output==null||output_capacity<bytes)return -2;put_i64(output,0,time);put_i64(output,1,count);for(int i=0;i<count;i++){put_i64(output,(usz)(2+3*i),tt[i]);put_i64(output,(usz)(3+3*i),te[i]);put_i64(output,(usz)(4+3*i),tp[i]);}return (long)bytes;
}
