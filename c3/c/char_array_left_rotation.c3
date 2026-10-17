module char_array_left_rotation;
const usz MAX_LEN=256;
fn void reverse_bytes(char*a,usz from,usz to){while(from<to){char t=a[from];a[from]=a[to];a[to]=t;from++;to--;}}
fn long char_array_left_rotation(long*input,usz length,char*output,usz capacity) @export("char_array_left_rotation"){if(input==null||length<2||length>MAX_LEN+3||input[0]<0||input[0]>256)return -1;usz n=(usz)input[0];if(input[1]<0||input[1]>(long)n||length!=n+2)return -1;for(usz i=0;i<n;i++)if(input[i+2]<0||input[i+2]>127)return -1;if(output==null||capacity<n)return -2;char[MAX_LEN] a;for(usz i=0;i<n;i++)a[i]=(char)input[i+2];usz k=(usz)input[1];if(k>0)reverse_bytes(&a[0],0,k-1);if(k<n)reverse_bytes(&a[0],k,n-1);if(n>0)reverse_bytes(&a[0],0,n-1);for(usz i=0;i<n;i++)output[i]=a[i];return (long)n;}
