//Copyright (c) 2021,  Iztok Dogsa and University of Ljubljana, Slovenia
//All rights reserved.

//This source code is licensed under the BSD-style license found in the
//LICENSE file in the root directory of this source tree. 

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 																												//
// iztok.dogsa@bf.uni-lj.si																						//
//package: MSSegregation																						//
//MSS_calc ver 1.36																								//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////



setBatchMode(true);
var ver="1.36";
var dir_save,ns1,stack_ch1_bin, ch1_height,ch1_width,ns2,stack_ch2_bin, ch2_height,ch2_width;
var stack_ch1_bin_Sdmax, stack_ch2_bin_Sdmax,stack_ch1_bin_Sdmin, stack_ch2_bin_Sdmin;

 
var   Sd_calc,Sdmax_calc,Sdmin_calc,MSSLD_calc, local_Sd_store; // what to calculate or store (boolean)
var assume_Sdmax=false; //if cacaluation assumes Sd^max=1;
var assume_Sdmin=false; //if cacaluation assumes Sd^min=0;
var MSSD=0; //multiscale spatial segergation distance in units of pix
var MSSL=0; //multiscale spatial segergation level in units of segregation level (no units)
var rMSSL=0;
var MSSD_SE=0; // corresponding standard errors
var MSSL_SE=0;
var MSSD_min=0; //multiscale spatial segergation distance in units of pix
var MSSL_min=0; //multiscale spatial segergation level in units of segregation level (no units)
var MSSD_SE_min=0; // corresponding standard errors
var MSSL_SE_min=0;
var MSSD_max=0; //multiscale spatial segergation distance in units of pix
var MSSL_max=0; //multiscale spatial segergation level in units of segregation level (no units)
var MSSD_SE_max=0; // corresponding standard errors
var MSSL_SE_max=0;
var rMSSL_SE=0;
var bit32_image=false; //by default binary images, with 0 and 255 values are assumed. Program can also handle 32bit images where pixel value is proportional to the amount of particles 
var resizing=false; // you can use this if the images are of high res and the computation time is long, as smaller images are processed much faster

var mean_area=0;
var count_aarea=0;
var d=0;
var dmin=0;
var dmax=0;
var dmax_full=0;
var mean_ratio=0;
var mean_ratio_NN=0;
var total_ratio=0;
var mean_ratio_weighted=0;
var total_ratio_weighted=0;
var weighted_variance_area=0;
var weighted_SD=0;
var total_weight=0;
var weighted_rSD=0;
var total_sum=0;
var total_wmean_abs_ratio=0;
var wmean_abs_ratio=0;
var total_mean_abs_ratio=0;
var mean_abs_ratio=0;


var variance_weighted_abs_ratio=0;
var	SD_weighted_abs_ratio=0;
var	rSD_weighted_abs_ratio=0;	
var SE_weighted_abs_ratio=0;


var alpha, A; //fit paramteres for allometric function

var N=1000000; // up to milion samplings for FOV
N=round(N);
var ax= newArray (N);
var ay= newArray (N);
var awVar=  newArray (1000);
var awSD=  newArray (1000);
var awrSD=  newArray (1000); 
var awpon= newArray (1000); 
var awVar_weighted_abs_ratio=  newArray (1000); 
var awSD_weighted_abs_ratio=  newArray (1000);
var awrSD_weighted_abs_ratio=  newArray (1000); 
var awrSE_weighted_abs_ratio=	newArray (1000);
var awMean=  newArray (1000); //mean weighted ratio
var aMean=  newArray (1000); //mean ratio
var aMean_NN=  newArray (1000); //mean ratio
var awMean_abs=  newArray (1000);
var aMean_abs=  newArray (1000);

var aSd=newArray(1000); // to store Segregation levels for final calculation of MSSL and MSSD
//var aSd_corrected=newArray(1000); // to store corrected/renormalized Segregation levels for final calculation of MSSL and MSSD
var aSdmin=newArray(1000);
var aSdmax=newArray(1000);

var aSd_SE=newArray(1000); // to store standard errors of Segregation levels for final calculation of MSSL and MSSD
var aSdmin_SE=newArray(1000);
var aSdmax_SE=newArray(1000);
//var aSd_corrected_SE=newArray(1000);


var weight_local_Sd=newArray (N); //to store weights for local Sd (unweighted)
var local_Sd=newArray (N); //to store local Sd (unweighted)

var aarea=newArray(N);

var ad= newArray (1000);
var atotal_area= newArray(4);
var X; // to express how many times the total area 1 is bigger then total area 2 ( from the point of view of bigger area )
var favor_X; // to express in which favor is the ratio
var steps=0;
var sampling_factor=0.005; //default values, increase for better statristics
var res_factor=0.75; //default values

var total_area=0;


macro "MSS_calc_ver1.35" {

function open_stack() {
	
	open();
	no_slices=nSlices;
	temp=getTitle();
//	print("saving directory:");
//	print(dir_save);
	print("source file:");
	print(temp);
	
	print("stack size: "+no_slices);
	
 }

function Close_All_Windows() { 

      while (nImages>0) { 
          selectImage(nImages); 
          close(); 
      } 
 } 

function logTime()
{
	getDateAndTime(year, month, week, day, hour, min, sec, msec);
	month=month+1; //because january starts with 0
	print("Date: "+year+"/"+month+"/"+day);
	print("Time:");
	print("\\Update:"+"Time: "+hour+":"+min+":"+sec+":"+floor(msec/100));


}

function fill_array(n)
{
	for (a=0; a<n; a++) {
		r1=random;
		r2=random;
//		ax[a]=round(r1*(dmax-d));
//		ay[a]=round(r2*(dmax-d));
		ax[a]=floor(r1*(dmax-d-0+1))+0; // from 0 to (dmax-d), both inclusive
		ay[a]=floor(r2*(dmax-d-0+1))+0;
		
		
	}
		

}

function scan(i,ns,n,d) 
{	
	selectImage(i);
	for (a=1; a<=ns; a++) {
		setSlice(a);
		for (b=0; b<n; b++) {
			
			x=ax[b];
			y=ay[b];
			makeRectangle(x, y, d, d);
			getRawStatistics(nPixels,meanpix);
			aarea[count_aarea]=nPixels*meanpix;  //positive pixels have value=1 if the images were normalized before ( in case of 8-bit binary images)
			count_aarea=count_aarea+1;		
		}
	}
}


function ratio(n)
{
	//N = nResults;
	
	//Mean "Area"column
	for (a=0; a<n*ns1; a++) {
		//prvi=getResult("Area",a);
	//	prvi = List.getValue("Area");
		prvi=aarea[a];
		b=a+n*ns1;
	//	drugi=getResult("Area",b);
	//	drugi = List.getValue("Area");
		drugi=aarea[b];

	
	  if ((prvi+drugi)==0)
	  {
	  	ratio_=0;
	  }else{
	 	ratio_=(prvi-drugi)/(prvi+drugi);
	  }
	  setResult("ratio_NN",a,ratio_);
	  
	  prvi=prvi/atotal_area[1]; //se normalizirajo na celo njihovo area-o; na ta način lahko opazujeom tudi mesanje sevovo, ki niso v istih deležih
	  drugi=drugi/atotal_area[2];
	  if ((prvi+drugi)==0)
	  {
	  	ratio_n=0;
	  }else{
	 	ratio_n=(prvi-drugi)/(prvi+drugi);
	  }
	  	weight=prvi+drugi;
	    setResult("ratio",a,ratio_n);
	    setResult("weight",a,weight);


	
	    
	}
//updateResults();
	//waitForUser;
}



function weighted_mean(pon)
{
	
	total_weight=0;
	total_ratio_weighted=0;
	
	NN = nResults;
	for (a=0; a<(pon*ns1); a++) {
		
	    total_weight= total_weight+getResult("weight",a);
	    total_ratio_weighted= total_ratio_weighted+getResult("weight",a)*getResult("ratio",a);
	    
	    
	}
	mean_ratio_weighted=total_ratio_weighted/( total_weight);
	setResult("weight",NN,"mean_ratio_weighted");
	setResult("weight",NN+1,mean_ratio_weighted);
}
function mean(pon)
{
	nn=nResults;
	total_ratio=0;
	total_ratio_NN=0;
	//Mean "Area"column
	for (a=0; a<(pon*ns1); a++) {
		
	    total_ratio=total_ratio+getResult("ratio",a);
	    total_ratio_NN=total_ratio_NN+getResult("ratio_NN",a);
	    
	    
	}
	mean_ratio=total_ratio/(pon*ns1);
	mean_ratio_NN=total_ratio_NN/(pon*ns1);
	setResult("ratio",nn,"mean_ratio");
	setResult("ratio",nn+1,mean_ratio);

	setResult("ratio",nn+2,"mean_ratio_NN");
	setResult("ratio",nn+3,mean_ratio_NN);
}


function var_weighted_mean_ratio(pon)
{
	NN=nResults;
	total_sum=0;
	for (a=0; a<(pon*ns1); a++) {
	    
	     total_sum=total_sum+getResult("weight",a)*(getResult("ratio",a)-(mean_ratio_weighted))*(getResult("ratio",a)-(mean_ratio_weighted));
	}

	
	weighted_variance_area=total_sum/total_weight;
	setResult("weight",NN,"weighted variance of weighted mean ratio");
	setResult("weight",NN+1,weighted_variance_area);
	setResult("weight",NN+2,"weightedSD of weighted mean ratio");
	weighted_SD=sqrt(weighted_variance_area);
	setResult("weight",NN+3,weighted_SD);
	setResult("weight",NN+4,"weighted_rSD of weighted mean ratio");
	weighted_rSD=(weighted_SD)/(mean_ratio_weighted);
	setResult("weight",NN+5,weighted_rSD);
}


function var_weighted_mean_abs_ratio(pon)
{
	NN=nResults;
	total_sum=0;
	total_sum_SE= 0;
	for (a=0; a<(pon*ns1); a++) {
	   total_sum=total_sum+getResult("weight",a)*(abs(getResult("ratio",a))-(wmean_abs_ratio))*(abs(getResult("ratio",a))-(wmean_abs_ratio));
	   total_sum_SE=total_sum_SE+getResult("weight",a)*getResult("weight",a)*(abs(getResult("ratio",a))-(wmean_abs_ratio))*(abs(getResult("ratio",a))-(wmean_abs_ratio)); 
	}



	
	variance_weighted_abs_ratio=total_sum/total_weight;
	setResult("weight",NN,"variance of weighted abs ratio");
	setResult("weight",NN+1,variance_weighted_abs_ratio);
	setResult("weight",NN+2,"SD of weighted abs ratio");
	SD_weighted_abs_ratio=sqrt(variance_weighted_abs_ratio);
	setResult("weight",NN+3,SD_weighted_abs_ratio);
	setResult("weight",NN+4,"rSD of weighted abs ratio");
	rSD_weighted_abs_ratio=(SD_weighted_abs_ratio)/(wmean_abs_ratio);  
	setResult("weight",NN+5,rSD_weighted_abs_ratio);
	setResult("weight",NN+6,"SE of weighted abs ratio");
	SE_weighted_abs_ratio=sqrt(pon/(pon-1)*total_sum_SE/(total_weight*total_weight));
}


function mean_abs_ratio_(pon)   
{
	NN=nResults;
	
	for (a=0; a<(pon*ns1); a++) {
	    //total_wmean_abs_ratio=total_wmean_abs_ratio=getResult("weight",a)*abs(getResult("ratio",a)-(mean_ratio_weighted));
	   temp_w= getResult("weight",a);
	   temp_abs=abs(getResult("ratio",a));
	   
	    total_wmean_abs_ratio=total_wmean_abs_ratio+temp_w*temp_abs; // to je abs obtezenega povprecja
	    wmean_abs_ratio=total_wmean_abs_ratio/total_weight;  //=Sd^
	
	    
	    local_Sd[a]=temp_abs;
		weight_local_Sd[a]=temp_w;
	    
	//	print("total_weight:");
	//	print(total_weight);
	     total_mean_abs_ratio=total_mean_abs_ratio+temp_abs; // to je abs navadnega povprecja
	     mean_abs_ratio=total_mean_abs_ratio/(pon*ns1);
	    
	}
	//print(total_weight);
	//print(total_wmean_abs_ratio);
	
	setResult("weight",NN,"mean weighted abs ratio");
	setResult("weight",NN+1,wmean_abs_ratio);
	setResult("weight",NN+2,"mean abs ratio");
	setResult("weight",NN+3,mean_abs_ratio);
}

function store_local_Sd(d_fov)
{
	
	run("Clear Results");

	for (a=0; a<(pon*ns1); a++) {
		
		
		x=ax[a]+d_fov/2; //to center the Sd in the middle of FOV
		y=ay[a]+d_fov/2; //to center the Sd in the middle of FOV for later plotting

		to_round=(a/pon)-0.5;
		
		z=round(to_round)+1; //slice number

		
	
		
		setResult("d of FOV",a,d_fov);
		setResult("x",a,x);
		setResult("y",a,y);
		setResult("slice",a,z);
		setResult("weight",a,weight_local_Sd[a]);
		setResult("local Sd (unweighted)",a,local_Sd[a]);
		
		

	}

	if (Sd_calc==true) // stores only for sample images
	{
		temp="_";
/*	if (Sdmax_calc==true)
		temp="max";
	if (Sdmin_calc==true)
		temp="min"; */   
	
	name = "local_Sd"+temp+d_fov; 
	selectWindow("Results");
	saveAs("Text", dir_save +name);
	}
	
}

function disply_aa()
{
	run("Clear Results");
	for (aa=0; aa<(steps); aa++) {
		setResult("d",aa,ad[aa]);
		setResult("pon",aa,awpon[aa]);
		setResult("mean_ratio_NN",aa,aMean_NN[aa]);
		setResult("mean_ratio",aa,aMean[aa]);
		setResult("mean_weighted_ratio",aa,awMean[aa]);
		setResult("mean abs ratio",aa,aMean_abs[aa]); //kako izgleda tipicen subspace
		setResult("mean weighted abs ratio (=Sd^)",aa,awMean_abs[aa]); //kako izgleda tipicen subspace obtezen
		
		setResult("variance of mean_weighted_ratio",aa,awVar[aa]);
		setResult("SD mean_weighted_ratio",aa,awSD[aa]);
		setResult("rSD mean_weighted_ratio",aa,awrSD[aa]);
		
		setResult("variance of weighted abs ratio",aa,awVar_weighted_abs_ratio[aa]);
		setResult("SD of weighted abs ratio",aa,awSD_weighted_abs_ratio[aa]);
		setResult("rSD of weighted abs ratio",aa,awrSD_weighted_abs_ratio[aa]);
		
		setResult("SE of weighted abs ratio",aa,awrSE_weighted_abs_ratio[aa]);
	   

		
	}
//	run("Summarize");
}





function total_area_(i,ns)
{
	run("Clear Results");
	total_area=0;
	selectImage(i);
	for (a=1; a<=ns; a++) {
		setSlice(a);
		run("Select All");
		run("Measure");
		if (bit32_image==false)
			total_area=total_area+getResult("Area",(a-1));
		if (bit32_image==true)								// if pixels have values meaning their amounts, it means the total amount is area x intesity = IntDen
			total_area=total_area+getResult("IntDen",(a-1));
		run("Select None");
		}
}

function save_files(x)
{	name = "statistics_of_segregation_"+x+"_ver"+ver; 
	selectWindow("Results");
	saveAs("Text", dir_save +name);
	name = "Log_"+x+"_ver"+ver; 
	selectWindow("Log");  //select Log-window 
	saveAs("Text", dir_save +name);
}


function preparation()
{
	print("\\Clear");
	run("Set Measurements...", "area integrated limit scientific redirect=None decimal=3");
	run("Clear Results");
	Close_All_Windows();
	dir_save = getDirectory("Choose a Directory to save your results "); 
	print("Saving directory:");
	print(dir_save);
	
}


function get_image_ch1(x)
{
	Dialog.create("Select files");
	Dialog.addMessage("Select binary image (stack) representing ch1 (particles) "+x);	// min = 0 max =255
	Dialog.show();
	print("sample stack or image for ch1:");    
	open_stack();
	run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove scale, we work in pixels!
	
	if ((bitDepth() != 8)&&(bit32_image==false)) exit ("8-bit image required."); 
	if ((bitDepth() != 32)&&(bit32_image==true)) exit ("32-bit image required."); 
	t_ch1 = getTitle();
	ns1=nSlices;
	if(bit32_image==false)
		setThreshold(1, 255); //for correct area calculation; not necessary for 32bit images, as 0 pixels times are = 0
	stack_ch1_bin_x=getImageID(); 
	ch1_height=getHeight();
	ch1_width=getWidth();
	return stack_ch1_bin_x;	
}

function get_image_ch2(x)
{
	Dialog.create("Select files");
	Dialog.addMessage("Select binary image (stack) representing ch2 (particles)"+x);	 // min = 0 max =255
	Dialog.show();	
	print("sample stack or image for ch:2");    
	open_stack();
	run("Set Scale...", "distance=0 known=0 unit=pixel"); //remove scale, we work in pixels!
	if ((bitDepth() != 8)&&(bit32_image==false)) exit ("8-bit image required."); 
	if ((bitDepth() != 32)&&(bit32_image==true)) exit ("32-bit image required.");  
	t_ch2 = getTitle();
	ns2=nSlices;
	if(bit32_image==false)
		setThreshold(1, 255); //for correct area calculation; not necessary for 32bit images, as 0 pixels times are = 0

	stack_ch2_bin_x=getImageID(); 
	ch2_height=getHeight();
	ch2_width=getWidth();
	return stack_ch2_bin_x;

}

function check_images()
{
	if ((ch1_height!=ch2_height)||(ch1_width!=ch2_width)){
	print("dimensions of two images (stack) do not match!");
	}

	if (ch1_height<ch1_width){ // only the rectangular part of an image is considered. The image considered is virtually cropped to the size of (larger) original image of dimensions dmax x dmax
		dmax_full=ch1_height; 
	}else{
		dmax_full=ch1_width;
	}

	if (ns1!=ns2){
		print("no slices of the two stacks dont match!");
	}

	
	
}

function total_area_calc(stack_ch1_bin_x,stack_ch2_bin_x)
{
	total_area_(stack_ch1_bin_x,ns1);
	atotal_area[1]=total_area;
	print("total area of particles in image (stack) ch1:");
	print(atotal_area[1]);
	total_area_(stack_ch2_bin_x,ns2);
	atotal_area[2]=total_area;
	print("total area of particles in image (stack) ch2:");
	print(atotal_area[2]);

	
}

function X_ratio()
{
	
	if(atotal_area[1]>atotal_area[2])
	{
		X=atotal_area[1]/atotal_area[2];
		favor_X=1;
	}

	
	if(atotal_area[1]<atotal_area[2])
	{
		X=atotal_area[2]/atotal_area[1];
		favor_X=2;
	}
	
	if(atotal_area[1]==atotal_area[2])
	{
		X=1;
		favor_X=0;
	}	
	
print("X:1="+X);
}

function simulate_steps()
{
	real_steps=0;		
	d=dmax_new;
	for (aa=0; aa<(steps); aa++) {
		if((d>=1))
		{		
			dnew=d*res_factor;
			if (d==round(dnew))
			{
				dnew=round(dnew-0.5);
			}
			else 
			{
				dnew=round(dnew);			
			}
			d=dnew;
	 		real_steps=real_steps+1;
		}
	}

	return real_steps;
}

function set_parameters()
{
	
	dmax=dmax_full;
	dmin=5;
  //	res_factor=0.75;
  //	sampling_factor=0.1;
  	err=true;
  	dmin_old=dmin;
  	dmax_old=dmax;
  	dmax_new=dmax;
  	res_factor_old=res_factor;
    sampling_factor_old=sampling_factor;
 
 	 while (err==true){
  	 	err=false;

		
		steps= (log(dmin/dmax_new))/log(res_factor)+1; //+1 as the 1st step equals to dmax in function calc_segregation_level
		steps=round(steps);
		steps=simulate_steps();

	
		dmax_sampling=round(((dmax_new-dmax_new)*(dmax_new-dmax_new))*sampling_factor+3);
		//dmax_sampling=steps*sampling_factor;
		dmin_sampling=round(((dmax_new-dmin)*(dmax_new-dmin))*sampling_factor+3);
			
		Dialog.create("Calculation parameters");
		Dialog.addMessage("original image has dimensions: "+dmax_full+" x "+dmax_full);
		Dialog.addNumber("image size (dmax of FOV):", dmax_new); //if you lower this number and check Downsize, it will FOV scan the image as it was croped to dimensions of dmax_new x dmax_new. The full image has size dmax_full x dmax_full. If Downsize is not checked the largerst d of FOV will be this number
		Dialog.addCheckbox("Downsize the image to above dimensions", resizing);
		Dialog.addNumber("dmin of FOV:", dmin);
		Dialog.addNumber("resolution factor: (more than 0, less than 1):", res_factor);
		Dialog.addNumber("sampling factor: (more than 0):", sampling_factor,5,7,"");
		Dialog.addMessage("dimension points from dmin to dmax: "+steps);
		
		Dialog.addMessage("sampling size (n) at dmin: "+dmin_sampling);
		Dialog.addMessage("sampling size (n) at dmax: "+dmax_sampling);
		Dialog.show();
		dmax_new = Dialog.getNumber();
		resizing = Dialog.getCheckbox();
		dmin = Dialog.getNumber();
		res_factor = Dialog.getNumber();
		sampling_factor=  Dialog.getNumber();

		 
		
		if ((dmin!=dmin_old)||(dmax_new!=dmax_old)||(res_factor!=res_factor_old)||(sampling_factor!=sampling_factor_old)){
		  steps= (log(dmin/dmax_new))/log(res_factor)+1; //+1 as the 1st step equals to dmax in function calc_segregation_level
		  steps=round(steps);
		  steps=simulate_steps();
		  dmin_sampling=(dmax_new/dmin*dmax_new/dmin)*sampling_factor;
		  dmin_old=dmin;
  		  dmax_old=dmax_new;
  	      res_factor_old=res_factor;
  	      sampling_factor_old=sampling_factor;
  	      
		  Dialog.create("Refreshing parameteres");
		  Dialog.addMessage("The sampling size will be updated");
		  Dialog.show();
		  err=true; // just to refresh the displayed data
		}

		if ((dmax_full>dmax_new)&&(err==true)&&(resizing==true)){
			dmax_new= getNumber("Warning! By downsizing the image you increase the speed of calculation, but also decrease the resolution of the original image("+dmax_full+" x "+dmax_full+") available to FOV scanning ! Reenter or keep new dmax:", dmax_new);	
	
		}
		

		if ((dmin<1)||(dmin>=dmax_new)){
			dmin= getNumber("dmin must be more than 0 and less than dmax! Enter dmin:", 2);	
			err=true;
		}

		if ((dmax_new>dmax)){
			dmax_new= getNumber("dmax cannot exceed the image dimensions! Enter new value:", dmax_new);	
			err=true;	
		}
	
		if ((res_factor<=0)||(res_factor>=1)){
			res_factor= getNumber("resolution factor must be more than 0 and less than 1! Enter new value:", 0.75);
			err=true;
		}

		if ((sampling_factor<=0)){
			res_factor= getNumber("sampling factor must be more than 0; Enter new value:",1);
			err=true;
		}
		if ((steps<6)){
			res_factor= getNumber("Please, increase resolution factor to have at least 6 points in the segregation level curve:",0.75);
			err=true;
		}

		if ((dmin_sampling>N)){
			sampling_factor= getNumber("sampling at dmin too much; decrase sampling factor (or decrase dmax/dmin):",1);
			err=true;
		}  
  }
  dmax=dmax_new;
  print ("dmax =" +dmax);
  print ("dmin =" +dmin);
  print ("steps ="+steps);
  print ("res_factor =" +res_factor);
  print ("sampling_factor =" +sampling_factor);
  print ("dmin sampling =" +dmin_sampling);
  print ("resizing = " +resizing);
  
}
function normalize_255(stack_ch1_bin_x,stack_ch2_bin_x)
{
	selectImage(stack_ch1_bin_x);
	run("Divide...", "value=255 stack");
	selectImage(stack_ch2_bin_x);
	run("Divide...", "value=255 stack");
	
}


function decision_what_to_calc()
{
	var err=true;
	while (err==true){
	  	 	err=false;
	  Dialog.create("Calculation choices");
	  Dialog.addMessage("What do you want to calculate?");
	 /* Dialog.addString("Title:", title);
	  Dialog.addChoice("Type:", newArray("8-bit", "16-bit", "32-bit", "RGB"));
	  Dialog.addNumber("Width:", 512);
	  Dialog.addNumber("Height:", 512);*/
	  Dialog.addCheckbox("1. segregation level (Sd^) as a function of dimension of field of view (FOV) of two particles each shown in seperate image (ch1, ch2)", true);
	  Dialog.addCheckbox("2. maximum segregation level (Sd^max) as a function of dimension of field of view (FOV) of simulated max seg. image", false);
	  Dialog.addCheckbox("3. minimum segregation level (Sd^min) as a function of dimension of field of view (FOV) of simulated min seg. image", false);
	  Dialog.addCheckbox("4. calculate also multiscale spatial segregation level (MSSL, rMSSL) and distance (MSSD)", false);
	  Dialog.addCheckbox("5. store local Sd (unweighted) together with coordinates", false);
	  Dialog.addCheckbox("6. I have 32-bit images, where pixel value means number of particle (default is 8-bit binary images)", false);
	  Dialog.show();
	
	
	    Sd_calc = Dialog.getCheckbox();
	    Sdmax_calc= Dialog.getCheckbox();
	    Sdmin_calc= Dialog.getCheckbox();
	    MSSLD_calc= Dialog.getCheckbox();
	    local_Sd_store=Dialog.getCheckbox();
		bit32_image=Dialog.getCheckbox();
		
	    if ((MSSLD_calc==true)&&((Sd_calc==false)||(Sdmax_calc==false)||(Sdmin_calc==false)))
	    {
	    		// Dialog.create("Warning!");
	    		 dec=getBoolean("If you want MSSL and MSSD computer needs to calculate data on  Sd^, Sd^max, Sd^min! If you press YES, you will be able to reselct calculation of Sd^max, Sd^min, if NO, you can choose assumptions ");
			//	 Dialog.show();  
			 if(dec==true) 		
	    		 	err=true;
	    	 if(dec==false)
	    	{
	    	 	
	    	 	Dialog.create("Which assumptions to make about Sdmax and Sdmin?");
     			Dialog.addCheckbox("maximum segregation level (Sd^max)  of simulated max seg. image is 1 for all d of FOV", false);
				Dialog.addCheckbox("minimum segregation level (Sd^min) of simulated min seg. image is 0 for all d of FOV", false);
	 			Dialog.show;

	  			
	    	 	assume_Sdmax=Dialog.getCheckbox();
	    	 	assume_Sdmin=Dialog.getCheckbox();   	 	
	    	 	store_Sdmin_array();
	    	 	store_Sdmax_array();
	    	 	Sd_calc = true;

	    	 	if (assume_Sdmax==false)
	    	 		 Sdmax_calc=true;

	    	 	if (assume_Sdmin==false)
	    	 		 Sdmin_calc=true;    	 		
	    	 	
	    	}
	    }
	}
}
function reduce_size(stack,ns)
{
	
	selectImage(stack);	
	run("Size...", "width=[dmax] height=[dmax] depth=[ns] constrain average interpolation=Bilinear");	
}

function calc_segregation_level(stack_ch1_bin_x,stack_ch2_bin_x)
{
	if (resizing==true){   //reduce the size, if this was a wish
		reduce_size(stack_ch1_bin_x,ns1);
		reduce_size(stack_ch2_bin_x,ns2);
	}
	
	run("Clear Results");
	if((atotal_area[2]==0)&&(atotal_area[1]==0))
	{
		
		/*allow_part_overlap=getBoolean("Warning, image of ch1 and ch2 are empty! The program will exit!");*/
		Dialog.create("Warning!");
		Dialog.addMessage("Image of ch1 and ch2 are empty! The Sd calculation of this image pair will be skipped!");
		Dialog.show();  
	}else{
		if((atotal_area[2]>0)&&(atotal_area[1]>0)) // else one of them is 0 so, no need to calaculate, as seg. level si alaways 1
		{
			
			if (bit32_image==false) // only if binary image where  pixel value 255 menas paricle is present and 0 it is not
				normalize_255(stack_ch1_bin_x,stack_ch2_bin_x);
			
			d=dmax;
			
			for (aa=0; aa<(steps); aa++) {
				if((d>=1))
				{
					run("Clear Results");
					count_aarea=0;
					
					selectWindow("Log");
					print("distance (pix): "+d);
					mean_ratio=0;
					total_ratio=0;
					total_ratio_NN=0;
					mean_ratio_weighted=0;
					total_ratio_weighted=0;
					total_weight=0;
					
					weighted_variance_area=0;
					weighted_SD=0;
					weighted_rSD=0;	
					
			
			
					variance_weighted_abs_ratio=0;
					SD_weighted_abs_ratio=0;
					SD_weighted_abs_ratio=0;	
				
			
					
					mean_area=0;
					wmean_abs_ratio=0;
					total_wmean_abs_ratio=0;
					mean_abs_ratio=0;
					total_mean_abs_ratio=0;
				
					pon=((dmax-d)*(dmax-d))*sampling_factor+3;
				//	pon=(dmax/d*dmax/d)*steps/(aa+1)*sampling_factor;  
					pon=round(pon);
					if (pon<1)
						pon=1;
					awpon[aa]=pon;
					print("n of FOV: "+pon);
					fill_array(pon);
					scan(stack_ch1_bin_x,ns1,pon,d);
					scan(stack_ch2_bin_x,ns2,pon,d);
					ratio(pon); //pove razmerje povrsin
					mean(pon); // pove povrepcno razmerje
					weighted_mean(pon);
					mean_abs_ratio_(pon);

				
					
					var_weighted_mean_abs_ratio(pon);
					awVar_weighted_abs_ratio[aa]=variance_weighted_abs_ratio;
					awSD_weighted_abs_ratio[aa]=SD_weighted_abs_ratio;
				 	awrSD_weighted_abs_ratio[aa]=rSD_weighted_abs_ratio;
				 	awrSE_weighted_abs_ratio[aa]=SE_weighted_abs_ratio;
				 
			
				 	
				 	var_weighted_mean_ratio(pon);
				 	awVar[aa]=weighted_variance_area;
					awSD[aa]=weighted_SD;
				 	awrSD[aa]=weighted_rSD; 
				 	
				 	
					awMean[aa]=mean_ratio_weighted ; //mean weighted ratio
					aMean[aa]=mean_ratio; //mean ratio
					aMean_NN[aa]=mean_ratio_NN;
					awMean_abs[aa]= wmean_abs_ratio;
					aMean_abs[aa]= mean_abs_ratio;
					ad[aa]=d;
					dnew=d*res_factor;
					if (d==round(dnew))
					{
						dnew=round(dnew-0.5);
					}
					else 
					{
						dnew=round(dnew);			
					}
					
					d=dnew;
					
				}
				else {
				print("during calculations the dimension of the FOV become smaller than 1 pixel, only calculations with FOV equal or greater than 1 pix will be displayed and saved.");
				}
				if (local_Sd_store==true)  //stores local Sd ( unweighted) together with coordinates nad weights, so the user can plot spatial Sd
						store_local_Sd(ad[aa]);
			}
			
			
			if (steps>1){
				disply_aa();
				}
		}
	}
}


function store_Sd_array()
{
	for (aa=0; aa<(steps); aa++) {
		aSd[aa]=awMean_abs[aa];
		aSd_SE[aa]=awrSE_weighted_abs_ratio[aa];	
		//print(aSd_SE[aa]);		
	}

	if ((atotal_area[2]==0)||(atotal_area[1]==0))
	{// it was assumed that Sdmax=1 =(or one of the two particles is not present in the max images)
		print("Ch1 or Ch2 Sd image is empty. Only one type of particle is present. Sd=1 assumed!");
		for (aa=0; aa<(steps); aa++) {
			aSd[aa]=1;
			aSd_SE[aa]=0;	
		}
	}
}


function store_Sdmax_array()
{
	
	if (assume_Sdmax==false)
	{
		for (aa=0; aa<(steps); aa++) {
			aSdmax[aa]=awMean_abs[aa];
			aSdmax_SE[aa]=awrSE_weighted_abs_ratio[aa];	
		}
		if ((atotal_area[2]==0)||(atotal_area[1]==0))// it was assumed that Sdmax=1 =(or one of the two particles is not present in the max images)
		{
			print("Ch1 or Ch2 Sdmax image is empty. Only one type of particle is present. Sdmax=1 assumed!");
			for (aa=0; aa<(steps); aa++) {
				aSdmax[aa]=1;
				aSdmax_SE[aa]=0;	
			}
		}
	}
		
	if ((assume_Sdmax==true)) // it was assumed that Sdmax=1 
		for (aa=0; aa<(steps); aa++) {
			aSdmax[aa]=1;
			aSdmax_SE[aa]=0;	
		}
	
				
}

function store_Sdmin_array()
{
	
	if (assume_Sdmin==false)
	{
		for (aa=0; aa<(steps); aa++) {
			aSdmin[aa]=awMean_abs[aa];
			aSdmin_SE[aa]=awrSE_weighted_abs_ratio[aa];		
		}
		if ((atotal_area[2]==0)||(atotal_area[1]==0)) // it was assumed that Sdmax=1 =(or one of the two particles is not present in the max images)
		{
			print("Ch1 or Ch2 Sdmin image is empty. Only one type of particle is present. Sdmin=1 assumed!");
			for (aa=0; aa<(steps); aa++) {
				aSdmin[aa]=1;
				aSdmin_SE[aa]=0;	
			}
		}
	}	
	if (assume_Sdmin==true)
		for (aa=0; aa<(steps); aa++) {
			aSdmin[aa]=0;
			aSdmin_SE[aa]=0;	
		}

	
}





function calculate_MSSLD_new()
{	


		MSSD_IE=0;
		MSSD=0;
		for (aa=0; aa<(steps-1); aa++) {									// integration by trapezoid rule
			MSSD=MSSD+(aSd[aa]+aSd[aa+1])*0.5*(ad[aa]-ad[aa+1]);
			print(MSSD);
			//MSSD_SE=MSSD_SE+(aSd_SE[aa]*aSd_SE[aa]);
			
			
			
			MSSD_SE=MSSD_SE+abs(((aSd[aa+1]+aSd_SE[aa+1])-(aSd[aa]-aSd_SE[aa]))*0.5*(ad[aa]-ad[aa+1])); //max erro, including integration error
		}

		//MSSD_SE=sqrt(steps/(steps-1)*sumw/((ad[aa]-ad[step-1])*(ad[aa]-ad[step-1]));
		print ("integation error of MSSD = "+MSSD_SE);
		
		MSSD_SE=MSSD_SE; // final SE of MSSD
		
		MSSL=MSSD/(ad[0]-ad[(steps-1)]);
		MSSL_SE=MSSD_SE/(ad[0]-ad[(steps-1)]);	 // final SE of MSSL	


		MSSD_IE_min=0;
		MSSD_min=0;
		for (aa=0; aa<(steps-1); aa++) {									// integration by trapezoid rule
			MSSD_min=MSSD_min+(aSdmin[aa]+aSdmin[aa+1])*0.5*(ad[aa]-ad[aa+1]);
			print(MSSD_min);
			//MSSD_SE_min=MSSD_SE_min+(aSdmin_SE[aa]*aSdmin_SE[aa]);
			MSSD_SE_min=MSSD_SE_min+abs(((aSdmin[aa+1]+aSdmin_SE[aa+1])-(aSdmin[aa]-aSdmin_SE[aa]))*0.5*(ad[aa]-ad[aa+1])); //max integration eror
		}
		print ("integation error of MSSD_min = "+MSSD_SE_min);
		
		MSSD_SE_min=MSSD_SE_min; // final SE of MSSD
		
		MSSL_min=MSSD_min/(ad[0]-ad[(steps-1)]);
		MSSL_SE_min=MSSD_SE_min/(ad[0]-ad[(steps-1)]);	 // final SE of MSSL



		MSSD_IE_max=0;
		MSSD_max=0;
		for (aa=0; aa<(steps-1); aa++) {									// integration by trapezoid rule
			MSSD_max=MSSD_max+(aSdmax[aa]+aSdmax[aa+1])*0.5*(ad[aa]-ad[aa+1]);
			print(MSSD_max);
		//	MSSD_SE_max=MSSD_SE_max+(aSdmax_SE[aa]*aSdmax_SE[aa]);
			MSSD_SE_max=MSSD_SE_max+abs(((aSdmax[aa+1]+aSdmax_SE[aa+1])-(aSdmax[aa]-aSdmax_SE[aa]))*0.5*(ad[aa]-ad[aa+1])); //max integration eror
		}
		print ("integation error of MSSD_max = "+MSSD_SE_max);
		
		MSSD_SE_max=MSSD_SE_max; // final SE of MSSD
		
		MSSL_max=MSSD_max/(ad[0]-ad[(steps-1)]);
		MSSL_SE_max=MSSD_SE_max/(ad[0]-ad[(steps-1)]);	 // final SE of MSSL


		rMSSL=(MSSL-MSSL_min)/(MSSL_max-MSSL_min);

		absSE_up=sqrt(MSSL_SE*MSSL_SE+MSSL_SE_min*MSSL_SE_min);		//SE estimation
		absSE_down=sqrt(MSSL_SE_max*MSSL_SE_max+MSSL_SE_min*MSSL_SE_min);
		rabsSE_up=absSE_up/(MSSL-MSSL_min);
		rabsSE_down=absSE_down/(MSSL_max-MSSL_min);
		rabsSE=sqrt(rabsSE_up*rabsSE_up+absSE_down*absSE_down);
		rMSSL_SE=abs(rMSSL*rabsSE); // absolute standard error of Sd^'
		
		
		
}
function display_important()
{
	run("Clear Results");
	for (aa=0; aa<(steps); aa++) {
		setResult("d of FOV",aa,ad[aa]);
		setResult("n of FOV",aa,awpon[aa]);

		setResult("segregation level in your image (Sd^)",aa,aSd[aa]);
		setResult("standard error of (Sd^)",aa,aSd_SE[aa]); 
		
		
	

		setResult("segregation level in min seg image (Sd^min)",aa,aSdmin[aa]); 
		setResult("standard error of (Sd^min)",aa,aSdmin_SE[aa]);
		
		setResult("segregation level in max seg image (Sd^max)",aa,aSdmax[aa]); 
		setResult("standard error of (Sd^max)",aa,aSdmax_SE[aa]);
		
		
	//	setResult("corrected&renormalized segregation level (Sd^')",aa,aSd_corrected[aa]); 		
	//	setResult("standard error of (Sd^'corr)",aa,aSd_corrected_SE[aa]);
		
		if (aa<4)
		{
				setResult("ratio of the two types of particles",0,"X:1 = ");
				setResult("ratio of the two types of particles",1,X);
	
				setResult("ratio of the two types of particles",2,"in the favor of particle ch: ");
				setResult("ratio of the two types of particles",3,favor_X);
		}else {
				setResult("ratio of the two types of particles",aa," ");

		}


		
		if (aa<6)
		{
			
			
			setResult("multiscale spatial segergation level(MSSL)",0,"your image:");
			setResult("multiscale spatial segergation level(MSSL)",1,MSSL);
			
			setResult("standard eror of MSSL",0,"your image:");
			setResult("standard eror of MSSL",1,MSSL_SE);

			setResult("multiscale spatial segergation distance (MSSD)[pix]",0,"your image:");
			setResult("multiscale spatial segergation distance (MSSD)[pix]",1,MSSD);

			setResult("standard eror of MSSD",0,"your image:");
			setResult("standard eror of MSSD",1,MSSD_SE);


			setResult("multiscale spatial segergation level(MSSL)",2,"max image:");
			setResult("multiscale spatial segergation level(MSSL)",3,MSSL_max);
			
			setResult("standard eror of MSSL",2,"max image:");
			setResult("standard eror of MSSL",3,MSSL_SE_max);

			setResult("multiscale spatial segergation distance (MSSD)[pix]",2,"max image:");
			setResult("multiscale spatial segergation distance (MSSD)[pix]",3,MSSD_max);

			setResult("standard eror of MSSD",2,"max image:");
			setResult("standard eror of MSSD",3,MSSD_SE_max);


			setResult("multiscale spatial segergation level(MSSL)",4,"min image:");
			setResult("multiscale spatial segergation level(MSSL)",5,MSSL_min);
			
			setResult("standard eror of MSSL",4,"min image:");
			setResult("standard eror of MSSL",5,MSSL_SE_min);

			setResult("multiscale spatial segergation distance (MSSD)[pix]",4,"min image:");
			setResult("multiscale spatial segergation distance (MSSD)[pix]",5,MSSD_min);

			setResult("standard eror of MSSD",4,"min image:");
			setResult("standard eror of MSSD",5,MSSD_SE_min);

		
			


				
		}else {
			setResult("multiscale spatial segergation level(MSSL)",aa," ");
			setResult("standard eror of MSSL",aa," ");
			setResult("multiscale spatial segergation distance (MSSD)[pix]",aa," ");
			setResult("standard eror of MSSD",aa," ");	
		}
		if (aa<1)
		{
			setResult("relative multiscale spatial segergation level (rMSSL-your image)",0,rMSSL);
			setResult("standard eror of rMSSL",0,rMSSL_SE);
		}else {
			setResult("relative multiscale spatial segergation level (rMSSL-your image)",aa," ");
			setResult("standard eror of rMSSL",aa," ");
		}
		 
			
	}
	name = "Sd_MSSDL"+"_ver"+ver; 
	selectWindow("Results");
	saveAs("Text", dir_save +name);	
}



function display_graph()
{
	dec=false;
	dec=getBoolean("Plot a graph d of FOV vs segregation level, Sd^ ?");
	if (dec==true)
	{
		Plot.create("Plot of Results", "d of FOV", "segregation level (Sd^)");
		Plot.add("Circle", Table.getColumn("d of FOV", "Results"), Table.getColumn("segregation level in your image (Sd^)", "Results"));
		Plot.add("error", Table.getColumn("standard error of (Sd^)", "Results"));
		Plot.setStyle(0, "black,#999999,1.0,Circle");
		if (Sdmax_calc==true){
			Plot.add("Circle", Table.getColumn("d of FOV", "Results"), Table.getColumn("segregation level in max seg image (Sd^max)", "Results"));
			Plot.add("error", Table.getColumn("standard error of (Sd^max)", "Results"));
			Plot.setStyle(1, "blue,#9999ff,1.0,Circle");
		}
		if (Sdmin_calc==true){
			Plot.add("Circle", Table.getColumn("d of FOV", "Results"), Table.getColumn("segregation level in min seg image (Sd^min)", "Results"));
			Plot.add("error", Table.getColumn("standard error of (Sd^min)", "Results"));
			Plot.setStyle(2, "red,#ff9999,1.0,Circle");
		}
		Plot.setAxisLabelSize(14.0, "plain");
		Plot.setFontSize(14.0);
		Plot.setXYLabels("d of FOV", "segregation level in your image (Sd^)");
		Plot.setFormatFlags("11001100111111");
		Plot.setLogScaleX(true);
		Plot.setLogScaleY(false);
		Plot.setLimits(dmin,dmax,0.000,1.015);
		Plot.addLegend("Sd^ in user’s sample image \nSd^ in max segregation image\nSd^ in min segregation image", "Auto");
	}
}
////////////////////////main////////////////////////////////////////////////////////////////////////////////

requires("1.53c");

decision_what_to_calc();
preparation();

//load corresponding images according to choice of what to calculate

if (Sd_calc==true)
{
	stack_ch1_bin=get_image_ch1(" of your sample (for Sd^ calculation)"); //for image of your sample
	stack_ch2_bin=get_image_ch2(" of your sample (for Sd^ calculation)");
	check_images();
}

if (Sdmax_calc==true)
{
	stack_ch1_bin_Sdmax=get_image_ch1("maximal segregation (for Sd^max calculation)"); //for simulated max segergation image
	stack_ch2_bin_Sdmax=get_image_ch2("maximal segregation (for Sd^max calculation)");
	check_images();
}

if (Sdmin_calc==true)
{
	stack_ch1_bin_Sdmin=get_image_ch1("minimal segregation (for Sd^min calculation)");  //for simulated min segergation image
	stack_ch2_bin_Sdmin=get_image_ch2("minimal segregation (for Sd^min calculation)");
	check_images();
}


set_parameters(); 

print("calculation start:");
logTime();


if (Sd_calc==true) //for image of your sample

{
	total_area_calc(stack_ch1_bin,stack_ch2_bin);
	X_ratio();
	calc_segregation_level(stack_ch1_bin,stack_ch2_bin);
	print ("calculation end of Sd");
	store_Sd_array();
	save_files("Sd");
}

if (Sdmax_calc==true) //for simulated max segergation image

{
	total_area_calc(stack_ch1_bin_Sdmax,stack_ch2_bin_Sdmax);
	calc_segregation_level(stack_ch1_bin_Sdmax,stack_ch2_bin_Sdmax);
	print ("calculation end of Sd^max");
	store_Sdmax_array();
	save_files("Sd^max");
}

if (Sdmin_calc==true) //for simulated min segergation image

{
	total_area_calc(stack_ch1_bin_Sdmin,stack_ch2_bin_Sdmin);
	calc_segregation_level(stack_ch1_bin_Sdmin,stack_ch2_bin_Sdmin);
	print ("calculation end of Sd^min");
	store_Sdmin_array();
	save_files("Sd^min");
}

if(assume_Sdmax==true)
{	    	
	    	 	
	    	 	store_Sdmax_array();
}

if(assume_Sdmin==true)
{	    	
	    	 	
	    	 	store_Sdmin_array();
}

if (MSSLD_calc==true)
{

	calculate_MSSLD_new();
	
}
	

	
print ("calculation end:");

logTime();

Close_All_Windows();

display_important();

display_graph();

selectWindow("Log");
print ("end");
setBatchMode(false);
}
