const MAX_VALUES:usize=512;
fn put_i64(output:*mut u8,offset:usize,value:i64){for(i,b)in value.to_le_bytes().iter().enumerate(){unsafe{*output.add(offset+i)=*b;}}}
fn winner(values:&[i64;MAX_VALUES],tree:&[i32;2*MAX_VALUES+1],left:usize,right:usize)->i32{let l=tree[left];let r=tree[right];if l<0{return r;}if r<0{return l;}if values[l as usize]<=values[r as usize]{l}else{r}}
#[no_mangle]
pub unsafe extern "C" fn tournament_sort(input:*const i64,length:usize,output:*mut u8,capacity:usize)->i64{
 if input.is_null()||length<1{return -1;}let raw=unsafe{std::slice::from_raw_parts(input,length)};if raw[0]<0||raw[0]>MAX_VALUES as i64{return -1;}let n=raw[0] as usize;if length!=1+n{return -1;}let mut values=[0i64;MAX_VALUES];for i in 0..n{if raw[i+1]<i32::MIN as i64||raw[i+1]>i32::MAX as i64{return -1;}values[i]=raw[i+1];}
 let mut leaves=1usize;while leaves<n{leaves*=2;}let mut tree=[-1i32;2*MAX_VALUES+1];for i in 0..n{tree[leaves+i]=i as i32;}for node in (1..leaves).rev(){tree[node]=winner(&values,&tree,node*2,node*2+1);}
 let bytes=(1+n)*8;if output.is_null()||capacity<bytes{return -2;}unsafe{put_i64(output,0,n as i64);}for out in 0..n{let w=tree[1] as usize;unsafe{put_i64(output,(1+out)*8,values[w]);}let mut node=leaves+w;tree[node]=-1;while node>1{node/=2;tree[node]=winner(&values,&tree,node*2,node*2+1);}}bytes as i64
}
