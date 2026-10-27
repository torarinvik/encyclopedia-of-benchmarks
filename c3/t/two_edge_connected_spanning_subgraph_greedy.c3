module two_edge_connected_spanning_subgraph_greedy;
const usz MAX_N=8;const usz MAX_M=28;const usz MAX_INPUT=59;
fn void put(char*o,usz at,long x){ulong b=(ulong)x;for(usz i=0;i<8;i+=1){o[at+i]=(char)(b&255);b>>=8;}}
fn bool connected(usz n,usz m,usz[MAX_M]&u,usz[MAX_M]&v,bool[MAX_M]&on,long skip){bool[MAX_N] seen=zeroed;usz[MAX_N]q=zeroed;usz head=0,tail=1;q[0]=0;seen[0]=true;while(head<tail){usz a=q[head];head+=1;for(usz e=0;e<m;e+=1)if(on[e]&&(long)e!=skip){usz b=MAX_N;if(u[e]==a)b=v[e];else if(v[e]==a)b=u[e];if(b<MAX_N&&!seen[b]){seen[b]=true;q[tail]=b;tail+=1;}}}for(usz i=0;i<n;i+=1)if(!seen[i])return false;return true;}
fn bool edge_connected(usz n,usz m,usz[MAX_M]&u,usz[MAX_M]&v,bool[MAX_M]&on){if(!connected(n,m,u,v,on,-1))return false;for(usz e=0;e<m;e+=1)if(on[e]&&!connected(n,m,u,v,on,e.long()))return false;return true;}
long two_edge_connected_spanning_subgraph_greedy(long*in,usz len,char*out,usz cap) @export("two_edge_connected_spanning_subgraph_greedy"){
 if(in==null||len<2||len>MAX_INPUT)return -1;long n0=in[0],m0=in[1];if(n0<3||n0>8||m0<3||m0>28||len!=2+2*m0.usz())return -1;usz n=n0.usz(),m=m0.usz();usz[MAX_M]u=zeroed,v=zeroed;bool[MAX_M]on=zeroed;
 for(usz i=0;i<m;i+=1){long a=in[2+2*i],b=in[3+2*i];if(a<0||a>=b||b>=n0)return -1;u[i]=a.usz();v[i]=b.usz();on[i]=true;for(usz j=0;j<i;j+=1)if(u[j]==u[i]&&v[j]==v[i])return -1;}
 if(!edge_connected(n,m,u,v,on))return -1;for(usz e=0;e<m;e+=1){on[e]=false;if(!edge_connected(n,m,u,v,on))on[e]=true;}
 usz count=0;for(usz e=0;e<m;e+=1)if(on[e])count+=1;usz bytes=8*(1+2*count);if(out==null||cap<bytes)return -2;put(out,0,count.long());usz at=8;for(usz a=0;a<n;a+=1)for(usz b=a+1;b<n;b+=1)for(usz e=0;e<m;e+=1)if(on[e]&&u[e]==a&&v[e]==b){put(out,at,a.long());put(out,at+8,b.long());at+=16;}return bytes.long();
}
