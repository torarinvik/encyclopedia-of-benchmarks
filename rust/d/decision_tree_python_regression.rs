const MAX_SAMPLES: usize = 12;
const MAX_QUERIES: usize = 12;
const MAX_INPUT: usize = 41;
const MAX_OUTPUT: usize = 13;
const MAX_TREE_NODES: usize = 23;

#[derive(Clone, Copy)]
struct TreeNode { prediction: f64, boundary: f64, left: i32, right: i32, leaf: bool }

fn sum_range(values: &[f64; MAX_SAMPLES], start: usize, end: usize) -> f64 {
    let mut sum=0.0;
    for i in start..end { sum+=values[i]; }
    sum
}
fn mean_range(values: &[f64; MAX_SAMPLES], start: usize, end: usize) -> f64 {
    sum_range(values,start,end)/(end-start) as f64
}
fn mse_against(values: &[f64; MAX_SAMPLES], start: usize, end: usize, prediction: f64) -> f64 {
    let mut sum=0.0;
    for i in start..end { let delta=values[i]-prediction;sum+=delta*delta; }
    sum/(end-start) as f64
}
fn build_tree(nodes: &mut [TreeNode; MAX_TREE_NODES], used: &mut usize,
              x: &[f64; MAX_SAMPLES], y: &[f64; MAX_SAMPLES], start: usize, end: usize,
              min_leaf: usize, depth: i32) -> i32 {
    if *used>=MAX_TREE_NODES{return -1;}
    let current=*used;*used+=1;let length=end-start;
    nodes[current]=TreeNode{prediction:mean_range(y,start,end),boundary:0.0,left:-1,right:-1,leaf:true};
    if length<2*min_leaf||depth==1{return current as i32;}
    let mut min_error=2.0*mse_against(x,start,end,nodes[current].prediction);
    let mut best_split=0usize;
    for split in 0..length {
        let right_count=length-split;
        if split<min_leaf||right_count<min_leaf{continue;}
        let left_mean=mean_range(y,start,start+split);
        let right_mean=mean_range(y,start+split,end);
        let error=mse_against(x,start,start+split,left_mean)+mse_against(x,start+split,end,right_mean);
        if error<min_error{best_split=split;min_error=error;}
    }
    if best_split==0{return current as i32;}
    nodes[current].leaf=false;nodes[current].boundary=x[start+best_split];
    let left=build_tree(nodes,used,x,y,start,start+best_split,min_leaf,depth-1);
    if left<0{return -1;}
    let right=build_tree(nodes,used,x,y,start+best_split,end,min_leaf,depth-1);
    if right<0{return -1;}
    nodes[current].left=left;nodes[current].right=right;current as i32
}
fn predict(nodes: &[TreeNode; MAX_TREE_NODES], mut node: usize, query: f64) -> f64 {
    while !nodes[node].leaf {
        node=if query>=nodes[node].boundary {nodes[node].right as usize} else {nodes[node].left as usize};
    }
    nodes[node].prediction
}
fn integer_in_range(value: f64, minimum: i32, maximum: i32) -> bool {
    value.is_finite()&&value>=minimum as f64&&value<=maximum as f64&&value.fract()==0.0
}

#[no_mangle]
pub unsafe extern "C" fn decision_tree_python_regression(
    input: *const f64, input_length: usize, output: *mut f64, output_capacity: usize,
) -> i64 {
    if input.is_null()||input_length<8||input_length>MAX_INPUT{return -1;}
    let values=unsafe{std::slice::from_raw_parts(input,input_length)};
    if values.iter().any(|x|!x.is_finite()){return -1;}
    if !integer_in_range(values[0],1,6)||!integer_in_range(values[1],1,6)||!integer_in_range(values[2],2,12){return -1;}
    let depth=values[0] as i32;let min_leaf=values[1] as usize;let samples=values[2] as usize;
    let query_index=3+2*samples;
    if input_length<=query_index||!integer_in_range(values[query_index],1,12){return -1;}
    let query_count=values[query_index] as usize;
    if input_length!=query_index+1+query_count||input_length>40{return -1;}
    let mut x=[0.0;MAX_SAMPLES];let mut y=[0.0;MAX_SAMPLES];let mut queries=[0.0;MAX_QUERIES];
    for i in 0..samples {
        x[i]=values[3+i];y[i]=values[3+samples+i];
        if !integer_in_range(x[i],-8,8)||!integer_in_range(y[i],-8,8){return -1;}
    }
    for i in 0..query_count {
        queries[i]=values[query_index+1+i];if !integer_in_range(queries[i],-8,8){return -1;}
    }
    let mut nodes=[TreeNode{prediction:0.0,boundary:0.0,left:-1,right:-1,leaf:true};MAX_TREE_NODES];
    let mut used=0usize;let root=build_tree(&mut nodes,&mut used,&x,&y,0,samples,min_leaf,depth);
    if root<0{return -1;}
    let mut staged=[0.0;MAX_OUTPUT];staged[0]=query_count as f64;
    for i in 0..query_count{staged[i+1]=predict(&nodes,root as usize,queries[i]);}
    if output.is_null()||output_capacity<query_count+1{return -2;}
    for i in 0..query_count+1{unsafe{*output.add(i)=staged[i];}}
    (query_count+1) as i64
}
