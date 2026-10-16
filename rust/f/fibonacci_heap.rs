const MAX_KEYS: usize = 128;
const NONE: usize = usize::MAX;

#[derive(Clone, Copy)]
struct Node { key: i64, parent: usize, child: usize, left: usize, right: usize, degree: usize }
const EMPTY: Node = Node { key: 0, parent: NONE, child: NONE, left: NONE, right: NONE, degree: 0 };

fn remove_ring(nodes: &mut [Node; MAX_KEYS], x: usize) {
    nodes[nodes[x].left].right=nodes[x].right;
    nodes[nodes[x].right].left=nodes[x].left;
}
fn add_root(nodes: &mut [Node; MAX_KEYS], minimum: &mut usize, x: usize) {
    nodes[x].parent=NONE;
    if *minimum==NONE { nodes[x].left=x;nodes[x].right=x;*minimum=x; }
    else { let m=*minimum;let r=nodes[m].right;nodes[x].left=m;nodes[x].right=r;nodes[m].right=x;nodes[r].left=x;if nodes[x].key<nodes[m].key{*minimum=x;} }
}
fn link_child(nodes: &mut [Node; MAX_KEYS], parent: usize, child: usize) {
    remove_ring(nodes,child);nodes[child].parent=parent;
    if nodes[parent].child==NONE { nodes[child].left=child;nodes[child].right=child;nodes[parent].child=child; }
    else { let c=nodes[parent].child;let r=nodes[c].right;nodes[child].left=c;nodes[child].right=r;nodes[c].right=child;nodes[r].left=child; }
    nodes[parent].degree+=1;
}
fn consolidate(nodes: &mut [Node; MAX_KEYS], minimum: &mut usize) {
    if *minimum==NONE{return;}
    let mut roots=[NONE;MAX_KEYS];let mut count=0;let mut x=*minimum;
    loop { roots[count]=x;count+=1;x=nodes[x].right;if x==*minimum{break;} }
    let mut degree=[NONE;MAX_KEYS+1];
    for &root in &roots[..count] { x=root;if nodes[x].parent!=NONE{continue;}let mut d=nodes[x].degree;
        while degree[d]!=NONE { let mut y=degree[d];if nodes[y].key<nodes[x].key{std::mem::swap(&mut x,&mut y);}degree[d]=NONE;link_child(nodes,x,y);d=nodes[x].degree; }
        degree[d]=x;
    }
    *minimum=NONE;
    for &root in &degree { if root!=NONE { add_root(nodes,minimum,root); } }
}

#[no_mangle]
pub extern "C" fn fibonacci_heap(input: *const i64, length: usize, output: *mut u8, output_capacity: usize) -> i64 {
    if (input.is_null()&&length>0)||length>MAX_KEYS{return -1;}
    for i in 0..length { let key=unsafe{*input.add(i)};if key<i32::MIN as i64||key>i32::MAX as i64{return -1;} }
    let bytes=length*8;
    if output_capacity<bytes||(length>0&&output.is_null()){return -2;}
    let mut nodes=[EMPTY;MAX_KEYS];let mut minimum=NONE;
    for i in 0..length { let key=unsafe{*input.add(i)};nodes[i].key=key;nodes[i].parent=NONE;nodes[i].child=NONE;nodes[i].degree=0;nodes[i].left=i;nodes[i].right=i;add_root(&mut nodes,&mut minimum,i); }
    for out in 0..length { let z=minimum;let bits=nodes[z].key as u64;
        for b in 0..8 { unsafe{*output.add(out*8+b)=(bits>>(8*b)) as u8;} }
        if nodes[z].child!=NONE { let mut children=[NONE;MAX_KEYS];let mut count=0;let mut c=nodes[z].child;loop{children[count]=c;count+=1;c=nodes[c].right;if c==nodes[z].child{break;}}for &child in &children[..count]{add_root(&mut nodes,&mut minimum,child);} }
        remove_ring(&mut nodes,z);
        if nodes[z].right==z { minimum=NONE; } else { minimum=nodes[z].right;consolidate(&mut nodes,&mut minimum); }
    }
    bytes as i64
}
