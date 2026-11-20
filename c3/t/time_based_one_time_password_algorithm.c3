module time_based_one_time_password_algorithm;

const usz MAX_KEY = 64;
const usz MAX_WORDS = 67;

fn uint rol(uint x, usz n) { return (x << n) | (x >> (32 - n)); }
fn uint add32(uint a,uint b){return (uint)(((ulong)a+(ulong)b)&0xffffffff);}

fn void compress(uint* h, uchar* block) {
    uint[80] w;
    for (usz i=0;i<16;i++) { usz j=i*4;w[i]=((uint)block[j]<<24)|((uint)block[j+1]<<16)|((uint)block[j+2]<<8)|(uint)block[j+3]; }
    for (usz i=16;i<80;i++) w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
    uint a=h[0],b=h[1],c=h[2],d=h[3],e=h[4];
    for (usz i=0;i<80;i++) {
        uint f,k;
        if(i<20){f=(b&c)|(~b&d);k=0x5a827999;}else if(i<40){f=b^c^d;k=0x6ed9eba1;}else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8f1bbcdc;}else{f=b^c^d;k=0xca62c1d6;}
        uint t=add32(add32(add32(add32(rol(a,5),f),e),k),w[i]);e=d;d=c;c=rol(b,30);b=a;a=t;
    }
    h[0]=add32(h[0],a);h[1]=add32(h[1],b);h[2]=add32(h[2],c);h[3]=add32(h[3],d);h[4]=add32(h[4],e);
}

fn void initial(uint* h){h[0]=0x67452301;h[1]=0xefcdab89;h[2]=0x98badcfe;h[3]=0x10325476;h[4]=0xc3d2e1f0;}
fn void serialize(uint* h,uchar* out){for(usz i=0;i<5;i++)for(usz b=0;b<4;b++)out[i*4+b]=(uchar)(h[i]>>(24-8*b));}

fn void compute(long* input,usz key_len,uchar* output){
    uchar[64] key;uchar[64] block;uchar[20] inner;uint[5] h;
    for(usz i=0;i<64;i++){key[i]=0;block[i]=0;}for(usz i=0;i<key_len;i++)key[i]=(uchar)input[i+1];
    for(usz i=0;i<64;i++)block[i]=key[i]^0x36;initial(&h[0]);compress(&h[0],&block[0]);for(usz i=0;i<64;i++)block[i]=0;
    ulong counter=(ulong)input[key_len+1]/30;for(usz i=0;i<8;i++)block[i]=(uchar)(counter>>(56-8*i));block[8]=0x80;block[62]=2;block[63]=0x40;
    compress(&h[0],&block[0]);serialize(&h[0],&inner[0]);for(usz i=0;i<64;i++)block[i]=key[i]^0x5c;
    initial(&h[0]);compress(&h[0],&block[0]);for(usz i=0;i<64;i++)block[i]=0;for(usz i=0;i<20;i++)block[i]=inner[i];block[20]=0x80;block[62]=2;block[63]=0xa0;
    compress(&h[0],&block[0]);serialize(&h[0],&inner[0]);usz offset=inner[19]&15;
    uint binary=((uint)inner[offset]<<24)|((uint)inner[offset+1]<<16)|((uint)inner[offset+2]<<8)|(uint)inner[offset+3];binary&=0x7fffffff;
    uint value=binary%1000000;for(long i=5;i>=0;i--){output[i]=(uchar)('0'+value%10);value/=10;}
}

fn long time_based_one_time_password_algorithm(long* input, usz length, uchar* output, usz capacity)
    @export("time_based_one_time_password_algorithm") {
    if(input==null||length<3||length>MAX_WORDS)return -1;
    long key_word=input[0];if(key_word<16||key_word>(long)MAX_KEY||length!=(usz)key_word+2)return -1;
    usz key_len=(usz)key_word;for(usz i=0;i<key_len;i++)if(input[i+1]<0||input[i+1]>255)return -1;
    if(input[key_len+1]<0)return -1;
    uchar[6] staged;compute(input,key_len,&staged[0]);if(output==null||capacity<6)return -2;
    for(usz i=0;i<6;i++)output[i]=staged[i];return 6;
}
