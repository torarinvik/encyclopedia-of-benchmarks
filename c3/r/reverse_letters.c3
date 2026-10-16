module reverse_letters;

fn long reverse_letters(long* input, usz length, char* output, usz output_capacity) @export("reverse_letters") {
    if(input==null||length<1||input[0]<0||input[0]>256)return -1;
    usz n=(usz)input[0];
    if(length!=n+1)return -1;
    for(usz i=0;i<n;i++){
        long value=input[i+1];
        if(value==32){if(i==0||i+1==n||input[i]==32)return -1;}
        else if(value<33||value>126)return -1;
    }
    if(output==null||output_capacity<n+1)return -2;
    usz start=0;
    while(start<n){
        usz end=start;
        while(end<n&&input[end+1]!=32)end++;
        for(usz i=0;i<end-start+1;i++)output[start+i]=(char)input[end-i+1];
        if(end<n)output[end]=' ';
        start=end+1;
    }
    output[n]=0;
    return (long)n;
}
