module reverse_string;

fn long reverse_string(long* input, usz length, char* output, usz output_capacity) @export("reverse_string") {
    if(input==null||length<1||input[0]<0||input[0]>256)return -1;
    usz n=(usz)input[0];
    if(length!=n+1)return -1;
    for(usz i=0;i<n;i++){if(input[i+1]<33||input[i+1]>126)return -1;}
    if(output==null||output_capacity<n+1)return -2;
    for(usz i=0;i<n;i++)output[i]=(char)input[n-i];
    output[n]=0;
    return (long)n;
}
