ruleset manage_sensors {

    meta {
        use module io.picolabs.wrangler alias wrangler
        shares show_children, sensors
    }

    global {
        show_children = function() {
            wrangler:children()
        }

        sensors = function() {
            ent:sensors
        }

        generate_name = function() {
            <<Sensor #{wrangler:children().length() + 1}>>
        }

        defaultThreshold = 75
        defaultSMSReceiver = "8013191995"
    }

    rule init {
        select when wrangler ruleset_installed

        if (ent:sensors) then noop()
        
        notfired {
          ent:sensors := {}.klog("Initialized sensors entity variable to: ")
        }
      }

    rule add_sensor {
        select when sensor new_sensor

        pre {
            newSensorName = generate_name()
            exists = ent:sensors{newSensorName} != null
        }

        if (exists) then noop()

        notfired {
            raise wrangler event "new_child_request" attributes {
                "name": newSensorName,
                "backgroundColor": "#ffa500"
            }
        }
    }

    rule new_sensor_created {
        select when wrangler new_child_created

        pre {
            name = event:attrs{"name"}.klog("sensor_created new child name: ")
            childID = event:attrs{"eci"}.klog("new child eci: ")
        }

        if name && childID then noop()

        fired {
            ent:sensors{name} := childID
        }
    }

    rule initialize_picolabs_emitter_ruleset {
        select when wrangler new_child_created

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "io.picolabs.wovyn.emitter",
                    "config": {}
                }
            }
        )
    }

    rule initialize_wovyn_ruleset {
        select when wrangler new_child_created

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "wovyn_base",
                    "config": {}
                }
            }
        )
    }

    rule initialize_temperature_store_ruleset {
        select when wrangler new_child_created

        pre {
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "temperature_store",
                    "config": {}
                }
            }
        )
    }
    
    rule initialize_sensor_profile_ruleset {
        select when wrangler new_child_created

        pre {
            name = event:attrs{"name"}
            eci = event:attrs{"eci"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "install-ruleset",
                "domain": "wrangler", "type": "install_ruleset_request",
                "attrs": {
                    "absoluteURL": meta:rulesetURI,
                    "rid": "sensor_profile",
                    "config": {}
                }
            }
        )
    }

    rule configure_child_sensor_profile{
        select when wrangler child_initialized

        pre {
            eci = event:attrs{"eci"}
            name = event:attrs{"name"}
        }

        event:send(
            {
                "eci": eci,
                "eid": "configure-ruleset",
                "domain": "sensor", "type": "profile_update",
                "attrs": {
                    "SMS_receiver": defaultSMSReceiver,
                    "threshold": defaultThreshold,
                    "location": "unspecified",
                    "name": name
                }
            }
        )
    }

    rule remove_sensor {
        select when sensor unneeded_sensor

        pre {
            sensorName = event:attrs{"name"}.klog("received sensor name to remove: ")
            eci = ent:sensors.get(sensorName)
            exists = ent:sensors && eci != null
        }

        if exists then noop()

        fired {
            raise wrangler event "child_deletion_request" attributes {
                "eci": eci
            }
            clear ent:sensors{sensorName}
        }
    }


}