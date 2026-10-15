module wave_sort;
const usz MAX_ARRAY_LENGTH=4096;
fn void sift_down(long* v, usz root_input, usz end) { usz root=root_input; while(root<end/2){usz child=root*2+1;if(child+1<end&&v[child]<v[child+1])child++;if(v[root]>=v[child])break;long t=v[root];v[root]=v[child];v[child]=t;root=child;} }

fn long wave_sort(long* input, usz length, char* output, usz output_capacity) @export("wave_sort") {
    if(length>MAX_ARRAY_LENGTH||(length!=0&&input==null)) return -1;
    long[MAX_ARRAY_LENGTH] values;
    for(usz i=0;i<length;i++){if(input[i]<-2147483648||input[i]>2147483647)return -1;values[i]=input[i];}
    usz bytes=length*4;if(output_capacity<bytes||(bytes!=0&&output==null))return -2;
        for(usz start=length/2;start>0;start--)sift_down(&values[0],start-1,length);
    for(usz end=length;end>1;end--){long t=values[0];values[0]=values[end-1];values[end-1]=t;sift_down(&values[0],0,end-1);}
    for(usz i=0;i+1<length;i+=2){long t=values[i];values[i]=values[i+1];values[i+1]=t;}

    for(usz i=0;i<length;i++){uint bits=(uint)(int)values[i];for(usz b=0;b<4;b++)output[i*4+b]=(char)((bits>>(b*8))&255);}
    return (long)length;
}
