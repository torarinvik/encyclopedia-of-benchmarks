module universal_sequencing_doubling;
const int N=12;const int W=32;const int MAX_INPUT=25;const int MAX_OUTPUT=104;
fn void put_i64(char* out,usz at,long value){ulong bits=(ulong)value;for(usz i=0;i<8;i++){out[at+i]=(char)(bits&255);bits>>=8;}}
fn long universal_sequencing_doubling(long* values,usz length,char* output,usz capacity) @export("universal_sequencing_doubling") {
 if(values==null||length<3||length>MAX_INPUT||values[0]<1||values[0]>N||length!=1+2*(usz)values[0])return -1;
 int n=(int)values[0];long[N] p={};int[N] w={};int total=0;
 for(int j=0;j<n;j++){long pj=values[1+2*j],wj=values[2+2*j];if(pj<1||pj>255||wj<1||wj>W)return -1;p[j]=pj;w[j]=(int)wj;total+=(int)wj;}
 if(total>W||(total&(total-1))!=0)return -1;
 ushort[6] sets={};int levels=0;
 for(int bound=1;bound<=total;bound*=2){long[W+1] best={};ushort[W+1] masks={};bool[W+1] reach={};reach[0]=true;
  for(int j=0;j<n;j++){for(int used=bound;used>=w[j];used--){if(!reach[used-w[j]])continue;long cand=best[used-w[j]]+p[j];ushort cm=(ushort)(masks[used-w[j]]|(1u<<j));if(!reach[used]||cand>best[used]||(cand==best[used]&&cm<masks[used])){reach[used]=true;best[used]=cand;masks[used]=cm;}}}
  long maximum=-1;ushort selected=0;for(int used=0;used<=bound;used++){if(reach[used]&&(best[used]>maximum||(best[used]==maximum&&masks[used]<selected))){maximum=best[used];selected=masks[used];}}sets[levels]=selected;levels++;
 }
 int[N] rank={};for(int j=0;j<n;j++){rank[j]=-1;for(int level=0;level<levels;level++){if((sets[level]&(1u<<j))!=0){rank[j]=level;break;}}if(rank[j]<0)return -1;}
 long[N+1] words={};words[0]=n;int count=1;for(int level=levels-1;level>=0;level--){for(int j=0;j<n;j++){if(rank[j]==level){words[count]=j;count++;}}}
 usz bytes=8*(usz)count;if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged={};for(int i=0;i<count;i++)put_i64(staged,8*(usz)i,words[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
