module generate_subsets_recursive;

const usz MAX_ITEMS = 12;
fn void put32(uchar* out, usz* pos, uint value) { uint bits=value; for(usz i=0;i<4;i++){out[*pos]=(uchar)(bits&255);*pos+=1;bits>>=8;} }
fn void emit_subsets(long* input, usz n, usz index, uint mask, uint selected, uchar* out, usz* pos) {
    if(index==n) { put32(out,pos,selected); for(usz i=0;i<n;i++) if((mask & ((uint)1<<i))!=0) { out[*pos]=(uchar)input[i+1]; *pos+=1; } return; }
    emit_subsets(input,n,index+1,mask|((uint)1<<index),selected+1,out,pos);
    emit_subsets(input,n,index+1,mask,selected,out,pos);
}

fn long generate_subsets_recursive(long* input, usz length, uchar* output, usz capacity) @export("generate_subsets_recursive") {
    if(input==null || length<1 || length>13 || input[0]<0 || input[0]>12) return -1;
    usz n=(usz)input[0]; if(length!=n+1) return -1;
    for(usz i=0;i<n;i++) if(input[i+1]<0 || input[i+1]>127) return -1;
    usz subsets=(usz)1<<n; usz needed=4+4*subsets+n*(subsets/2);
    if(output==null || capacity<needed) return -2;
    usz pos=0; put32(output,&pos,(uint)subsets);
    emit_subsets(input,n,0,0,0,output,&pos);
    return (long)pos;
}
