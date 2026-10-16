module floor_and_ceiling;
fn void put_i64_le(long value, char* output, usz offset) {
    ulong bits=(ulong)value;
    for(usz b=0;b<8;b+=1){output[offset+b]=(char)(bits&255);bits>>=8;}
}
fn long floor_and_ceiling(long* input, usz length, char* output, usz capacity) @export("floor_and_ceiling") {
    if(input==null || length<3 || length>384)return -1;
    long raw_n=input[0],root=input[1],key=input[2];
    if(raw_n<0 || raw_n>127 || key < -1000000 || key>1000000 || length!=3+3*(usz)raw_n)return -1;
    usz n=(usz)raw_n;
    if((n==0 && root!=-1)||(n>0 && (root<0 || root>=raw_n)))return -1;
    long floor=long.min,ceiling=long.min;
    usz current=n;
    if(n>0)current=(usz)root;
    for(usz step=0;step<n;step+=1){
        if(current>=n)break;
        usz base=3+3*current;long value=input[base],left=input[base+1],right=input[base+2];
        if(value < -1000000 || value>1000000 || left < -1 || right < -1 || left>=raw_n || right>=raw_n)return -1;
        if(value==key){floor=value;ceiling=value;break;}
        if(key<value){ceiling=value;current=if left<0 then n else (usz)left;}
        else{floor=value;current=if right<0 then n else (usz)right;}
    }
    if(output==null || capacity<16)return -2;
    put_i64_le(floor,output,0);put_i64_le(ceiling,output,8);return 16;
}
