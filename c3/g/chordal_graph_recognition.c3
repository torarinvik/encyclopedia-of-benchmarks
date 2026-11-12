module chordal_graph_recognition;
const int N=6;const int MAX_INPUT=32;const int MAX_OUTPUT=64;
fn void put_u64(char* out,usz index,ulong value){for(usz byte=0;byte<8;byte++){out[index*8+byte]=(char)(value&255);value>>=8;}}
fn bool find_cycle(bool* adjacent,int n,int* cycle,int* cycle_length){
 for(uint mask=0;mask<(1u<<n);mask++){
  int[N] vertices={};int count=0;for(int v=0;v<n;v++)if((mask&(1u<<v))!=0){vertices[count]=v;count++;}if(count<4)continue;
  bool valid=true;for(int i=0;i<count;i++){int degree=0;for(int j=0;j<count;j++)if(adjacent[vertices[i]*N+vertices[j]])degree++;if(degree!=2)valid=false;}if(!valid)continue;
  bool[N] seen={};int[N] queue={};int head=0,tail=1;seen[vertices[0]]=true;queue[0]=vertices[0];
  while(head<tail){int v=queue[head++];for(int j=0;j<count;j++){int u=vertices[j];if(adjacent[v*N+u]&&!seen[u]){seen[u]=true;queue[tail++]=u;}}}if(tail!=count)continue;
  int start=vertices[0],previous=start,current=start;for(int j=0;j<count;j++)if(adjacent[start*N+vertices[j]]){current=vertices[j];break;}cycle[0]=start;
  for(int i=1;i<count;i++){cycle[i]=current;int next=start;for(int j=0;j<count;j++){int u=vertices[j];if(adjacent[current*N+u]&&u!=previous){next=u;break;}}previous=current;current=next;}
  *cycle_length=count;return true;
 }return false;
}
fn long chordal_graph_recognition(long* input,usz length,char* output,usz capacity) @export("chordal_graph_recognition"){
 if(input==null||length<2||length>MAX_INPUT||input[0]<1||input[0]>N||input[1]<0||input[1]>15)return -1;
 int n=(int)input[0],m=(int)input[1];if(m>n*(n-1)/2||length!=(usz)(2+2*m))return -1;
 bool[N*N] adjacent={};for(int e=0;e<m;e++){long a0=input[2+2*e],b0=input[3+2*e];if(a0<0||b0<0||a0>=n||b0>=n||a0==b0)return -1;int a=(int)a0,b=(int)b0;if(adjacent[a*N+b])return -1;adjacent[a*N+b]=true;adjacent[b*N+a]=true;}
 bool[N] selected={};int[N] label={},reverse_order={},order={},position={};
 for(int step=0;step<n;step++){int chosen=-1;for(int v=0;v<n;v++)if(!selected[v]&&(chosen<0||label[v]>label[chosen]))chosen=v;selected[chosen]=true;reverse_order[step]=chosen;for(int u=0;u<n;u++)if(!selected[u]&&adjacent[chosen*N+u])label[u]++;}
 for(int i=0;i<n;i++){order[i]=reverse_order[n-i-1];position[order[i]]=i;}
 bool peo=true;for(int i=0;i<n;i++){int v=order[i],parent=-1;for(int u=0;u<n;u++)if(adjacent[v*N+u]&&position[u]>i&&(parent<0||position[u]<position[parent]))parent=u;if(parent>=0)for(int u=0;u<n;u++)if(adjacent[v*N+u]&&position[u]>i&&u!=parent&&!adjacent[parent*N+u])peo=false;}
 ulong[8] packed={};usz count=0;if(peo){packed[count++]=1;for(int i=0;i<n;i++)packed[count++]=(ulong)order[i];}else{int[N] cycle={};int cycle_length=0;if(!find_cycle(&adjacent[0],n,&cycle[0],&cycle_length))return -1;packed[count++]=0;packed[count++]=(ulong)cycle_length;for(int i=0;i<cycle_length;i++)packed[count++]=(ulong)cycle[i];}
 usz bytes=count*8;if(output==null||capacity<bytes)return -2;char[MAX_OUTPUT] staged={};for(usz i=0;i<count;i++)put_u64(staged,i,packed[i]);for(usz i=0;i<bytes;i++)output[i]=staged[i];return (long)bytes;
}
