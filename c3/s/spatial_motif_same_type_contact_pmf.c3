module spatial_motif_same_type_contact_pmf;

const int MAX_LENGTH = 16;
const int MAX_SUPPORT = 17;

fn long choose_value(int n,int k0) {
    if(k0<0||k0>n)return 0;
    int k=k0;if(k>n-k)k=n-k;
    long result=1;
    for(int i=1;i<=k;i++)result=result*(long)(n-k+i)/(long)i;
    return result;
}
fn long gcd_value(long a,long b){while(b!=0){long r=a%b;a=b;b=r;}return a;}
fn void put_i64(char* output,usz word,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)output[word*8+b]=(char)((bits>>(b*8))&255);}

fn long spatial_motif_same_type_contact_pmf(long* input,usz input_length,char* output,usz output_capacity) @export("spatial_motif_same_type_contact_pmf") {
    if(input==null||input_length!=3)return -1;
    long l0=input[0],x10=input[1],x20=input[2];
    if(l0<1||l0>MAX_LENGTH||x10<0||x10>l0||x20<0||x20>l0)return -1;
    int l=(int)l0,x1=(int)x10,x2=(int)x20;
    int low=x1+x2>l?x1+x2-l:0,high=x1<x2?x1:x2;
    long denominator=choose_value(l,x2);long[MAX_SUPPORT] numerators={0};
    for(int i=low;i<=high;i++)numerators[i-low]=choose_value(x1,i)*choose_value(l-x1,x2-i);
    long expected_num=(long)(x1*x2),expected_den=(long)l,divisor=gcd_value(expected_num,expected_den);
    expected_num/=divisor;expected_den/=divisor;
    usz count=(usz)(high-low+1),bytes=(3+count+2)*8;
    if(output==null||output_capacity<bytes)return -2;
    put_i64(output,0,(long)low);put_i64(output,1,(long)high);put_i64(output,2,denominator);
    for(usz i=0;i<count;i++)put_i64(output,3+i,numerators[i]);
    put_i64(output,3+count,expected_num);put_i64(output,4+count,expected_den);
    return (long)bytes;
}
