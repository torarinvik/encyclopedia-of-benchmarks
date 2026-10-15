module next_permutation;
const usz MAX_LENGTH=128;

fn void reverse(int* values,usz left,usz right){while(left<right){int temporary=values[left];values[left]=values[right];values[right]=temporary;left++;right--;}}
fn void store_i32_le(char* output,usz position,int value){uint bits=(uint)value;for(usz byte=0;byte<4;byte++)output[position+byte]=(char)((bits>>(byte*8))&255);}

fn long next_permutation(long* input,usz length,char* output,usz output_capacity) @export("next_permutation") {
    if(input==null||length<1||length>MAX_LENGTH+1)return -1;
    long n_value=input[0];if(n_value<0||n_value>(long)MAX_LENGTH||length!=(usz)n_value+1)return -1;
    usz n=(usz)n_value;int[MAX_LENGTH] values;
    for(usz i=0;i<n;i++){long x=input[i+1];if(x<-2147483648L||x>2147483647L)return -1;values[i]=(int)x;}
    usz required=n*4;if(output_capacity<required||(required!=0&&output==null))return -2;
    usz pivot=n;usz index=n;while(index>1){index--;if(values[index-1]<values[index]){pivot=index-1;break;}}
    if(pivot==n){if(n>1)reverse(&values[0],0,n-1);}else{usz successor=n-1;while(values[successor]<=values[pivot])successor--;int temporary=values[pivot];values[pivot]=values[successor];values[successor]=temporary;reverse(&values[0],pivot+1,n-1);}
    for(usz i=0;i<n;i++)store_i32_le(output,i*4,values[i]);return (long)n;
}
