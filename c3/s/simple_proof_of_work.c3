module proof_of_work;

const uint[64] K={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
const usz MAX_INPUT=4096, MAX_PADDED=4160;
fn uint rotr(uint x,uint n){return (x>>n)|(x<<(32-n));}
fn long proof_of_work_hash(long* input,usz length,char* output,usz capacity) {
    if(length>MAX_INPUT||(length>0&&input==null))return -1;
    for(usz i=0;i<length;i++)if(input[i]<0||input[i]>255)return -1;
    u8[MAX_PADDED] padded;for(usz i=0;i<MAX_PADDED;i++)padded[i]=0;
    for(usz i=0;i<length;i++)padded[i]=(u8)input[i];padded[length]=0x80;
    usz blocks=(length+9+63)/64,padded_length=blocks*64;ulong bit_length=(ulong)length*8;
    for(usz i=0;i<8;i++)padded[padded_length-1-i]=(u8)(bit_length>>(8*i));
    uint[8] h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    for(usz block=0;block<blocks;block++){
        uint[64] w;
        for(usz i=0;i<16;i++){usz p=block*64+i*4;w[i]=((uint)padded[p]<<24)|((uint)padded[p+1]<<16)|((uint)padded[p+2]<<8)|(uint)padded[p+3];}
        for(usz i=16;i<64;i++){uint x=w[i-15],y=w[i-2];uint s0=rotr(x,7)^rotr(x,18)^(x>>3),s1=rotr(y,17)^rotr(y,19)^(y>>10);w[i]=s1+w[i-7]+s0+w[i-16];}
        uint a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
        for(usz i=0;i<64;i++){
            uint s1=rotr(e,6)^rotr(e,11)^rotr(e,25),ch=(e&f)^(~e&g),t1=hh+s1+ch+K[i]+w[i];
            uint s0=rotr(a,2)^rotr(a,13)^rotr(a,22),maj=(a&b)^(a&c)^(b&c),t2=s0+maj;
            hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;
        }
        h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
    }
    if(output==null||capacity<32)return -2;
    for(usz i=0;i<8;i++)for(usz byte=0;byte<4;byte++)output[i*4+byte]=(char)(h[i]>>(24-8*byte));
    return 32;
}


const long MAX_VALUES=134, HEADER=5, MAX_FIELD=64, MAX_NONCE=4096;
fn usz append_decimal(long* out,usz pos,ulong value){u8[20] d;usz n=0;do{d[n++]=(u8)(48+value%10);value/=10;}while(value>0);while(n>0){n--;out[pos++]=(long)d[n];}return pos;}
fn bool zero_prefix(char* d,long difficulty){for(long i=0;i<difficulty;i++){u8 b=(u8)d[(usz)i/2];if((i%2==0?(b>>4):(b&15))!=0)return false;}return true;}
fn long simple_proof_of_work(long* input,usz length,char* output,usz capacity) @export("simple_proof_of_work"){
 if(input==null||length<HEADER||length>MAX_VALUES)return -1;long block=input[0],difficulty=input[1],max_nonce=input[2],tl=input[3],pl=input[4];
 if(block<0||difficulty<0||difficulty>2||max_nonce<0||max_nonce>MAX_NONCE||tl<0||tl>MAX_FIELD||pl<0||pl>MAX_FIELD)return -1;if(length!=HEADER+(usz)tl+(usz)pl)return -1;
 long* tx=input+HEADER;long* prev=tx+(usz)tl;for(usz i=0;i<(usz)tl;i++)if(tx[i]<0||tx[i]>127)return -1;for(usz i=0;i<(usz)pl;i++)if(prev[i]<0||prev[i]>127)return -1;if(output==null||capacity<72)return -2;
 const u8[16] hex={48,49,50,51,52,53,54,55,56,57,97,98,99,100,101,102};for(ulong nonce=0;nonce<=(ulong)max_nonce;nonce++){long[151] m;usz n=append_decimal(&m[0],0,(ulong)block);for(usz i=0;i<(usz)tl;i++)m[n++]=tx[i];for(usz i=0;i<(usz)pl;i++)m[n++]=prev[i];n=append_decimal(&m[0],n,nonce);char[32] d;if(proof_of_work_hash(&m[0],n,&d[0],32)!=32)return -1;if(zero_prefix(&d[0],difficulty)){for(usz i=0;i<8;i++)output[i]=(char)(u8)(nonce>>(8*i));for(usz i=0;i<32;i++){u8 b=(u8)d[i];output[8+2*i]=(char)hex[b>>4];output[9+2*i]=(char)hex[b&15];}return 72;}}return -3;
}
