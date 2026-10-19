module bitmap_block_allocation;
const usz MAX_BITS=4096;
const usz MAX_OPS=32;
const usz MAX_INPUT_LENGTH=66;
const usz MAX_OUTPUT=MAX_BITS/8;
fn long bitmap_block_allocation(long* values, usz length, char* output, usz output_capacity)
    @export("bitmap_block_allocation") {
    if(values==null || length<2 || length>MAX_INPUT_LENGTH) return -1;
    long raw_bits=values[0], raw_ops=values[1];
    if(raw_bits<1 || raw_bits>(long)MAX_BITS || raw_ops<0 || raw_ops>(long)MAX_OPS || length!=2+2*(usz)raw_ops) return -1;
    usz bits=(usz)raw_bits, ops=(usz)raw_ops;
    usz[MAX_OPS] offsets; usz[MAX_OPS] runs;
    for(usz i=0;i<ops;i+=1){long o=values[2+2*i], n=values[3+2*i];
        if(o<0 || o>raw_bits || n<0 || n>raw_bits-o) return -1;
        offsets[i]=(usz)o; runs[i]=(usz)n;
    }
    bool[MAX_BITS] bitmap;
    for (usz b=0;b<bits;b+=1) bitmap[b]=false;
    for(usz b=0;b<bits;b+=2) bitmap[b]=true;
    for(usz i=0;i<ops;i+=1) for(usz b=offsets[i];b<offsets[i]+runs[i];b+=1){
        if(i%3==0) bitmap[b]=true; else if(i%3==1) bitmap[b]=false; else bitmap[b]=!bitmap[b];
    }
    usz byte_count=(bits+7)/8;
    if(output==null || output_capacity<byte_count) return -2;
    for(usz j=0;j<byte_count;j+=1){
        uint packed=0;
        for(usz bit=0;bit<8;bit+=1){usz position=j*8+bit;if(position<bits && bitmap[position]) packed|=1<<bit;}
        output[j]=(char)packed;
    }
    return (long)byte_count;
}
