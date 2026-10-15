module a5_key_stream_generator;

fn uint parity(uint value) { uint x=value; x^=x>>16; x^=x>>8; x^=x>>4; x^=x>>2; x^=x>>1; return x&1; }
fn uint fb1(uint r) { return parity(r&((1u<<13)|(1u<<16)|(1u<<17)|(1u<<18))); }
fn uint fb2(uint r) { return parity(r&((1u<<20)|(1u<<21))); }
fn uint fb3(uint r) { return parity(r&((1u<<7)|(1u<<20)|(1u<<21)|(1u<<22))); }
fn uint push(uint r, usz width, uint bit) { return ((r<<1)|bit)&((1u<<width)-1); }
fn void initialize(ulong key,uint frame,uint* r1,uint* r2,uint* r3) {
    *r1=0;*r2=0;*r3=0;
    for(int i=63;i>=0;i--){uint bit=(uint)((key>>(usz)i)&1);*r1=push(*r1,19,bit^fb1(*r1));*r2=push(*r2,22,bit^fb2(*r2));*r3=push(*r3,23,bit^fb3(*r3));}
    for(int i=21;i>=0;i--){uint bit=(frame>>(usz)i)&1;*r1=push(*r1,19,bit^fb1(*r1));*r2=push(*r2,22,bit^fb2(*r2));*r3=push(*r3,23,bit^fb3(*r3));}
}
fn uint tick(uint* r1,uint* r2,uint* r3) {
    uint c1=(*r1>>8)&1;
    uint c2=(*r2>>10)&1;
    uint c3=(*r3>>10)&1;
    uint majority=(c1+c2+c3>=2)?1u:0u;
    uint out=((*r1>>18)^(*r2>>21)^(*r3>>22))&1;
    if(c1==majority)*r1=push(*r1,19,fb1(*r1));if(c2==majority)*r2=push(*r2,22,fb2(*r2));if(c3==majority)*r3=push(*r3,23,fb3(*r3));return out;
}
fn uint next_frame(uint frame){for(int i=21;i>=0;i--){uint mask=1u<<(usz)i;if((frame&mask)==0)return frame|mask;frame&=~mask;}return frame;}
fn void store_bit(char* output,usz block,usz bit,uint value){output[block*32+bit/8]=(char)((uint)output[block*32+bit/8]|(value<<(bit%8)));}

fn long a5_key_stream_generator(long* input, usz length, char* output, usz output_capacity) @export("a5_key_stream_generator") {
    if (input==null || length!=3 || input[2]<1 || input[2]>4) return -1;
    usz blocks=(usz)input[2];
    usz bytes=29*blocks;
    if(output==null||output_capacity<bytes)return -2;
    ulong key=(ulong)input[0];
    uint frame=(uint)((ulong)input[1]&0x3fffff);
    for(usz block=0;block<blocks;block++){
        uint r1,r2,r3;
        initialize(key,frame,&r1,&r2,&r3);
        uint ignored=0;
        for(int i=0;i<100;i++)ignored=tick(&r1,&r2,&r3);
        for(usz i=0;i<29;i++)output[block*29+i]=0;
        for(usz bit=0;bit<228;bit++){
            uint value=tick(&r1,&r2,&r3);
            output[block*29+bit/8]=(char)((uint)output[block*29+bit/8]|(value<<(bit%8)));
        }
        frame=next_frame(frame);
    }
    return (long)bytes;
}
