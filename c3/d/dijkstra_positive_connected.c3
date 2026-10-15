module dijkstra_positive_connected;
fn void put_i64(long value,char* output,usz index){ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++){output[index*8+b]=(char)(bits&255);bits>>=8;}}
fn long dijkstra_positive_connected(long* input,usz length,char* output,usz capacity) @export("dijkstra_positive_connected") {
 if(input==null||length<2)return -1;long nv=input[0],mv=input[1];if(nv<1||nv>4||mv<0||mv>6||length!=(usz)(2+3*mv))return -1;usz n=(usz)nv,m=(usz)mv;if(m<n-1||m>n*(n-1)/2)return -1;
 bool[16] adj;long[16] weight;usz[4*6] neighbors;usz[4] degree;for(usz e=0;e<m;e++){long av=input[2+3*e],bv=input[3+3*e],cost=input[4+3*e];if(av<0||av>=nv||bv<0||bv>=nv||av==bv||cost<1||cost>255)return -1;usz a=(usz)av,b=(usz)bv;usz ab=a*4+b,ba=b*4+a;if(adj[ab])return -1;adj[ab]=true;adj[ba]=true;weight[ab]=cost;weight[ba]=cost;neighbors[a*6+degree[a]]=b;degree[a]++;neighbors[b*6+degree[b]]=a;degree[b]++;}
 bool[4] seen;usz[4] stack;usz top=1;stack[0]=0;seen[0]=true;while(top>0){usz u=stack[--top];for(usz j=0;j<degree[u];j++){usz v=neighbors[u*6+j];if(!seen[v]){seen[v]=true;stack[top++]=v;}}}for(usz v=0;v<n;v++)if(!seen[v])return -1;
 long[4] dist;bool[4] done;for(usz v=0;v<4;v++){dist[v]=1000000000;done[v]=false;}dist[0]=0;for(usz step=0;step<n;step++){long selected=-1;for(usz v=0;v<n;v++)if(!done[v]&&(selected<0||dist[v]<dist[(usz)selected]))selected=(long)v;if(selected<0)break;usz u=(usz)selected;done[u]=true;for(usz j=0;j<degree[u];j++){usz v=neighbors[u*6+j];long cost=weight[u*4+v];if(!done[v]&&dist[u]+cost<dist[v])dist[v]=dist[u]+cost;}}
 if(output==null||capacity<n*8)return -2;for(usz v=0;v<n;v++)put_i64(dist[v],output,v);return (long)(n*8);
}
