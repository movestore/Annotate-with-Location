library('move2')
library('sf')
library('foreach')

## The parameter "data" is reserved for the data object passed on from the previous app

## to display messages to the user in the log file of the App in MoveApps one can use the function from the logger.R file: 
# logger.fatal(), logger.error(), logger.warn(), logger.info(), logger.debug(), logger.trace()

rFunction = function(data,attr) {

  #this App must to be used in combination with the "Transfer to Location Type" App!!
  
  if (!any(data$IOTYPE=="move2_nonloc"))
  {
    logger.info("There are no non-location measurements as indicated by the 'Transfer to Location' App that can be annotated with a location. Make sure to run this App before adding appropriate location data and then running this here App. For now returning input data set.")
    result <- data
  } else
  {
    nonloc <- data[!is.na(data$IOTYPE) & data$IOTYPE=="move2_nonloc",]
    nonloc <- nonloc[,!sapply(nonloc, function(x) all(is.na(x)))] #take out NA columns
    mt_track_id(nonloc) <- do.call(rbind,strsplit(as.character(mt_track_id(nonloc)),"\\."))[,1] #recap original names, if no point then keeps name
    logger.info(paste("There are non-location measurements with the following track Ids:",paste(unique(mt_track_id(nonloc)),collapse=", ")))
  
    if (is.null(attr))
    {
      logger.info("You have selected not to append any animal attributes to the track locations.")
    } else attru <- trimws(strsplit(as.character(attr),",")[[1]])
    
    data <- data[is.na(data$IOTYPE),]
    data <- data[,!sapply(data, function(x) all(is.na(x)))] #take out NA columns
    mt_track_id(data) <- do.call(rbind,strsplit(as.character(mt_track_id(data)),"\\."))[,1] #recap original names, if no point then keeps name
    logger.info(paste("There are location tracks for annotating with the following track Ids:",paste(unique(mt_track_id(data)),collapse=", "),". Make sure that they are the same as for the non-location data (small name variations are allowed)."))
    
    data.split <- split(data,mt_track_id(data))
    nonloc.split <- split(nonloc,mt_track_id(nonloc))
    
    nonloc.ann <- foreach(nonloci = nonloc.split) %do% {

      animal <- unique(mt_track_id(nonloci))
      logger.info(animal)
      n <- nchar(animal)
      animal0 <- substring(animal,1,n-1)
      ix <- c(grep(animal,names(data.split)),grep(animal0,names(data.split)))
      if (length(ix)==0)
      {
        logger.info(paste("There are no location data available for individual",animal,". Make sure that the names match. Location (0,0) will be retained for this track."))
        
        if (!is.null(attr))
        {
          nonloci[,attru] <- as.data.frame(lapply(mt_track_data(nonloci)[attru], rep, dim(nonloci)[1])) #explicitly rep each row of the attr properties
        } #attributes are appended even if no locations annotated
        
      } else
      {
        if (length(unique(ix))>1) logger.info(paste("There are more than one location track for individual",animal,", possibly due to assumptions of the App. Selecting the first one here:", names(data.split)[ix[1]],". Beware that this might lead to that not all locations of this animal are used for annotation. Make sure that only one location track per animal is added."))
        
        datai <- data.split[[ix[1]]] #this works with name additions of one character in both direction, but will give an error if there are no according data; careful: if the names differ only by last character then this might lead to a mismatch... this will be fixed and improved with move2! (only ... renaming)
        
        co <- apply(matrix(as.character(mt_time(nonloci))),1,function(x) st_coordinates(datai[which(abs(difftime(mt_time(datai),x))==min(abs(difftime(mt_time(datai),x)))),]))
        if (is.list(co)) coo <- do.call(rbind,co)[1:length(co),] else coo <- t(co)
        
        #timestamp of position that the measurement is annotated with
        time_pos <- apply(matrix(as.character(mt_time(nonloci))),1,function(x) as.character(mt_time(datai))[which(abs(difftime(mt_time(datai),x))==min(abs(difftime(mt_time(datai),x))))])
        if (is.list(time_pos)) time_pos <- do.call(rbind,time_pos)[,1] #no idea why sometimes this is a list..
        
        nonloci$location_lat <- coo[,2]
        nonloci$location_long <- coo[,1]
        nonloci$location_timestamp <- time_pos
        nonloci$geometry <- st_sfc(st_multipoint(coo),crs=st_crs("WGS84"))
        
        if (!is.null(attr))
        {
          nonloci[,attru] <- as.data.frame(lapply(mt_track_data(nonloci)[attru], rep, dim(nonloci)[1])) #explicitly rep each row of the attr properties
          
          if ("timestamp_end" %in% attru)
          {
            #nonloci[,"timestamp_end"] <- as.character(as.POSIXct(as.data.frame(nonloci[,"timestamp_end"])[,"timestamp_end"],origin="1970-01-01 00:00:00"))
            y <- as.POSIXct((mt_track_data(nonloci)["timestamp_end"])[1,1],origin="1970-01-01 00:00:00")
            coo_end <- st_coordinates(datai[which(abs(difftime(mt_time(datai),y))==min(abs(difftime(mt_time(datai),y)))),])
            location_long_end <- coo_end[1]
            location_lat_end <- coo_end[2]
            nonloci[,c("location_long_end","location_lat_end")] <- as.data.frame(lapply(c(location_long_end,location_lat_end), rep, dim(nonloci)[1]))
          }
        }
      }
      nonloci
    }
    names(nonloc.ann) <- names(nonloc.split)

    result <- mt_stack(nonloc.ann) #returns non-location
  }
  
  return(result)
}
