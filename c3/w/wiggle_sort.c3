module wiggle_sort;
const usz MAX_ARRAY_LENGTH=4096;

fn long wiggle_sort(long* input, usz length, char* output, usz output_capacity) @export("wiggle_sort") {
    if(length>MAX_ARRAY_LENGTH||(length!=0&&input==null)) return -1;
    long[MAX_ARRAY_LENGTH] values;
    for(usz i=0;i<length;i++){if(input[i]<-2147483648||input[i]>2147483647)return -1;values[i]=input[i];}
    usz bytes=length*4;if(output_capacity<bytes||(bytes!=0&&output==null))return -2;
        for(usz i=1;i<length;i++){if((i%2==1&&values[i-1]>values[i])||(i%2==0&&values[i-1]<values[i])){long t=values[i];values[i]=values[i-1];values[i-1]=t;}}

    for(usz i=0;i<length;i++){uint bits=(uint)(int)values[i];for(usz b=0;b<4;b++)output[i*4+b]=(char)((bits>>(b*8))&255);}
    return (long)length;
}
