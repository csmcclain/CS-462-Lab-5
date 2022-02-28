ruleset sensor_profile {

    meta {
        shares get_sensor_info
    }

    //Define global variables/functions
    global {
        get_sensor_info = function() {
            {
                "location": ent:location == null => "Not Configured" | ent:location,
                "name": ent:name == null => "Not Configured" | ent:name,
                "SMS_receiver": ent:smsReceiver == null => "8013191995" | ent:smsReceiver,
                "threshold": ent:threshold == null => 75 | ent:threshold
            }
        }
    }


    rule process_profile_update {
        // Define when rule is selected
        select when sensor profile_update

        // Set variables that are needed (prelude)
        pre {
            location = event:attrs{"location"}.klog("Received new location: ")
            name = event:attrs{"name"}.klog("Received new name: ")
            smsReceiver = event:attrs{"SMS_receiver"}.klog("Received new sms number: ")
            threshold = event:attrs{"threshold"}.klog("Received new threshold: ")
        }

        always {
            ent:location := location;
            ent:name := name;
            ent:smsReceiver := smsReceiver;
            ent:threshold := threshold;

            raise wovyn event "configuration_change" attributes {
                "smsReceiver": smsReceiver,
                "threshold": threshold
            }
        }
    }
}