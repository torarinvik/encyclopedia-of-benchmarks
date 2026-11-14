struct SweepTree {
mut:
    key [65]i64
    height [65]int
    left [65]int
    right [65]int
}

fn cps_height(tree &SweepTree, node int) int {
    if node==0 { return 0 }
    return tree.height[node]
}
fn cps_refresh(mut tree SweepTree, node int) {
    lh:=cps_height(tree,tree.left[node])
    rh:=cps_height(tree,tree.right[node])
    tree.height[node]=1+(if lh>rh { lh } else { rh })
}
fn cps_rotate_right(mut tree SweepTree, root int) int {
    pivot:=tree.left[root]
    tree.left[root]=tree.right[pivot]; tree.right[pivot]=root
    cps_refresh(mut tree,root); cps_refresh(mut tree,pivot)
    return pivot
}
fn cps_rotate_left(mut tree SweepTree, root int) int {
    pivot:=tree.right[root]
    tree.right[root]=tree.left[pivot]; tree.left[pivot]=root
    cps_refresh(mut tree,root); cps_refresh(mut tree,pivot)
    return pivot
}
fn cps_balance(mut tree SweepTree, root int) int {
    cps_refresh(mut tree,root)
    difference:=cps_height(tree,tree.left[root])-cps_height(tree,tree.right[root])
    if difference>1 {
        child:=tree.left[root]
        if cps_height(tree,tree.left[child])<cps_height(tree,tree.right[child]) { tree.left[root]=cps_rotate_left(mut tree,child) }
        return cps_rotate_right(mut tree,root)
    }
    if difference< -1 {
        child:=tree.right[root]
        if cps_height(tree,tree.right[child])<cps_height(tree,tree.left[child]) { tree.right[root]=cps_rotate_right(mut tree,child) }
        return cps_rotate_left(mut tree,root)
    }
    return root
}
fn cps_insert(mut tree SweepTree, root int, index int) int {
    if root==0 { return index }
    if tree.key[index]<tree.key[root] { tree.left[root]=cps_insert(mut tree,tree.left[root],index) }
    else { tree.right[root]=cps_insert(mut tree,tree.right[root],index) }
    return cps_balance(mut tree,root)
}
fn cps_erase(mut tree SweepTree, root int, key i64) int {
    if root==0 { return 0 }
    if key<tree.key[root] { tree.left[root]=cps_erase(mut tree,tree.left[root],key) }
    else if key>tree.key[root] { tree.right[root]=cps_erase(mut tree,tree.right[root],key) }
    else if tree.left[root]==0 { return tree.right[root] }
    else if tree.right[root]==0 { return tree.left[root] }
    else {
        mut successor:=tree.right[root]
        for tree.left[successor]!=0 { successor=tree.left[successor] }
        replacement:=tree.key[successor]
        tree.key[root]=replacement
        tree.right[root]=cps_erase(mut tree,tree.right[root],replacement)
    }
    return cps_balance(mut tree,root)
}
fn cps_range_best(tree &SweepTree, root int, low i64, high i64, x i64, y i64, initial i64) i64 {
    if root==0 { return initial }
    key:=tree.key[root]
    mut best:=initial
    if key>=low { best=cps_range_best(tree,tree.left[root],low,high,x,y,best) }
    if key>=low && key<=high {
        dx:=x-(key%2001-1000)
        dy:=y-(key/2001-1000)
        distance:=dx*dx+dy*dy
        if distance<best { best=distance }
    }
    if key<=high { best=cps_range_best(tree,tree.right[root],low,high,x,y,best) }
    return best
}

@[export: 'closest_pair_sweep']
pub fn closest_pair_sweep(input &i64, length usize) i64 {
    if length<5 || length>130 { return -1 }
    unsafe {
        if input==nil || input[0]<2 || input[0]>64 { return -1 }
        n:=int(input[0])
        if length!=usize(1+2*n) { return -1 }
        mut points:=[64]i64{}
        mut scratch:=[64]i64{}
        for i in 0 .. n {
            x,y:=input[1+2*i],input[2+2*i]
            if x< -1000 || x>1000 || y< -1000 || y>1000 { return -1 }
            points[i]=(x+1000)*2001+y+1000
        }
        mut width:=1
        for width<n {
            mut begin:=0
            for begin<n {
                middle:=if begin+width<n { begin+width } else { n }
                end:=if begin+2*width<n { begin+2*width } else { n }
                mut i:=begin
                mut j:=middle
                for k in begin .. end {
                    if j==end || (i<middle && points[i]<=points[j]) { scratch[k]=points[i]; i++ }
                    else { scratch[k]=points[j]; j++ }
                }
                begin+=2*width
            }
            for i in 0 .. n { points[i]=scratch[i] }
            width*=2
        }
        for i in 1 .. n { if points[i]==points[i-1] { return 0 } }
        mut tree:=SweepTree{}
        mut root:=0
        mut oldest:=0
        mut best:=i64(8000001)
        for i in 0 .. n {
            x:=points[i]/2001-1000
            y:=points[i]%2001-1000
            for oldest<i {
                old_x:=points[oldest]/2001-1000
                dx:=x-old_x
                if dx*dx<=best { break }
                old_y:=points[oldest]%2001-1000
                root=cps_erase(mut tree,root,(old_y+1000)*2001+old_x+1000)
                oldest++
            }
            mut lo:=i64(0)
            mut hi:=i64(3000)
            for lo<hi {
                middle:=(lo+hi+1)/2
                if middle*middle<=best { lo=middle } else { hi=middle-1 }
            }
            best=cps_range_best(&tree,root,(y-lo+1000)*2001,(y+lo+1000)*2001+2000,x,y,best)
            index:=i+1
            tree.key[index]=(y+1000)*2001+x+1000
            tree.height[index]=1
            root=cps_insert(mut tree,root,index)
        }
        return best
    }
}
