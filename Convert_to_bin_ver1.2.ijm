//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This ImageJ (Fiji) script was written by Iztok Dogsa, Biotechnical Faculty, University of Ljubljana, Slovenia//
// iztok.dogsa@bf.uni-lj.si																						//
//package: MSSegregation																						//
//convert_to_bin.ijm ver 1.2																					//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var ns1,ns2,no_slices; // number of slices per channel or no of slices in single two channle image file
var t_ch1, t_ch2; // to store the titles of the two iamges representing two types of particles ) or particle and background)
var dir_save; // directory to save
var n=0; // counter for how many files(images) have bben processed
var want_more=true; // to continue with next image to convert
var do_despeckle, do_convert_bin,do_convert_bin_white, do_exclude_small, do_exclude_small_holes, do_fill; // for storing what to do
var ch1_height,ch1_width,ch2_height,ch2_width; // dimensions of images for each ch
var TF_SI,SF_SI,SF_TI; // type of files containing source images
var SF_SI_g;

macro "Convert_to_bin_ver1.2" {


function decision_what_to_do()
{
	var err=true;
	while (err==true)
	{
	  	 	err=false;
	  	 	
	  Dialog.create("Procedure choices");
	
	  Dialog.addMessage("What do you want to do? (Cancel will exit the program)");
	
	  Dialog.addCheckbox("1. Filter original images to despecle noise.", true);
	  Dialog.addCheckbox("2A. Convert sample images to two binary (particles =black & background= white) 8-bit images. ", true);
	  Dialog.addCheckbox("2B. Convert sample images to two binary (particles =white & background= black) 8-bit images. ", false);

	  Dialog.show();
	
	
	  do_despeckle = Dialog.getCheckbox();
	  do_convert_bin= Dialog.getCheckbox();
	  do_convert_bin_white=Dialog.getCheckbox();

		
	   if ((do_despeckle==false)&&(do_convert_bin==false)&&(do_convert_bin_white==false)
)
	    {
	    		// Dialog.create("Warning!");
	    	dec=getBoolean("You need to select at least option 1. or 2.! Do you want to exit the programe?(Yes and Cancel will exit the program) ", "Yes", "No");
			//	 Dialog.show();  
			if(dec==false) 		
	    		 	err=true;
	    	if(dec==true)
	    	{
	    	 	exit("User decided to exit the program!");		
	    	 	
	    	}
	    }



	   if ((do_convert_bin==true)&&(do_convert_bin_white==true))
	    {
	    		// Dialog.create("Warning!");
	    	dec=getBoolean("You need to select either option 2A. or 2B.! Do you want to exit the programe?(Yes and Cancel will exit the program) ", "Yes", "No");
			//	 Dialog.show();  
			if(dec==false) 		
	    		 	err=true;
	    	if(dec==true)
	    	{
	    	 	exit("User decided to exit the program!");		
	    	 	
	    	}
	    }
 
	}
}

function preparation()
{
	print("\\Clear");
	run("Set Measurements...", "area limit scientific redirect=None decimal=3");
	run("Clear Results");
	Close_All_Windows();
	decision_what_to_do();
	dir_save = getDirectory("Choose a Directory to save"); 	
}







function decision_of_type()
{
 var err=true;
	
 while (err==true){
	  	err=false;
	 	a=0;
	 	b=0;
		c=0;
		Dialog.create("Image type choices");
		Dialog.addMessage("What is the format of your image regarding particle presentation (select only one type)? ");
		
		Dialog.addCheckbox("1. I have a single file that contains a single image, where one type and the other type of particles (background) are depicted", true); //SF_SI
		Dialog.addCheckbox("2. I have a single file that contains two images, each for one type of particles or background (colour channel, RGB not supported). ", false);// SF_TI
		Dialog.addCheckbox("3. I have two files each contains one image for one type of particle or background (colour channel). ", false); // TF_SI
		Dialog.show();
	
		SF_SI=Dialog.getCheckbox(); if (SF_SI==true) a=1;
		SF_TI=Dialog.getCheckbox(); if (SF_TI==true) b=1;
		TF_SI=Dialog.getCheckbox(); if (TF_SI==true) c=1;
	
		
		if (((a+b+c)>1)||((a+b+c)==0))
		 {
				err=true;
				Dialog.create("Warning!");
				Dialog.addMessage("You have to select (only) ONE image type!");
				Dialog.show(); 
		} 
	
 }
 
}


function open_type()
{
	
	
	
	if (SF_SI==true)
	{
	
		open_stack();
		if (do_despeckle==true)
			run("Despeckle", "stack");
	
	}
	
	if (SF_TI==true)
	{
		open_stack();
		if (do_despeckle==true)
			run("Despeckle", "stack");
		run("Split Channels");
		selectImage(nImages-1);
  		t_ch1 = getTitle();
  		selectImage(nImages);
  		t_ch2= getTitle();
		
		no_slices=no_slices*0.5;
	}
	if (TF_SI==true)
	{
		get_image1();
		get_image2();
		check_images();
	}
}


function open_stack() {
	
	  
	open();	 
	no_slices=nSlices;
	print(dir_save);
	print("stack size: "+no_slices);
	print(bitDepth());
	if ((bitDepth()!= 24)&&(SF_SI==true))  //assuming 24-bit is RGB image ; SF_SI==true, means there is just one file and one image- from this image two 8-bit images need to extracted, each dispalying one type of particle
	{
		t_ch1 = getTitle();
		run("Duplicate...", "duplicate");
		t_ch2 = getTitle();
		
  	} 
	if ((bitDepth()== 24)&&(SF_TI==false)) //assuming 24-bit is RGB image
	{
		run("Split Channels");
		waitForUser("RGB image was split to three 8-bit images (green, red, blue). Close the image with the worst contrast, one type of the particle against the second type (background)!. Press OK to continue");
		while (nImages>2)
		{
			waitForUser("Please close the third image!");
		}			
     	selectImage(nImages-1);
  		t_ch1 = getTitle();
  		print (t_ch1);
  		selectImage(nImages);
  		t_ch2= getTitle();
  		print (t_ch2);
	}
	if ((bitDepth()== 24)&&(SF_TI==true))
	{
		waitForUser("Single file, containing two RGB images is not supported. Press OK to exit.");
		exit;
	}
	
 }

function Close_All_Windows() { 

      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
 } 






function get_image1()
{
	showMessage("locate sample image (stack) representing ch1 (particles)");    
	open_stack();
	//if (bitDepth() != 8) exit ("8 bit image required."); 
	t_ch1 = getTitle();
	ns1=nSlices;
	ch1_height=getHeight();
	ch1_width=getWidth();
	if (do_despeckle==true)
		run("Despeckle", "stack");	
}


function get_image2()
{
	showMessage("locate sample image (stack) representing ch2 (particles)");    
	open_stack();
	//if (bitDepth() != 8) exit ("8 bit image required."); 
	t_ch2 = getTitle();
	ns2=nSlices;
	ch2_height=getHeight();
	ch2_width=getWidth();
	if (do_despeckle==true)
		run("Despeckle", "stack");
		
}


function check_images()
{
	if ((ch1_height!=ch2_height)||(ch1_width!=ch2_width)){
		showMessage("dimensions of two images (stack) do not match! Program will now terminate!");
		exit;
	}

	if (ns1!=ns2){
		showMessage("no slices of the two stacks dont match! Program will now terminate!");
		exit;
	}

	
	
}

function menu_threshold() 
{ 
// function description
	Dialog.createNonBlocking("Thresholding OK?");

	Dialog.addMessage("Check/Adjust threshold and click OK ");
		
	Dialog.addCheckbox("Additionaly filter created binary images by excluding small noise particles. ", false);
	Dialog.addCheckbox("Fill particles in created binary images. ", false);
	Dialog.addCheckbox("Exclude holes in created binary images by size. ", false);
	Dialog.show();
	
	do_exclude_small= Dialog.getCheckbox();
	do_fill=Dialog.getCheckbox();
	do_exclude_small_holes=Dialog.getCheckbox();

}


function auto_contr()  // credits to Dr. Kota Miura, Scientist & IT Engineer Centre for Molecular and Cellular Imaging, European Molecular Biology Laboratory Meyerhofstr. 1 69117 Heidelberg GERMANY 
{
	 AUTO_THRESHOLD = 5000; 
	 getRawStatistics(pixcount); 
	 limit = pixcount/10; 
	 threshold = pixcount/AUTO_THRESHOLD; 
	 nBins = 256; 
	 getHistogram(values, histA, nBins); 
	 i = -1; 
	 found = false; 
	 do { 
	         counts = histA[++i]; 
	         if (counts > limit) counts = 0; 
	         found = counts > threshold; 
	 } while ((!found) && (i < histA.length-1)) 
	 hmin = values[i]; 
	
	 i = histA.length; 
	 do { 
	         counts = histA[--i]; 
	         if (counts > limit) counts = 0; 
	         found = counts > threshold; 
	 } while ((!found) && (i > 0)) 
	 hmax = values[i]; 
	
	 setMinAndMax(hmin, hmax); 
	 //print(hmin, hmax); 
	 run("Apply LUT", "stack"); // remove, if you do not want to permanently change the values of pixels!
}


function convert_image1()
{
	selectImage(t_ch1);
	middle=round(0.5*no_slices);
	setSlice(middle);
	method = "Li";
	bckg= " dark";
	input=method+bckg;
	
	auto_contr();
	run("Brightness/Contrast...");	
	waitForUser("Check/Adjust contrast and click OK");
	call("ij.plugin.frame.ThresholdAdjuster.setMethod",method);
	run("Threshold...");
	setSlice(middle);
	setAutoThreshold(input);
	
//	waitForUser("Check/Adjust treshold and click OK");	

	menu_threshold();
	getThreshold(lower,upper);
	print("threshold"+lower);
	print("threshold"+upper);
	if	((do_convert_bin)==true){
		setOption("black background", false);
		run("Convert to Mask", "method=Default background=Default");
		}
	if	((do_convert_bin_white)==true){
		setOption("black background", true);
		run("Convert to Mask", "method=Default background=Default black");
		}
	selectWindow("Threshold");
 	run("Close");	

	 if (do_exclude_small==true)
	 {
	 	waitForUser("With oval/rectengular tool encircle the biggest particle you still want to remove and click OK");
	 	run("Clear Results");
		setThreshold(1, 255);
	 	run("Measure");
	 	max_area=getResult("Area", 0);
	 	print(max_area);
	 	run("Select None"); 	
	 	run("Analyze Particles...", "size=["+max_area+"]-Infinity show=Masks in_situ");
	 }
	 if (do_exclude_small_holes==true)
	 {
	 	waitForUser("With oval/rectengular tool encircle the biggest hole you still want to remove and click OK");
	 	run("Clear Results");
		setThreshold(0, 0);
	 	run("Measure");
	 	max_area=getResult("Area", 0);
	 	print(max_area);

	 	run("Select None");
	 	run("Invert");
	 	setThreshold(1, 255);	
	 	run("Analyze Particles...", "size=["+max_area+"]-Infinity show=Masks in_situ");
	 	run("Invert");
		}




	 
	 if (do_fill==true)
		run("Fill Holes");


    waitForUser("Check if the result image is ok. If not, you can use Built-In ImageJ tools. Once satisfied, click on the binary image you want to save and click OK");

	
	stack_ch1_bin=getImageID();
	imageBIN_t=getTitle();
	saveAs("tiff", dir_save+imageBIN_t+ns1+"_ch1_bin");
	print("image ch1 was saved");
	close();
	
}

function convert_image2()
{
	
	selectImage(t_ch2);
	middle=round(0.5*no_slices);
	setSlice(middle);
	method = "Li";
	bckg= " dark";
	input=method+bckg;
	auto_contr();
	run("Brightness/Contrast...");	
	waitForUser("Check/Adjust contrast and click OK");
	call("ij.plugin.frame.ThresholdAdjuster.setMethod",method);
	run("Threshold...");
	setSlice(middle);
	setAutoThreshold(input);
	
	menu_threshold();
//	waitForUser("Adjust treshold and click OK");
	getThreshold(lower,upper);
	print("threshold"+lower);
	print("threshold"+upper);
	if	((do_convert_bin)==true){
		setOption("black background", false);
		run("Convert to Mask", "method=Default background=Default");
		}
	if	((do_convert_bin_white)==true){
		setOption("black background", true);
		run("Convert to Mask", "method=Default background=Default black");
		}
	selectWindow("Threshold");
 	run("Close");

	 if (do_exclude_small==true)
	 {
	 waitForUser("With oval/rectengular tool encircle the biggest particle you still want to remove and click OK");
	 	run("Clear Results");
		setThreshold(1, 255);
	 	run("Measure");
	 	max_area=getResult("Area", 0);
	 	print(max_area);
	 	run("Select None"); 	
	 	run("Analyze Particles...", "size=["+max_area+"]-Infinity show=Masks in_situ");
	 }

	if (do_exclude_small_holes==true)
	 {
	 	waitForUser("With oval/rectengular tool encircle the biggest hole you still want to remove and click OK");
	 	run("Clear Results");
		setThreshold(0, 0);
	 	run("Measure");
	 	max_area=getResult("Area", 0);
	 	print(max_area);

	 	run("Select None");
	 	run("Invert");
	 	setThreshold(1, 255);	
	 	run("Analyze Particles...", "size=["+max_area+"]-Infinity show=Masks in_situ");
	 	run("Invert");
		}





	 
	 if (do_fill==true)
		run("Fill Holes");

 	

	resetThreshold();
	waitForUser("Check if the result is ok. If not, you can use additional Built-In ImageJ tools. Once you are satisfied, click on the bin image you want to save and click OK");
 	
	stack_ch2_bin=getImageID();
	imageBIN_t=getTitle();
	saveAs("tiff", dir_save+imageBIN_t+ns2+"_ch2_bin");	
	print("image ch2 was saved");
	close();
	
}








while (want_more==true)  //za vec datotek 
{

	preparation();
	
	decision_of_type();//ask_type();

	if (n==0)
		waitForUser("During opening the images the Bio-fromats Import Options window may appear. Unselect everythink, except in 'View stack with:' dropdown menu choose 'Hyperstack'.!");

	open_type(); // opens images according to the type
	
	if ((do_convert_bin==true)||(do_convert_bin_white==true)) // at this point two images need to be loaded (obtained), each for one type of the particle
	{
		convert_image1();
		convert_image2();
	}

	n=n+1;
	select=getBoolean("Do you want to procees next image set?");
	if (select==true)
		want_more==true;
	if (select==false)
		want_more=false;
	
}



close("B&C");
close("Results");


print("end");


}