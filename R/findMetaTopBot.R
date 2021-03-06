# findMetaTopBot finds the Metalimnion top and bottom depths.
#
#
# Author: Luke Winslow <lawinslow@gmail.com>
# Translated from FindMetaBot.m in https://github.com/jread-usgs/Lake-Analyzer/
#

findMetaTopBot= function(wtr, thermoD, depths, slope){
	#require(stats)
	 #We need water density, not temperature to do this
	rhoVar = waterDensity(wtr)

	dRhoPerc = 0.15; #in percentage max for unique thermocline step
	numDepths = length(depths);
	drho_dz = vector(mode="double", length=numDepths-1);

	#Calculate the first derivative of density
	for(i in 1:numDepths-1){
		drho_dz[i] = ( rhoVar[i+1]-rhoVar[i] )/( depths[i+1] - depths[i] );
	}
	
	#initiate metalimnion bottom as last depth, this is returned if we can't
	# find a bottom
	metaBot_depth = depths[numDepths]; 
	Tdepth = vector(mode="double", length=numDepths-1)*NaN
	
	for(i in 1:numDepths-1){
		Tdepth[i] = mean(depths[ i:(i+1) ]);
	}
	
	tmp = sort.int(c(Tdepth, thermoD+1e-6), index.return = TRUE)
	sortDepth = tmp$x
	sortInd = tmp$ix
	drho_dz = approx(Tdepth, drho_dz, sortDepth)
	drho_dz = drho_dz$y
	
	thermo_index = 1
	thermoId = numDepths;
	for(i in 1:numDepths){
		if(thermoId == sortInd[i]){
			thermo_index = i
			break;
		}
	}
	
	for (i in thermo_index:numDepths){ # moving down from thermocline index
		if (drho_dz[i] < slope){ #top of metalimnion
			metaBot_depth = sortDepth[i];
			break
		}
	}
	
	if (i-thermo_index > 1 && drho_dz[thermo_index] > slope){
		metaBot_depth = approx(drho_dz[thermo_index:i],
			sortDepth[thermo_index:i],slope)
		metaBot_depth = metaBot_depth$y
	}
	
	if(is.na(metaBot_depth)){
		metaBot_depth = depths[numDepths]
	}
	
	for(i in seq(thermo_index,1)){
		if(drho_dz[i] < slope){
			metaTop_depth = sortDepth[i];
			break;
		}
	}
	
	if(thermo_index - i > 1 && drho_dz[thermo_index] > slope){
		metaTop_depth = approx(drho_dz[i:thermo_index], sortDepth[i:thermo_index], slope);
		metaTop_depth = metaTop_depth$y
	}
	
	list(botDepth = metaBot_depth, topDepth = metaTop_depth)
}



# Calculates water density with supplied temperature data
# wtr is in degC
# waterDensity is in grams/Liter

# <<--- Effective range of function: 0-40�C --->>

# -- Author: R. Iestyn. Woolway ----
# -- Modified by : Luke Winslow <lawinslow@gmail.com>

waterDensity <- function(wtr){
  
  if(!is.numeric(wtr)){
    stop("waterDensity input must be in numeric form (vector or matrix).")
  }
  
  # calculate density
  rho <- 1000*(1-(wtr+288.9414)*
              (wtr-3.9863)^2/(508929.2*(wtr+68.12963)))
  
  # << equation provided by:
  # �� Martin, J.L., McCutcheon, S.C., 1999. Hydrodynamics and Transport ��
  # �� for Water Quality Modeling. Lewis Publications, Boca              ��
  # �� Raton, FL, 794pp. >>
  
  return(rho)
  
}