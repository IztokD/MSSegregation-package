//Copyright (c) 2021,  Iztok Dogsa and University of Ljubljana, Slovenia
//All rights reserved.

//This source code is licensed under the BSD-style license found in the
//LICENSE file in the root directory of this source tree. 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 																												//
//iztok.dogsa@bf.uni-lj.si																						//
//package: MSSegregation																						//
//Decode choropleth ver 1.3																						//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////




//this macro helps to decode the colors ( gray units, pixel intesities) in the images to obtain the underlying original values. For example, if the pixel value of 126 (gray color) means 25000 infected people /km2 than, after decoding, this pixel will have a value of 25000.
//what is requiered is: a sample image that will get decoded, an image of the same size that clearly shows the area in a sample image that needs to be decoded ( mask image). The color scale on sample image needs to be linear in gray or RGB space, or have a color scale in the legend that is continous and is linear along its longer axis, min and max original value
var m_height,m_width,ch_height,ch_width, ns_ch, ns_m; // dimensions of images (mask=m, sample= ch) and number of slices if images are stacks
var dir_save;
var t_ch, t_m; //for storing titles of images
var max_original,min_original; //min and max original values encoded in the colors of image
var decoded_image,decoded_image_t; //to store the ID and title of decoded image

var  RGB_linear; //endoding type, i.e. how original values, like intesity are encoded into the colours of your image (e.g.choropleth maps)

var ax= newArray (10000); //original values extracted from plot of a legend (color scale) i.e each pixel-ax, has gray value of ay.  max size of images  10000 x 10000 pix
var ay= newArray (10000);

var ax_interpolated=newArray (256);  //legend (color scale) fit to 256 grays i.e. what is the inetrperation (ax_interopolated) of eaych of gray value in ay_interopolated
var ay_interpolated=newArray (256);

var scale_length;  //color scle in legend, its length in pix

var max_gray; //max and min gray values in the legend (color scale) that will be latter determined
var min_gray;
	
var mask_exists; // to mark, wheather the masking image was already created;


macro "Decode_choropleth_ver1.3" {


function preparation()
{
	print("\\Clear");
	run("Set Measurements...", "area limit scientific redirect=None decimal=3");
	run("Clear Results");
	Close_All_Windows();
	
	
}

function Close_All_Windows() { 

      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
} 
 
function check_images()
{
	if ((ch_height!=m_height)||(ch_width!=m_width)){
	exit("dimensions of two images (stack) do not match! The program will exit");
	}

	if (ns_ch!=ns_m){
		exit("no slices of the two stacks dont match!The program will exit");
	}

	
	
}

function open_stack() {
	
	open();
	no_slices=nSlices;
	temp=getTitle();
	print("saving directory:");
	print(dir_save);
	print("source file:");
	print(temp);
	
	print("stack size: "+no_slices);	
 }


function get_image()
{
		

	Dialog.create("Select files");
	Dialog.addMessage(" In the next dialog box choose a file representing 8-bit image (or stack of images) where color codes for intesity. If the image is RGB it will get converted to grayscale.");	
	Dialog.show();
	print("sample stack or image:");    
	open_stack();
	if (bitDepth() != 8)
	{
		Dialog.create("Warning!");
		Dialog.addMessage("Your image is not 8-bit, by conversion to 8-bit image some precision loss can occur!");
		Dialog.show(); 

	}
	run("8-bit");
	run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove size scale, we work in pixels!

	t_ch = getTitle();
	ns_ch=nSlices;
	ch_height=getHeight();
	ch_width=getWidth();

	if ((ch_height>10000)||(ch_width>10000))
		¸	exit ("image exceeds maxium size of 10000 x 10000 pix"); 
	
	reselect=true;
	while (reselect==true){
		select_bckg=getBoolean("What are particles, what is background? Click 'Yes' to make a selection with ImageJ selection tools ( e.g. rectangle, oval) somewhere in the pure background. If you press No, program will assume background pixel values are 0 and white");
		setTool("rectangle");
		if (select_bckg==true)
		{					
				selectImage(t_ch);		
				waitForUser("Make a selection");
				getRawStatistics(nPixels,meanpix);
			//	print(nPixels,meanpix);
				background=meanpix;
				print(background);
		}
		if (select_bckg==false)
		{
				background=0;
		}
		reselect=false;
		run("Select All");
		if (background==255)
			run("Invert", "stack");
		if (is("Inverting LUT")==false)
			run("Invert LUT");
			
				
		if ((background!=255)&&(background!=0))
		{
			Dialog.create("warning!");
  			Dialog.addMessage("the pixel intensity of background is not 0 or 255, please reselect region of the background or, if the original background is really not white, choose 'Make background white'!");
  			Dialog.addCheckbox(" Make background white ", false); //
 			Dialog.show;

			make_bckg_white=Dialog.getCheckbox(); 
 			if (make_bckg_white==true)
 			{
 				selectImage(t_ch);
 				run("Subtract...", "value="+background+" stack");
 			}
 		
 			if (make_bckg_white==false)
 			reselect=true;
 			
		}	
		
	}
}

function get_mask()
{
	
	Dialog.create("Select files");
	Dialog.addMessage("In the next dialog box choose a file that will represent image (stack) masking the region of interest on image.");	
	Dialog.addCheckbox("The mask image is already created", true);
	Dialog.show();

	mask_exists= Dialog.getCheckbox();

		
	print("sample stack or image for mask:");    
	open_stack();

	if ((ch_height>10000)||(ch_width>10000))
		¸exit ("image exceeds maxium size of 10000 x 10000 pix");
		

//	if (bitDepth() != 8) exit ("8 bit image required."); 
	t_m = getTitle();
	ns_m=nSlices;
	m_height=getHeight();
	m_width=getWidth();


	 
	if (mask_exists==false)
	{
		run("8-bit");
		run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove scale, we work in pixels!
		reselect=true;
		while (reselect==true){
			setTool("rectangle");
			select_bckg=getBoolean("What is background? Click Yes to make a selection with Imagej selection tools ( e.g. rectangle, oval) somewhere in the pure background . If you press No, program will assume background values are 0 and white");
			if (select_bckg==true)
			{					
				selectImage(t_m);		
				waitForUser("Make a selection");
				getRawStatistics(nPixels,meanpix);
				background=meanpix;
				print(background);
			}
			reselect=false;	
			if(select_bckg==false)
				background=0;
			run("Select All");
			if (background==255)
				run("Invert", "stack");
			if (is("Inverting LUT")==false)
				run("Invert LUT");
				
			if ((background!=255)&&(background!=0))
			{
				Dialog.create("warning!");
	  			Dialog.addMessage("the pixel intensity of background is not 0 or 255, please reselect region of the background or, if the original background is really not white, choose 'Make background white'!");
	  			Dialog.addCheckbox(" Make background white ", false); //
	 			Dialog.show;
	
				make_bckg_white=Dialog.getCheckbox(); 
	 			if (make_bckg_white==true)
	 			{
	 				selectImage(t_m);
	 				run("Subtract...", "value="+background+" stack");
	 			}
	 		
	 			if (make_bckg_white==false)
	 			reselect=true;
	 			
			}	
			
		}
		run("Select None");
		select_scale=getBoolean("Is there a color scale on this (mask) image or other objects that are not the focus of analysis?");
		
		s=-1;
		while (s==-1)
		{
			if (select_scale==true)
			{
				setTool("rectangle");
				waitForUser("With oval/rectengular tool encircle the objects you want to remove and click OK. By holding Shift between slections you can select more of them.");
				s=selectionType();
				 
				if (s!=-1)
					run("Clear");
				else 
					{
						waitForUser("Nothing was selected!");
					}
			//	run("Invert"); // version dependant! at least ver 1.53c imageJ is requiered, otherwise enable this line!
			}
		}
		run("Select All");
		setThreshold(1, 255);
		
		setOption("BlackBackground", false);
		run("Threshold...");	
		waitForUser("Check/Adjust threshold and click OK");	
		
		
		run("Convert to Mask");
		run("Divide...", "value=255.000 stack"); // normalization of mask to 1; background is 0
		setMinAndMax(0, 1);
	}
}




function decode_image()
{
	print("decoding");
	setBatchMode(true);
	var original_value,gray_value;
	
//	selectImage(t_m);
//	run("32-bit");	
	
	selectImage(t_ch);
	run("32-bit");
	coef=(max_original-min_original)/255;
	
	for (a=1; a<=ns_ch; a++) {
		setSlice(a);
			for (x=0; x<=ch_width; x++) 
				for (y=0; y<=ch_height; y++) {
					gray_value=getPixel(x, y);
					original_value=gray_value*coef+min_original;	
					setPixel(x, y,original_value);
					}
		
		}
	selectImage(t_m);
	run("32-bit");	
	imageCalculator("Multiply stack", t_ch,t_m);
	decoded_image=getImageID();
	setBatchMode(false);	
	print("decoding done");	
}

	
	
	
	


function get_decoding_param()  
{
	max_original =0;
	min_original =0;
  	err=true;

  	selectImage(t_ch);
  	
 	while (err==true){
  	 	err=false;		
		Dialog.create("decoding parameters");
	  	Dialog.addMessage("To decode gray level color coded image to an image with pixels having original values, enter the following:");
	  	Dialog.addNumber("min original value:", min_original); //maximum value before the image was 8-bit color coded
		Dialog.addNumber("max original value:", max_original); //maximum value before the image was 8-bit color coded
	
		items = newArray("The original values are encoded in colours linearly in RGB space of the image", "No, or not sure- the color scale in the image will be used to extract the original values (the color scale must be present)");
  		Dialog.addRadioButtonGroup("Are original values encoded in the colors linear in RGB space?", items, 2, 1, "No, or not sure- the color scale in the image will be used to extract the original values (the color scale must be present)");
		Dialog.show();
		
		min_original= Dialog.getNumber();
		max_original = Dialog.getNumber();

	
		
		RGB_linear_string= Dialog.getRadioButton(); 
		if (RGB_linear_string=="No, or not sure- the color scale in the image will be used to extract the original values (the color scale must be present)")
				RGB_linear=false;
		else 
				RGB_linear=true;


		if (min_original>max_original){
			waitForUser("Warning! minimum value is bigger than max value!");	
			err=true;
		}

		if (min_original<0){
			waitForUser("Warning! minimum value is negative!");	
			err=true;
		}

		if (max_original<=0){		
			waitForUser("Warning! max value is negative or zero!");	
			err=true;
		} 	
  }
  print ("max original value:" +max_original);
  print ("min original value:" +min_original);  
}

function decode_scale()
{		
	selectImage(t_ch);
	run("8-bit"); // to get rid of rgb image
	run("Select None");
	setOption("InterpolateLines", false); 
	
	satisfied=false;  //a color scale is not yet satifactorily marked
	satisfied_line=false; // without user confirmation, the line on color scale is not satisfactoriliy aligned
	
	while (satisfied==false)
	{
		selectImage(t_ch);
		setTool("line");
		Dialog.createNonBlocking("Draw a line inside the color scale");
		Dialog.addMessage("By straigt line tool, draw a line inside the legend (color scale) and than press 'OK' ");
		Dialog.addCheckbox("I have done this very exactly by myself (no automatic adjustments of the drawn line will be made) ", false); //		
		Dialog.show();
	
		myself_exactly=Dialog.getCheckbox(); 
	
		if (myself_exactly==false)
		{
			getLine(x1, y1, x2, y2, lineWidth);			
		   	if (x1==-1)
		   	{
		      waitForUser("This macro requires a straight line selection! Please, retry!");
		   	} 
			else 
			{
				start_line=getPixel(x1,y1);
				stop_line=getPixel(x2,y2);
			
				print(start_line+"  "+stop_line);
			
				while ((start_line==0)||(stop_line==0))
				{			
					Dialog.createNonBlocking("Draw a line that begins and ends within the color scale");
					Dialog.addMessage("Draw a line that begins and ends within the color scale ");		
					Dialog.show();
					getLine(x1, y1, x2, y2, lineWidth);
					start_line=getPixel(x1,y1);
					stop_line=getPixel(x2,y2);
				}
						
				//vetical or horizontal legend (color scale)
				
				if ((x2-x1)>(y2-y1))
					line_dir=0; //horizontal
				if ((x2-x1)<(y2-y1))
					line_dir=1; //vertical
				if ((x2-x1)==(y2-y1)) // 45 deg
					 exit("This macro requires a horizontal line in case of horizontal color scale or vertical line in case of vertical color scale!");
					
				//line inside legend
				if (line_dir==0)
				{
					print("horizontal");
					while ((start_line!=0)&&(x1>0))
					{
						x1=x1-1;
						start_line=getPixel(x1,y1);	
					}
					while ((stop_line!=0)&&(x2<=ch_width))
					{
						x2=x2+1;
						stop_line=getPixel(x2,y1);	
					}
					x2=x2-1; //to get on the scale
					makeLine(x1,y1,x2,y1);
				}
				if (line_dir==1)
				{
					print("vertical");
					while ((start_line!=0)&&(y1>0))
					{
						y1=y1-1;
						start_line=getPixel(x1,y1);	
					}
					while ((stop_line!=0)&&(y2<=ch_height))
					{
						y2=y2+1;
						stop_line=getPixel(x1,y2);	
					}
					y2=y2-1; //to get on the scale
					makeLine(x1,y1,x1,y2);
				}
			
				dec=getBoolean("Is line positioned on the color coding scale OK? ", "Yes", "No");
	  			if (dec==true)
	  				satisfied_line=true; 
	  			else
					satisfied_line=false; 
			}
		}
		if (myself_exactly==true)
		{
			getLine(x1, y1, x2, y2, lineWidth);
			satisfied_line=true;	
			if (x1==-1)
			    exit("This macro requires a straight line selection! The macro will now exit!");	    	
		}
			
		if (satisfied_line==true)
		{ 
			run("Plot Profile");
	  		Plot.getValues(x, y);
	  		close();
	  		Plot.create("Plot Values", "lenght of scale [pix]", "gray value", x, y);
	  		Plot.show();
  			dec=getBoolean("Is scale reading (gray value on the scale vs its lenght) OK? ", "Yes", "No");
	  		if (dec==true){
	  			satisfied=true;
	  			close();
	  		}	 
	  		else
				satisfied=false;
		
		}
		if (satisfied_line==false)
			satisfied=false;		
	}
		

	max_gray=0; // for sure they are different, and will be determined ( few lines below)
	min_gray=255;

	coef=(max_original-min_original);
  
	for (i=0; i<x.length; i++)
  	{
	   //  x[i]=(x[i]+0.5)/(x.length-0.5)*coef+min_original; // +1 and -0.5 to get aligment in the middle 
	      x[i]=(x[i])*coef/(x.length-1)+min_original; 
	     scale_length=x.length;
	     ax[i]=x[i];   //copy to global array
	     ay[i]=y[i];
	 	
		 if (y[i]>max_gray) // find max and min grayvalues for nicer full grayscale these are 255 and 0, but for some color conversions they can get narrower
		 		max_gray=y[i];
		 if (y[i]<min_gray)
		 		min_gray=y[i];	
		 			 					
	     print (ax[i]+" "+ay[i]);
  	}
  Plot.create("Plot Values", "Original values", "Gray scale", x, y);	
  Plot.show();
  waitForUser ("The conversion from Gray levels to Original values will be performed based on this plot") ;
  close();
}

function interpolate() //make exactly 256 values
{
	interpolation_complete=true;

  	for (i=min_gray; i<=max_gray; i++)
  	{
  			ay_interpolated[i]=i;
  			ax_interpolated[i]=-1; // -1 means it is empty
  	}

  	//replace empty ones and remove duplictaes
	for (i=0; i<scale_length; i++)
  	{
	   	
	  //  if((ax_interpolated[ay[i]]<ax[i]))
	  	if((ax_interpolated[ay[i]]<ax[i]))
	    {
	    	if((ax_interpolated[ay[i]]==-1)){
	    		ax_interpolated[ay[i]]=ax[i];
	    	}
			else {
	    	if(ax[i-1]==ax[i])
	    		ax_interpolated[ay[i]]=ax[i];
			}
	    }
  	}
    	 
	for (i=min_gray; i<=max_gray; i++)
  	{
  			print(ay_interpolated[i]+" "+ax_interpolated[i]);
  	}
  	 //find the missing values in grayscale and make interpolation
  	for (i=min_gray; i<=max_gray; i++)
  	{
  			if(ax_interpolated[i]==-1) // missing x  value identified at y of i
  			{
  				interpolation_complete=false;	//interpolation is not yet done
  				x0=ax_interpolated[i-1]; // firts value for begining interpolation
  				y0=i-1;
  				j=i;							//seek the next value starting from current i
  				while ((interpolation_complete==false)&&(j<256))  //seeking next non missing x-value
  				{
  					if(ax_interpolated[j]!=-1)
  					{	
  						x1=ax_interpolated[j]; //second velue to end interpolation
  						y1=j;
  						x_missing = x0 + ((x1 -x0)/(y1 - y0)) * (i - y0); //interpolation
  						ax_interpolated[i]=x_missing; //interpolation completed
  						interpolation_complete=true;
  					}
  					j=j+1;		
  				}				
  			}
  			if (interpolation_complete==false)
  				exit("your legend (color scale) is of bad quality!");
  	}
  	for (i=min_gray; i<=max_gray; i++)
  	{
  			print(ay_interpolated[i]+" "+ax_interpolated[i]);
  	} 	
}

function extrapolation_max(value)
{
	
	if (value>255)
	 exit("gray value on your 8-bit image should not be bigger than 255, program will now exit!");
	delta_gray=value-max_gray;
	slope=(ax_interpolated[max_gray]-ax_interpolated[max_gray-1])/1; //div by 1 as the distance between two neihgbouring graylevels is 1.
	ax_interpolated[value]=ax_interpolated[max_gray]+delta_gray*slope;
}


function extrapolation_min(value)
{
	
	if (value<0)
	 exit("gray value on your 8-bit image should not be smaller than 0, program will now exit!");
	delta_gray=min_gray-value;
	slope=(ax_interpolated[min_gray+1]-ax_interpolated[min_gray])/1; //div by 1 as the distance betwwen two neihgbouring graylevels is 1.
	ax_interpolated[value]=ax_interpolated[min_gray]-delta_gray*slope;
}


function decode_image2()
{
	print("decoding");
	setBatchMode(true);
	var original_value,gray_value;
		
	selectImage(t_ch);
	run("32-bit");
//	coef=(max_original-min_original)/255;
	ns_ch=1;
	for (a=1; a<=ns_ch; a++) {
		setSlice(a);
			for (x=0; x<=ch_width; x++) 
				for (y=0; y<=ch_height; y++) {
					gray_value=getPixel(x, y);
					if (gray_value>max_gray)
						extrapolation_max(gray_value);
					if (gray_value<min_gray)
						extrapolation_min(gray_value);
					
					original_value=ax_interpolated[gray_value];
					setPixel(x, y,original_value);
					}
		
		}

	selectImage(t_m);
	run("32-bit");	
	imageCalculator("Multiply stack", t_ch,t_m);
	decoded_image=getImageID();
	
	setBatchMode(false);


print("decoding done");	
}



function save_images()
{
	if (mask_exists==false)
	{
		selectImage(t_m);
		temp=getTitle();
		saveAs("tiff", dir_save+"mask_"+temp);
		print("the mask image is now saved to the disk");
	}	
	selectImage(decoded_image);
	temp=getTitle();
	run("Select None");
	saveAs("tiff", dir_save+"decod_"+temp);
	print("the decoded image is now saved to the disk");
	decoded_image_t=getTitle();
	
	
}
//////main////////////////////////////////////////////

dir_save = getDirectory("Choose a Directory to save your results "); 

keep=true;
while (keep==true)
{

	preparation();
	get_image();
	get_mask();
	check_images();

	get_decoding_param();
	if (RGB_linear==true)
		decode_image();
	if (RGB_linear==false)
	{
		decode_scale();
		interpolate();
		decode_image2();	
	}
	
	save_images();
	
	
	selectWindow(decoded_image_t);// to make it the first image on the screen in front of the user
	
	keep=getBoolean("Continue with next image?");
}

}
