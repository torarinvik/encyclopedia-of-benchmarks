module bfs_result_tree;
fn void put_i64(long value,char* output,usz word){ulong bits=@bitcast(ulong,value);for(usz b=0;b<8;b++){output[word*8+b]=(char)(bits&255);bits>>=8;}}
fn long bfs_result_tree(long* input,usz length,char* output,usz capacity) @export("bfs_result_tree") {
 if(input==null||length<3)return -1;long nv=input[0],mv=input[1],sv=input[2];if(nv<1||nv>32||mv<0||mv>126||sv<0||sv>=nv||length!=(usz)(3+2*mv))return -1;
 usz n=(usz)nv,m=(usz)mv,start=(usz)sv;usz[32*126] adj;usz[32] degree;bool[32] seen;long[32] parent,distance;usz[32] queue,order;for(usz v=0;v<32;v++){degree[v]=0;seen[v]=false;parent[v]=-1;distance[v]=-1;}
 for(usz e=0;e<m;e++){long av=input[3+2*e],bv=input[4+2*e];if(av<0||av>=nv||bv<0||bv>=nv)return -1;usz a=(usz)av;adj[a*126+degree[a]]=(usz)bv;degree[a]++;}
 usz head=0,tail=0,count=0;seen[start]=true;distance[start]=0;queue[tail++]=start;while(head<tail){usz v=queue[head++];order[count++]=v;for(usz j=0;j<degree[v];j++){usz w=adj[v*126+j];if(!seen[w]){seen[w]=true;parent[w]=(long)v;distance[w]=distance[v]+1;queue[tail++]=w;}}}
 usz words=4+6*count;if(output==null||capacity<words*8)return -2;usz k=0;put_i64((long)count,output,k++);for(usz i=0;i<count;i++)put_i64((long)order[i],output,k++);put_i64((long)count,output,k++);for(usz i=0;i<count;i++)put_i64((long)order[i],output,k++);put_i64((long)count,output,k++);for(usz i=0;i<count;i++){usz v=order[i];put_i64((long)v,output,k++);put_i64(parent[v],output,k++);}put_i64((long)count,output,k++);for(usz i=0;i<count;i++){usz v=order[i];put_i64((long)v,output,k++);put_i64(distance[v],output,k++);}return (long)(words*8);
}
