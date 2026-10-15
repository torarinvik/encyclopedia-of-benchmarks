module k_nearest_neighbors_binary;

const usz MAX_DIM=8, MAX_POINTS=128;
fn long k_nearest_neighbors_binary(long* input,usz length,char* output,usz capacity) @export("k_nearest_neighbors_binary"){
    if(input==null||length<3)return -1;
    long d64=input[0],n64=input[1],k64=input[2];
    if(d64<1||d64>(long)MAX_DIM||n64<1||n64>(long)MAX_POINTS||k64<1||k64>n64||k64%2==0||length!=3+(usz)d64+(usz)n64*((usz)d64+1))return -1;
    usz d=(usz)d64,n=(usz)n64,k=(usz)k64;
    for(usz axis=0;axis<d;axis++)if(input[3+axis]< -1000||input[3+axis]>1000)return -1;
    long[MAX_POINTS] distances;
    long[MAX_POINTS] labels;
    for(usz point=0;point<n;point++){
        usz base=3+d+point*(d+1);long sum=0;
        for(usz axis=0;axis<d;axis++){long x=input[base+axis];if(x< -1000||x>1000)return -1;long delta=x-input[3+axis];sum+=delta*delta;}
        long label=input[base+d];if(label!=0&&label!=1)return -1;
        for(usz prev=0;prev<point;prev++)if(distances[prev]==sum)return -1;
        distances[point]=sum;labels[point]=label;
    }
    for(usz i=1;i<n;i++){
        long distance=distances[i],label=labels[i];usz j=i;
        while(j>0&&distances[j-1]>distance){distances[j]=distances[j-1];labels[j]=labels[j-1];j--;}
        distances[j]=distance;labels[j]=label;
    }
    long ones=0;for(usz i=0;i<k;i++)ones+=labels[i];long prediction=ones>(long)(k/2)?1:0;
    if(output==null||capacity<8)return -2;
    ulong bits=(ulong)prediction;for(usz b=0;b<8;b++)output[b]=(char)(bits>>(8*b));return 8;
}
