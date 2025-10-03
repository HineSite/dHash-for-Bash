# Overview
This is just a handful of tests designed to show the differences in different types of image distortions. I also wrote it to act as something of a unit test for the various functions within the dHash script.

# Alyson Hannigan
The images used in this test are of an actress named Alyson Hannigan. Don’t judge me, I’m simply using the same test image Dr. Neal Krawetz used in his blog post: [Kind of Like That](https://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html)

# Results
The lower the ham value, the more similar it is to the original test image. A ham value of less than or equal to 10 is considered a match or very similar.

As you can see from the results, scaling, stretching, compressing the image had little to no effect on changing the value. I also love how the mustache picture is considered an exact match, despite the obvious handle bars…

You can also see how rotating the image drastically effects the results. It’s enough that if your application may have rotated image, you should either use a different algorithm or modify the dHash algorithm to also check rotations.

I was surprised to see how far off the autographed photo was. I suspect it is less to do with the autograph and more to do with the extra image at the bottom and top. You can see from the cropped images, it doesn’t handle cropping all that well either, but it’s not too bad.


```
test-image
ham: 0

compressed-20
ham: 0

compressed-50
ham: 0

scale-200
ham: 0

scale-80
ham: 1

scale-1000
ham: 0

stretch-700-horiz
ham: 0

stretch-700-vert
ham: 0

stretch-900-horiz
ham: 0

stretch-900-vert
ham: 0

mustache
ham: 0

wash-out
ham: 1

meme
ham: 3

autographed
ham: 15

full
ham: 21

sweater
ham: 31

wallpaper
ham: 38

crop-25
ham: 7

crop-100
ham: 41

rot-90
ham: 41

rot-180
ham: 35

rot-240
ham: 25
```
