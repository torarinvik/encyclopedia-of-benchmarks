module heap_permutation;

const usz MAX_LENGTH = 7;
fn void put_i32(char* output, usz offset, int value) { uint bits=(uint)value;for(usz b=0;b<4;b++)output[offset+b]=(char)(bits>>(8*b)); }
fn void generate(int* values, usz n, usz k, char* output, usz* rows) {
    if(k==1){usz start=*rows*n*4;for(usz j=0;j<n;j++)put_i32(output,start+j*4,values[j]);*rows+=1;return;}
    for(usz i=0;i<k;i++){usz swap_index=k%2==0?i:0;int temp=values[swap_index];values[swap_index]=values[k-1];values[k-1]=temp;generate(values,n,k-1,output,rows);}
}
fn long heap_permutation(long* input, usz length, char* output, usz capacity) @export("heap_permutation") {
    if(input==null||length<1||length>MAX_LENGTH+1)return -1;
    long n_value=input[0];if(n_value<0||n_value>(long)MAX_LENGTH||(usz)n_value+1!=length)return -1;
    usz n=(usz)n_value;int[MAX_LENGTH] values;
    for(usz i=0;i<n;i++){long v=input[i+1];if(v< -2147483648||v>2147483647)return -1;values[i]=(int)v;}
    usz permutations=1;for(usz f=2;f<=n;f++)permutations*=f;usz required=permutations*n*4;
    if(capacity<required||(required!=0&&output==null))return -2;if(n==0)return 1;
    usz rows=0;generate(&values[0],n,n,output,&rows);return (long)rows;
}
