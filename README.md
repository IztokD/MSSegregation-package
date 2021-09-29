# MSSegregation-package
This software package is intended to perform segregation analysis in digital images. Although primary developed for microscopy of mixed species biofilm, it can be applied whenever the quantification of segregation level or mixing efficiency of two components is required and digital images of such a binary system can be obtained. The package is composed of three scripts written in ImageJ macro code:

Convert_to_bin_ver1.2.ijm  ---> splitting the depicted two-componets mixtures in digital image (or stack) into two binary digital images, where each image represents one component 

Sim_seg_extremes_ver1.2.ijm ---> Based on output of Convert_to_bin_ver1.2.ijm, the images of most segregation case and least segregated (well mixed) case are produced.

MSS_calc_ver1.2.ijm ---> Multiscale spatial segregation calculations of the depicted two-components mixtures in digital image (or stack) are produced, by taking into account images represnting segregation extremes and  two binary digital images, where each image represents one component (outputs of Convert_to_bin_ver1.2.ijm and im_seg_extremes_ver1.2.ijm)

Example1: This folder contains original inoput image: t3.tif and all the output images of the three macros. In addition also log files and calculation files are given of segregation analysis.

Example2: This folder contains log files and calculation files of segregation analysis. The original stack of images (mixed species biofilm) and output images are deposited in FigShare:
https://figshare.com/s/5a4500aefaf368e97fe5

The macros can be run in Fiji-ImageJ. For details, please, see the package_example_manual.pdf
