module reverse_words;

fn long reverse_words(long* input, usz length, char* output, usz output_capacity) @export("reverse_words") {
    if(input==null||length<1||input[0]<0||input[0]>256)return -1;usz n=(usz)input[0];if(length!=n+1)return -1;
    if(output==null||output_capacity<n+1)return -2;
    for(usz i=0;i<n;i++){long b=input[i+1];if(!(b==32||(b>=33&&b<=126)))return -1;if(b==32&&(i==0||i+1==n||input[i]==32))return -1;}
    usz written=0,ending=n;
    while(ending>0){usz start=ending;while(start>0&&input[start]!=32)start--;usz word_start=start;
        for(usz i=word_start;i<ending;i++)output[written++]=(char)input[i+1];
        if(word_start==0)break;output[written++]=32;ending=start-1;
    }
    output[written]=0;return (long)written;
}
