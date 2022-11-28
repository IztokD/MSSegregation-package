# MSSegregation-package
This software package is intended to perform segregation analysis of particles depicted in digital images. All the particles belong to one of the two types i.e. the images depict binary mixtures, whre particles can be more or less segragated. Although primarily developed for microscopy of mixed species biofilm, it can be applied whenever the quantification of segregation level or mixing efficiency of two components is required and digital images of such a binary system can be obtained. The package is composed of three scripts written in ImageJ macro code given in folder MSS_segration_package_software:

1. Convert_to_bin_ver1.3.ijm  ---> Splitting the depicted two-components mixtures in digital image (or stack) into two binary digital images, where each image represents one component 

2. Sim_seg_extremes_ver1.32.ijm ---> Based on output of Convert_to_bin_ver1.3.ijm, the images of most segregated case and least segregated (well mixed) case are simulated. These images represent segregation extremes.

3. MSS_calc_ver1.31.ijm ---> Multiscale spatial segregation calculations of the depicted two-components mixtures in digital image (or stack) are produced by taking into account images representing segregation extremes and two binary digital images, where each image represents one component (outputs of Sim_seg_extremes_ver1.3.ijm and Convert_to_bin_ver1.3.ijm).


Example 1: This folder contains original input image: t3.tif (oats and raisins) and all the output images of the macros 1, 2 and 3. In addition, also log files and calculation files of segregation analysis are given.

Example 2: This folder contains log files and calculation files of segregation analysis for mixed species biofilm. The original stack of images (mixed species biofilm) and output images are deposited in FigShare:
https://figshare.com/s/5a4500aefaf368e97fe5


Original images: This folder contains original (source) images that were used to perform all the analysis in article.

The videos showing the re-make of the examples are avaialable on FigShare https://figshare.com/s/5a08f7b84a76586e1601

The macros can be run in Fiji-ImageJ. For details, please, see the package_example_manual.pdf

Cite: Iztok Dogsa, Ines Mandic-Mulec, Multiscale spatial segregation analysis in digital images of mixed-species biofilms, xx year, XX journal, xx vol, xx pages




