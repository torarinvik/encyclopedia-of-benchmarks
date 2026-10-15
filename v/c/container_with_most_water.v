module container_with_most_water

// Two-pointer maximum area between vertical lines.
@[export: 'container_with_most_water']
pub fn container_with_most_water(heights &i64, length usize) i64 {
    if length > 4096 { return -1 }
    for index in 0 .. length {
        value := unsafe { heights[index] }
        if value < 0 || value > 2147483647 { return -1 }
    }
    if length < 2 { return 0 }

    mut left := usize(0)
    mut right := length - 1
    mut best := i64(0)
    for left < right {
        left_height := unsafe { heights[left] }
        right_height := unsafe { heights[right] }
        height := if left_height < right_height { left_height } else { right_height }
        area := height * i64(right - left)
        if area > best { best = area }
        if left_height <= right_height { left++ } else { right-- }
    }
    return best
}
