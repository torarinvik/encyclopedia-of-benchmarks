export fn number_container_system(v:[*]const i64,n:usize,out:[*]u8,cap:usize)i64{
 if(n<1 or v[0]<0 or v[0]>32 or n!=1+3*@as(usize,@intCast(v[0])))return -1;
 var slots=[_]i64{0}**64;var present=[_]bool{false}**64;var b:[128]u8=undefined;var used:usize=0;
 for(0..@intCast(v[0]))|i|{const op=v[1+3*i];const a=v[2+3*i];const value=v[3+3*i];if(op==0){if(a<0 or a>63 or value< -100 or value>100)return -1;slots[@intCast(a)]=value;present[@intCast(a)]=true;}else if(op==1){if(a< -100 or a>100 or value!=0)return -1;var found:i64=-1;for(0..64)|j|{if(present[j] and slots[j]==a){found=@intCast(j);break;}}if(used>0){b[used]=',';used+=1;}if(found<0){b[used]='-';used+=1;found=-found;}var d:[3]u8=undefined;var k:usize=0;while(true){d[k]=@intCast('0'+@as(u8,@intCast(@rem(found,10))));k+=1;found=@divTrunc(found,10);if(found==0)break;}while(k>0){k-=1;b[used]=d[k];used+=1;}}else return -1;}
 if(used>cap)return -2;@memcpy(out[0..used],b[0..used]);return @intCast(used);
}
