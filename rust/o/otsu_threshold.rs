#[no_mangle]
pub unsafe extern "C" fn otsu_threshold(v:*const i64,n:usize,out:*mut u8,cap:usize)->i64{
 if v.is_null()||n<2{return -1}let count=*v as usize;if !(1..=32).contains(&count)||n!=count+1{return -1}let mut hist=[0u64;256];for j in 0..count{let p=*v.add(j+1);if !(0..=255).contains(&p){return -1}hist[p as usize]+=1;}
 let mut total=0.0;for i in 0..256{total+=i as f64*hist[i] as f64;}let(mut maxv,mut sum,mut wb,mut t)=(0.0,0.0,0usize,0usize);
 for i in 0..256{wb+=hist[i] as usize;if wb==0{continue}let wf=count-wb;if wf==0{break}sum+=i as f64*hist[i] as f64;let mb=sum/wb as f64;let mf=(total-sum)/wf as f64;let var=wb as f64*wf as f64*(mb-mf)*(mb-mf);if var>maxv{maxv=var;t=i;}}
 if cap<count||out.is_null(){return -2}for j in 0..count{*out.add(j)=if *v.add(j+1)>t as i64{255}else{0};}count as i64
}
