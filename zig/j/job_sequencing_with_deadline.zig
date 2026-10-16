export fn job_sequencing_with_deadline(v:[*]const i64,n:usize)i64{
 if(n<1 or n>65)return -1;
 const count=v[0];if(count<1 or count>32 or n!=1+2*@as(usize,@intCast(count)))return -1;
 var d:[32]i64=@splat(0);var p:[32]i64=@splat(0);var order:[32]usize=@splat(0);
 for(0..@as(usize,@intCast(count)))|i|{d[i]=v[1+2*i];p[i]=v[2+2*i];if(d[i]<0 or d[i]>32 or p[i]<0 or p[i]>1000000)return -1;order[i]=i;}
 for(1..@as(usize,@intCast(count)))|i|{const key=order[i];var j=i;while(j>0 and p[order[j-1]]<p[key]){order[j]=order[j-1];j-=1;}order[j]=key;}
 var slots:[33]bool=@splat(false);var chosen:i64=0;var profit:i64=0;
 for(0..@as(usize,@intCast(count)))|k|{var slot:i64=d[order[k]];while(slot>0){const ix:usize=@intCast(slot);if(!slots[ix]){slots[ix]=true;chosen+=1;profit+=p[order[k]];break;}slot-=1;}}
 return chosen*32000001+profit;
}
