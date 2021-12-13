//Copyright (c) 2021,  Iztok Dogsa and University of Ljubljana, Slovenia
//All rights reserved.

//This source code is licensed under the BSD-style license found in the
//LICENSE file in the root directory of this source tree. 



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This ImageJ (Fiji) script was written by Iztok Dogsa, Biotechnical Faculty, University of Ljubljana, Slovenia//
// iztok.dogsa@bf.uni-lj.si																						//
//package: MSSegregation																						//
//convert_to_bin.ijm ver 1.3																					//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////


var dir_save;
var image_title,t_ch1, t_ch2;
var dir_save,ns1,stack_ch1_bin, ch1_height,ch1_width,ns2,stack_ch2_bin, ch2_height,ch2_width;
var dmax_full=0;
var total_area=0;
var atotal_area= newArray(4);
var diameter_ch1=1;
var diameter_ch2=1;
var circles_ch1, circles_ch2;
var total_area_together,effective_occupancy;
var stack_sourinding_zero;
var min_segregation, max_segregation;
var imageBIN_ch2_random, imageBIN_ch1_random;
var original_stack_ch1,original_stack_ch2;
var mask_of_original=false;
var manual_masking=false;
var fill_holes=false; // fill holes in common space of ch1+ch2

var inverted_mask_of_orginal_stack1,inverted_mask_of_orginal_stack2,overlap_image;

macro "sim_seg_extremes_ver1.3" {

function open_stack() {
	
	open();
	no_slices=nSlices;
	print(dir_save);
	print("stack size: "+no_slices);
	setColor(255);
	
 }

function Close_All_Windows() { 

      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      }
      
 } 





function preparation()
{
	print("\\Clear");
	run("Set Measurements...", "area limit scientific redirect=None decimal=3");
	run("Clear Results");
	Close_All_Windows();
	dir_save = getDirectory("Choose a Directory to save your results "); 
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	
}


function total_area_(i,ns)
{
	run("Clear Results");
	total_area=0;
	selectImage(i);
	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Measure");
		total_area=total_area+getResult("Area",(a-1));
		}
	//close("Results");
}


function total_area_calc()
{
//	if (mask_of_original==false)
	total_area_(stack_ch1_bin,ns1);
	atotal_area[1]=total_area;
	print("total area of particles in image (stack) ch1:");
	print(atotal_area[1]);
//	if (mask_of_original==false)
	total_area_(stack_ch2_bin,ns2);
	atotal_area[2]=total_area;
	print("total area of particles in image (stack) ch2:");
	print(atotal_area[2]);

	print("total area of particles together:");
	total_area_together=atotal_area[1]+atotal_area[2];
	print(total_area_together);
	
	
	close("Results");
	
}



function get_image1()
{
	Dialog.create("Select files");
	Dialog.addMessage("Select binary image (stack) representing ch1 (particles) of your sample");	
	Dialog.show();
	print("sample stack or image for ch1:");    
	open_stack();
	run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove scale, we work in pixels!
	if (bitDepth() != 8) exit ("8 bit image required."); 
	t_ch1 = getTitle();
	t_ch1 = substring(t_ch1,0,(lengthOf(t_ch1)-4));
	ns1=nSlices;
	setThreshold(1, 255);
	stack_ch1_bin=getImageID(); 
	ch1_height=getHeight();
	ch1_width=getWidth();	

	run("Duplicate...", "duplicate");
	original_stack_ch1=getImageID(); 
}

function get_image2()
{
	Dialog.create("Select files");
	Dialog.addMessage("Select binary image (stack) representing ch2 (particles) of your sample");	
	Dialog.show();	
	print("sample stack or image for ch:2");    
	open_stack();
	run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove scale, we work in pixels!
	if (bitDepth() != 8) exit ("8 bit image required."); 
	t_ch2 = getTitle();
	t_ch2 = substring(t_ch2,0,(lengthOf(t_ch2)-4));
	ns2=nSlices;
	setThreshold(1, 255);
	stack_ch2_bin=getImageID(); 
	ch2_height=getHeight();
	ch2_width=getWidth();


	
	run("Duplicate...", "duplicate");
	original_stack_ch2=getImageID();

}

function check_images()
{
	if ((ch1_height!=ch2_height)||(ch1_width!=ch2_width)){
	print("dimensions of two images (stack) do not match!");
	}

	if (ch1_height<ch1_width){ // only the rectangular part of an image is considered. The image considered is virtually cropped original image of dimensions dmax x dmax
		dmax_full=ch1_height; 
	}else{
		dmax_full=ch1_width;
	}

	if (ns1!=ns2){
		print("no slices of the two stacks dont match!");
	}

	
	
}






function randomize_pixels(i,ns,n_full_pixels,d) 
{	
	

	selectImage(i);
//	print(i);
	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Select All");
		run("Clear", "slice");
		if(getPixel(0, 0)==255){
			run("Invert", "slice");
		}
		b=0;
	}
		while (b<n_full_pixels){
			c=floor(random*(ns-1+1))+1;
			setSlice(c);		
			r1=random;
			r2=random;
			x=round(r1*d);
			y=round(r2*d);
			if(getPixel(x, y)==0){ // number of pixels needs to be constant adn pixels from the same channel do not overlap
				setPixel(x, y, 255);
				b=b+1;
			}		
				
		}
	
	
}

function randomize_circles(i,j,ns,n_circles_i,n_circles_j ,d) 
{	

	

	selectImage(i);




	
	if (mask_of_original==false)
		for (a=1; a<=ns; a++) {
			setSlice(a);
			run("Select All");
			fill();
			run("Restore Selection");
			run("Clear", "slice");
			
			getRawStatistics(nPixels,meanpix);
			if(meanpix==255){
				
				run("Invert", "slice");
			}
		
		}
		
	run("Select All");   //to get the sourounding to zero-later
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	stack_sourinding_zero=getImageID(); 
	

	selectImage(j);
//	print(j);

	
	if (mask_of_original==false)
	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Select All");
		fill();
		run("Restore Selection");
		run("Clear", "slice");
		getRawStatistics(nPixels,meanpix);
		if(meanpix==255){
		
			run("Invert", "slice");

		}	
	}
	



		
		selectImage(i);
		print("Placing ch1 particles, please wait...");
		try=0;
		b=0;
		allow_part_overlap=false;
		
		while (b<n_circles_i){
			try=try+1;		
			if ((try%(10*n_circles_i)==0))
				{
					accomplished=(1-((n_circles_i-b)/(n_circles_i)))*100;
					contin=getBoolean("This is getting slowly, placed ch1 particles: "+accomplished+"%  Should I continue placing ch1 particles?");
					if (contin==false)
					{
					//	print("b="+b);
						b=n_circles_i;
					}
					if (contin==true)
					{
						remains=100-accomplished;
						allow_part_overlap=getBoolean("Should I allow partial overlap of the rest ("+remains+"%) of ch1 particles with ch1 particles?"); //allow_part_overlap can become true					
					}
				
					
				}
			c=floor(random*(ns-1+1))+1;
			setSlice(c);		
			r1=random;
			r2=random;
			x=round(r1*(d-diameter_ch1));
			y=round(r2*(d-diameter_ch1));
			if (allow_part_overlap==false) 
			{
				makeOval(x, y, diameter_ch1, diameter_ch1);
				getRawStatistics(nPixels,meanpix);
			/*	print(nPixels); // !!!!!!!!!!!
				print(meanpix);
				print(x);
				print(y);
				print(diameter_ch1);
				print(diameter_ch2);*/
			

				
				if(meanpix==0){
					fill();
					b=b+1;		
				}
			}else { 									//allow_part_overlap==true, but particles must still have at least one free pixel, or pixel without ch1 particle
				
				if(getPixel(x, y)==0){
					makeOval(x, y, diameter_ch1, diameter_ch1);
					fill();
					b=b+1;			
				}
			}			
		}
	//	print("b="+b);
		print("Placing ch2 particles, please wait...");
		allow_part_overlap=false;
		try=0;
		bb=0;		
		selectImage(j);
		while (bb<n_circles_j){
			try=try+1;
				if ((try%(10*n_circles_j)==0))
				{
					accomplished=(1-((n_circles_j-bb)/(n_circles_j)))*100;
					contin=getBoolean("This is getting slowly, placed ch2 particles: "+accomplished+"%  Should I continue placing ch2 particles?");
					if (contin==false)
					{
					//	print("bb="+bb);
						bb=n_circles_j;
					}
					if (contin==true)
					{
						remains=100-accomplished;
						allow_part_overlap=getBoolean("Should I allow partial overlap of the rest ("+remains+"%) of ch2 particles with ch2 particles?"); //allow_part_overlap can become true					
					}
					
				}
	
			c=floor(random*(ns-1+1))+1;
			setSlice(c);		
			r1=random;
			r2=random;
			x=round(r1*(d-diameter_ch2));
			y=round(r2*(d-diameter_ch2));
			if (allow_part_overlap==false) 
			{
				makeOval(x, y, diameter_ch2, diameter_ch2);
				getRawStatistics(nPixels,meanpix);
				if(meanpix==0){
					fill();
					bb=bb+1;		
				}
			}else { 									//allow_part_overlap==true, but particles must still have at least one free pixel, or pixel without ch1 particle
				
				if(getPixel(x, y)==0){
					makeOval(x, y, diameter_ch2, diameter_ch2);
					fill();
					bb=bb+1;			
				}
			}			
				
		}
	//	print("bb="+bb);
	
	
}

function randomize_pixels_no_overlap(i,j,ns,n_full_pixels_i,n_full_pixels_j ,d) 
{	
	

	selectImage(i);
//	print(i);

	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Select All");
		run("Clear", "slice");
		if(getPixel(0, 0)==255){
			run("Invert","slice");
		}
	}

	selectImage(j);
//	print(j);
	
	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Select All");
		run("Clear", "slice");
		if(getPixel(0, 0)==255){
			run("Invert", "slice");

		}
	
	}


		if(n_full_pixels_i>n_full_pixels_j){
			n_full_pixels_larger=n_full_pixels_i;
			n_full_pixels_smaller=n_full_pixels_j;
			larger=i;
			smaller=j;
		}else {
			n_full_pixels_larger=n_full_pixels_j;
			n_full_pixels_smaller=n_full_pixels_i;
			larger=j;
			smaller=i;
		}
			



		b=0;
		bb=0;
		while (b<n_full_pixels_larger){
			c=floor(random*(ns-1+1))+1;
		
			r1=random;
			r2=random;
			x=round(r1*d);
			y=round(r2*d);

			free_space_i=false;
			free_space_j=false;
			selectImage(larger);
			setSlice(c);	
			if(getPixel(x, y)==0){			
				free_space_i=true;
			}
			selectImage(smaller);
			setSlice(c);	
			if(getPixel(x, y)==0){		
				free_space_j=true;
			}
			
			if ((free_space_i==true)&&(free_space_j==true)){
				selectImage(larger);
				setPixel(x, y, 255); //space is free, pixel can be set
				b=b+1;
				
				while (bb<n_full_pixels_smaller){					//2nd type of particle can be placed
					c=floor(random*(ns-1+1))+1;
						
					r1=random;
					r2=random;
					x=round(r1*d);
					y=round(r2*d);
	
					free_space_i=false;
					free_space_j=false;
					selectImage(larger);
					setSlice(c);	
					if(getPixel(x, y)==0){			
						free_space_i=true;
					}
					selectImage(smaller);
					setSlice(c);	
					if(getPixel(x, y)==0){		
						free_space_j=true;
					}
				
					if ((free_space_i==true)&&(free_space_j==true)){
						selectImage(smaller);
						setPixel(x, y, 255);
						bb=bb+1;
					}		

				
			}
			
					
				
		}
	}
	
}


function randomize_circles_no_overlap(i,j,ns,n_full_circles_i,n_full_circles_j ,d)  // n_full_circles_i,j: number of circles for particles ch1,ch2
{	
	
	var diameter_larger;
	var diameter_smaller;
	var smaller_channel_no,larger_channel_no;
	
	selectImage(i);
	//print(i);
	if (mask_of_original==true)
	{
			
		
	}else
	{
	
		for (a=1; a<=ns; a++) 
		{
			setSlice(a);
			run("Select All");
			fill();
			run("Restore Selection");
			run("Clear", "slice");
			
			getRawStatistics(nPixels,meanpix);
			if(meanpix==255){
				run("Invert", "slice");
			}
	
		}
	}
	
	run("Select All");   //to get the sourounding to zero-later
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	stack_sourinding_zero=getImageID(); 
	
	
	selectImage(j);
//	print("J0:"+j);
//	print(j);
	if (mask_of_original==true)
	{
		
		//	j=inverted_mask_of_orginal_stack2;
		//	stack_ch2_bin=j;
	}else
	{
		for (a=1; a<=ns; a++) {
			setSlice(a);
			run("Select All");
			fill();
			run("Restore Selection");
			run("Clear", "slice");
			getRawStatistics(nPixels,meanpix);
			if(meanpix==255){
				run("Invert", "slice");
			}
		}
	}



	// if number of ch1 particles is alrger than ch2 particles... 
		if(n_full_circles_i>=n_full_circles_j){
			n_full_circles_larger=n_full_circles_i;
			n_full_circles_smaller=n_full_circles_j;
			larger=i;
			smaller=j;
			diameter_larger=diameter_ch1;
			diameter_smaller=diameter_ch2;			
			larger_channel_no="ch1";
			smaller_channel_no="ch2";
			
		}else {
			n_full_circles_larger=n_full_circles_j;
			n_full_circles_smaller=n_full_circles_i;
			larger=j;
			smaller=i;
			diameter_smaller=diameter_ch1;
			diameter_larger=diameter_ch2;
			smaller_channel_no="ch1";
			larger_channel_no="ch2";
			
		}
	//setBatchMode("show");		

	//print("diameter_larger:"+diameter_larger);

		b=0;
		bb=0;
		try=0;
		print("Placing particles, please wait...");
		while (b<n_full_circles_larger){

			try=try+1;
			
			if ((try%(10*n_full_circles_larger)==0))
				{
					accomplished=(1-((n_full_circles_larger-b)/(n_full_circles_larger)))*100;
					contin=getBoolean("This is getting slowly, placed "+ larger_channel_no + " particles: "+accomplished+"%  Should I continue placing "+larger_channel_no+" particles?");
					if (contin==false)
					{
					//	print("b="+b);
						b=n_full_circles_larger;
					//	bb=n_full_circles_smaller;
					}
					/*Dialog.create("Warning");
					Dialog.addMessage("This is getting slowly, placed particles: "+accomplished);
					Dialog.addMessage("Should I continue? ");
					Dialog.show();*/
					
				}
			
			c=floor(random*(ns-1+1))+1;
		
			r1=random;
			r2=random;
			x=round(r1*(d-diameter_larger));
			y=round(r2*(d-diameter_larger));

			free_space_larger=false;
			free_space_smaller=false;
			selectImage(larger);
			setSlice(c);	
			makeOval(x, y, diameter_larger, diameter_larger);
			getRawStatistics(nPixels,meanpix);
			if(meanpix==0){			
				free_space_larger=true;
			}
			selectImage(smaller);
			setSlice(c);
			makeOval(x, y, diameter_larger, diameter_larger);
			getRawStatistics(nPixels,meanpix);	
			if(meanpix==0){		
				free_space_smaller=true;
			}
			
			if ((free_space_larger==true)&&(free_space_smaller==true)){
				selectImage(larger);
				makeOval(x, y, diameter_larger, diameter_larger);//space is free, circle can be set
				fill();
				b=b+1;
				small_placed=false;
				try_s=0;
				while ((bb<n_full_circles_smaller)&&(small_placed==false)){	//2nd type of particle can be placed
					try_s=try_s+1;
					if ((try_s%(10*n_full_circles_smaller)==0))
					{
					accomplished=(1-((n_full_circles_smaller-bb)/(n_full_circles_smaller)))*100;
					contin=getBoolean("This is getting slowly, placed "+ smaller_channel_no + " particles: "+accomplished+"%  Should I continue placing "+smaller_channel_no+" particles?");
					if (contin==false)
						{
					//	b=n_full_circles_larger;
					//	print("bb="+bb);
						bb=n_full_circles_smaller;
						}
					
					}
			
					
					c=floor(random*(ns-1+1))+1;
						
					r1=random;
					r2=random;
					x=round(r1*(d-diameter_smaller));
					y=round(r2*(d-diameter_smaller));
	
					free_space_larger=false;
					free_space_smaller=false;
					selectImage(larger);
					setSlice(c);	
					makeOval(x, y, diameter_smaller, diameter_smaller);
					getRawStatistics(nPixels,meanpix);	
					if(meanpix==0){			
						free_space_larger=true;
					}
					selectImage(smaller);
					setSlice(c);
					makeOval(x, y, diameter_smaller, diameter_smaller);
					getRawStatistics(nPixels,meanpix);	
					if(meanpix==0){				
						free_space_smaller=true;
					}
				
					if ((free_space_larger==true)&&(free_space_smaller==true)){
						selectImage(smaller);
						makeOval(x, y, diameter_smaller, diameter_smaller);//space is free, circle can be set
						fill();
						bb=bb+1;
						small_placed=true;
						
					}		

				
			}
			
					
				
		}
	}
	
//	print("b*="+b);
//	print("bb*="+bb);
	
	
}



function exportXY()
{
	save_name=dir_save+image_title+".txt";
	run("Save XY Coordinates...", "background=0 save=["+save_name+"]");
}

function number_circles()
{
//	rr_ch1=0.5*0.5*diameter_ch1*diameter_ch1;
//	rr_ch2=0.5*0.5*diameter_ch2*diameter_ch2;

	newImage("testing_circle_ch1", "8-bit white", 1000, 1000, 1);
	makeOval(0, 0, diameter_ch1, diameter_ch1);
	getRawStatistics(nPixels,meanpix);
	area_circles_ch1=nPixels;
	close(); 

	newImage("testing_circle_ch2", "8-bit white", 1000, 1000, 1);
	makeOval(0, 0, diameter_ch2, diameter_ch2);
	getRawStatistics(nPixels,meanpix);
	area_circles_ch2=nPixels;
	close(); 
	
	
	circles_ch1=round(atotal_area[1]/area_circles_ch1);
	circles_ch2=round(atotal_area[2]/area_circles_ch2);
	print("diameter:");
	print(diameter_ch1);
	print(diameter_ch2);
	print("No. of circles:");
	print(circles_ch1);
	print(circles_ch2);

	square_area_ch1=diameter_ch1*diameter_ch1*circles_ch1;
	square_area_ch2=diameter_ch2*diameter_ch2*circles_ch2;

	print("square_area");
	print(square_area_ch1);
	print(square_area_ch2);


	total_square_area=square_area_ch1+square_area_ch2;

	if (mask_of_original==false)
		effective_occupancy=total_square_area/(dmax_full*dmax_full*ns1)*100;


	if (mask_of_original==true)
		effective_occupancy=total_square_area/(atotal_area[1]+atotal_area[2])*100;
	
	

	print("total area of (ch1+ch2) simulated spherical particles"+ "total_area_together+");
	print("total area of (ch1+ch2) simulated particles outlined by square"+ "total_square_area+");

	

	print("% of theoretical occupancy by simulated particles outlined by a square of total area of "+":"+effective_occupancy);

	
	
}

function selection_of_seg_extremes()
{
	 var err=true;
	
	 while (err==true){
  	 	min_segregation=1;
		max_segregation=1;
  	 	err=false;
		Dialog.create("Choose the situation best describing the extremes of segregation for your system:");
		items = newArray("Randomly placed particles in the image (stack): ch1 and ch2 particles can overlap ", "Randomly placed particles in the image (stack): ch1 and ch2 particles can not overlap");
		Dialog.addRadioButtonGroup("1. Least segregated case:", items, 2, 1, "Randomly placed particles in the image (stack): ch1 and ch2 particles can overlap ");
		items = newArray("ch1 and ch2 particles will be present in the image (stack)", "ch1 particles will replace ch2 particles in the image (stack)", "ch2 particles will replace ch1 particles in the image (stack)");
		Dialog.addRadioButtonGroup("2. Most segregated case:", items, 2, 1, "ch1 and ch2 particles will be present in the image (stack)");
  		Dialog.show;
  	
	  	min_segregation_button=Dialog.getRadioButton;
	  	max_segregation_button=Dialog.getRadioButton;
	
	
	  	if((min_segregation_button=="Randomly placed particles in the image (stack): ch1 and ch2 particles can not overlap"))
	  		min_segregation=2;
	
	  	if(max_segregation_button=="ch1 particles will replace ch2 particles in the image (stack)")
		  	max_segregation=2;


		if(max_segregation_button=="ch2 particles will replace ch1 particles in the image (stack)")
		  	max_segregation=3;
	
		if((effective_occupancy>100)&&(min_segregation==2)&&(diameter_ch1>1)&&(diameter_ch2>1)){
		
			 Dialog.create("Warning!");
			 Dialog.addMessage("Total area of simulated spherical particles outlined by square exceeds the available image space, next time you may have to choose randomly placed particles can overlap or consider particles are disperesed in continous matrix (e.g one particle is pixel sized!)");
			 Dialog.show;
		}
		if((effective_occupancy>100)&&(min_segregation==2)&&((diameter_ch1==1)||(diameter_ch2==1))){
		
			 Dialog.create("Warning!");
			 Dialog.addMessage("Total area of simulated spherical particles outlined by square exceeds the available image space, next time you may have to choose randomly placed particles can overlap!");
			 Dialog.show;
		}
		
	 }	

	print(min_segregation_button);
	print(max_segregation_button);
	
	
	//  print(min_segregation);
	//  print(max_segregation);
  	
  	
}

function selection_of_diameters()
{
	 var err=true;
	 
	 while (err==true){
  	 	err=false;

		print(dmax_full);
			
		Dialog.create("Simulation parameters");
	
		Dialog.addNumber("diameter of ch 1 particles (pixles):", diameter_ch1); 
		Dialog.addNumber("diameter of ch 2 particles (pixles):", diameter_ch2); 
		Dialog.show();
		diameter_ch1=Dialog.getNumber(); 
		diameter_ch2=Dialog.getNumber(); 
		

		//	print(diameter_ch1);
		//	print(diameter_ch2);
	
		if ((diameter_ch1<1)||(diameter_ch1>dmax_full)){
			diameter_ch1= getNumber("diameter of ch 1 particles must be more than 1 pixel and less than dimension of image (dmax)! Enter diameter again:", 2);	
			print(dmax_full);
			print(diameter_ch1);
			
			
			err=true;
		}
		if ((diameter_ch2<1)||(diameter_ch2>dmax_full)){
			diameter_ch2= getNumber("diameter of ch 2 particles must be more than 1 pixel and less than dimension of image (dmax)! Enter diameter again:", 2);	
			print(dmax_full);
			print(diameter_ch2);
			err=true;
		}

	 }
		
		
}


function show_overlap_of_random_img()
{

	selectImage(stack_sourinding_zero);

	//waitForUser;
	run("Divide...", "value=255 stack");
	
	
	selectImage(stack_ch1_bin);
	run("Select All");
	imageCalculator("Multiply stack", stack_ch1_bin,stack_sourinding_zero);
	imageBIN_ch1_random=getImageID();

	selectImage(stack_ch2_bin);
	run("Select All");

	imageCalculator("Multiply stack" ,stack_ch2_bin,stack_sourinding_zero);
//	run("Restore Selection");
//	run("Clear Outside", "stack");
	imageBIN_ch2_random=getImageID();
	imageCalculator("Add create 32-bit stack", stack_ch1_bin,stack_ch2_bin);
	rename("overlap of ch1 min seg and ch2 min seg");
	overlap_image=getImageID();
///	selectImage(stack_ch1_bin);
//	resetThreshold();

//	selectImage(stack_ch1_bin);
//	resetThreshold();
}


function mask_originals()
{



	
	
	selectImage(original_stack_ch1);

	run("Select All");
	imageCalculator("Multiply create stack", original_stack_ch1,stack_sourinding_zero);
	saveAs("tiff", dir_save+"M_orig_ch1_bin_"+t_ch1);	


	selectImage(original_stack_ch2);

	run("Select All");
	imageCalculator("Multiply create stack", original_stack_ch2,stack_sourinding_zero);
	saveAs("tiff", dir_save+"M_orig_ch2_bin_"+t_ch2);	
	
}



function make_subselection()
{	
	var err=true;
	
	contin=getBoolean("Restrict simulation only to ROI in the image? If you press No, the entire image will be selected");
	if (contin==true)
	{
		subselect=getBoolean("Press Yes to mark ROI by hand with Imagej selection tools. If you press No, ROI will be the space occupied by particles ch1 + ch2");
		if (subselect==true)
		{		
			
			selectImage(stack_ch1_bin);
			setBatchMode("show");
			
			waitForUser("Mark ROI (the ROI will be automatically copied to ch2 image)");
			selectImage(stack_ch2_bin);
			setBatchMode("show");
			run("Restore Selection");
	//		waitForUser;
			selectImage(stack_ch1_bin);
			run("Restore Selection");
			manual_masking=true;

			print ("manual ROI selection for simulation was choosen");
		}
		if (subselect==false) 		
		{
				mask_of_original=true;
				
				imageCalculator("Add create stack", original_stack_ch1,original_stack_ch2);
				setBatchMode("show");

				
				while (err==true)
				{
					Dialog.createNonBlocking("Fill holes");
					Dialog.addMessage("Fill holes in the depicted space of ch1 and ch2?");
					Dialog.addCheckbox("Yes", false);
					Dialog.addCheckbox("No", true);
					Dialog.show();
					
					positive= Dialog.getCheckbox();
					negative= Dialog.getCheckbox();
				
					err=false;
				
					if (positive==negative)
					{
						err=true;
						Dialog.create("Warning!");
						Dialog.addMessage("You have to select (only) ONE option!");
						Dialog.show(); 
					}
				}	
				
				if (positive==true)
				{
					fill_holes=true;
					run("Fill Holes");

					confirm_OK=getBoolean("OK? No will undo the Fill, Cancel will exit the macro");

					if(confirm_OK==false)
					run("Undo");
				}
					
					
				setBatchMode("hide");	
				run("Invert", "stack");
				inverted_mask_of_orginal_stack1=getImageID();
				run("Duplicate...", "duplicate");
				inverted_mask_of_orginal_stack2=getImageID();

				selectImage(stack_ch1_bin);
				close();
				selectImage(stack_ch2_bin);
				close();
				
				stack_ch1_bin=inverted_mask_of_orginal_stack1;
				stack_ch2_bin=inverted_mask_of_orginal_stack2;
				
				print ("simulation ROI was space of ch1 + ch2");
		}	
	}
	if (contin==false)
	{
		selectImage(stack_ch1_bin);
		run("Select All");
		selectImage(stack_ch2_bin);
		run("Select All");

		print("entire area of image was selected for simulation");
	}
	selectImage(stack_ch1_bin);
	setBatchMode("hide");
	
	selectImage(stack_ch2_bin);
	setBatchMode("hide");


//	setBatchMode("hide");


	
}



function save_images()
{
	
	print("saving files");
	selectImage(imageBIN_ch1_random);
	
	saveAs("tiff", dir_save+"segmin_ch1_bin_"+t_ch1);
	selectImage(imageBIN_ch1_random);	
	resetThreshold();
	selectImage(imageBIN_ch2_random);

	selectImage(imageBIN_ch2_random);
	saveAs("tiff", dir_save+"segmin_ch2_bin_"+t_ch2);
	selectImage(imageBIN_ch2_random);
	resetThreshold();
	selectImage(stack_sourinding_zero);
	rename("mask");
	setMinAndMax(0, 1);
	saveAs("tiff", dir_save+"Mask_"+t_ch1+" "+t_ch2);

	selectImage(overlap_image);
	overlap_image_t=getTitle();
	saveAs("tiff", dir_save+overlap_image_t);

	
	name = "Log_sim_seg_extremes_ver1.3"; 
	selectWindow("Log");  //select Log-window 
	saveAs("Text", dir_save +name);
	
	
	
}


function logTime(state)
{
	getDateAndTime(year, month, week, day, hour, min, sec, msec);
	month=month+1; //because january starts with 0
	print(state);
	print("Date: "+year+"/"+month+"/"+day);
	print("Time:");
	print("\\Update:"+"Time: "+hour+":"+min+":"+sec+":"+floor(msec/100));


}

function all_to_ch1()
{
	selectImage(original_stack_ch1);
	all_in_ch1_original_t=getTitle();


	// the line bellow is correct only, if ch2 particles become ch1
	imageCalculator("Add create stack", original_stack_ch1,original_stack_ch2);
	all_in_ch1=getImageID();
	imageCalculator("Multiply stack" ,all_in_ch1,stack_sourinding_zero);
	saveAs("tiff", dir_save+"segmax_ch1_bin_"+t_ch1);	


 
	selectImage(original_stack_ch2);
	run("Duplicate...", "duplicate");
	dupl_original_stack_ch2=getTitle();
	run("Multiply...", "value=0 stack");
	saveAs("tiff", dir_save+"segmax_ch2_bin_"+t_ch2);	
	
	
}


function all_to_ch2() 
{
	
	selectImage(original_stack_ch2);
	all_in_ch2_original_t=getTitle();


	
	// the line bellow is correct only, if ch1 particles become ch2
	imageCalculator("Add create stack", original_stack_ch1,original_stack_ch2);	
	all_in_ch2=getImageID();


	imageCalculator("Multiply stack" ,all_in_ch2,stack_sourinding_zero);
	saveAs("tiff", dir_save+"segmax_ch2_bin_"+t_ch2);	


 
	selectImage(original_stack_ch1);
	run("Duplicate...", "duplicate");
	dupl_original_stack_ch1=getTitle();
	run("Multiply...", "value=0 stack");
	saveAs("tiff", dir_save+"segmax_ch1_bin_"+t_ch2);	
	
	
}


function all_to_edges()
{
	
//	waitForUser;
	
	selectImage(original_stack_ch1);
	run("Select All");
	run("Duplicate...", "duplicate");
	dupl_original_stack_ch1=getTitle();
	run("Multiply...", "value=0 stack");

	temp=getImageID();
	
	rect_height=ch1_height;
	rect_lenght=atotal_area[1]/(ch1_height*ns1);
	selectImage(temp);
	for (a=1; a<=ns1; a++) {
		setSlice(a);
		fillRect(0, 0, rect_lenght, ch1_height);
	}
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch1_bin_"+t_ch1);	


	selectImage(original_stack_ch2);
	run("Select All");
	run("Duplicate...", "duplicate");
	dupl_original_stack_ch2=getTitle();
	run("Multiply...", "value=0 stack");
	temp=getImageID();

	rect_height=ch2_height;
	rect_lenght=atotal_area[2]/(ch2_height*ns2);
	selectImage(temp);
	for (a=1; a<=ns2; a++) {
		setSlice(a);
		fillRect((dmax_full-rect_lenght), 0, rect_lenght, ch2_height);
	}
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch2_bin_"+t_ch2);

	selectImage(temp);

	
}
function fill_max_segregation_manual_masked()
{


	
	
	selectImage(stack_sourinding_zero);
	run("Duplicate...", "duplicate");
	run("Invert", "stack");
	inverted_originals_mask=getImageID();
	setThreshold(1, 255);


	selectImage(inverted_originals_mask); 
	run("Duplicate...", "duplicate");
	dupl_stack_ch1_bin=getImageID();
	run("Select All");
	setThreshold(1, 255);



	total_area_(inverted_originals_mask,ns1);
	M_stack_ch1_bin=total_area;	
	
	
	selectImage(dupl_stack_ch1_bin);
	setThreshold(1, 255);
	height=0;
	area_filled=0;
	while (area_filled<(atotal_area[1]+M_stack_ch1_bin)) {
		height=height+1;	 
		for (a=1; a<=ns1; a++) {
			setSlice(a);
			fillRect(0, 0, ch1_width, height);		
		}
		total_area_(dupl_stack_ch1_bin,ns1);	
		area_filled=total_area;	
	//	print("area filled:"+area_filled);	
	}

	
	selectImage(dupl_stack_ch1_bin);
	imageCalculator("Subtract create stack", dupl_stack_ch1_bin,inverted_originals_mask);
	temp=getImageID();
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch1_bin_"+t_ch1);	

	selectImage(inverted_originals_mask);

	setThreshold(1, 255);
	run("Duplicate...", "duplicate");
	dupl_stack_ch2_bin=getImageID();
	run("Select All");


	total_area_(inverted_originals_mask,ns2);
	M_stack_ch2_bin=total_area;	
	
	
	selectImage(dupl_stack_ch2_bin);
	setThreshold(1, 255);
	height=0;
	area_filled=0;
	while (area_filled<(atotal_area[2]+M_stack_ch2_bin)) {
		height=height+1;	 
		for (a=1; a<=ns2; a++) {
			setSlice(a);
			fillRect(0, (dmax_full-height), ch2_width, height);
	
		}
		total_area_(dupl_stack_ch2_bin,ns2);	
		area_filled=total_area;	
	//	print("area filled:"+area_filled);	
	}

	
	selectImage(dupl_stack_ch2_bin);
	imageCalculator("Subtract create stack", dupl_stack_ch2_bin,inverted_originals_mask);
	temp=getImageID();
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch2_bin_"+t_ch2);	
	
	//close unnecessary images
	selectImage(dupl_stack_ch2_bin);
	close();
	selectImage(dupl_stack_ch1_bin);
	close();
	selectImage(inverted_originals_mask);
	close();

}

function fill_max_segregation() //to make segregation extrem in the common original space of two particles
{
	

	
	
// to get common (i.e. ch1+ ch2 particles) space of two particles
	imageCalculator("Add create stack", original_stack_ch1,original_stack_ch2);
	if (fill_holes==true)
		run("Fill Holes");
	run("Invert", "stack");
	
	inverted_originals_mask=getImageID();
	setThreshold(1, 255);


	selectImage(inverted_originals_mask); 
	run("Duplicate...", "duplicate");
	dupl_stack_ch1_bin=getImageID();
	run("Select All");
	setThreshold(1, 255);



	total_area_(inverted_originals_mask,ns1);
	M_stack_ch1_bin=total_area;	
	
	
	selectImage(dupl_stack_ch1_bin);
	setThreshold(1, 255);
	height=0;
	area_filled=0;
	while (area_filled<(atotal_area[1]+M_stack_ch1_bin)) {
		height=height+1;	 
		for (a=1; a<=ns1; a++) {
			setSlice(a);
			fillRect(0, 0, ch1_width, height);		
		}
		total_area_(dupl_stack_ch1_bin,ns1);	
		area_filled=total_area;	
	//	print("area filled:"+area_filled);	
	}

	
	selectImage(dupl_stack_ch1_bin);
	imageCalculator("Subtract create stack", dupl_stack_ch1_bin,inverted_originals_mask);
	temp=getImageID();
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch1_bin_"+t_ch1);	



	selectImage(inverted_originals_mask);

	setThreshold(1, 255);
	run("Duplicate...", "duplicate");
	dupl_stack_ch2_bin=getImageID();
	run("Select All");


	total_area_(inverted_originals_mask,ns2);
	M_stack_ch2_bin=total_area;	
	
	
	selectImage(dupl_stack_ch2_bin);
	setThreshold(1, 255);
	height=0;
	area_filled=0;
	while (area_filled<(atotal_area[2]+M_stack_ch2_bin)) {
		height=height+1;	 
		for (a=1; a<=ns2; a++) {
			setSlice(a);
			fillRect(0, (dmax_full-height), ch2_width, height);
	
		}
		total_area_(dupl_stack_ch2_bin,ns2);	
		area_filled=total_area;	
	//	print("area filled:"+area_filled);	
	}

	
	selectImage(dupl_stack_ch2_bin);
	imageCalculator("Subtract create stack", dupl_stack_ch2_bin,inverted_originals_mask);
	temp=getImageID();
	selectImage(temp);
	saveAs("tiff", dir_save+"segmax_ch2_bin_"+t_ch2);	
	
	//close unnecessary images
	selectImage(dupl_stack_ch2_bin);
	close();
	selectImage(dupl_stack_ch1_bin);
	close();
	selectImage(inverted_originals_mask);
	close();
	
}




////main




preparation();


get_image1();
get_image2();

setBatchMode(true);

check_images();
total_area_calc();

make_subselection();

if (mask_of_original==false)
	total_area_calc();

selection_of_diameters();

number_circles();

selection_of_seg_extremes();



logTime("simulation started:");
print("Please, wait...");
//both chanells can overlap-but with circles
if (min_segregation==1){
	randomize_circles(stack_ch1_bin,stack_ch2_bin,ns1,circles_ch1,circles_ch2 ,dmax_full);

}
//no  overlap of particles-circles from both channels are excluding each other
if (min_segregation==2)
	randomize_circles_no_overlap(stack_ch1_bin,stack_ch2_bin,ns1,circles_ch1,circles_ch2 ,dmax_full);

if (max_segregation==2) //only A in the system
	all_to_ch1();

if (max_segregation==3) //only B in the system
	all_to_ch2();
		
if (max_segregation==1) //A and B in the system
{
	if ((mask_of_original==false)&&(manual_masking==false))
				all_to_edges();
				
	if (mask_of_original==true)

				fill_max_segregation();
				
	if (manual_masking==true)
			fill_max_segregation_manual_masked();
			
	print("Particles placing complete!");

}



show_overlap_of_random_img();
		
setBatchMode("exit and display");
setBatchMode(false);

logTime("end of simulation:");
save_images();
mask_originals();
	
//close copies of originals and unnecessary windows 
selectImage(original_stack_ch1);
close();
selectImage(original_stack_ch2);
close();

close("B&C");
close("Results");

print("end");
}
