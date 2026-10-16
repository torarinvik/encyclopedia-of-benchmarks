module unbias_01;

fn long unbias_01(long* input, usz length) @export("unbias_01") {
    if (input == null || length < 1 || length > 257) return -1;
    long n=input[0]; if(n<0 || n>256 || length!=(usz)(n+1))return -1;
    for(usz i=0;i<(usz)n;i++)if(input[i+1]!=0&&input[i+1]!=1)return -1;
    for(usz i=0;i+1<(usz)n;i+=2)if(input[i+1]!=input[i+2])return input[i+1];
    return -1;
}
