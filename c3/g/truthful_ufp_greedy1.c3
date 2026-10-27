module truthful_ufp_greedy1;
extern fn double pow(double base,double exponent);
const int MAX_N=8;const int MAX_M=16;const int MAX_K=8;const int MAX_INPUT=75;const int MAX_OUTPUT=648;
fn void put_i64(char*out,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;i++){out[at+i]=(char)(b&255);b>>=8;}}
fn long truthful_ufp_greedy1(long*a,usz n,char*out,usz cap) @export("truthful_ufp_greedy1"){
 if(a==null||n<(usz)9||n>(usz)MAX_INPUT||a[0]<2||a[0]>MAX_N||a[1]<1||a[1]>MAX_M||a[2]<1||a[2]>MAX_K)return -1;
 int nv=(int)a[0],m=(int)a[1],k=(int)a[2];if(n!=(usz)(3+3*m+3*k))return -1;
 int[MAX_M] eu;int[MAX_M] ev;int[MAX_M] bc;double[MAX_M] y;int B=9,pu=-1,pv=-1;
 for(int e=0;e<m;e++){long u=a[3+3*e],v=a[4+3*e],b=a[5+3*e];if(u<0||v<=u||v>=nv||b<2||b>8||(e>0&&(u<pu||(u==pu&&v<=pv))))return -1;eu[e]=(int)u;ev[e]=(int)v;bc[e]=(int)b;y[e]=1.0/(double)b;if(b<B)B=(int)b;pu=(int)u;pv=(int)v;}
 int[MAX_K] src;int[MAX_K] dst;int[MAX_K] val;for(int i=0;i<k;i++){long s=a[3+3*m+3*i],t=a[4+3*m+3*i],c=a[5+3*m+3*i];if(s<0||s>=nv||t<0||t>=nv||s==t||c<1||c>100)return -1;src[i]=(int)s;dst[i]=(int)t;val[i]=(int)c;}
 double threshold=pow(2.718281828459045,(double)(B-1))*(double)m;bool[MAX_K] live=zeroed;for(int i=0;i<k;i++)live[i]=true;
 int[MAX_K] chosen;int[MAX_K] plen;int[MAX_K*MAX_N] paths;int count=0;
 while(count<k){int best=-1;double best_score=-1.0;int[MAX_K*MAX_N] route_table=zeroed;int[MAX_K] route_len=zeroed;
  for(int i=0;i<k;i++)if(live[i]){double[MAX_N] d=zeroed;int[MAX_N] prev=zeroed;bool[MAX_N] used=zeroed;for(int v=0;v<nv;v++){d[v]=1e300;prev[v]=-1;}d[src[i]]=0.0;
   for(int step=0;step<nv;step++){int u=-1;for(int v=0;v<nv;v++)if(!used[v]&&(u<0||d[v]<d[u]||(d[v]==d[u]&&v<u)))u=v;if(u<0||d[u]>=1e299)break;used[u]=true;
    for(int e=0;e<m;e++){int v=-1;if(eu[e]==u)v=ev[e];else if(ev[e]==u)v=eu[e];if(v<0||used[v])continue;double cand=d[u]+y[e];if(cand<d[v]||(cand==d[v]&&(prev[v]<0||u<prev[v]))){d[v]=cand;prev[v]=u;}}
   }
   if(d[dst[i]]>=1e299)return -1;int[MAX_N] rev=zeroed;int len=0,v=dst[i];while(v!=src[i]&&len<nv){rev[len]=v;len+=1;v=prev[v];if(v<0)return -1;}if(v!=src[i])return -1;rev[len]=src[i];len+=1;route_len[i]=len;for(int q=0;q<len;q++)route_table[i*MAX_N+q]=rev[len-1-q];double score=(double)val[i]/d[dst[i]];if(best<0||score>best_score){best=i;best_score=score;}
  }
  if(best<0)break;live[best]=false;chosen[count]=best;plen[count]=route_len[best];for(int q=0;q<plen[count];q++)paths[count*MAX_N+q]=route_table[best*MAX_N+q];count+=1;
  for(int q=0;q<plen[count-1]-1;q++){int u=paths[(count-1)*MAX_N+q],v=paths[(count-1)*MAX_N+q+1];for(int e=0;e<m;e++)if((eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u))y[e]*=pow(threshold,1.0/(double)(bc[e]-1));}
  double dual=0.0;for(int e=0;e<m;e++)dual+=(double)bc[e]*y[e];if(dual>=threshold)break;
 }
 usz words=1;for(int i=0;i<count;i++)words+=(usz)(2+plen[i]);usz bytes=8*words;if(out==null||cap<bytes)return -2;char[MAX_OUTPUT] staged=zeroed;put_i64(&staged[0],0,(long)count);usz w=1;for(int i=0;i<count;i++){put_i64(&staged[0],8*w,(long)chosen[i]);w+=1;put_i64(&staged[0],8*w,(long)plen[i]);w+=1;for(int q=0;q<plen[i];q++){put_i64(&staged[0],8*w,(long)paths[i*MAX_N+q]);w+=1;}}for(usz i=0;i<bytes;i++)out[i]=staged[i];return (long)bytes;
}
