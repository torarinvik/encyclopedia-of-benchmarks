#include <stddef.h>
#include <stdint.h>
#include <math.h>

enum { MAX_N=8, MAX_M=16, MAX_K=8, MAX_INPUT=75, MAX_OUTPUT=648 };
static void put_i64(uint8_t*out,size_t at,int64_t x){uint64_t b=(uint64_t)x;for(size_t i=0;i<8;i++){out[at+i]=(uint8_t)(b&255);b>>=8;}}

int64_t truthful_ufp_greedy1(const int64_t*a,size_t n,uint8_t*out,size_t cap){
 if(!a||n<9||n>MAX_INPUT||a[0]<2||a[0]>MAX_N||a[1]<1||a[1]>MAX_M||a[2]<1||a[2]>MAX_K)return -1;
 int nv=(int)a[0],m=(int)a[1],k=(int)a[2];if(n!=(size_t)(3+3*m+3*k))return -1;
 int eu[MAX_M],ev[MAX_M],bc[MAX_M],B=9,pu=-1,pv=-1;double y[MAX_M];
 for(int e=0;e<m;e++){int64_t u=a[3+3*e],v=a[4+3*e],b=a[5+3*e];if(u<0||v<=u||v>=nv||b<2||b>8||(e>0&&(u<pu||(u==pu&&v<=pv))))return -1;eu[e]=(int)u;ev[e]=(int)v;bc[e]=(int)b;y[e]=1.0/(double)b;if(b<B)B=(int)b;pu=(int)u;pv=(int)v;}
 int src[MAX_K],dst[MAX_K],val[MAX_K];for(int i=0;i<k;i++){int64_t s=a[3+3*m+3*i],t=a[4+3*m+3*i],c=a[5+3*m+3*i];if(s<0||s>=nv||t<0||t>=nv||s==t||c<1||c>100)return -1;src[i]=(int)s;dst[i]=(int)t;val[i]=(int)c;}
 const double threshold=pow(2.718281828459045,(double)(B-1))*(double)m;
 int live[MAX_K],chosen[MAX_K],paths[MAX_K][MAX_N],plen[MAX_K],count=0;for(int i=0;i<k;i++)live[i]=1;
 while(count<k){int route[MAX_K][MAX_N],rlen[MAX_K];double best_score=-1.0;int best=-1;
  for(int i=0;i<k;i++)if(live[i]){double d[MAX_N];int prev[MAX_N],used[MAX_N];for(int v=0;v<nv;v++){d[v]=1e300;prev[v]=-1;used[v]=0;}d[src[i]]=0.0;
   for(int step=0;step<nv;step++){int u=-1;for(int v=0;v<nv;v++)if(!used[v]&&(u<0||d[v]<d[u]||(d[v]==d[u]&&v<u)))u=v;if(u<0||d[u]>=1e299)break;used[u]=1;
    for(int e=0;e<m;e++){int v=-1;if(eu[e]==u)v=ev[e];else if(ev[e]==u)v=eu[e];if(v<0||used[v])continue;double cand=d[u]+y[e];if(cand<d[v]||(cand==d[v]&&(prev[v]<0||u<prev[v]))){d[v]=cand;prev[v]=u;}}
   }
   if(d[dst[i]]>=1e299)return -1;int rev[MAX_N],len=0,v=dst[i];while(v!=src[i]&&len<nv){rev[len++]=v;v=prev[v];if(v<0)return -1;}if(v!=src[i])return -1;rev[len++]=src[i];rlen[i]=len;for(int q=0;q<len;q++)route[i][q]=rev[len-1-q];dist[i][0]=d[dst[i]];
   double score=(double)val[i]/d[dst[i]];if(best<0||score>best_score){best=i;best_score=score;}
  }
  if(best<0)break;live[best]=0;chosen[count]=best;plen[count]=rlen[best];for(int q=0;q<plen[count];q++)paths[count][q]=route[best][q];count++;
  for(int q=0;q<plen[count-1]-1;q++){int u=paths[count-1][q],v=paths[count-1][q+1];for(int e=0;e<m;e++)if((eu[e]==u&&ev[e]==v)||(eu[e]==v&&ev[e]==u))y[e]*=pow(threshold,1.0/(double)(bc[e]-1));}
  double dual=0.0;for(int e=0;e<m;e++)dual+=(double)bc[e]*y[e];if(dual>=threshold)break;
 }
 size_t words=1;for(int i=0;i<count;i++)words+=2+(size_t)plen[i];size_t bytes=8*words;if(!out||cap<bytes)return -2;uint8_t staged[MAX_OUTPUT];put_i64(staged,0,count);size_t w=1;for(int i=0;i<count;i++){put_i64(staged,8*w++,chosen[i]);put_i64(staged,8*w++,plen[i]);for(int q=0;q<plen[i];q++)put_i64(staged,8*w++,paths[i][q]);}for(size_t i=0;i<bytes;i++)out[i]=staged[i];return (int64_t)bytes;
}
