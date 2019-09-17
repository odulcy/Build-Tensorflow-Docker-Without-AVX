# Compile Tensorflow without AVX on old CPU with Docker

If you are running on a old CPU which doesn't have AVX flag, you have to build Tensorflow from source.

I created a Dockerfile to compile Tensorflow (you can select the version through a variable at the beginning of the file).
It should take approximately 3 hours on a computer with a Intel(R) Xeon(R) CPU E5540 @ 2.53GHz and 12GB of RAM.
