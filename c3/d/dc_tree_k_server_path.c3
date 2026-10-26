module dc_tree_k_server_path;
fn void put_i64(uint8*out,long value){ulong bits=(ulong)value;for(usz b=0;b<8;b++)out[b]=(uint8)(bits>>(8*b));}
fn long dc_tree_k_server_path(long*input,usz length,uint8*output,usz capacity) @export("dc_tree_k_server_path"){
    if(input==null||length<5||length>18)return -1;long k0=input[0],q0=input[1];if(k0<2||k0>4||q0<1||q0>12)return -1;usz k=(usz)k0,q=(usz)q0;if(length!=2+k+q)return -1;
    long[4] pos;for(usz i=0;i<k;i++){pos[i]=input[2+i];if(pos[i]<0||pos[i]>15)return -1;}for(usz i=0;i<q;i++)if(input[2+k+i]<0||input[2+k+i]>15)return -1;
    long[60] staged=zeroed;usz at=0;
    for(usz r=0;r<q;r++){long target=input[2+k+r],nearest=9223372036854775807l;bool[4] active=zeroed;usz active_count=0;
        for(usz i=0;i<k;i++){bool first=true;for(usz j=0;j<i;j++)if(pos[j]==pos[i]){first=false;break;}if(first){active[i]=true;active_count++;long delta=pos[i]>target?pos[i]-target:target-pos[i];if(delta<nearest)nearest=delta;}}
        staged[at]=nearest*(long)active_count;at++;for(usz i=0;i<k;i++)if(active[i]){if(pos[i]<target)pos[i]+=nearest;else if(pos[i]>target)pos[i]-=nearest;}for(usz i=0;i<k;i++){staged[at]=pos[i];at++;}
    }
    usz bytes=8*q*(k+1);if(output==null||capacity<bytes)return -2;for(usz i=0;i<at;i++)put_i64(output+8*i,staged[i]);return (long)bytes;
}
