# youtube random sampler 
Assuming you have the requisite programs in your path [nix,youtube-dl,ffmpeg,curl,md5sum,shuf] this script will search youtube for a pair of random English words and download a random segment of the top matching youtube video (if one is found). The program generates a nix expression that performs the download so you can delete the video file and still have a record of how to get the same video segment from youtube again byte for byte.

## usage
```shell
./youtube_random_sample_nix_gen.sh 10
```
