module sha1;

const usz MAX_INPUT = 4096;
const usz MAX_PADDED = 4160;

fn uint rol(uint value, uint shift) { return (value << shift) | (value >> (32 - shift)); }

fn long sha1(long* input, usz length, u8* output, usz capacity) @export("sha1") {
    if (length > MAX_INPUT || (length > 0 && input == null)) return -1;
    for (usz i=0;i<length;i++) if(input[i]<0||input[i]>255)return -1;
    u8[MAX_PADDED] padded;
    for (usz i=0;i<MAX_PADDED;i++) padded[i]=0;
    for (usz i=0;i<length;i++) padded[i]=(u8)input[i];
    padded[length]=0x80;
    usz blocks=(length+9+63)/64, padded_length=blocks*64;
    ulong bit_length=(ulong)length*8;
    for(usz i=0;i<8;i++)padded[padded_length-1-i]=(u8)(bit_length>>(8*i));
    uint h0=0x67452301,h1=0xEFCDAB89,h2=0x98BADCFE,h3=0x10325476,h4=0xC3D2E1F0;
    for(usz block=0;block<blocks;block++){
        uint[80] w;
        for(usz i=0;i<16;i++){usz p=block*64+i*4;w[i]=((uint)padded[p]<<24)|((uint)padded[p+1]<<16)|((uint)padded[p+2]<<8)|(uint)padded[p+3];}
        for(usz i=16;i<80;i++)w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
        uint a=h0,b=h1,c=h2,d=h3,e=h4;
        for(usz i=0;i<80;i++){
            uint f,k;
            if(i<20){f=(b&c)|((~b)&d);k=0x5A827999;}
            else if(i<40){f=b^c^d;k=0x6ED9EBA1;}
            else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC;}
            else{f=b^c^d;k=0xCA62C1D6;}
            uint temp=rol(a,5)+f+e+k+w[i];e=d;d=c;c=rol(b,30);b=a;a=temp;
        }
        h0+=a;h1+=b;h2+=c;h3+=d;h4+=e;
    }
    if(output==null||capacity<20)return -2;
    uint[5] digest={h0,h1,h2,h3,h4};
    for(usz i=0;i<5;i++)for(usz byte=0;byte<4;byte++)output[i*4+byte]=(u8)(digest[i]>>(24-8*byte));
    return 20;
}
