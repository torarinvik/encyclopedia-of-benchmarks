/* Layered edit-distance shortest paths over a supplied literal NFA. */
#include <cstddef>
#include <cstdint>

extern "C" int64_t approximate_regex_matching(const int64_t*x,size_t len,uint8_t*out,size_t cap){
 if(!x)return -2;if(len<6||len>66)return -1;
 auto sv=x[0],ev=x[1],tv=x[2],kv=x[3],stv=x[4],av=x[5];
 if(sv<2||sv>8||ev<1||ev>16||tv<0||tv>12||kv<0||kv>3||stv<0||av<0||stv>=sv||av>=sv||stv==av)return -1;
 size_t s=sv,e=ev,t=tv,k=kv,start=stv,accept=av,ts=6+3*e;if(len!=ts+t)return -1;
 size_t from[16],to[16];uint8_t label[16];
 for(size_t i=0;i<e;i++){auto a=x[6+3*i],b=x[7+3*i],c=x[8+3*i];if(a<0||a>=sv||b<0||b>=sv||c<1||c>127)return -1;from[i]=a;to[i]=b;label[i]=c;for(size_t j=0;j<i;j++)if(from[i]==from[j]&&to[i]==to[j]&&label[i]==label[j])return -1;}
 for(size_t i=0;i<t;i++)if(x[ts+i]<1||x[ts+i]>127)return -1;if(cap<t||(t&& !out))return -2;
 int inf=int(k)+1,cur[8],next[8];for(size_t q=0;q<s;q++)cur[q]=inf;
 for(size_t pos=0;pos<t;pos++){
  cur[start]=0;
  for(size_t pass=0;pass<s-1;pass++){bool changed=false;for(size_t i=0;i<e;i++)if(cur[from[i]]<inf&&cur[from[i]]+1<cur[to[i]]){cur[to[i]]=cur[from[i]]+1;changed=true;}if(!changed)break;}
  for(size_t q=0;q<s;q++)next[q]=cur[q]<inf?cur[q]+1:inf;
  for(size_t i=0;i<e;i++)if(cur[from[i]]<inf){int c=cur[from[i]]+(label[i]!=uint8_t(x[ts+pos]));if(c<next[to[i]])next[to[i]]=c;}
  for(size_t pass=0;pass<s-1;pass++){bool changed=false;for(size_t i=0;i<e;i++)if(next[from[i]]<inf&&next[from[i]]+1<next[to[i]]){next[to[i]]=next[from[i]]+1;changed=true;}if(!changed)break;}
  out[pos]=next[accept]<=int(k)?1:0;for(size_t q=0;q<s;q++)cur[q]=next[q];
 }
 return int64_t(t);
}
