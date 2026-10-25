fn put(out:[*]u8,w:usize,x:i64)void{const u:u64=@bitCast(x);for(0..8)|b|out[w*8+b]=@truncate(u>>@intCast(8*b));}
export fn versabench_dbms_contract_root(raw:?[*]const i64,n:usize,raw_out:?[*]u8,cap:usize)i64{
 if(raw==null or n<3 or n>12)return -1;const v=raw.?[0..n];if(v[0]<1 or v[0]>5 or n!=1+2*@as(usize,@intCast(v[0])))return -1;const count:usize=@intCast(v[0]);var levels:[5]i64=@splat(0);var entries:[5]i64=@splat(0);
 for(0..count)|i|{levels[i]=v[1+2*i];entries[i]=v[2+2*i];if(levels[i]<0 or levels[i]>4 or entries[i]<0 or entries[i]>4)return -1;if(i+1<count and (levels[i]==0 or entries[i]!=1 or levels[i+1]!=levels[i]-1))return -1;}
 if(levels[count-1]>0 and entries[count-1]==1)return -1;if(levels[count-1]>0 and entries[count-1]==0 and count!=1)return -1;var root:usize=0;var promotions:usize=0;while(levels[root]>0 and entries[root]==1){root+=1;promotions+=1;}var fl=levels[root];var fc=entries[root];if(fl>0 and fc==0){fl=0;fc=0;}if(raw_out==null or cap<24)return -2;const out=raw_out.?;put(out,0,@intCast(promotions));put(out,1,fl);put(out,2,fc);return 24;
}
