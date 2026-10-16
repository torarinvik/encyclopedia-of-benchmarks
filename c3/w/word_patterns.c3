module word_patterns;

fn long word_patterns(long* input, usz length, char* output, usz capacity) @export("word_patterns") {
    if(input==null||length<1||input[0]<0||input[0]>256||length!=(usz)input[0]+1)return -1;
    usz n=(usz)input[0];
    int first[128];for(int i=0;i<128;i++)first[i]=-1;int next=0;usz pos=0;
    for(usz i=0;i<n;i++){long ch=input[i+1];if(ch<0||ch>127)return -1;if(ch>=97&&ch<=122)ch-=32;int c=(int)ch;if(first[c]<0)first[c]=next++;}
    if(output==null||capacity<4*n+1)return -2;pos=0;
    for(usz i=0;i<n;i++){long ch=input[i+1];if(ch>=97&&ch<=122)ch-=32;int c=(int)ch;if(i>0)output[pos++]='.';int value=first[c];char digits[3];usz count=0;do{digits[count++]=(char)('0'+value%10);value/=10;}while(value);while(count>0)output[pos++]=digits[--count];}
    output[pos]=0;return (long)pos;
}
