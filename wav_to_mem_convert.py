import sys
import numpy as np
from scipy.io import wavfile

"""
Converts a 16-bit signed .wav file into an 8-bit unsigned .mem file for Verilog.
Outputs the total number of samples in each created .mem file.

Inputs:
	wav_file: input .wav filename
		pcm_s16le Audio Codec, 256 KiB audio bitrate, mono channel, 16000 Hz sample rate
    mem_file: output .mem filename
		hex format, one sample per line

Dependencies:
	sys, numpy, scipy.io (wavfile)
"""

wav_file = sys.argv[1]
mem_file = sys.argv[2]

fs, data = wavfile.read(wav_file)
data8 = ((data.astype(np.int16) >> 8) + 128).astype(np.uint8)

with open(mem_file, "w") as f:
	for val in data8:
		f.write(f"{val:02x}\n")
    
print(f"{wav_file} -> {mem_file} | Total samples: {len(data8)}")