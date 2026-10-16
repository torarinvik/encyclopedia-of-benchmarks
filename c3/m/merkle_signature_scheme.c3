module merkle_signature_scheme;

const uint[64] K={
0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2};
const usz MAX_INPUT=8192, MAX_PADDED=8256;
fn uint rotr(uint x,uint n){return (x>>n)|(x<<(32-n));}
fn long sha256(long* input,usz length,char* output,usz capacity) @export("sha256") {
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


fn long min_cost_signature_verify(long* input, usz height, usz w, usz msg, usz leaf_index, usz sig_pos, usz pk_pos, usz auth_pos, usz root_pos, usz l) {
    char[32] digest, current;
    if (sha256(input+3,msg,&digest[0],32)!=32) return 0;
    uchar[133] digits; usz log_w=w==4?2:(w==16?4:8),len1=w==4?128:(w==16?64:32),len2=l-len1,digit=0;int checksum=0,mask=(int)w-1;
    for(usz i=0;i<32;i++)for(usz part=0;part<8/log_w;part++){usz shift=8-log_w*(part+1);uint v=(uint)(uchar)digest[i];digits[digit]=(uchar)((v>>shift)&(uint)mask);checksum+=mask-(int)digits[digit];digit++;}
    for(usz i=0;i<len2;i++){digits[len1+len2-1-i]=(uchar)(checksum&mask);checksum>>=log_w;}
    long[32] chain;for(usz i=0;i<l;i++){for(usz j=0;j<32;j++)chain[j]=input[sig_pos+32*i+j];for(usz step=0;step<w-1-(usz)digits[i];step++){if(sha256(&chain[0],32,&current[0],32)!=32)return 0;for(usz j=0;j<32;j++)chain[j]=(uchar)current[j];}for(usz j=0;j<32;j++)if((uchar)chain[j]!=(uchar)input[pk_pos+32*i+j])return 0;}
    if(sha256(input+pk_pos,32*l,&digest[0],32)!=32)return 0;long[64] pair;usz index=leaf_index;for(usz level=0;level<height;level++){for(usz j=0;j<32;j++){long left=(uchar)digest[j],right=input[auth_pos+32*level+j];pair[j]=index%2==0?left:right;pair[32+j]=index%2==0?right:left;}if(sha256(&pair[0],64,&digest[0],32)!=32)return 0;index>>=1;}for(usz j=0;j<32;j++)if((uchar)digest[j]!=(uchar)input[root_pos+j])return 0;return 1;
}
fn long merkle_signature_scheme(long* input,usz length,char* output,usz capacity) @export("merkle_signature_scheme") {
    if(input==null||length<4||length>8932)return -1;long h0=input[0],w0=input[1],m0=input[2];if(h0<2||h0>10||(w0!=4&&w0!=16&&w0!=256)||m0<0||m0>64)return -1;
    usz height=(usz)h0,w=(usz)w0,msg=(usz)m0,l=w==4?133:(w==16?67:34),index_pos=3+msg,expected=4+msg+64*l+32*height+32;if(length!=expected)return -1;
    for(usz i=0;i<msg;i++)if(input[3+i]<0||input[3+i]>127)return -1;long index0=input[index_pos];if(index0<0||(ulong)index0>=(1ul<<height))return -1;
    usz sig=index_pos+1,pk=sig+32*l,auth=pk+32*l,root=auth+32*height;for(usz i=sig;i<length;i++)if(input[i]<0||input[i]>255)return -1;if(output==null||capacity<8)return -2;
    long valid=min_cost_signature_verify(input,height,w,msg,(usz)index0,sig,pk,auth,root,l);for(usz i=0;i<8;i++)output[i]=0;output[0]=(char)valid;return 8;
}
