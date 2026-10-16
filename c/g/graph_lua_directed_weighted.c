/* Trace directed weighted-graph mutations and queries; normalize Lua true edges. */
#include <stddef.h>
#include <stdint.h>
static void put_i64(uint8_t*out,size_t i,int64_t v){uint64_t bits=(uint64_t)v;for(size_t b=0;b<8;b++)out[i*8+b]=(uint8_t)(bits>>(8*b));}
int64_t graph_lua_directed_weighted(const int64_t*in,size_t len,uint8_t*out,size_t cap){
 if(!in||len<2)return -1;int64_t nv=in[0],ov=in[1];if(nv<1||nv>16||ov<0||ov>63||len!=(size_t)(2+4*ov))return -1;int n=(int)nv,ops=(int)ov;int kind[16][16]={{0}};int64_t weight[16][16]={{0}},rtype[63],rvalue[63];
 for(int i=0;i<ops;i++){int64_t op=in[2+4*i],a=in[3+4*i],b=in[4+4*i],v=in[5+4*i];if(op<0||op>5||a<0||a>=n||b<0||b>=n)return -1;int x=(int)a,y=(int)b;
  if(op==0){if(v< -1000||v>1000)return -1;kind[x][y]=2;weight[x][y]=v;rtype[i]=-1;rvalue[i]=0;}
  else if(op==1){if(v!=0)return -1;kind[x][y]=1;weight[x][y]=0;rtype[i]=-1;rvalue[i]=0;}
  else if(op==2){if(v!=0)return -1;kind[x][y]=0;weight[x][y]=0;rtype[i]=-1;rvalue[i]=0;}
  else if(op==3){if(v!=0||kind[x][y]!=0)return -1;kind[x][y]=1;weight[x][y]=0;rtype[i]=-1;rvalue[i]=0;}
  else if(op==4){if(v!=0)return -1;rtype[i]=kind[x][y];rvalue[i]=kind[x][y]==2?weight[x][y]:0;}
  else{if(v!=0)return -1;rtype[i]=kind[x][y]!=0?1:0;rvalue[i]=0;}
 }
 size_t edges=0;for(int a=0;a<n;a++)for(int b=0;b<n;b++)if(kind[a][b])edges++;size_t words=2+2*(size_t)ops+4*edges;if(!out||cap<words*8)return -2;size_t k=0;put_i64(out,k++,ops);for(int i=0;i<ops;i++){put_i64(out,k++,rtype[i]);put_i64(out,k++,rvalue[i]);}put_i64(out,k++,edges);for(int a=0;a<n;a++)for(int b=0;b<n;b++)if(kind[a][b]){put_i64(out,k++,a);put_i64(out,k++,b);put_i64(out,k++,kind[a][b]);put_i64(out,k++,weight[a][b]);}return (int64_t)(words*8);
}
