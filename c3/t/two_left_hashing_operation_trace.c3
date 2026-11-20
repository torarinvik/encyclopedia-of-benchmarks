module two_left_hashing_operation_trace;

const QMAX=40; const HALF=8; const KEY_CAP=32;
fn void put(u8* output, usz offset, long value){
    ulong bits=(ulong)value;
    for(usz j=0;j<8;j++) output[offset+j]=(u8)((bits>>(8*j))&255);
}
fn long two_left_hashing_operation_trace(long* input, usz length, u8* output, usz output_capacity)
    @export("two_left_hashing_operation_trace") {
    if(input==null||length<5||length>162)return -1;
    if(input[0]<1||input[0]>QMAX||length!=1+4*(usz)input[0])return -1;
    usz q=(usz)input[0];
    for(usz i=0;i<q;i++){
        long op=input[1+4*i],key=input[2+4*i],left=input[3+4*i],right=input[4+4*i];
        if(op<0||op>2||key<0||key>63||left<0||left>=HALF||right<0||right>=HALF)return -1;
        for(usz j=0;j<i;j++)if(input[2+4*j]==key&&(input[3+4*j]!=left||input[4+4*j]!=right))return -1;
    }
    usz bytes=16*q;if(output==null||output_capacity<bytes)return -2;
    long[16] head; long[16] lengths; long[32] keys; long[32] next;
    long[40] statuses; long[40] placements;
    for(usz b=0;b<16;b++){head[b]=-1;lengths[b]=0;}
    for(usz x=0;x<32;x++){keys[x]=-1;next[x]=-1;}
    usz live=0;
    for(usz i=0;i<q;i++){
        long op=input[1+4*i],key=input[2+4*i],lb=input[3+4*i],rb=8+input[4+4*i];
        long found=-1,fb=-1;
        for(usz side=0;side<2;side++){long b=side==0?lb:rb;long x=head[(usz)b];while(x>=0){if(keys[(usz)x]==key){found=x;fb=b;break;}x=next[(usz)x];}if(found>=0)break;}
        if(op==0){if(found>=0){statuses[i]=0;placements[i]=-1;continue;}if(live==32)return -3;
            bool use_left=lengths[(usz)lb]<=lengths[(usz)rb];long b=use_left?lb:rb;usz x=0;while(keys[x]>=0)x++;
            keys[x]=key;next[x]=head[(usz)b];head[(usz)b]=(long)x;lengths[(usz)b]++;live++;statuses[i]=1;placements[i]=use_left?0:1;
        }else if(op==1){statuses[i]=found>=0?1:0;placements[i]=-1;
        }else if(found<0){statuses[i]=0;placements[i]=-1;
        }else{long prev=-1,x=head[(usz)fb];while(x!=found){prev=x;x=next[(usz)x];}if(prev<0)head[(usz)fb]=next[(usz)x];else next[(usz)prev]=next[(usz)x];keys[(usz)x]=-1;next[(usz)x]=-1;lengths[(usz)fb]--;live--;statuses[i]=1;placements[i]=-1;}
    }
    for(usz i=0;i<q;i++){put(output,16*i,statuses[i]);put(output,16*i+8,placements[i]);}
    return (long)bytes;
}
