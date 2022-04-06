#!/bin/bash

declare PROJECT_IDS=$(gcloud projects list --format="flattened(PROJECT_ID)" | grep project_id | cut -d " " -f 2);

declare SEPARATOR="----------------------------------------------------------------------------------------";

for PROJECT_ID in $PROJECT_IDS; do

	gcloud config set project $PROJECT_ID;

	declare RESULTS=$(gcloud compute firewall-rules list --quiet --format="json");

	if [[ $RESULTS != "[]" ]]; then
		
		PROJECT_DETAILS=$(gcloud projects describe $PROJECT_ID --format="json");
		PROJECT_NAME=$(echo $PROJECT_DETAILS | jq '.name');
		PROJECT_APPLICATION=$(echo $PROJECT_DETAILS | jq '.labels.app');
		PROJECT_OWNER=$(echo $PROJECT_DETAILS | jq '.labels.adid');

		echo $SEPARATOR;
		echo "Firewall rules for project $PROJECT_ID";
		echo "";
		
		echo $RESULTS | jq -rc '.[]' | while IFS='' read FIREWALL_RULE;do

			ALLOWED_LABEL="";
			DENIED_LABEL="";
		
			NAME=$(echo $FIREWALL_RULE | jq '.name');
			ALLOWED=$(echo $FIREWALL_RULE | jq -c '.allowed');
			DENIED=$(echo $FIREWALL_RULE | jq -c '.denied');
			DIRECTION=$(echo $FIREWALL_RULE | jq '.direction');
			LOG_CONFIG=$(echo $FIREWALL_RULE | jq '.logConfig.enable');
			SOURCE_RANGES=$(echo $FIREWALL_RULE | jq -c '.sourceRanges');
			SOURCE_TAGS=$(echo $FIREWALL_RULE | jq -c '.sourceTags');
			DEST_RANGES=$(echo $FIREWALL_RULE | jq -c '.destinationRanges');
			DEST_TAGS=$(echo $FIREWALL_RULE | jq -c '.sourceTags');
			DISABLED=$(echo $FIREWALL_RULE | jq '.disabled');
			HAS_INTERNET_SOURCE=$(echo $SOURCE_RANGES | jq '.[]' | jq 'select(. | contains("0.0.0.0/0"))');
			ALLOWS_SSH=$(echo $ALLOWED | jq 'map(.ports)' | jq '.[] | index("22")');
			ALLOWS_RDP=$(echo $ALLOWED | jq 'map(.ports)' | jq '.[] | index("3389")');
			ALLOWS_HTTP=$(echo $ALLOWED | jq 'map(.ports)' | jq '.[] | index("80")');
			
			if [[ $ALLOWED != "null" ]]; then ALLOWED_LABEL="ALLOWED"; fi;
			if [[ $DENIED != "null" ]]; then DENIED_LABEL="DENIED"; fi;

			echo "Name: $NAME ($DIRECTION $ALLOWED_LABEL$DENIED_LABEL)";
			echo "Project Name: $PROJECT_NAME";
			echo "Project Application: $PROJECT_APPLICATION";
			echo "Project Owner: $PROJECT_OWNER";
			if [[ $ALLOWED != "null" ]]; then echo "Allowed: $ALLOWED"; fi;
			if [[ $DENIED != "null" ]]; then echo "Denied: $DENIED"; fi;
			if [[ $SOURCE_RANGES != "null" ]]; then echo "Source Ranges: $SOURCE_RANGES"; fi;
			if [[ $SOURCE_TAGS != "null" ]]; then echo "Source Tags: $SOURCE_TAGS"; fi;
			if [[ $DEST_RANGES != "null" ]]; then echo "Destination Ranges: $DEST_RANGES"; fi;
			if [[ $DEST_TAGS != "null" ]]; then echo "Destination Tags: $DEST_TAGS"; fi;
			if [[ $LOG_CONFIG != "null" ]]; then echo "Logging: $LOG_CONFIG"; fi;
			if [[ $DISABLED != "null" ]]; then echo "Disabled: $DISABLED"; fi;
			if [[ $ALLOWED_LABEL != "" && $HAS_INTERNET_SOURCE != "" ]]; then echo "Violation: Allows acccess from entire Internet"; fi;
			if [[ "$ALLOWS_SSH" =~ ^[0-9]+$ ]]; then echo "Violation: Rule includes port 22/SSH"; fi;
			if [[ "$ALLOWS_RDP" =~ ^[0-9]+$ ]]; then echo "Violation: Rule includes port 3389/RDP"; fi;
			if [[ "$ALLOWS_HTTP" =~ ^[0-9]+$ ]]; then echo "Violation: Rule includes port 80/HTTP"; fi;
			if [[ $NAME == "default-allow-icmp" ]]; then echo "Violation: Default ICMP rule implemented"; fi;
			if [[ $NAME == "default-allow-ssh" ]]; then echo "Violation: Default SSH rule implemented"; fi;
			if [[ $NAME == "default-allow-rdp" ]]; then echo "Violation: Default RDP rule implemented"; fi;			
			echo "";
		done;
	else
		echo $SEPARATOR;
		echo "No firewall rules found for $PROJECT_ID";
		echo "";
	fi;
	sleep 1;
done;

