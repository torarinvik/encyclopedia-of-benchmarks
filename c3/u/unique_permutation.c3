module unique_permutation;
const usz MAX_LENGTH=6;

fn void generate(int* values, usz n, usz depth, int* current, bool* used,
                 char* output, usz* result_count) {
    if(depth==n){usz row=(*result_count)*n;for(usz i=0;i<n;i++)output[row+i]=(char)current[i];(*result_count)++;return;}
    for(usz i=0;i<n;i++){
        if(used[i])continue;
        if(i>0&&values[i]==values[i-1]&&!used[i-1])continue;
        current[depth]=values[i];used[i]=true;generate(values,n,depth+1,current,used,output,result_count);used[i]=false;
    }
}

fn long unique_permutation(long* input,usz length,char* output,usz output_capacity) @export("unique_permutation") {
    if(input==null||length<1||length>MAX_LENGTH+1)return -1;
    long n_value=input[0];if(n_value<0||n_value>MAX_LENGTH||length!=(usz)n_value+1)return -1;
    usz n=(usz)n_value;int[MAX_LENGTH] values;
    for(usz i=0;i<n;i++){long value=input[i+1];if(value<0||value>127)return -1;values[i]=(int)value;}
    for(usz i=1;i<n;i++){int value=values[i];usz p=i;while(p>0&&values[p-1]>value){values[p]=values[p-1];p--;}values[p]=value;}
    usz max_count=1;for(usz factor=2;factor<=n;factor++)max_count*=factor;
    usz required=max_count*n;if(output_capacity<required||(required!=0&&output==null))return -2;
    int[MAX_LENGTH] current;bool[MAX_LENGTH] used;for(usz i=0;i<n;i++)used[i]=false;
    usz result_count=0;generate(&values[0],n,0,&current[0],&used[0],output,&result_count);return (long)result_count;
}
