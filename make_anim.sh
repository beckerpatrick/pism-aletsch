#/bin/bash

resolution=1280x720

ffmpeg -y \
  -framerate 3   \
  -i thk_%04d.png  \
  -s:v $resolution \
  -c:v libx264  \
  -crf 20 \
  -pix_fmt yuv420p \
  -r 3 \
  thk.mp4   

ffmpeg -y \
  -framerate 3   \
  -i csurf_%04d.png  \
  -s:v $resolution \
  -c:v libx264  \
  -crf 20 \
  -pix_fmt yuv420p \
  -r 3 \
  csurf.mp4   

im-plot.py -v csurf -o low_2.pdf  --bounds 0 300 a100m_low_2_high_*
im-plot.py -v csurf -o low_5.pdf  --bounds 0 300 a100m_low_5_high_*
im-plot.py -v csurf -o low_10.pdf  --bounds 0 300 a100m_low_10_high_*