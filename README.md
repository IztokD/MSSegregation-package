# MSSegregation-package
This software package is intended to perform segregation analysis in digital images. Although primarily developed for microscopy of mixed species biofilm, it can be applied whenever the quantification of segregation level or mixing efficiency of two components is required and digital images of such a binary system can be obtained. The package is composed of three scripts written in ImageJ macro code:

1. Convert_to_bin_ver1.2.ijm  ---> splitting the depicted two-components mixtures in digital image (or stack) into two binary digital images, where each image represents one component 

2. Sim_seg_extremes_ver1.2.ijm ---> Based on output of Convert_to_bin_ver1.2.ijm, the images of most segregated case and least segregated (well mixed) case are simulated. These images represent segregation extremes.

3. MSS_calc_ver1.2.ijm ---> Multiscale spatial segregation calculations of the depicted two-components mixtures in digital image (or stack) are produced by taking into account images representing segregation extremes and two binary digital images, where each image represents one component (outputs of Sim_seg_extremes_ver1.2.ijm and Convert_to_bin_ver1.2.ijm).

Example1: This folder contains original input image: t3.tif (oats and raisins) and all the output images of the three macros. In addition, also log files and calculation files of segregation analysis are given.

Example2: This folder contains log files and calculation files of segregation analysis. The original stack of images (mixed species biofilm) and output images are deposited in FigShare:
https://figshare.com/s/5a4500aefaf368e97fe5

The macros can be run in Fiji-ImageJ. For details, please, see the package_example_manual.pdf
