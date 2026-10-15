module linear_congruential_generator;

fn void put_u64_le(char* output, usz offset, ulong value) {
    for (usz byte = 0; byte < 8; byte++) output[offset + byte] = (char)(value >> (8 * byte));
}

fn long linear_congruential_generator(long* input, usz length, char* output, usz capacity) @export("linear_congruential_generator") {
    if(input==null||length!=5)return -1;
    long seed=input[0],multiplier=input[1],increment=input[2],modulo=input[3],count=input[4];
    if(modulo<2||modulo>4294967296l||seed<0||seed>=modulo||multiplier<0||multiplier>65535||increment<0||increment>4294967295l||count<0||count>512)return -1;
    usz n=(usz)count,required=8*n;if(capacity<required||(required!=0&&output==null))return -2;
    ulong state=(ulong)seed;for(usz i=0;i<n;i++){state=((ulong)multiplier*state+(ulong)increment)%(ulong)modulo;put_u64_le(output,i*8,state);}return (long)required;
}
