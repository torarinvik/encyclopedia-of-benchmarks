module tournament_sort;
const usz MAX_VALUES=512;
fn int choose(long* values,int* tree,int left,int right){if(left<0)return right;if(right<0)return left;return values[left]<=values[right]?left:right;}
fn void put_i64(char* output,usz offset,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++){output[offset+b]=(char)(bits&255);bits>>=8;}}
fn long tournament_sort(long* input,usz length,char* output,usz capacity) @export("tournament_sort"){
 if(input==null||length<1||input[0]<0||input[0]>(long)MAX_VALUES)return -1;usz n=(usz)input[0];if(length!=1+n)return -1;long[MAX_VALUES] values;for(usz i=0;i<n;i++){if(input[i+1]<(-2147483647-1)||input[i+1]>2147483647)return -1;values[i]=input[i+1];}
 usz leaves=1;while(leaves<n)leaves*=2;int[2*MAX_VALUES+1] tree;for(usz i=0;i<2*leaves;i++)tree[i]=-1;for(usz i=0;i<n;i++)tree[leaves+i]=(int)i;usz node=leaves;while(node>1){node--;tree[node]=choose(&values,&tree,(int)(2*node),(int)(2*node+1));}
 usz bytes=(1+n)*8;if(output==null||capacity<bytes)return -2;put_i64(output,0,(long)n);for(usz out=0;out<n;out++){int w=tree[1];put_i64(output,(1+out)*8,values[w]);usz pos=leaves+(usz)w;tree[pos]=-1;while(pos>1){pos/=2;tree[pos]=choose(&values,&tree,(int)(2*pos),(int)(2*pos+1));}}return (long)bytes;
}
