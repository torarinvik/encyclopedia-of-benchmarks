module mibench_security_sha0;

const long INVALID_RESULT = -1, OUTPUT_ERROR = -2;
const usz MAX_MESSAGE_BYTES = 55;

fn uint rol32(uint value, uint shift) { return (value << shift) | (value >> (32-shift)); }
fn uint add32(uint a, uint b) { return (a + b); }

fn void transform_sha0(u8* block, uint* state) {
    uint words[80];
    for (usz i=0;i<16;i++) { usz p=i*4; words[i]=((uint)block[p]<<24)|((uint)block[p+1]<<16)|((uint)block[p+2]<<8)|(uint)block[p+3]; }
    for (usz i=16;i<80;i++) words[i]=words[i-3]^words[i-8]^words[i-14]^words[i-16];
    uint a=state[0],b=state[1],c=state[2],d=state[3],e=state[4];
    for (usz i=0;i<80;i++) {
        uint f,k;
        if(i<20){f=(b&c)|(~b&d);k=0x5A827999;}
        else if(i<40){f=b^c^d;k=0x6ED9EBA1;}
        else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC;}
        else{f=b^c^d;k=0xCA62C1D6;}
        uint temp=rol32(a,5)+f+e+words[i]+k;
        e=d;d=c;c=rol32(b,30);b=a;a=temp;
    }
    state[0]+=a;state[1]+=b;state[2]+=c;state[3]+=d;state[4]+=e;
}

fn long mibench_security_sha0(long* input, usz input_length, u8* output, usz output_capacity) @export("mibench_security_sha0") {
    if(input==null || input_length<1 || input_length>MAX_MESSAGE_BYTES+2) return INVALID_RESULT;
    long message_length=input[0];
    if(message_length<0 || message_length>55 || input_length!=(usz)message_length+1) return INVALID_RESULT;
    for(usz i=1;i<input_length;i++) if(input[i]<0 || input[i]>255) return INVALID_RESULT;
    u8 block[64]; for(usz i=0;i<64;i++) block[i]=0;
    for(usz i=0;i<(usz)message_length;i++) block[i]=(u8)input[i+1];
    block[(usz)message_length]=0x80;
    ulong bits=(ulong)message_length*8;
    for(usz i=0;i<8;i++) block[63-i]=(u8)(bits>>(8*i));
    uint state[5]={0x67452301,0xEFCDAB89,0x98BADCFE,0x10325476,0xC3D2E1F0};
    transform_sha0(&block[0],&state[0]);
    if(output==null || output_capacity<20) return OUTPUT_ERROR;
    for(usz i=0;i<5;i++) for(usz j=0;j<4;j++) output[i*4+j]=(u8)(state[i]>>(24-8*j));
    return 20;
}
