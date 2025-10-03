# Overview
This is a perceptual hash, known as Difference Hash, implemented in Bash. It utilizes ImageMagick to scale the images and apply the grayscale. This was written using ImageMagick 6.9.11 but should still work with ImageMagick 7.0 and above.

The purpose of perceptual hashes is to create a kind of “loose fingerprint” of an image (or other type of media) that can be used to identify it’s content. I say “loose fingerprint” because it is not meant to exactly identify an image, but rather to find images that are nearly identical. For example, they can still identify an image even if it has been cropped, compressed, rotated, skewed, or has various other filters applied.

There are many different perceptual hashes each with their own capabilities and limits. dHash is meant to be quick and fairly accurate, but it doesn’t handle heavily cropped or rotated images.

There are many variations on this algorithm, but the first step for calculating the hash is to reduce the image size and make the image grayscale. This process removes most of the small details that make images different in the first place, allowing for a comparison on the general shape of the content.

Once the image is scaled and in grayscale, all that’s left to do is compare the difference in brightness between adjacent pixels. The comparison is a simple binary comparison where if one pixel is brighter than the other, a 1 or 0 is recorded. The resulting bit output is the hash and can be later compared to other hashes by simply using the hamming distance.

# dHash for Bash
This implementation is based on the blog post, [Kind of Like That](https://www.hackerfactor.com/blog/index.php?/archives/529-Kind-of-Like-That.html) by Dr. Neal Krawetz.

In this implementation, ImageMagick is used to scale the image to a 9x8 and convert it to grayscale. The hash is then computed by reading the pixels from left to right and top to bottom where each row is computed independently of 
the next. Each bit is then set based on whether the pixel on the left is lighter than the pixel on the right. If it is, the bit is set to a 1, otherwise a 0.

# Problems
Neither bash nor ImageMagick made this an easy task. You can see my notes in the code for more details. The biggest limitation in bash is its lack of unsigned 64 bit integers (or any data type really…). This meant I couldn’t store the bits in a simple integer and use the appropriate bit-wise operations to manipulate them without rollover. This meant I had to store the bits in a string and convert them between bases in chunks. I chose to use chunks of 16 bits so this should work in a 32 bit environment.

The biggest hangup with ImageMagick is the inconsistency with data returned. The “fix” for this was pretty simple, but I suspect there are some other possible outputs that I am not accounting for.

It also took a lot of trial and error to formulate the exact command I needed to perform the scaling and color space changes needed for the first step. Some commands were slower but produced more accurate results and others were faster but created very inaccurate results. The command I settled on was the quickest command I could make while still produces accurate enough results.

# Performance
I have done very little performance testing on this outside of creating the ImageMagick commands. But from the few tests I did run, it took about 3 minutes and 28 seconds to calculate and compare the dHash of 2,180 images. When I removed the calculations, and only performed the ImageMagick functions, it took about 3 minutes and 16 seconds.

Meaning only 6% of the time is spent calculating and comparing the dHash. So, while I am confident there are performance improvements to be had in my implementation, it’s not worth my time or effort.

I also took the same 2,180 images and scaled and converted them to grayscale ahead of time so I could run the calculations without the scaling. It only took about 28 seconds. When I removed the dHash calculations and only loaded the images, it took about 19 seconds.

Meaning 68% of the time was used to load the images, and the remaining 32% was used to make the calculations. That puts it at about 77 images per second or 1 million images in 3.6 hours. If I could shave 20% off the calculation time, that would 105 images per second or 1 million images in 2.6 hours. But, I don’t have millions of images to compare, so I am still not worried about.

These tests were ran on an AMD Ryzen 7 3700x for those interested.

# Error Handling
Yeah, there is none. Sorry not sorry. Use at your own risk.

# Usage
Calculating the hash is a multi step process. First you load the pixel data by either using the `convertImage` function or the `getPixelData` function:
```
pixels=$(fun_convertImage "${PATH_TO_FILE}")
```

Use `convertImage` for images that need to be scaled and grayscaled. Use `getPixelData` if the image is already scaled and in grayscale.


Next you use the `getDhashBits` function to calculate the dHash.
```
bits=$(fun_getDhashBits "${pixels[*]}")
```


Once you have the dHash for 2 files, you can compare the two using the `calculateHammingDistance` function.
```
ham=$(fun_calculateHammingDistance "${bits}" "${other_bits}")
```


Optionally: `getDhashBits` returns a string of bits which is not convenient to look at or store, so you can use the `convertBitsToBase16` function to get a nicer looking base16 hash.

```
hash=$(fun_convertBitsToBase16 "${bits}")
```


If you wish to compare an image against a list of preexisting dHashes, you will need the dHash bits. If you chose to save them in base16, they will need to be converted back into bits using the `convertBase16ToBits` function.
```
bits=$(fun_convertBase16ToBits "${hash}")
```
