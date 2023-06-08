# Annotate with Location*

MoveApps

Github repository: *github.com/movestore/Annotate-with-Location*

## Description
Annotates non-location data with closest-in-time locations of same individual. Works only if used `Transfer to Location Type` App on non-location data and thereafter added location data of same animals and time.

## Documentation
Note that this App is a workaround for integrating non-location and location data of the same animals/tags in time, that works in the presently linear workflow structure of MoveApps. It is linked with the `Transfer to Location Type` App and needs to be used in combination with it and some location data upload; see example workflow `Mortality by Activity with Location`. Both Apps will be removed/replaced when MoveApps will be enabled to allow for Apps with several inputs.

The App splits the data into originally non-location tracks (indicated by the attribute IOTYPE='move2_nonloc' set by the `Transfer to Location Type` App) and location tracks. Then the names are checked for overlap, the names of the non-location tracks should be contained in the location track names or vice versa (e.g. 'abc' and 'abc1'; after running check the App logs for names). If no partner location track is found the (0,0) locations are retained for that animal/track.

Once the split and pairing was successful, each originally non-location measurment will be attributed as location the closest-in-time location of the matched track. The `location_timestamp` is added as additional attribute for each row.

For analysis or integration by subsequent Apps in the workflow, a user-defined selection of animal attributes will be added to the track table (with quite some redundancy). If this selection includes `timestamp_end`, also `location_long_end` and `location_lat_end` for this timestamp and animal/track will be added.

Be aware that this likely only works with move2 location data loaded from Movebank/cloud stoage, as the adaption for same animal/track names differs between move and move2.


### Input data
move2 location object in Movebank format: combination of transformed non-location data and same-indidividual-and-time location data

### Output data
move2 location object in Movebank format: only transformed non-location data with annotated closest-in-time locations

### Artefacts
none

### Settings 
**`Animal attributes to append` (attr)**: User-listed animal attributes that will be appended to all locations of the respective track for further analyses. The names need to be in the exact spelling as provided in the output summary of the previous App, separated by comma. Default: `null`.

### Most common errors
Usually, the names of the originally non-location tracks and the location tracks do not overlap exactly, and the App has made some assumptions for renaming. The assumptions might not work for some use cases. Check the logs of the App after it has run. Please submit an issue here (with example data), if you cannot solve this naming problem.

### Null or error handling
**Setting `attr`:** Note that this setting is for animal attriutes only and that spelling mistakes will lead to the App failing. Check carefully in the output summary/overview of the previous App of the workflow.

**data:** See above for likely problems if the original non-location tracks and location tracks do not have sufficiently matching names. Note that only the annotated, originally non-location tracks will be passed on as App output.
