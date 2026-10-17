module subtract;

fn void store_i32_le(uint value, char* output, usz offset) { for(usz b=0;b<4;b++)output[offset+b]=(char)((value>>(b*8))&255); }

fn long subtract(long* input, usz length, char* output, usz output_capacity) @export("subtract") {
    if(input==null||length<4||input[0]<0||input[0]>16||input[1]<0||input[1]>16)return -2;
    usz ra=(usz)input[0],ca=(usz)input[1];if(ra==0&&ca!=0)return -2;usz na=ra*ca,bd=2+na;
    if(bd+2>length||input[bd]<0||input[bd]>16||input[bd+1]<0||input[bd+1]>16)return -2;
    usz rb=(usz)input[bd],cb=(usz)input[bd+1];if(rb==0&&cb!=0)return -2;usz nb=rb*cb;
    if(length!=bd+2+nb)return -2;if(ra!=rb||ca!=cb)return -1;
    for(usz i=0;i<na;i++)if(input[2+i]<-2147483648||input[2+i]>2147483647||input[bd+2+i]<-2147483648||input[bd+2+i]>2147483647)return -2;
    if(na==0)return 0;if(output==null||output_capacity<na*4)return -3;
    for(usz i=0;i<na;i++)store_i32_le((uint)(int)input[2+i]-(uint)(int)input[bd+2+i],output,i*4);
    return (long)na;
}
